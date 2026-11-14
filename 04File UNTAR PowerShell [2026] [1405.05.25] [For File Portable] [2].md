
> [!INFO] استخراج آرشیو TAR همراه با نمایش اطلاعات و ایجاد پوشه مقصد
> در صورت نیاز، اسکریپت را با دسترسی Administrator مجدداً اجرا می‌کند.
> پیش از شروع عملیات، اطلاعات کامل بسته شامل نوع آرشیو، ساختار، محتویات و مشخصات آن را به کاربر نمایش می‌دهد.
> با استفاده از Read-Host، پیام راهنمای شروع برنامه را نمایش داده و منتظر فشردن کلید Enter می‌ماند.
> مسیر فایل TAR ورودی و پوشه مقصد استخراج را از طریق متغیرهای قابل تنظیم مشخص می‌کند.
> بخش محاسبه حجم کل فایل‌ها و پایش لحظه‌ای اندازه آرشیو با استفاده از Start-Job به‌صورت کامنت غیرفعال شده است.
> با استفاده از دستور New-Item، پوشه مقصد استخراج را در صورت نیاز ایجاد می‌کند.
> با استفاده از ابزار TAR ویندوز، تمام فایل‌ها و زیرپوشه‌های موجود در آرشیو را استخراج می‌کند.
> ساختار کامل پوشه‌ها و مسیرهای داخلی را مطابق ساختار اصلی آرشیو حفظ می‌کند.
> هنگام اجرای عملیات استخراج، پیام پیشرفت ثابت ۵۰ درصدی را از طریق Write-Progress نمایش می‌دهد.
> پس از پایان اجرای دستور، پیام اتمام عملیات را نمایش داده و برای خروج از برنامه منتظر فشردن کلید Enter می‌ماند.


> [!INFO] Extracting A TAR Archive With Information Display And Destination Directory Creation
> Relaunches The Script With Administrator Privileges When Necessary.
> Displays Complete Package Information, Including Archive Type, Structure, Contents, And Specifications Before Starting The Operation.
> Uses Read-Host To Display The Program Startup Instructions And Waits For The User To Press Enter.
> Defines The Input TAR Archive Path And Extraction Destination Directory Through Configurable Variables.
> Disables The Total File Size Calculation And Real-Time Archive Size Monitoring Using Start-Job By Commenting Out That Section.
> Uses The New-Item Command To Create The Extraction Destination Directory When Necessary.
> Uses The Windows TAR Utility To Extract All Files And Subdirectories Contained Within The Archive.
> Preserves The Complete Directory Structure And Internal Paths According To The Original Archive.
> Displays A Fixed 50 Percent Progress Indicator Through Write-Progress During The Extraction Operation.
> Displays The Operation Completion Message And Waits For The User To Press Enter Before Exiting The Program.


```
# ===================================================================================================================================
#	UNTAR PACKAGE INFORMATION
#	* Package Type: UNTAR Archive
#	* Purpose: Portable File & Folder Package
#	* Compression: None
#	* Structure: Fully Preserved
#	* This UNTAR Archive Contains The Complete Directory Structure And All Files Within The Original Package.
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
# Second Session --- UnTar Script
# ===================================================================================================================================

Read-Host "`n`n`n* Package Type: UNTAR Archive`n* Purpose: Portable File & Folder Package`n* Compression: None`n* Structure: Fully Preserved`n* This TAR Archive Contains The Complete Directory Structure And All Files Within The Original Package.`n* Designed For Reliable, Portable, And Lossless Transfer Of Files And Nested Directories Without Compression.`n* PowerShell Script Designer: Farzad Nafari`n`n`nDear User; The Program You Are Using Is Designed To UnPackage The Folder Or File You Want. Please Follow All The Instructions For The Related Operations And Wait Until The Process Is Completed, Which You Will Be Informed About. To Start, Please Enter The Number.`n`n`nThe Program Has Started, Please Press The [ENTER] Key"

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

New-Item -ItemType Directory -Path "###" -Force

tar -xf "***.tar" -C "###" | ForEach-Object { Write-Progress -Activity "Creating TAR Archive" -Status "Processing..." -PercentComplete 50 }

# ===================================================================================================================================
# End Session --- End Script
# ===================================================================================================================================

Read-Host "`n`n`nThe Program Has Finished. Please Press The [ENTER] Key"
```

