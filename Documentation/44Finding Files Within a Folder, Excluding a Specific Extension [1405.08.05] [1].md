
> [!INFO] شناسایی و دسته‌بندی فایل‌ها بر اساس پسوندهای غیر از پسوند انتخاب‌شده
> در صورت نیاز، دسترسی Administrator را از طریق UAC درخواست کرده و اسکریپت را با سطح دسترسی مدیریتی اجرا می‌کند.
> مسیر پوشه اصلی موردنظر را از کاربر دریافت می‌کند.
> پسوند موردنظر برای حذف از محدوده جست‌وجو را از کاربر دریافت می‌کند.
> پوشه اصلی و تمام زیرپوشه‌های آن را به‌صورت بازگشتی، شامل فایل‌ها و پوشه‌های مخفی، جست‌وجو می‌کند.
> تمام فایل‌هایی را که پسوند آن‌ها با پسوند انتخاب‌شده متفاوت است شناسایی می‌کند.
> فایل‌های شناسایی‌شده را بر اساس مسیر پوشه و نوع پسوند دسته‌بندی می‌کند.
> برای هر ترکیب پوشه و پسوند، تعداد فایل‌ها را محاسبه کرده و از ثبت موارد تکراری جلوگیری می‌کند.
> مسیر کامل پوشه، نوع فایل و تعداد فایل‌های هر گروه را در گزارش نهایی ثبت می‌کند.
> گزارش را داخل پوشه اصلی انتخاب‌شده ذخیره کرده و خطاهای جست‌وجو و دسترسی را ثبت می‌کند.
> تعداد کل پوشه‌ها، فایل‌ها و انواع پسوندهای شناسایی‌شده را نمایش می‌دهد، هیچ فایلی را حذف یا ویرایش نمی‌کند و پیش از خروج سه مرتبه منتظر فشردن کلید Enter می‌ماند.


> [!INFO] File Identification And Categorization By Excluded File Extension
> Requests Administrator Privileges Through UAC When Necessary And Runs The Script With Administrative Permissions.
> Requests The Root Directory Path From The User.
> Requests The File Extension That Must Be Excluded From The Search Results.
> Recursively Scans The Root Directory And All Subdirectories, Including Hidden Files And Folders.
> Identifies All Files Whose Extensions Differ From The Selected Excluded Extension.
> Groups The Identified Files By Their Folder Paths And File Extensions.
> Calculates The Number Of Files For Each Folder And Extension Combination And Prevents Duplicate Entries.
> Records The Full Folder Path, File Type, And Corresponding File Count In The Final Report.
> Saves The Report Inside The Selected Root Directory And Records Search And Folder Access Errors.
> Displays The Total Number Of Folders, Files, And Identified File Types, Does Not Delete Or Modify Existing Files, And Waits For Three Separate Enter Key Presses Before Exiting.


```
# =====================================================================
# Script Name: Find-OtherFilesByExtension.ps1
# =====================================================================
# Features:
# 1. Request Administrator privileges if necessary.
# 2. Ask for the root folder.
# 3. Ask for an extension to EXCLUDE.
# 4. Search recursively, including hidden files and folders.
# 5. Group all other files by folder and extension.
# 6. Report folder path, file type, and file count.
# 7. Avoid duplicate folder/type entries.
# 8. Save the report in the selected root folder.
# 9. Report search/access errors.
# 10. Display total folders, files, and file types.
# 11. Wait for Enter three times before closing.
#
# This script does not delete or modify existing files.
# =====================================================================

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

        $Arguments = @(
            "-NoProfile"
            "-ExecutionPolicy"
            "Bypass"
            "-File"
            "`"$PSCommandPath`""
        )

        Start-Process `
            -FilePath $PowerShellExe `
            -ArgumentList $Arguments `
            -Verb RunAs `
            -ErrorAction Stop

        exit
    }
    catch {
        Write-Host ""
        Write-Host "Administrator access was not granted." -ForegroundColor Red
        Read-Host "Press Enter to close"
        exit
    }
}

# ---------------------------------------------------------------------
# Step 2: Configure the console
# ---------------------------------------------------------------------

$Host.UI.RawUI.WindowTitle = "Other File Types Search"
Clear-Host

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "       OTHER FILE TYPES SEARCH                " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------
# Step 3: Get the root folder
# ---------------------------------------------------------------------

do {
    $RootPath = Read-Host "Enter the full path of the folder to search"
    $RootPath = $RootPath.Trim().Trim('"')

    if (-not (Test-Path -LiteralPath $RootPath -PathType Container)) {
        Write-Host "Invalid folder path. Please try again." -ForegroundColor Red
        $RootPath = $null
    }
}
while ([string]::IsNullOrWhiteSpace($RootPath))

$RootPath = (Resolve-Path -LiteralPath $RootPath).Path

# ---------------------------------------------------------------------
# Step 4: Get the extension to EXCLUDE
# ---------------------------------------------------------------------

do {
    $ExcludeExtension = Read-Host "Enter the extension to exclude (example: mp3, txt, pdf)"
    $ExcludeExtension = $ExcludeExtension.Trim().TrimStart('.')

    if ([string]::IsNullOrWhiteSpace($ExcludeExtension)) {
        Write-Host "Extension cannot be empty. Try again." -ForegroundColor Red
    }
    elseif ($ExcludeExtension -match '[\\/:*?"<>|]') {
        Write-Host "Enter only a file extension, such as mp3 or txt." -ForegroundColor Red
        $ExcludeExtension = $null
    }
}
while ([string]::IsNullOrWhiteSpace($ExcludeExtension))

# ---------------------------------------------------------------------
# Step 5: Prepare the report path
# ---------------------------------------------------------------------

$TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$ReportPath = Join-Path `
    -Path $RootPath `
    -ChildPath "OtherFiles_Except_${ExcludeExtension}_${TimeStamp}.txt"

Write-Host ""
Write-Host "Search started..." -ForegroundColor Yellow
Write-Host "Root folder: $RootPath"
Write-Host "Excluded extension: .$ExcludeExtension"
Write-Host "All other file types will be counted."
Write-Host "Report file: $ReportPath"
Write-Host ""

# ---------------------------------------------------------------------
# Step 6: Search and count files by folder and extension
# ---------------------------------------------------------------------

# Dictionary:
# Folder path -> Dictionary of extension -> file count

$FolderFileCounts =
    [System.Collections.Generic.Dictionary[
        string,
        System.Collections.Generic.Dictionary[string, int]
    ]]::new([System.StringComparer]::OrdinalIgnoreCase)

$SearchErrors = @()
$TotalMatchingFiles = 0

try {
    Get-ChildItem `
        -LiteralPath $RootPath `
        -File `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue `
        -ErrorVariable +SearchErrors |
    ForEach-Object {

        $File = $_

        # Exclude the selected extension, case-insensitively.
        if ($File.Extension -ine ".$ExcludeExtension") {

            $FolderPath = $File.DirectoryName

            # Use "(no extension)" for files without an extension.
            if ([string]::IsNullOrEmpty($File.Extension)) {
                $FileType = "(no extension)"
            }
            else {
                $FileType = $File.Extension.TrimStart('.').ToLowerInvariant()
            }

            # Create the folder entry if it does not exist.
            if (-not $FolderFileCounts.ContainsKey($FolderPath)) {
                $FolderFileCounts.Add(
                    $FolderPath,
                    [System.Collections.Generic.Dictionary[string, int]]::new(
                        [System.StringComparer]::OrdinalIgnoreCase
                    )
                )
            }

            # Create the file type entry if it does not exist.
            $TypeCounts = $FolderFileCounts[$FolderPath]

            if (-not $TypeCounts.ContainsKey($FileType)) {
                $TypeCounts.Add($FileType, 0)
            }

            $TypeCounts[$FileType]++
            $TotalMatchingFiles++
        }
    }
}
catch {
    $SearchErrors += $_
}

# ---------------------------------------------------------------------
# Step 7: Calculate summary totals
# ---------------------------------------------------------------------

$SortedFolders = @($FolderFileCounts.Keys | Sort-Object)

$TotalMatchingFolders = $FolderFileCounts.Count

$AllFileTypes = @(
    foreach ($Folder in $SortedFolders) {
        foreach ($Type in $FolderFileCounts[$Folder].Keys) {
            $Type
        }
    }
)

$UniqueFileTypes = @(
    $AllFileTypes |
        Sort-Object -Unique
)

# ---------------------------------------------------------------------
# Step 8: Build the report
# ---------------------------------------------------------------------

$ReportLines = @(
    "OTHER FILE TYPES SEARCH REPORT"
    "=================================================="
    "Search date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Root folder: $RootPath"
    "Excluded extension: .$ExcludeExtension"
    ""
    "SUMMARY"
    "--------------------------------------------------"
    "Folders containing other file types: $TotalMatchingFolders"
    "Total matching files: $TotalMatchingFiles"
    "Different file types found: $($UniqueFileTypes.Count)"
    "=================================================="
    ""
)

if ($TotalMatchingFiles -gt 0) {

    $ReportLines += "FOLDERS, FILE TYPES, AND COUNTS:"
    $ReportLines += ""

    foreach ($Folder in $SortedFolders) {

        $TypeCounts = $FolderFileCounts[$Folder]

        $ReportLines += "Folder: $Folder"

        $SortedTypes = @($TypeCounts.Keys | Sort-Object)

        foreach ($Type in $SortedTypes) {
            $Count = $TypeCounts[$Type]
            $ReportLines += "  File type: $Type | Count: $Count"
        }

        $FolderTotal = 0

        foreach ($Type in $SortedTypes) {
            $FolderTotal += $TypeCounts[$Type]
        }

        $ReportLines += "  Total other files in this folder: $FolderTotal"
        $ReportLines += ""
    }
}
else {
    $ReportLines += "No files other than the excluded extension were found."
    $ReportLines += ""
}

# ---------------------------------------------------------------------
# Step 9: Add overall totals and warnings
# ---------------------------------------------------------------------

$ReportLines += "=================================================="
$ReportLines += "FINAL TOTALS"
$ReportLines += "--------------------------------------------------"
$ReportLines += "Total folders: $TotalMatchingFolders"
$ReportLines += "Total files: $TotalMatchingFiles"
$ReportLines += "Different file types: $($UniqueFileTypes.Count)"
$ReportLines += "=================================================="
$ReportLines += "Search completed."

if ($SearchErrors.Count -gt 0) {
    $ReportLines += ""
    $ReportLines += "WARNING: Some folders could not be accessed or searched."
    $ReportLines += "Number of reported search errors: $($SearchErrors.Count)"
    $ReportLines += ""
    $ReportLines += "ERROR DETAILS:"

    foreach ($SearchError in $SearchErrors) {
        $ReportLines += $SearchError.ToString()
    }
}

# ---------------------------------------------------------------------
# Step 10: Save the report
# ---------------------------------------------------------------------

try {
    $ReportLines |
        Set-Content -LiteralPath $ReportPath -Encoding UTF8 -ErrorAction Stop

    Write-Host ""
    Write-Host "Search completed." -ForegroundColor Green
    Write-Host "Folders containing other file types: $TotalMatchingFolders" -ForegroundColor Green
    Write-Host "Total other files: $TotalMatchingFiles" -ForegroundColor Green
    Write-Host "Different file types: $($UniqueFileTypes.Count)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Report saved to:" -ForegroundColor Cyan
    Write-Host $ReportPath -ForegroundColor White
}
catch {
    Write-Host "Failed to save the report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# ---------------------------------------------------------------------
# Step 11: Display warnings
# ---------------------------------------------------------------------

if ($SearchErrors.Count -gt 0) {
    Write-Host ""
    Write-Host "Warning: Some folders may not have been searched." -ForegroundColor Yellow
    Write-Host "Check the report for error details." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------
# Step 12: Wait for Enter three times
# ---------------------------------------------------------------------

Write-Host ""
Write-Host "The script has finished." -ForegroundColor Cyan
Write-Host "Press Enter three times to close this window." -ForegroundColor Yellow

for ($i = 1; $i -le 3; $i++) {
    [void](Read-Host "Press Enter ($i/3)")
}
```

