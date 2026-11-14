
> [!INFO] مقایسه محتوایی نسخه اسکریپت‌های PowerShell با استفاده از SHA-256
> مسیر دو پوشه SOURCE و TARGET را از کاربر دریافت کرده و فایل‌های PowerShell با پسوند PS1 را در هر دو مسیر شناسایی می‌کند.
> هر دو پوشه را به‌صورت بازگشتی همراه با تمام زیرپوشه‌ها اسکن می‌کند.
> برای تک‌تک فایل‌های موجود در پوشه TARGET یک اثرانگشت دیجیتال بر اساس الگوریتم SHA-256 تولید می‌کند.
> سپس محتوای فایل‌های پوشه SOURCE را نیز با همان الگوریتم هش کرده و اثرانگشت آن‌ها را استخراج می‌کند.
> اثرانگشت فایل‌های SOURCE را با تمام اثرانگشت‌های ثبت‌شده در TARGET مقایسه می‌کند.
> اگر محتوای یک فایل در هر نقطه از پوشه TARGET کاملاً یکسان باشد، نتیجه آن FOUND در نظر گرفته می‌شود.
> اگر هیچ فایل همسانی از نظر محتوا در TARGET وجود نداشته باشد، فایل موردنظر با وضعیت MISSING مشخص می‌شود.
> نام فایل، مسیر ذخیره‌سازی، نام پوشه و ساختار زیرپوشه‌ها هیچ تأثیری در نتیجه مقایسه ندارند.
> در پایان، گزارشی متنی روی Desktop ایجاد می‌کند که فقط فایل‌های مفقودشده را همراه با نام و مسیر کامل آن‌ها ثبت می‌کند.


> [!INFO] PowerShell Script Content Comparison And Version Identification Using SHA-256
> Requests SOURCE And TARGET Folder Paths And Identifies PowerShell Files With The PS1 Extension In Both Locations.
> Recursively Scans Both Directories, Including All Their Subdirectories.
> Generates A SHA-256 Digital Fingerprint For Every File Found Inside The TARGET Directory.
> Calculates The SHA-256 Hash Of Each SOURCE File Using The Same Algorithm.
> Compares SOURCE File Fingerprints Against All Recorded TARGET Fingerprints.
> If Identical Content Exists Anywhere Inside TARGET, The File Is Classified As FOUND.
> If No Content-Identical File Exists In TARGET, The SOURCE File Is Classified As MISSING.
> File Names, Storage Paths, Folder Names, And Subdirectory Structures Have No Influence On Comparison Results.
> Generates A Text Report On The Desktop Containing Only Missing Files, Including Their File Names And Full Paths.


```
# ================================================================
#                POWERSHELL VERSION CHECKER
# ================================================================
#
# PURPOSE
# -------
# This PowerShell tool compares all .ps1 files found inside a
# SOURCE folder against all .ps1 files found inside a TARGET folder.
#
# The comparison is based ONLY on the actual file content.
# File names, file paths, folder names, and file locations are
# completely ignored during the comparison.
#
#
# HOW IT WORKS
# ------------
# 1. The user provides a SOURCE folder path.
#
# 2. The user provides a TARGET folder path.
#
# 3. All PowerShell (.ps1) files inside the SOURCE folder and
#    its subfolders are detected.
#
# 4. All PowerShell (.ps1) files inside the TARGET folder and
#    its subfolders are detected.
#
# 5. A SHA-256 content fingerprint (hash) is generated for every
#    PowerShell file in the TARGET folder.
#
# 6. Each SOURCE PowerShell file is then hashed using SHA-256
#    and its content fingerprint is compared against the TARGET
#    fingerprints.
#
# 7. If an identical file exists anywhere inside the TARGET folder,
#    it is considered FOUND, regardless of:
#
#       - File name
#       - File path
#       - Folder name
#       - Folder structure
#
# 8. If no identical content exists anywhere inside the TARGET
#    folder, the SOURCE file is considered MISSING.
#
#
# IMPORTANT
# ---------
# This tool does NOT compare files by name.
#
# For example:
#
#       SOURCE:  1.ps1
#       TARGET:  2.ps1
#
# If both files contain exactly the same content, they are treated
# as the same PowerShell version.
#
# Conversely, if two files have the same name but different content,
# they are treated as different files.
#
#
# REPORT
# ------
# At the end of the comparison, a text report is created on the
# user's Desktop.
#
# The report contains ONLY SOURCE files whose exact content could
# not be found anywhere inside the TARGET folder.
#
# Each missing file is reported using:
#
#       Full Path
#       File Name
#
# followed by two empty lines before the next result.
#
#
# EXAMPLE
# -------
#
# SOURCE:
#       C:\Source\Scripts\1.ps1
#
# TARGET:
#       D:\Target\Backup\2.ps1
#
# If 1.ps1 and 2.ps1 have identical content:
#
#       RESULT = FOUND
#
# If no file inside TARGET has identical content:
#
#       RESULT = MISSING
#
#
# HASH ALGORITHM
# --------------
# SHA-256 is used to create a content fingerprint for each file.
#
# The hash is calculated from the actual bytes of the file.
# Therefore, changing the file content changes its SHA-256 hash.
#
#
# SCOPE
# -----
# Only PowerShell files with the .ps1 extension are included.
#
# Both SOURCE and TARGET folders are scanned recursively,
# including their subfolders.
#
# ================================================================

$ErrorActionPreference = "Stop"

Clear-Host

# ================================================================
#                    POWERSHELL VERSION CHECKER
# ================================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "              POWERSHELL VERSION CHECKER" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This tool compares PowerShell scripts by CONTENT." -ForegroundColor DarkGray
Write-Host "File names are completely ignored." -ForegroundColor DarkGray
Write-Host ""

# ================================================================
# SOURCE FOLDER
# ================================================================

Write-Host "SOURCE FOLDER" -ForegroundColor Yellow
Write-Host "Enter the folder containing the original PowerShell scripts." -ForegroundColor DarkGray
Write-Host ""

$SourceFolder = Read-Host "Path"

if ([string]::IsNullOrWhiteSpace($SourceFolder)) {
    Write-Host ""
    Write-Host "No source folder was entered." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

$SourceFolder = $SourceFolder.Trim().Trim('"')

# ================================================================
# TARGET FOLDER
# ================================================================

Write-Host ""
Write-Host "TARGET FOLDER" -ForegroundColor Yellow
Write-Host "Enter the folder to search for matching script content." -ForegroundColor DarkGray
Write-Host ""

$TargetFolder = Read-Host "Path"

if ([string]::IsNullOrWhiteSpace($TargetFolder)) {
    Write-Host ""
    Write-Host "No target folder was entered." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

$TargetFolder = $TargetFolder.Trim().Trim('"')

# ================================================================
# VALIDATE FOLDERS
# ================================================================

if (-not (Test-Path -LiteralPath $SourceFolder -PathType Container)) {

    Write-Host ""
    Write-Host "ERROR: SOURCE folder was not found." -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

if (-not (Test-Path -LiteralPath $TargetFolder -PathType Container)) {

    Write-Host ""
    Write-Host "ERROR: TARGET folder was not found." -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

$SourceFolder = (Resolve-Path -LiteralPath $SourceFolder).Path
$TargetFolder = (Resolve-Path -LiteralPath $TargetFolder).Path

# ================================================================
# SCAN SOURCE
# ================================================================

Write-Host ""
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " SCANNING SOURCE" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

$SourceFiles = @(
    Get-ChildItem `
        -LiteralPath $SourceFolder `
        -Filter "*.ps1" `
        -File `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue
)

Write-Host "PowerShell files found: " -NoNewline
Write-Host $SourceFiles.Count -ForegroundColor Green

# ================================================================
# SCAN TARGET
# ================================================================

Write-Host ""
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " SCANNING TARGET" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

$TargetFiles = @(
    Get-ChildItem `
        -LiteralPath $TargetFolder `
        -Filter "*.ps1" `
        -File `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue
)

Write-Host "PowerShell files found: " -NoNewline
Write-Host $TargetFiles.Count -ForegroundColor Green

# ================================================================
# CREATE TARGET CONTENT INDEX
# ================================================================

Write-Host ""
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " ANALYZING SCRIPT CONTENT" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

$TargetHashIndex = @{}

foreach ($TargetFile in $TargetFiles) {

    try {

        $Hash = (
            Get-FileHash `
                -LiteralPath $TargetFile.FullName `
                -Algorithm SHA256 `
                -ErrorAction Stop
        ).Hash.ToLowerInvariant()

        $TargetHashIndex[$Hash] = $true
    }
    catch {
        continue
    }
}

# ================================================================
# COMPARE SOURCE AGAINST TARGET
# ================================================================

$MissingFiles = @()
$CheckedCount = 0

foreach ($SourceFile in $SourceFiles) {

    $CheckedCount++

    try {

        $SourceHash = (
            Get-FileHash `
                -LiteralPath $SourceFile.FullName `
                -Algorithm SHA256 `
                -ErrorAction Stop
        ).Hash.ToLowerInvariant()

    }
    catch {
        continue
    }

    # ------------------------------------------------------------
    # IMPORTANT:
    # Only CONTENT is compared.
    # File name and file path in TARGET are ignored.
    # ------------------------------------------------------------

    if (-not $TargetHashIndex.ContainsKey($SourceHash)) {

        $MissingFiles += $SourceFile
    }
}

# ================================================================
# CREATE REPORT
# ================================================================

$DesktopPath = [Environment]::GetFolderPath("Desktop")

$ReportPath = Join-Path `
    $DesktopPath `
    "PowerShell_Version_Mismatches.txt"

$ReportLines = @()

foreach ($MissingFile in $MissingFiles) {

    $ReportLines += $MissingFile.DirectoryName
    $ReportLines += $MissingFile.Name
    $ReportLines += ""
    $ReportLines += ""
}

if ($ReportLines.Count -gt 0) {

    $ReportLines | Set-Content `
        -LiteralPath $ReportPath `
        -Encoding UTF8
}
else {

    # Create an empty report when everything exists.
    Set-Content `
        -LiteralPath $ReportPath `
        -Value "" `
        -Encoding UTF8
}

# ================================================================
# FINAL RESULT
# ================================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                         COMPLETE" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Source scripts checked : " -NoNewline
Write-Host $SourceFiles.Count -ForegroundColor White

Write-Host "Target scripts checked : " -NoNewline
Write-Host $TargetFiles.Count -ForegroundColor White

Write-Host "Missing versions       : " -NoNewline

if ($MissingFiles.Count -eq 0) {
    Write-Host "0" -ForegroundColor Green
}
else {
    Write-Host $MissingFiles.Count -ForegroundColor Red
}

Write-Host ""
Write-Host "Report:" -ForegroundColor Yellow
Write-Host $ReportPath -ForegroundColor DarkGray
Write-Host ""

if ($MissingFiles.Count -eq 0) {

    Write-Host "All SOURCE scripts exist in TARGET." -ForegroundColor Green
}
else {

    Write-Host "Some SOURCE scripts have no matching content in TARGET." -ForegroundColor Red
}

Write-Host ""

Read-Host "Press Enter to exit"
```

