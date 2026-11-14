# ================================================================
# RAR FILE SCANNER & BLUEPRINT
# ================================================================

# Self-elevate to Administrator
$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

    exit
}

# Execution Policy Bypass
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                RAR FILE SCANNER & BLUEPRINT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$FolderPath = Read-Host "Please Enter Directory File"

$FolderPath = $FolderPath.Trim('"')

Write-Host ""

if (-not (Test-Path -LiteralPath $FolderPath -PathType Container)) {

    Write-Host "[ERROR] Folder not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Read-Host "Press Enter to exit"
    Read-Host
    Read-Host

    exit
}

Write-Host "[OK] Folder found." -ForegroundColor Green
Write-Host ""

Write-Host "[SCAN] Searching for RAR files..." -ForegroundColor Yellow
Write-Host "[SCAN] Searching all subfolders..." -ForegroundColor Yellow
Write-Host ""

$RARFiles = Get-ChildItem `
    -LiteralPath $FolderPath `
    -Recurse `
    -File `
    -Filter "*.rar" `
    -ErrorAction SilentlyContinue

$RARFiles = @($RARFiles)

$RARCount = $RARFiles.Count

$TotalBytes = ($RARFiles | Measure-Object -Property Length -Sum).Sum

if ($null -eq $TotalBytes) {
    $TotalBytes = 0
}

$TotalKB = $TotalBytes / 1KB
$TotalMB = $TotalBytes / 1MB
$TotalGB = $TotalBytes / 1GB

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                     RAR BLUEPRINT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Scanned Folder:" -ForegroundColor White
Write-Host $FolderPath -ForegroundColor Gray

Write-Host ""
Write-Host "------------------------------------------------------------"

Write-Host "Total RAR Files : " -NoNewline
Write-Host $RARCount -ForegroundColor Green

Write-Host "Total Size      : " -NoNewline
Write-Host ("{0:N2} GB" -f $TotalGB) -ForegroundColor Green

Write-Host "Total Size      : " -NoNewline
Write-Host ("{0:N2} MB" -f $TotalMB) -ForegroundColor Green

Write-Host "------------------------------------------------------------"
Write-Host ""

if ($RARCount -eq 0) {

    Write-Host "[INFO] No RAR files found." -ForegroundColor Yellow

}
else {

    Write-Host "RAR FILE LIST:" -ForegroundColor Cyan
    Write-Host ""

    $Index = 1

    foreach ($File in $RARFiles) {

        $FileSizeGB = $File.Length / 1GB
        $FileSizeMB = $File.Length / 1MB

        Write-Host "[$Index] $($File.Name)" -ForegroundColor White
        Write-Host "     Size : $("{0:N2}" -f $FileSizeGB) GB" -ForegroundColor Yellow
        Write-Host "     Path : $($File.FullName)" -ForegroundColor Gray
        Write-Host ""

        $Index++
    }
}

$ReportPath = Join-Path $FolderPath "RAR_Blueprint_Report.csv"

$Report = foreach ($File in $RARFiles) {

    [PSCustomObject]@{
        Number       = 0
        FileName     = $File.Name
        SizeGB       = [math]::Round(($File.Length / 1GB), 2)
        SizeMB       = [math]::Round(($File.Length / 1MB), 2)
        SizeBytes    = $File.Length
        FullPath     = $File.FullName
        LastModified = $File.LastWriteTime
    }
}

$Number = 1

foreach ($Item in $Report) {
    $Item.Number = $Number
    $Number++
}

$Report | Export-Csv `
    -Path $ReportPath `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                    SCAN COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[OK] Total RAR Files: $RARCount" -ForegroundColor Green
Write-Host "[OK] Total Size: $("{0:N2}" -f $TotalGB) GB" -ForegroundColor Green
Write-Host ""

Write-Host "[OK] Report saved:" -ForegroundColor Green
Write-Host $ReportPath -ForegroundColor Gray
Write-Host ""

Write-Host "Press Enter 3 times to exit..." -ForegroundColor Cyan

Read-Host

Read-Host

Read-Host