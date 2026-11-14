# ============================================================
# FOLDER STRUCTURE EXPORTER
# ============================================================
# Exports all folders, subfolders, and files recursively.
# Saves the report as a TXT file beside this PowerShell script.
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "       FOLDER STRUCTURE EXPORTER" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Get source directory
# ------------------------------------------------------------

$RootPath = Read-Host "Enter the full path of the folder to inspect"

if (-not (Test-Path -LiteralPath $RootPath -PathType Container)) {
    Write-Host ""
    Write-Host "[ERROR] The specified folder does not exist." -ForegroundColor Red
    Read-Host "Press ENTER to exit"
    exit
}

$RootPath = (Get-Item -LiteralPath $RootPath).FullName

# ------------------------------------------------------------
# Determine report location
# ------------------------------------------------------------

if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $ReportDirectory = (Get-Location).Path
}
else {
    $ReportDirectory = $PSScriptRoot
}

$ReportPath = Join-Path $ReportDirectory "Folder_Structure_Report.txt"

# ------------------------------------------------------------
# Initialize report
# ------------------------------------------------------------

$Report = [System.Collections.Generic.List[string]]::new()

$Report.Add("FOLDER STRUCTURE REPORT")
$Report.Add("============================================")
$Report.Add("Root Directory: $RootPath")
$Report.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$Report.Add("============================================")
$Report.Add("")

$FolderCount = 0
$FileCount = 0
$ErrorCount = 0

# ------------------------------------------------------------
# Recursive directory traversal
# ------------------------------------------------------------

$Stack = [System.Collections.Generic.Stack[string]]::new()
$Stack.Push($RootPath)

$Report.Add("[ROOT] $RootPath")
$FolderCount++

while ($Stack.Count -gt 0) {

    $CurrentDirectory = $Stack.Pop()

    try {

        $Entries = @(
            [System.IO.Directory]::EnumerateFileSystemEntries(
                $CurrentDirectory
            ) | Sort-Object -Descending
        )

    }
    catch {

        $Report.Add("[ACCESS ERROR] $CurrentDirectory")
        $Report.Add("  $($_.Exception.Message)")
        $ErrorCount++
        continue

    }

    foreach ($EntryPath in $Entries) {

        try {

            $Item = Get-Item -LiteralPath $EntryPath -Force -ErrorAction Stop

            $RelativePath = $Item.FullName.Substring(
                $RootPath.Length
            ).TrimStart('\', '/')

            if ($Item.PSIsContainer) {

                $Report.Add("[FOLDER] $RelativePath")
                $FolderCount++

                # Avoid following symbolic links and junctions
                $IsReparsePoint = (
                    $Item.Attributes -band
                    [System.IO.FileAttributes]::ReparsePoint
                ) -ne 0

                if (-not $IsReparsePoint) {
                    $Stack.Push($Item.FullName)
                }
                else {
                    $Report.Add("  [LINK - CONTENT NOT TRAVERSED]")
                }

            }
            else {

                $Report.Add("[FILE] $RelativePath")
                $FileCount++

            }

        }
        catch {

            $Report.Add("[ITEM ERROR] $EntryPath")
            $Report.Add("  $($_.Exception.Message)")
            $ErrorCount++

        }

    }

}

# ------------------------------------------------------------
# Add final statistics
# ------------------------------------------------------------

$Report.Add("")
$Report.Add("============================================")
$Report.Add("REPORT SUMMARY")
$Report.Add("============================================")
$Report.Add("Total Folders : $FolderCount")
$Report.Add("Total Files   : $FileCount")
$Report.Add("Access Errors : $ErrorCount")
$Report.Add("============================================")

# ------------------------------------------------------------
# Save report
# ------------------------------------------------------------

try {

    $Report | Set-Content -LiteralPath $ReportPath -Encoding UTF8

    Write-Host ""
    Write-Host "[SUCCESS] Folder structure exported." -ForegroundColor Green
    Write-Host ""
    Write-Host "Folders     : $FolderCount" -ForegroundColor Gray
    Write-Host "Files       : $FileCount" -ForegroundColor Gray
    Write-Host "Errors      : $ErrorCount" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Report saved to:" -ForegroundColor Cyan
    Write-Host $ReportPath -ForegroundColor Green

}
catch {

    Write-Host "[ERROR] Could not save report: $($_.Exception.Message)" -ForegroundColor Red

}

Write-Host ""
Read-Host "Press ENTER to exit"