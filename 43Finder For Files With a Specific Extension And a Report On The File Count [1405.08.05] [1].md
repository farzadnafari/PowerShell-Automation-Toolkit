
> [!INFO] شناسایی پوشه‌های حاوی فایل بر اساس پسوند
> در صورت نیاز، دسترسی Administrator را از طریق UAC درخواست کرده و اسکریپت را با سطح دسترسی مدیریتی اجرا می‌کند.
> مسیر پوشه اصلی موردنظر را از کاربر دریافت می‌کند.
> پسوند فایل موردنظر را مانند MP3، TXT یا PDF دریافت کرده و جست‌وجو را بر اساس آن انجام می‌دهد.
> پوشه اصلی و تمام زیرپوشه‌های آن را به‌صورت بازگشتی، شامل فایل‌ها و پوشه‌های مخفی، جست‌وجو می‌کند.
> تمام پوشه‌هایی را که حداقل یک فایل با پسوند انتخاب‌شده دارند شناسایی می‌کند.
> تعداد فایل‌های منطبق در هر پوشه را محاسبه کرده و از ثبت تکراری مسیر پوشه‌ها جلوگیری می‌کند.
> مسیر کامل هر پوشه منطبق و تعداد فایل‌های آن را در گزارش نهایی ثبت می‌کند.
> گزارش را در قالب فایل متنی داخل پوشه اصلی انتخاب‌شده ذخیره می‌کند.
> خطاهای احتمالی جست‌وجو و دسترسی به پوشه‌ها را ثبت کرده و تعداد کل پوشه‌ها و فایل‌های منطبق را نمایش می‌دهد.
> هیچ فایل یا پوشه‌ای را حذف یا ویرایش نمی‌کند و پیش از خروج، سه مرتبه برای فشردن کلید Enter منتظر می‌ماند.


> [!INFO] Folder Identification By File Extension
> Requests Administrator Privileges Through UAC When Necessary And Runs The Script With Administrative Permissions.
> Requests The Root Directory Path From The User.
> Requests The Desired File Extension, Such As MP3, TXT, Or PDF, And Performs The Search Accordingly.
> Recursively Scans The Root Directory And All Subdirectories, Including Hidden Files And Folders.
> Identifies Every Folder Containing At Least One File With The Selected Extension.
> Counts Matching Files In Each Folder And Prevents Duplicate Folder Paths From Being Recorded.
> Records The Full Path Of Every Matching Folder And Its Corresponding File Count In The Final Report.
> Saves The Text Report Inside The User-Selected Root Directory.
> Records Potential Search And Folder Access Errors And Displays The Total Number Of Matching Folders And Files.
> Does Not Delete Or Modify Any Files Or Folders And Waits For Three Separate Enter Key Presses Before Exiting.


```
# =====================================================================
# Script Name: Find-FoldersByFileExtension.ps1
# =====================================================================
# Features:
# 1. Request Administrator privileges if necessary.
# 2. Ask the user for the root folder.
# 3. Ask for the desired file extension.
# 4. Search recursively, including hidden files and folders.
# 5. Report each matching folder and its matching file count.
# 6. Avoid duplicate folder entries.
# 7. Save the report in the selected root folder.
# 8. Report search/access errors when encountered.
# 9. Display total matching folders and total matching files.
# 10. Wait for Enter to be pressed three times before closing.
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

$Host.UI.RawUI.WindowTitle = "File Extension Folder Search"

Clear-Host

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "       FILE EXTENSION FOLDER SEARCH           " -ForegroundColor Cyan
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
# Step 4: Get the file extension
# ---------------------------------------------------------------------

do {
    $Extension = Read-Host "Enter the file extension (example: mp3, txt, pdf)"

    $Extension = $Extension.Trim().TrimStart('.')

    if ([string]::IsNullOrWhiteSpace($Extension)) {
        Write-Host "Extension cannot be empty. Try again." -ForegroundColor Red
    }
    elseif ($Extension -match '[\\/:*?"<>|]') {
        Write-Host "Enter only a file extension, such as mp3 or txt." -ForegroundColor Red
        $Extension = $null
    }
}
while ([string]::IsNullOrWhiteSpace($Extension))


# ---------------------------------------------------------------------
# Step 5: Prepare the report path
# ---------------------------------------------------------------------

$TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$ReportPath = Join-Path `
    -Path $RootPath `
    -ChildPath "FolderSearch_${Extension}_${TimeStamp}.txt"

Write-Host ""
Write-Host "Search started..." -ForegroundColor Yellow
Write-Host "Root folder: $RootPath"
Write-Host "File extension: .$Extension"
Write-Host "Report file: $ReportPath"
Write-Host ""


# ---------------------------------------------------------------------
# Step 6: Search files and count matches in each folder
# ---------------------------------------------------------------------

# Dictionary: folder path -> number of matching files
$FolderFileCounts = @{}

# Case-insensitive folder path comparison
$FolderFileCounts =
    [System.Collections.Generic.Dictionary[string, int]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

$SearchErrors = @()

# Count every matching file found
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

        if ($File.Extension -ieq ".$Extension") {

            $FolderPath = $File.DirectoryName

            if (-not $FolderFileCounts.ContainsKey($FolderPath)) {
                $FolderFileCounts.Add($FolderPath, 0)
            }

            $FolderFileCounts[$FolderPath]++

            $TotalMatchingFiles++
        }
    }
}
catch {
    $SearchErrors += $_
}


# ---------------------------------------------------------------------
# Step 7: Build the report
# ---------------------------------------------------------------------

$SortedFolders = @(
    $FolderFileCounts.Keys | Sort-Object
)

$ReportLines = @(
    "FILE EXTENSION SEARCH REPORT"
    "=================================================="
    "Search date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Root folder: $RootPath"
    "File extension: .$Extension"
    ""
    "SUMMARY"
    "--------------------------------------------------"
    "Number of matching folders: $($FolderFileCounts.Count)"
    "Total matching files: $TotalMatchingFiles"
    "=================================================="
    ""
)

if ($FolderFileCounts.Count -gt 0) {

    $ReportLines += "MATCHING FOLDERS AND FILE COUNTS:"
    $ReportLines += ""

    foreach ($Folder in $SortedFolders) {

        $FileCount = $FolderFileCounts[$Folder]

        $ReportLines += "Folder: $Folder"
        $ReportLines += "Matching files: $FileCount"
        $ReportLines += ""
    }
}
else {
    $ReportLines += "No folders containing the requested file extension were found."
    $ReportLines += ""
}


# ---------------------------------------------------------------------
# Step 8: Add final totals and search warnings
# ---------------------------------------------------------------------

$ReportLines += "=================================================="
$ReportLines += "FINAL TOTALS"
$ReportLines += "--------------------------------------------------"
$ReportLines += "Total matching folders: $($FolderFileCounts.Count)"
$ReportLines += "Total matching files: $TotalMatchingFiles"
$ReportLines += "=================================================="
$ReportLines += "Search completed."

if ($SearchErrors.Count -gt 0) {
    $ReportLines += ""
    $ReportLines += "WARNING: Some folders could not be accessed or searched."
    $ReportLines += "Number of reported search errors: $($SearchErrors.Count)"
}


# ---------------------------------------------------------------------
# Step 9: Save the report
# ---------------------------------------------------------------------

try {
    $ReportLines |
        Set-Content -LiteralPath $ReportPath -Encoding UTF8 -ErrorAction Stop

    Write-Host ""
    Write-Host "Search completed successfully." -ForegroundColor Green
    Write-Host "Matching folders: $($FolderFileCounts.Count)" -ForegroundColor Green
    Write-Host "Total matching files: $TotalMatchingFiles" -ForegroundColor Green
    Write-Host ""
    Write-Host "Report saved to:" -ForegroundColor Cyan
    Write-Host $ReportPath -ForegroundColor White
}
catch {
    Write-Host "Failed to save the report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}


# ---------------------------------------------------------------------
# Step 10: Display warnings
# ---------------------------------------------------------------------

if ($SearchErrors.Count -gt 0) {
    Write-Host ""
    Write-Host "Warning: Some folders may not have been searched." -ForegroundColor Yellow
    Write-Host "Check permissions for a more complete search." -ForegroundColor Yellow
}


# ---------------------------------------------------------------------
# Step 11: Wait for Enter three times
# ---------------------------------------------------------------------

Write-Host ""
Write-Host "The script has finished." -ForegroundColor Cyan
Write-Host "Press Enter three times to close this window." -ForegroundColor Yellow

for ($i = 1; $i -le 3; $i++) {
    [void](Read-Host "Press Enter ($i/3)")
}
```

