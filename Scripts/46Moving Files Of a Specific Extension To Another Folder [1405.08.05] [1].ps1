# =====================================================================
# Script Name: Copy-ExtensionWithBlueprint.ps1
# Purpose:
# 1. Get source and destination parent folders.
# 2. Get a file extension, e.g. mp3.
# 3. Recreate the source folder structure in the destination.
# 4. Copy only matching files into their corresponding folders.
# 5. Avoid overwriting existing files.
# 6. Save a report in the destination folder.
# 7. Wait for Enter three times before closing.
# =====================================================================

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------
# Step 1: Console
# ---------------------------------------------------------------------

$Host.UI.RawUI.WindowTitle = "Copy Files With Folder Blueprint"
Clear-Host

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       COPY FILES WITH FOLDER BLUEPRINT           " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------
# Step 2: Get source parent folder
# ---------------------------------------------------------------------

do {
    $SourceRoot = (Read-Host "Enter SOURCE parent folder path").Trim().Trim('"')

    if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container)) {
        Write-Host "Source folder does not exist. Try again." -ForegroundColor Red
        $SourceRoot = $null
    }
}
while ([string]::IsNullOrWhiteSpace($SourceRoot))

$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path

# ---------------------------------------------------------------------
# Step 3: Get destination parent folder
# ---------------------------------------------------------------------

do {
    $DestinationRoot = (Read-Host "Enter DESTINATION parent folder path").Trim().Trim('"')

    if ([string]::IsNullOrWhiteSpace($DestinationRoot)) {
        Write-Host "Destination path cannot be empty." -ForegroundColor Red
        continue
    }

    if (-not (Test-Path -LiteralPath $DestinationRoot -PathType Container)) {
        Write-Host "Destination folder does not exist. Create it first." -ForegroundColor Red
        $DestinationRoot = $null
        continue
    }

    $DestinationRoot = (Resolve-Path -LiteralPath $DestinationRoot).Path

    # Prevent copying into the source tree or copying a source tree into itself.
    $SourceFull = [System.IO.Path]::GetFullPath($SourceRoot).TrimEnd('\') + '\'
    $DestinationFull = [System.IO.Path]::GetFullPath($DestinationRoot).TrimEnd('\') + '\'

    if ($SourceFull.StartsWith(
            $DestinationFull,
            [System.StringComparison]::OrdinalIgnoreCase
        ) -or
        $DestinationFull.StartsWith(
            $SourceFull,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {

        Write-Host "Source and destination must not be the same or nested inside each other." `
            -ForegroundColor Red

        $DestinationRoot = $null
    }
}
while ([string]::IsNullOrWhiteSpace($DestinationRoot))

# ---------------------------------------------------------------------
# Step 4: Get extension
# ---------------------------------------------------------------------

do {
    $Extension = (Read-Host "Enter extension to copy (example: mp3, jpg, pdf)").Trim()
    $Extension = $Extension.TrimStart('.')

    if ([string]::IsNullOrWhiteSpace($Extension) -or
        $Extension -match '[\\/:*?"<>|.]') {

        Write-Host "Invalid extension. Enter something like mp3." -ForegroundColor Red
        $Extension = $null
    }
}
while ([string]::IsNullOrWhiteSpace($Extension))

# ---------------------------------------------------------------------
# Step 5: Prepare report
# ---------------------------------------------------------------------

$TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$ReportPath = Join-Path $DestinationRoot `
    "BlueprintCopy_${Extension}_${TimeStamp}.txt"

$SearchErrors = @()
$CopyErrors = @()
$CreatedFolders = 0
$CopiedFiles = 0
$SkippedFiles = 0

Write-Host ""
Write-Host "Source:      $SourceRoot" -ForegroundColor Cyan
Write-Host "Destination: $DestinationRoot" -ForegroundColor Cyan
Write-Host "Extension:   .$Extension" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------
# Step 6: Get all source folders, including hidden folders
# ---------------------------------------------------------------------

$SourceFolders = @(
    Get-Item -LiteralPath $SourceRoot
)

try {
    $SourceFolders += @(
        Get-ChildItem -LiteralPath $SourceRoot `
            -Directory -Recurse -Force `
            -ErrorAction SilentlyContinue `
            -ErrorVariable +SearchErrors |
        Sort-Object { $_.FullName.Length }
    )
}
catch {
    $SearchErrors += $_
}

# ---------------------------------------------------------------------
# Step 7: Recreate folder blueprint in destination
# ---------------------------------------------------------------------

$FolderMap = @{}

foreach ($Folder in $SourceFolders) {
    if ($Folder.FullName -eq $SourceRoot) {
        $RelativePath = ""
    }
    else {
        $RelativePath = $Folder.FullName.Substring(
            $SourceRoot.TrimEnd('\').Length
        ).TrimStart('\')
    }

    $TargetFolder = if ([string]::IsNullOrEmpty($RelativePath)) {
        $DestinationRoot
    }
    else {
        Join-Path $DestinationRoot $RelativePath
    }

    # If a folder already exists, use a name ending in 2.
    # Additional conflicts become 3, 4, and so on.
    if ($RelativePath -ne "" -and
        (Test-Path -LiteralPath $TargetFolder -PathType Container)) {

        $ParentRelative = Split-Path $RelativePath -Parent
        $OriginalName = Split-Path $RelativePath -Leaf

        $ParentTarget = if ([string]::IsNullOrEmpty($ParentRelative)) {
            $DestinationRoot
        }
        else {
            Join-Path $DestinationRoot $ParentRelative
        }

        $CandidateName = "${OriginalName}2"
        $TargetFolder = Join-Path $ParentTarget $CandidateName
        $Suffix = 3

        while (Test-Path -LiteralPath $TargetFolder) {
            $CandidateName = "${OriginalName}${Suffix}"
            $TargetFolder = Join-Path $ParentTarget $CandidateName
            $Suffix++
        }
    }

    try {
        if (-not (Test-Path -LiteralPath $TargetFolder -PathType Container)) {
            New-Item -ItemType Directory -Path $TargetFolder -Force |
                Out-Null
            $CreatedFolders++
        }

        $FolderMap[$Folder.FullName] = $TargetFolder
    }
    catch {
        $CopyErrors += "Folder: $TargetFolder | $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------
# Step 8: Find and copy matching files
# ---------------------------------------------------------------------

$SourceFiles = @()

try {
    $SourceFiles = @(
        Get-ChildItem -LiteralPath $SourceRoot `
            -File -Recurse -Force `
            -ErrorAction SilentlyContinue `
            -ErrorVariable +SearchErrors |
        Where-Object { $_.Extension -ieq ".$Extension" }
    )
}
catch {
    $SearchErrors += $_
}

Write-Host "Matching files found: $($SourceFiles.Count)" -ForegroundColor Yellow
Write-Host ""

foreach ($File in $SourceFiles) {
    try {
        $SourceFolder = $File.DirectoryName

        if (-not $FolderMap.ContainsKey($SourceFolder)) {
            $CopyErrors += "No destination folder mapped for: $($File.FullName)"
            continue
        }

        $TargetFolder = $FolderMap[$SourceFolder]
        $TargetFile = Join-Path $TargetFolder $File.Name

        # Never overwrite an existing file.
        if (Test-Path -LiteralPath $TargetFile) {
            $SkippedFiles++
            continue
        }

        Copy-Item -LiteralPath $File.FullName `
            -Destination $TargetFile `
            -ErrorAction Stop

        $CopiedFiles++
    }
    catch {
        $CopyErrors += "File: $($File.FullName) | $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------
# Step 9: Build report
# ---------------------------------------------------------------------

$ReportLines = @(
    "BLUEPRINT AND FILE COPY REPORT"
    "=================================================="
    "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Source: $SourceRoot"
    "Destination: $DestinationRoot"
    "Extension: .$Extension"
    ""
    "SUMMARY"
    "Folders created: $CreatedFolders"
    "Matching files found: $($SourceFiles.Count)"
    "Files copied: $CopiedFiles"
    "Files skipped (already exist): $SkippedFiles"
    "Search errors: $($SearchErrors.Count)"
    "Copy errors: $($CopyErrors.Count)"
    ""
    "FOLDER MAPPING"
)

foreach ($SourceFolderPath in ($FolderMap.Keys | Sort-Object)) {
    $ReportLines += "$SourceFolderPath => $($FolderMap[$SourceFolderPath])"
}

if ($CopyErrors.Count -gt 0) {
    $ReportLines += ""
    $ReportLines += "COPY ERRORS:"
    $ReportLines += $CopyErrors
}

if ($SearchErrors.Count -gt 0) {
    $ReportLines += ""
    $ReportLines += "SEARCH ERRORS:"

    foreach ($SearchError in $SearchErrors) {
        $ReportLines += $SearchError.ToString()
    }
}

try {
    $ReportLines | Set-Content -LiteralPath $ReportPath -Encoding UTF8

    Write-Host ""
    Write-Host "Report saved: $ReportPath" -ForegroundColor Cyan
}
catch {
    Write-Host "Could not save report: $($_.Exception.Message)" -ForegroundColor Red
}

# ---------------------------------------------------------------------
# Step 10: Summary
# ---------------------------------------------------------------------

Write-Host ""
Write-Host "================ FINAL SUMMARY =================" -ForegroundColor Cyan
Write-Host "Folders created: $CreatedFolders"
Write-Host "Matching files found: $($SourceFiles.Count)"
Write-Host "Files copied: $CopiedFiles" -ForegroundColor Green
Write-Host "Files skipped: $SkippedFiles"
Write-Host "Search errors: $($SearchErrors.Count)"
Write-Host "Copy errors: $($CopyErrors.Count)"
Write-Host "================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Press Enter three times to close." -ForegroundColor Yellow

for ($i = 1; $i -le 3; $i++) {
    [void](Read-Host "Press Enter ($i/3)")
}