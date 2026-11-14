# ====================================================================================================
#                           BINARY FILE AUDIT & INTEGRITY VERIFICATION SYSTEM
#                              ADVANCED SHA-256 CONTENT COMPARISON ENGINE
# ====================================================================================================
#
# SCRIPT NAME       : BinaryFileAudit.ps1
# SCRIPT VERSION    : 2.0
# PLATFORM          : Microsoft Windows PowerShell
# HASH ALGORITHM    : SHA-256 (256-bit Cryptographic Hash)
# COMPARISON METHOD : File Extension + Complete Binary Content
# SCANNING MODE     : Recursive Directory Enumeration
# REPORT FORMAT     : Timestamped UTF-8 Text File
# OPERATION MODE    : Read-Only File Inspection
#
# ====================================================================================================
#                              ENGLISH TECHNICAL DOCUMENTATION
# ====================================================================================================
#
# PURPOSE:
# Compare files between a source directory and a destination directory to identify source files
# whose identical binary content cannot be found in the destination.
#
# COMPARISON:
# File names, directory paths, creation dates, modification dates, and ordinary filesystem
# metadata are not used to establish file identity. Matching is based on the selected extension
# and the SHA-256 hash of the complete file content.
#
# FILE DISCOVERY:
# Files are searched recursively through accessible subdirectories. Extension matching is
# case-insensitive. Files with different extensions are excluded from the comparison.
#
# METADATA CONSIDERATIONS:
# Embedded metadata, ID3 tags, album artwork, EXIF data, and internal media-container structures
# are part of the file's binary content. Changing them can produce a different SHA-256 hash,
# even when the underlying audio, image, or video appears identical.
#
# REPORTING:
# A timestamped report records scan statistics, unmatched source files, file paths, file sizes,
# SHA-256 hashes, and available scanning or hashing errors.
#
# PRIVILEGES:
# If required, the script requests Administrator elevation through Windows UAC and attempts
# to relaunch with a process-level ExecutionPolicy Bypass.
#
# DATA SAFETY:
# The script is designed to read files and generate a separate report. It does not intentionally
# delete, rename, move, or modify source or destination files.
#
# TECHNICAL LIMITATIONS:
# Identical SHA-256 hashes provide extremely strong evidence of identical binary content.
# Different hashes do not necessarily mean different underlying media content. Perceptual image
# comparison, audio fingerprinting, and metadata normalization are not performed.
#
# IMPORTANT:
# Review all reported errors and scanning warnings before treating the audit as complete.
# Three separate ENTER prompts are displayed at the end of execution.
#
# ====================================================================================================
#                                END OF ENGLISH DOCUMENTATION
# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
#                             سامانه پیشرفته بررسی و تطبیق یکپارچگی فایل‌ها
#                           موتور مقایسه محتوای باینری بر اساس - SHA-256
# ====================================================================================================
#                                  مستندات فنی فارسی
# ====================================================================================================
#
# هدف:
# مقایسه فایل‌های دو پوشه و شناسایی فایل‌های مبدأ که محتوای باینری یکسان آن‌ها در مقصد پیدا نمی‌شود.
#
# روش مقایسه:
# نام فایل، مسیر، تاریخ ایجاد، تاریخ ویرایش و مشخصات معمول سیستم فایل معیار تطبیق نیستند.
# تطبیق بر اساس پسوند انتخاب‌شده و هش SHA-256 کل محتوای فایل انجام می‌شود.
#
# جست‌وجوی فایل‌ها:
# فایل‌ها در زیرپوشه‌های قابل دسترسی نیز بررسی می‌شوند. مقایسه پسوند به بزرگی و کوچکی حروف حساس نیست.
# فایل‌هایی با پسوند متفاوت از محدوده بررسی خارج هستند.
#
# متادیتا:
# تگ‌های ID3، کاور موسیقی، اطلاعات EXIF و ساختارهای داخلی فایل‌های رسانه‌ای جزئی از محتوای باینری هستند.
# تغییر این اطلاعات می‌تواند هش فایل را تغییر دهد، حتی اگر صدا یا تصویر ظاهراً یکسان باقی مانده باشد.
#
# گزارش‌گیری:
# گزارش شامل آمار اسکن، فایل‌های فاقد تطبیق، مسیرها، اندازه فایل‌ها، هش SHA-256 و خطاهای ثبت‌شده است.
#
# سطح دسترسی:
# در صورت نیاز، اسکریپت برای اجرای مجدد با دسترسی Administrator از طریق UAC اقدام می‌کند
# و از ExecutionPolicy Bypass در فرایند جدید استفاده می‌کند.
#
# ایمنی اطلاعات:
# اسکریپت برای خواندن فایل‌ها و تولید گزارش طراحی شده است و عمداً فایل‌های اصلی را حذف،
# تغییر نام، جابه‌جا یا ویرایش نمی‌کند.
#
# محدودیت فنی:
# هش یکسان، شواهد بسیار قوی از یکسان بودن محتوای باینری است؛ اما هش متفاوت الزاماً به معنی
# متفاوت بودن محتوای اصلی رسانه نیست. مقایسه ادراکی تصویر، اثرانگشت صوتی و نرمال‌سازی متادیتا
# در این نسخه انجام نمی‌شوند.
#
# نکته مهم:
# پیش از قطعی دانستن نتیجه، خطاها و هشدارهای اسکن را بررسی کن.
# در پایان اجرا، سه درخواست جداگانه برای فشردن کلید ENTER نمایش داده می‌شود.
#
# ====================================================================================================
#                                    پایان مستندات فارسی
# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
# Set strict error handling for unexpected terminating errors.
# ====================================================================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# ====================================================================================================
# Verify that this script is running from a saved PowerShell file.
# ====================================================================================================
if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
    Write-Host 'ERROR: Save this code as a .ps1 file and run it again.' -ForegroundColor Red
    Read-Host 'Press Enter to exit'
    exit 1
}
# ====================================================================================================
# Relaunch this script with elevated privileges and a temporary execution policy bypass when necessary.
# ====================================================================================================
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
$isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdministrator) {
    Write-Host 'Administrator access is required. Requesting elevation...' -ForegroundColor Yellow
    try {
        $powerShellExe = Join-Path $PSHOME 'powershell.exe'
        if (-not (Test-Path -LiteralPath $powerShellExe -PathType Leaf)) {
            $powerShellExe = (Get-Command powershell.exe -ErrorAction Stop).Source
        }

        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '"'
        Start-Process -FilePath $powerShellExe -ArgumentList $arguments -Verb RunAs
        exit 0
    }
    catch {
        Write-Host ('ERROR: Could not start an elevated process. ' + $_.Exception.Message) -ForegroundColor Red
        Read-Host 'Press Enter to exit'
        exit 1
    }
}
# ====================================================================================================
# Initialize the report location beside the saved script.
# ====================================================================================================
$scriptDirectory = Split-Path -Parent $PSCommandPath
$reportTimestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$reportPath = Join-Path $scriptDirectory ("BinaryFileAudit_{0}.txt" -f $reportTimestamp)
$reportLines = New-Object 'System.Collections.Generic.List[string]'
$scriptStartTime = Get-Date
# ====================================================================================================
# Define a helper that writes the same message to the console and report.
# ====================================================================================================
function Write-AuditMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    Write-Host $Message -ForegroundColor $Color
    $script:reportLines.Add($Message)
}
# ====================================================================================================
# Display the program header and explain the matching rules in English.
# ====================================================================================================
Clear-Host
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '             BINARY FILE AUDIT - SHA-256' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host 'Matching is based on file extension and SHA-256 content hash.'
Write-Host 'File names and filesystem timestamps are ignored.'
Write-Host 'Files are read only; no source or destination files are modified.'
Write-Host ''
# ====================================================================================================
# Request the source directory and validate that it exists.
# ====================================================================================================
$SourcePath = ''
while ($true) {
    $SourcePath = (Read-Host 'Enter the SOURCE folder path').Trim().Trim('"')
    if (Test-Path -LiteralPath $SourcePath -PathType Container) {
        $SourcePath = (Resolve-Path -LiteralPath $SourcePath).Path
        break
    }
    Write-Host 'ERROR: The source folder does not exist. Try again.' -ForegroundColor Red
}
# ====================================================================================================
# Request one file extension and normalize its spelling.
# ====================================================================================================
$Extension = ''
while ($true) {
    $Extension = (Read-Host 'Enter the file extension, for example MP3, MP4, JPG, XLSX, TXT, MD').Trim()
    $Extension = $Extension.TrimStart('.').ToLowerInvariant()

    if ($Extension -match '^[a-z0-9][a-z0-9_-]*$') {
        break
    }

    Write-Host 'ERROR: Enter one valid extension without wildcards or path characters.' -ForegroundColor Red
}
# ====================================================================================================
# Request the destination directory and validate that it exists.
# ====================================================================================================
$DestinationPath = ''
while ($true) {
    $DestinationPath = (Read-Host 'Enter the DESTINATION folder path').Trim().Trim('"')
    if (Test-Path -LiteralPath $DestinationPath -PathType Container) {
        $DestinationPath = (Resolve-Path -LiteralPath $DestinationPath).Path
        break
    }
    Write-Host 'ERROR: The destination folder does not exist. Try again.' -ForegroundColor Red
}
# ====================================================================================================
# Write the audit configuration to the report.
# ====================================================================================================
$reportLines.Add('BINARY FILE AUDIT REPORT')
$reportLines.Add(('Started: {0}' -f $scriptStartTime.ToString('yyyy-MM-dd HH:mm:ss')))
$reportLines.Add(('Source folder: {0}' -f $SourcePath))
$reportLines.Add(('Destination folder: {0}' -f $DestinationPath))
$reportLines.Add(('Selected extension: .{0}' -f $Extension))
$reportLines.Add('Comparison method: file extension + SHA-256 of complete file bytes')
$reportLines.Add('File names and filesystem timestamps are not used for matching.')
$reportLines.Add('')
# ====================================================================================================
# Initialize counters and collections for the audit.
# ====================================================================================================
$sourceFiles = @()
$destinationFiles = @()
$sourceHashErrors = New-Object 'System.Collections.Generic.List[string]'
$destinationHashErrors = New-Object 'System.Collections.Generic.List[string]'
$missingFiles = New-Object 'System.Collections.Generic.List[object]'
$destinationHashIndex = @{}
$sourceHashCache = @{}
$destinationHashCache = @{}
$sourceScanErrors = New-Object 'System.Collections.Generic.List[string]'
$destinationScanErrors = New-Object 'System.Collections.Generic.List[string]'
# ====================================================================================================
# Enumerate matching files recursively in the source folder.
# ====================================================================================================
Write-Host ''
Write-Host 'Scanning the source folder...' -ForegroundColor Cyan
try {
    $sourceFiles = @(
        Get-ChildItem -LiteralPath $SourcePath -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension.TrimStart('.').ToLowerInvariant() -eq $Extension }
    )
}
catch {
    $sourceScanErrors.Add($_.Exception.Message)
}
# ====================================================================================================
# Enumerate matching files recursively in the destination folder.
# ====================================================================================================
Write-Host 'Scanning the destination folder...' -ForegroundColor Cyan
try {
    $destinationFiles = @(
        Get-ChildItem -LiteralPath $DestinationPath -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension.TrimStart('.').ToLowerInvariant() -eq $Extension }
    )
}
catch {
    $destinationScanErrors.Add($_.Exception.Message)
}
# ====================================================================================================
# Calculate SHA-256 hashes for destination files and index them by hash.
# ====================================================================================================
Write-Host 'Hashing destination files. This may take some time...' -ForegroundColor Cyan
$destinationCounter = 0

foreach ($file in $destinationFiles) {
    $destinationCounter++

    if (($destinationCounter % 100) -eq 0) {
        Write-Host ('Destination files processed: {0}/{1}' -f $destinationCounter, $destinationFiles.Count)
    }

    try {
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
        $destinationHashCache[$file.FullName] = $hash

        if (-not $destinationHashIndex.ContainsKey($hash)) {
            $destinationHashIndex[$hash] = New-Object 'System.Collections.Generic.List[string]'
        }

        $destinationHashIndex[$hash].Add($file.FullName)
    }
    catch {
        $destinationHashErrors.Add(('Path: {0} | Error: {1}' -f $file.FullName, $_.Exception.Message))
    }
}
# ====================================================================================================
# Hash each source file and determine whether an identical binary file exists in the destination.
# ====================================================================================================
Write-Host 'Hashing source files and checking for missing content...' -ForegroundColor Cyan
$sourceCounter = 0

foreach ($file in $sourceFiles) {
    $sourceCounter++

    if (($sourceCounter % 100) -eq 0) {
        Write-Host ('Source files processed: {0}/{1}' -f $sourceCounter, $sourceFiles.Count)
    }

    try {
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
        $sourceHashCache[$file.FullName] = $hash

        if (-not $destinationHashIndex.ContainsKey($hash)) {
            $missingFiles.Add([PSCustomObject]@{
                Name         = $file.Name
                FullPath     = $file.FullName
                Extension    = $file.Extension
                SizeBytes    = $file.Length
                SHA256       = $hash
                LastModified = $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
                Status       = 'NOT FOUND BY SHA256'
            })
        }
    }
    catch {
        $sourceHashErrors.Add(('Path: {0} | Error: {1}' -f $file.FullName, $_.Exception.Message))
    }
}
# ====================================================================================================
# Calculate summary statistics for the report.
# ====================================================================================================
$scriptEndTime = Get-Date
$elapsed = $scriptEndTime - $scriptStartTime
$matchedCount = $sourceFiles.Count - $missingFiles.Count - $sourceHashErrors.Count

if ($matchedCount -lt 0) {
    $matchedCount = 0
}
# ====================================================================================================
# Add the summary and all missing file details to the report.
# ====================================================================================================
$reportLines.Add('SUMMARY')
$reportLines.Add(('Completed: {0}' -f $scriptEndTime.ToString('yyyy-MM-dd HH:mm:ss')))
$reportLines.Add(('Elapsed time: {0:hh\:mm\:ss}' -f $elapsed))
$reportLines.Add(('Source files scanned: {0}' -f $sourceFiles.Count))
$reportLines.Add(('Destination files scanned: {0}' -f $destinationFiles.Count))
$reportLines.Add(('Source files with matching SHA-256: {0}' -f $matchedCount))
$reportLines.Add(('Source files not found by SHA-256: {0}' -f $missingFiles.Count))
$reportLines.Add(('Source hashing errors: {0}' -f $sourceHashErrors.Count))
$reportLines.Add(('Destination hashing errors: {0}' -f $destinationHashErrors.Count))
$reportLines.Add(('Source scan errors: {0}' -f $sourceScanErrors.Count))
$reportLines.Add(('Destination scan errors: {0}' -f $destinationScanErrors.Count))
$reportLines.Add('')
$reportLines.Add('MISSING FILES')
$reportLines.Add('The following source files have no matching SHA-256 hash in the destination.')
$reportLines.Add('')

if ($missingFiles.Count -eq 0) {
    $reportLines.Add('No unmatched source files were found.')
}
else {
    foreach ($item in $missingFiles) {
        $reportLines.Add(('File name: {0}' -f $item.Name))
        $reportLines.Add(('Full path: {0}' -f $item.FullPath))
        $reportLines.Add(('Extension: {0}' -f $item.Extension))
        $reportLines.Add(('Size in bytes: {0}' -f $item.SizeBytes))
        $reportLines.Add(('SHA-256: {0}' -f $item.SHA256))
        $reportLines.Add(('Last modified: {0}' -f $item.LastModified))
        $reportLines.Add(('Status: {0}' -f $item.Status))
        $reportLines.Add('------------------------------------------------------------')
    }
}
# ====================================================================================================
# Add destination hash failures to the report.
# ====================================================================================================
$reportLines.Add('')
$reportLines.Add('DESTINATION HASH ERRORS')
if ($destinationHashErrors.Count -eq 0) {
    $reportLines.Add('No destination hashing errors were recorded.')
}
else {
    foreach ($entry in $destinationHashErrors) {
        $reportLines.Add($entry)
    }
}
# ====================================================================================================
# Add source hash failures to the report.
# ====================================================================================================
$reportLines.Add('')
$reportLines.Add('SOURCE HASH ERRORS')
if ($sourceHashErrors.Count -eq 0) {
    $reportLines.Add('No source hashing errors were recorded.')
}
else {
    foreach ($entry in $sourceHashErrors) {
        $reportLines.Add($entry)
    }
}
# ====================================================================================================
# Add directory enumeration warnings to the report.
# ====================================================================================================
$reportLines.Add('')
$reportLines.Add('SCAN WARNINGS')
foreach ($entry in $sourceScanErrors) {
    $reportLines.Add(('Source scan: {0}' -f $entry))
}
foreach ($entry in $destinationScanErrors) {
    $reportLines.Add(('Destination scan: {0}' -f $entry))
}
# ====================================================================================================
# Save the report as UTF-8 text beside the script.
# ====================================================================================================
try {
    $reportLines | Set-Content -LiteralPath $reportPath -Encoding UTF8
    Write-Host ''
    Write-Host 'Audit completed.' -ForegroundColor Green
    Write-Host ('Report saved to: {0}' -f $reportPath) -ForegroundColor Green
}
catch {
    Write-Host ('ERROR: Could not save the report: {0}' -f $_.Exception.Message) -ForegroundColor Red
}
# ====================================================================================================
# Display the final summary in English.
# ====================================================================================================
Write-Host ''
Write-Host '==================== FINAL SUMMARY ====================' -ForegroundColor Cyan
Write-Host ('Source files: {0}' -f $sourceFiles.Count)
Write-Host ('Destination files: {0}' -f $destinationFiles.Count)
Write-Host ('Matching source files: {0}' -f $matchedCount) -ForegroundColor Green
Write-Host ('Unmatched source files: {0}' -f $missingFiles.Count) -ForegroundColor Yellow
Write-Host ('Source hashing errors: {0}' -f $sourceHashErrors.Count) -ForegroundColor Red
Write-Host ('Destination hashing errors: {0}' -f $destinationHashErrors.Count) -ForegroundColor Red
Write-Host '=======================================================' -ForegroundColor Cyan
# ====================================================================================================
# Request three separate Enter presses before closing the console.
# ====================================================================================================
Read-Host 'Press Enter (1 of 3) to continue'
Read-Host 'Press Enter (2 of 3) to continue'
Read-Host 'Press Enter (3 of 3) to exit'