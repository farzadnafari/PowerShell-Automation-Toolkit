# ================================================================
# Folder State Reader
# Scans the selected folder and records its size, file count,
# folder count, date, time, and fingerprint.
# Each scan is compared with the previous state to detect changes.
# "Folder Writer.txt" is excluded from the folder state calculation.
# ================================================================

$ErrorActionPreference = "Stop"

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                    FOLDER READER 5.4                       " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# ASK FOR FOLDER
# ============================================================

$FolderPath = Read-Host "Enter folder path"

if ([string]::IsNullOrWhiteSpace($FolderPath)) {
    Write-Host ""
    Write-Host "No folder path was entered." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

$FolderPath = $FolderPath.Trim().Trim('"')

# ============================================================
# CHECK FOLDER
# ============================================================

if (-not (Test-Path -LiteralPath $FolderPath -PathType Container)) {
    Write-Host ""
    Write-Host "ERROR: Folder not found." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

try {
    $FolderPath = (Resolve-Path -LiteralPath $FolderPath).Path
}
catch {
    Write-Host ""
    Write-Host "ERROR: Cannot access folder." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# ============================================================
# LOG FILE
# ============================================================

$LogFileName = "Folder Writer.txt"
$LogFile = Join-Path $FolderPath $LogFileName

# ============================================================
# CAPTURE CURRENT LOG FILE SIZE
# ============================================================

$LogExistsBeforeScan = Test-Path -LiteralPath $LogFile -PathType Leaf

[UInt64]$LogFileSizeBeforeScan = 0

if ($LogExistsBeforeScan) {

    try {

        $LogFileInfo = Get-Item `
            -LiteralPath $LogFile `
            -Force `
            -ErrorAction Stop

        $LogFileSizeBeforeScan = [UInt64]$LogFileInfo.Length

    }
    catch {

        $LogFileSizeBeforeScan = 0
    }
}

# ============================================================
# CHECK ROBOCOPY
# ============================================================

if (-not (Get-Command robocopy.exe -ErrorAction SilentlyContinue)) {

    Write-Host ""
    Write-Host "ERROR: ROBOCOPY.EXE was not found." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# ============================================================
# TEMP LOG
# ============================================================

$TempLog = Join-Path $env:TEMP (
    "FolderReader_" + [Guid]::NewGuid().ToString("N") + ".txt"
)

Write-Host ""
Write-Host "Scanning folder..." -ForegroundColor Cyan
Write-Host "Please wait..." -ForegroundColor DarkGray
Write-Host ""

# ============================================================
# ROBOCOPY
# ============================================================

try {

    & robocopy.exe `
        "$FolderPath" `
        "$FolderPath" `
        /L `
        /S `
        /BYTES `
        /XJ `
        /R:0 `
        /W:0 `
        /NP `
        /NJH `
        "/LOG:$TempLog" | Out-Null

    $RobocopyCode = $LASTEXITCODE

}
catch {

    Write-Host ""
    Write-Host "ERROR: Robocopy could not scan the folder." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    Remove-Item $TempLog -Force -ErrorAction SilentlyContinue

    Read-Host "Press Enter to exit"
    exit
}

# ============================================================
# ROBOCOPY STATUS
# ============================================================

if ($RobocopyCode -ge 8) {

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "SCAN FAILED" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Robocopy exit code: $RobocopyCode" -ForegroundColor Red
    Write-Host ""

    Remove-Item $TempLog -Force -ErrorAction SilentlyContinue

    Read-Host "Press Enter to exit"
    exit
}

# ============================================================
# READ ROBOCOPY LOG
# ============================================================

try {

    $Lines = Get-Content `
        -LiteralPath $TempLog `
        -Encoding Default `
        -ErrorAction Stop

}
catch {

    Write-Host ""
    Write-Host "ERROR: Cannot read Robocopy result." -ForegroundColor Red

    Remove-Item $TempLog -Force -ErrorAction SilentlyContinue

    Read-Host "Press Enter to exit"
    exit
}

# ============================================================
# FUNCTION
# ============================================================

function Get-RobocopyNumber {

    param(
        [string[]]$InputLines,
        [string]$Label
    )

    foreach ($Line in $InputLines) {

        if ($Line -match "^\s*$([regex]::Escape($Label))\s*:\s*(.*)$") {

            $RightSide = $Matches[1]

            if ($RightSide -match "([0-9][0-9,\.]*)") {

                $Number = $Matches[1]

                $Number = $Number -replace "[^0-9]", ""

                if ($Number.Length -gt 0) {
                    return [UInt64]$Number
                }
            }
        }
    }

    return $null
}

# ============================================================
# GET SUMMARY
# ============================================================

$FileResult = Get-RobocopyNumber `
    -InputLines $Lines `
    -Label "Files"

$DirResult = Get-RobocopyNumber `
    -InputLines $Lines `
    -Label "Dirs"

$ByteResult = Get-RobocopyNumber `
    -InputLines $Lines `
    -Label "Bytes"

# ============================================================
# VALIDATE
# ============================================================

if ($null -eq $ByteResult) {

    Write-Host ""
    Write-Host "ERROR: Could not read byte count from Robocopy." -ForegroundColor Red
    Write-Host ""

    $Lines |
        Select-Object -Last 25 |
        ForEach-Object {
            Write-Host $_
        }

    Remove-Item $TempLog -Force -ErrorAction SilentlyContinue

    Read-Host "Press Enter to exit"
    exit
}

if ($null -eq $FileResult) {

    Write-Host ""
    Write-Host "ERROR: Could not read file count." -ForegroundColor Red

    Remove-Item $TempLog -Force -ErrorAction SilentlyContinue

    Read-Host "Press Enter to exit"
    exit
}

if ($null -eq $DirResult) {

    Write-Host ""
    Write-Host "ERROR: Could not read folder count." -ForegroundColor Red

    Remove-Item $TempLog -Force -ErrorAction SilentlyContinue

    Read-Host "Press Enter to exit"
    exit
}

# ============================================================
# RAW VALUES
# ============================================================

[UInt64]$TotalBytes = [UInt64]$ByteResult
[UInt64]$FileCount = [UInt64]$FileResult
[UInt64]$FolderCount = [UInt64]$DirResult

# ============================================================
# REMOVE FOLDER WRITER.TXT
# ============================================================

if ($LogExistsBeforeScan) {

    if ($FileCount -gt 0) {
        $FileCount--
    }

    if ($TotalBytes -ge $LogFileSizeBeforeScan) {
        $TotalBytes -= $LogFileSizeBeforeScan
    }
    else {
        $TotalBytes = 0
    }
}

# ============================================================
# DELETE TEMP LOG
# ============================================================

Remove-Item $TempLog -Force -ErrorAction SilentlyContinue

# ============================================================
# CALCULATE GB
#
# 1 GB = 1,000,000,000 bytes
# ============================================================

$TotalGB = [double]$TotalBytes / 1000000000

$TotalGBText = $TotalGB.ToString(
    "N3",
    [System.Globalization.CultureInfo]::InvariantCulture
)

$TotalGBText = $TotalGBText.Replace(".", ",")

# ============================================================
# DATE / TIME
# ============================================================

$Now = Get-Date

$Date = $Now.ToString("yyyy.MM.dd")
$Time = $Now.ToString("HH:mm:ss")

# ============================================================
# FINGERPRINT
# ============================================================

$FingerprintSource = "{0}|{1}|{2}" -f `
    $TotalBytes,
    $FileCount,
    $FolderCount

$SHA256 = [System.Security.Cryptography.SHA256]::Create()

$SourceBytes = [System.Text.Encoding]::UTF8.GetBytes(
    $FingerprintSource
)

$HashBytes = $SHA256.ComputeHash($SourceBytes)

$SHA256.Dispose()

$Hash = (
    [System.BitConverter]::ToString($HashBytes)
).Replace("-", "").ToLowerInvariant()

$Fingerprint = "fg" + $Hash.Substring(0,16)

# ============================================================
# FORMAT BYTES
#
# IMPORTANT:
# This is ONLY for DISPLAY / LOG TEXT.
#
# Internal $TotalBytes remains a pure UInt64 number.
#
# Example:
#
# 37256458698
# ->
# 37,256,458,698
# ============================================================

$ByteDigits = $TotalBytes.ToString()

$FormattedBytes = ""

while ($ByteDigits.Length -gt 3) {

    $FormattedBytes =
        "," +
        $ByteDigits.Substring($ByteDigits.Length - 3) +
        $FormattedBytes

    $ByteDigits =
        $ByteDigits.Substring(0, $ByteDigits.Length - 3)
}

$TotalBytesText = $ByteDigits + $FormattedBytes

# ============================================================
# CURRENT LINE
# ============================================================

$CurrentLine = "{0} | {1} g | {2} | {3} | {4} | {5} | {6}" -f `
    $TotalBytesText,
    $TotalGBText,
    $FileCount,
    $FolderCount,
    $Date,
    $Time,
    $Fingerprint

# ============================================================
# READ PREVIOUS LINE
# ============================================================

$PreviousLine = $null

if (Test-Path -LiteralPath $LogFile) {

    try {

        $PreviousLine = Get-Content `
            -LiteralPath $LogFile `
            -Encoding UTF8 |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            } |
            Select-Object -Last 1

    }
    catch {

        $PreviousLine = $null
    }
}

# ============================================================
# PREVIOUS FINGERPRINT
# ============================================================

$PreviousFingerprint = $null

if (-not [string]::IsNullOrWhiteSpace($PreviousLine)) {

    $PreviousParts = $PreviousLine -split "\|"

    if ($PreviousParts.Count -eq 7) {

        $PreviousFingerprint = $PreviousParts[6].Trim()
    }
}

# ============================================================
# WRITE LOG
# ============================================================

try {

    Add-Content `
        -LiteralPath $LogFile `
        -Value $CurrentLine `
        -Encoding UTF8 `
        -ErrorAction Stop

}
catch {

    Write-Host ""
    Write-Host "ERROR: Cannot write Folder Writer.txt" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    Read-Host "Press Enter to exit"
    exit
}

# ============================================================
# RESULT
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                         RESULT                             " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host ("Folder      : {0}" -f $FolderPath)
Write-Host ("Bytes       : {0}" -f $TotalBytesText)
Write-Host ("GB          : {0} g" -f $TotalGBText)
Write-Host ("Files       : {0:N0}" -f $FileCount)
Write-Host ("Folders     : {0:N0}" -f $FolderCount)
Write-Host ("Date        : {0}" -f $Date)
Write-Host ("Time        : {0}" -f $Time)
Write-Host ("Fingerprint : {0}" -f $Fingerprint)

Write-Host ""
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray

# ============================================================
# COMPARE
# ============================================================

if ($null -eq $PreviousFingerprint) {

    Write-Host ""
    Write-Host "FIRST SCAN - FOLDER STATE RECORDED." `
        -ForegroundColor Cyan
}
elseif ($PreviousFingerprint -eq $Fingerprint) {

    Write-Host ""
    Write-Host "EVERYTHING IS OK - NO CHANGES DETECTED." `
        -ForegroundColor Green
}
else {

    Write-Host ""
    Write-Host "NEW CHANGE DETECTED." `
        -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Log file:" -ForegroundColor DarkGray
Write-Host $LogFile -ForegroundColor DarkGray

Write-Host ""
Read-Host "Press Enter to exit"