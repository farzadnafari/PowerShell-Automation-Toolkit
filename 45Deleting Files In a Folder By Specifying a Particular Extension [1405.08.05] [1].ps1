# =====================================================================
# Script Name: Remove-FilesByExtension.ps1
# Features:
# 1. Request Administrator privileges if necessary.
# 2. Ask for the root folder.
# 3. Ask for the extension to delete (example: jpg, mp3, pdf).
# 4. Search recursively, including hidden files and folders.
# 5. Display the matching files before deletion.
# 6. Require explicit confirmation before deleting.
# 7. Save a report in the root folder.
# 8. Report access and deletion errors.
# 9. Display final totals.
# 10. Wait for Enter three times before closing.
# =====================================================================

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------
# Step 1: Check Administrator privileges
# ---------------------------------------------------------------------

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal(
    $CurrentIdentity
)

$IsAdministrator = $CurrentPrincipal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdministrator) {
    Write-Host ""
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow

    try {
        $PowerShellExe = (Get-Process -Id $PID).Path

        Start-Process -FilePath $PowerShellExe `
            -ArgumentList @(
                '-NoProfile'
                '-ExecutionPolicy', 'Bypass'
                '-File', "`"$PSCommandPath`""
            ) -Verb RunAs -ErrorAction Stop

        exit
    }
    catch {
        Write-Host "Administrator access was not granted." -ForegroundColor Red
        [void](Read-Host "Press Enter to close")
        exit
    }
}

# ---------------------------------------------------------------------
# Step 2: Configure console
# ---------------------------------------------------------------------

$Host.UI.RawUI.WindowTitle = "Remove Files By Extension"
Clear-Host

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "          REMOVE FILES BY EXTENSION           " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "WARNING: Matching files will be permanently deleted." -ForegroundColor Red
Write-Host ""

# ---------------------------------------------------------------------
# Step 3: Get root folder
# ---------------------------------------------------------------------

do {
    $RootPath = (Read-Host "Enter the parent folder path").Trim().Trim('"')

    if (-not (Test-Path -LiteralPath $RootPath -PathType Container)) {
        Write-Host "Invalid folder path. Try again." -ForegroundColor Red
        $RootPath = $null
    }
}
while ([string]::IsNullOrWhiteSpace($RootPath))

$RootPath = (Resolve-Path -LiteralPath $RootPath).Path

# ---------------------------------------------------------------------
# Step 4: Get extension
# ---------------------------------------------------------------------

do {
    $Extension = (Read-Host "Enter extension to DELETE (example: jpg, mp3, pdf)").Trim()
    $Extension = $Extension.TrimStart('.')

    if ([string]::IsNullOrWhiteSpace($Extension) -or
        $Extension -match '[\\/:*?"<>|.]') {

        Write-Host "Enter a valid extension, such as jpg or pdf." -ForegroundColor Red
        $Extension = $null
    }
}
while ([string]::IsNullOrWhiteSpace($Extension))

# ---------------------------------------------------------------------
# Step 5: Create report path
# ---------------------------------------------------------------------

$TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$ReportPath = Join-Path -Path $RootPath `
    -ChildPath "DeletedFiles_${Extension}_${TimeStamp}.txt"

# ---------------------------------------------------------------------
# Step 6: Find matching files
# ---------------------------------------------------------------------

Write-Host ""
Write-Host "Searching... Please wait." -ForegroundColor Yellow

$SearchErrors = @()
$DeleteErrors = @()
$DeletedFiles = [System.Collections.Generic.List[string]]::new()
$MatchedFiles = @()

try {
    $MatchedFiles = @(
        Get-ChildItem -LiteralPath $RootPath `
            -File -Recurse -Force `
            -ErrorAction SilentlyContinue `
            -ErrorVariable +SearchErrors |
        Where-Object {
            $_.Extension -ieq ".$Extension" -and
            $_.FullName -ne $ReportPath
        }
    )
}
catch {
    $SearchErrors += $_
}

# ---------------------------------------------------------------------
# Step 7: Show matches and request confirmation
# ---------------------------------------------------------------------

Write-Host ""
Write-Host "Root folder: $RootPath"
Write-Host "Extension: .$Extension"
Write-Host "Matching files: $($MatchedFiles.Count)" -ForegroundColor Cyan
Write-Host ""

if ($MatchedFiles.Count -eq 0) {
    Write-Host "No matching files were found." -ForegroundColor Yellow
}
else {
    Write-Host "Files found:" -ForegroundColor Cyan

    $MatchedFiles |
        Select-Object -First 50 -ExpandProperty FullName |
        ForEach-Object { Write-Host $_ }

    if ($MatchedFiles.Count -gt 50) {
        Write-Host "... and $($MatchedFiles.Count - 50) more files."
    }

    Write-Host ""
    Write-Host "This operation deletes files; it does not move them to Recycle Bin." `
        -ForegroundColor Red

    $Confirmation = Read-Host "Type DELETE to permanently delete these files"

    if ($Confirmation -ceq 'DELETE') {
        foreach ($File in $MatchedFiles) {
            try {
                # Re-check that the file still exists and matches.
                if ((Test-Path -LiteralPath $File.FullName -PathType Leaf) -and
                    ([System.IO.Path]::GetExtension($File.FullName) -ieq ".$Extension")) {

                    Remove-Item -LiteralPath $File.FullName -Force -ErrorAction Stop
                    $DeletedFiles.Add($File.FullName)
                }
            }
            catch {
                $DeleteErrors += "File: $($File.FullName) | Error: $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Host "Deletion cancelled. No files were deleted." -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------
# Step 8: Build and save report
# ---------------------------------------------------------------------

$ReportLines = @(
    "FILE DELETION REPORT"
    "=================================================="
    "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Root folder: $RootPath"
    "Extension: .$Extension"
    "Files found: $($MatchedFiles.Count)"
    "Files deleted: $($DeletedFiles.Count)"
    "Search errors: $($SearchErrors.Count)"
    "Deletion errors: $($DeleteErrors.Count)"
    "=================================================="
    ""
    "DELETED FILES:"
)

$ReportLines += @($DeletedFiles | ForEach-Object { $_ })

if ($DeleteErrors.Count -gt 0) {
    $ReportLines += ""
    $ReportLines += "DELETION ERRORS:"
    $ReportLines += $DeleteErrors
}

if ($SearchErrors.Count -gt 0) {
    $ReportLines += ""
    $ReportLines += "SEARCH ERRORS:"

    foreach ($ErrorRecord in $SearchErrors) {
        $ReportLines += $ErrorRecord.ToString()
    }
}

try {
    $ReportLines | Set-Content -LiteralPath $ReportPath -Encoding UTF8

    Write-Host ""
    Write-Host "Report saved to: $ReportPath" -ForegroundColor Cyan
}
catch {
    Write-Host "Could not save the report: $($_.Exception.Message)" -ForegroundColor Red
}

# ---------------------------------------------------------------------
# Step 9: Summary
# ---------------------------------------------------------------------

Write-Host ""
Write-Host "================ FINAL SUMMARY ================" -ForegroundColor Cyan
Write-Host "Files found:    $($MatchedFiles.Count)"
Write-Host "Files deleted:  $($DeletedFiles.Count)" -ForegroundColor Green
Write-Host "Search errors:  $($SearchErrors.Count)"
Write-Host "Delete errors:  $($DeleteErrors.Count)"
Write-Host "================================================" -ForegroundColor Cyan

if ($SearchErrors.Count -gt 0 -or $DeleteErrors.Count -gt 0) {
    Write-Host "Some operations failed. Check the report." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------
# Step 10: Wait for Enter three times
# ---------------------------------------------------------------------

Write-Host ""
Write-Host "Script finished. Press Enter three times to close." -ForegroundColor Yellow

for ($i = 1; $i -le 3; $i++) {
    [void](Read-Host "Press Enter ($i/3)")
}