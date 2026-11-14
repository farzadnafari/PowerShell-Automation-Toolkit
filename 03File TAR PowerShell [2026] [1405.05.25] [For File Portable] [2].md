
> [!INFO] ایجاد آرشیو TAR همراه با نمایش اطلاعات و گزارش خطا
> در صورت نیاز، اسکریپت را با دسترسی Administrator مجدداً اجرا می‌کند.
> پیش از شروع عملیات، اطلاعات کامل آرشیو شامل نوع بسته‌بندی، ساختار و مشخصات آن را به کاربر نمایش می‌دهد.
> با استفاده از Read-Host، پیام راهنمای شروع برنامه را نمایش داده و منتظر فشردن کلید Enter می‌ماند.
> مسیر پوشه مبدأ و نام فایل TAR خروجی را از طریق متغیرهای قابل تنظیم مشخص می‌کند.
> بخش محاسبه حجم کل فایل‌ها و پایش لحظه‌ای اندازه آرشیو با استفاده از Start-Job به‌صورت کامنت غیرفعال شده است.
> با استفاده از ابزار TAR ویندوز، تمام محتویات مسیر مبدأ شامل فایل‌ها و زیرپوشه‌ها را در یک آرشیو قرار می‌دهد.
> ساختار کامل پوشه‌ها و مسیرهای داخلی را حفظ کرده و عملیات بسته‌بندی را بدون فشرده‌سازی انجام می‌دهد.
> خطاهای خروجی ابزار TAR را در فایل متنی Tar Errors.txt در مسیر تعیین‌شده ذخیره می‌کند.
> هنگام اجرای عملیات، پیام پیشرفت ثابت ۵۰ درصدی را از طریق Write-Progress نمایش می‌دهد.
> پس از پایان اجرای دستور، پیام اتمام عملیات را نمایش داده و برای خروج از برنامه منتظر فشردن کلید Enter می‌ماند.


> [!INFO] Creating A TAR Archive With Information And Error Logging
> Relaunches The Script With Administrator Privileges When Necessary.
> Displays Complete Archive Information, Including Package Type, Structure, And Specifications Before Starting The Operation.
> Uses Read-Host To Display The Program Startup Instructions And Waits For The User To Press Enter.
> Defines The Source Directory Path And Output TAR Archive Name Through Configurable Variables.
> Disables The Total File Size Calculation And Real-Time Archive Size Monitoring Using Start-Job By Commenting Out That Section.
> Uses The Windows TAR Utility To Package All Contents Of The Source Path, Including Files And Subdirectories.
> Preserves The Complete Directory Structure And Internal Paths While Creating An Uncompressed Archive.
> Redirects TAR Utility Error Output To A Text File Named Tar Errors.txt In The Specified Path.
> Displays A Fixed 50 Percent Progress Indicator Through Write-Progress During Archive Creation.
> Displays The Operation Completion Message And Waits For The User To Press Enter Before Exiting The Program.


```
# ===================================================================================================================================
#	TAR PACKAGE INFORMATION
#	* Package Type: TAR Archive
#	* Purpose: Portable File & Folder Package
#	* Compression: None
#	* Structure: Fully Preserved
#	* This TAR Archive Contains The Complete Directory Structure And All Files Within The Original Package.
#	* Designed For Reliable, Portable, And Lossless Transfer Of Files And Nested Directories Without Compression.
#	* PowerShell Script Designer: Farzad Nafari
# ===================================================================================================================================

# ===================================================================================================================================
# First Session --- Run As Administrator
# ===================================================================================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# ===================================================================================================================================
# Second Session --- Tar Script
# ===================================================================================================================================

Read-Host "`n`n`n* Package Type: TAR Archive`n* Purpose: Portable File & Folder Package`n* Compression: None`n* Structure: Fully Preserved`n* This TAR Archive Contains The Complete Directory Structure And All Files Within The Original Package.`n* Designed For Reliable, Portable, And Lossless Transfer Of Files And Nested Directories Without Compression.`n* PowerShell Script Designer: Farzad Nafari`n`n`nDear User; The Program You Are Using Is Designed To Package The Folder Or File You Want. Please Follow All The Instructions For The Related Operations And Wait Until The Process Is Completed, Which You Will Be Informed About. To Start, Please Enter The Number.`n`n`nThe Program Has Started, Please Press The [ENTER] Key"

# $Source = "***"
# $TarFile = "***.tar"
# 
# $TotalSize = (Get-ChildItem -LiteralPath $Source -File -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
# 
# Start-Job -ScriptBlock {
#     param($TarFile, $TotalSize)
# 
#     while (-not (Test-Path -LiteralPath $TarFile)) {
#         Start-Sleep -Milliseconds 500
#     }
# 
#     while ($true) {
#         $CurrentSize = (Get-Item -LiteralPath $TarFile).Length
#         $Percent = [Math]::Min(99, [Math]::Round(($CurrentSize / $TotalSize) * 100, 1))
# 
#         Write-Progress -Activity "TAR Creating" -Status "$Percent% Completed" -PercentComplete $Percent
# 
#         Start-Sleep -Milliseconds 500
#     }
# } -ArgumentList $TarFile, $TotalSize
# 

tar -cf "***.tar" -C "**" "*" 2> "**\Tar Errors.txt" | ForEach-Object { Write-Progress -Activity "Creating TAR Archive" -Status "Processing..." -PercentComplete 50 }

# ===================================================================================================================================
# End Session --- End Script
# ===================================================================================================================================

Read-Host "`n`n`nThe Program Has Finished. Please Press The [ENTER] Key"
```

