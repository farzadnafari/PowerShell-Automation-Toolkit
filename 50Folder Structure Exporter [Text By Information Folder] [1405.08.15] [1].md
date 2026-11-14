
> [!INFO] ابزار استخراج ساختار پوشه‌ها و فایل‌ها
> این اسکریپت برای استخراج ساختار پوشه‌ها، زیرپوشه‌ها و فایل‌های موجود در یک مسیر مشخص طراحی شده است.
> اسکریپت پس از اجرا، یک عنوان مشخص برای ابزار در پنجره PowerShell نمایش می‌دهد.
> مسیر پوشه مبدأ برای بررسی، به‌صورت تعاملی از کاربر دریافت می‌شود.
> با استفاده از دستور Test-Path اعتبار مسیر ورودی و وجود پوشه بررسی می‌شود.
> در صورت نامعتبر بودن مسیر یا نبودن پوشه، پیام خطا به رنگ قرمز نمایش داده می‌شود.
> پس از بروز خطا، اسکریپت از کاربر می‌خواهد کلید Enter را فشار دهد و سپس خاتمه می‌یابد.
> در صورت معتبر بودن مسیر، با استفاده از Get-Item مسیر کامل پوشه مبدأ استخراج می‌شود.
> مقدار ErrorActionPreference روی Stop تنظیم شده است تا خطاهای غیرقابل‌ادامه به‌صورت توقف اجرای اسکریپت مدیریت شوند.
> بخش قابل مشاهده کد هنوز شامل عملیات پیمایش بازگشتی، تولید گزارش TXT یا ذخیره فایل خروجی نیست و این قابلیت‌ها صرفاً در توضیحات ابتدایی معرفی شده‌اند.


> [!INFO] Folder Structure Exporter
> This script is designed to inspect a specified directory and identify its folders, subfolders, and files.
> It displays a formatted application title in the PowerShell console when executed.
> The source directory path is collected interactively from the user.
> The Test-Path cmdlet checks whether the specified path exists and represents a directory.
> If the path is invalid or the directory does not exist, an error message is displayed in red.
> After an invalid path is detected, the script prompts the user to press ENTER and then terminates.
> If the directory is valid, Get-Item retrieves its full path and assigns it to the RootPath variable.
> ErrorActionPreference is set to Stop so that terminating errors halt script execution.
> The visible code does not yet implement recursive folder traversal, TXT report generation, or output-file saving, although these operations are described in the introductory comments.


```
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
```

