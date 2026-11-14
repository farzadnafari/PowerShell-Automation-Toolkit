
> [!INFO] ایجاد آرشیو TAR بدون فشرده‌سازی
> در صورت نیاز، اسکریپت را با دسترسی Administrator مجدداً اجرا می‌کند.
> پیش از شروع عملیات، برای تأیید و آماده‌سازی کاربر منتظر فشردن کلید Enter می‌ماند.
> با استفاده از ابزار داخلی TAR ویندوز، یک آرشیو با پسوند TAR ایجاد می‌کند.
> مسیر پوشه مبدأ را دریافت کرده و فایل‌ها و زیرپوشه‌های آن را در آرشیو قرار می‌دهد.
> ساختار کامل پوشه‌ها و مسیرهای داخلی را بدون تغییر حفظ می‌کند.
> عملیات بسته‌بندی را بدون اعمال هیچ‌گونه فشرده‌سازی انجام می‌دهد.
> هنگام ایجاد آرشیو، پیام پیشرفت عملیات را از طریق Write-Progress نمایش می‌دهد.
> فایل TAR خروجی را در مسیر کاری اجرای دستور ذخیره می‌کند.
> پس از پایان اجرای دستور، برای خروج از برنامه منتظر فشردن کلید Enter می‌ماند.


> [!INFO] Creating An Uncompressed TAR Archive
> Relaunches The Script With Administrator Privileges When Necessary.
> Waits For The User To Press Enter Before Starting The Operation.
> Uses The Built-In Windows TAR Utility To Create A TAR Archive.
> Receives The Source Directory Path And Includes Its Files And Subdirectories In The Archive.
> Preserves The Complete Directory Structure And Internal Paths Without Modification.
> Performs The Packaging Operation Without Applying Any Compression.
> Displays An Operation Progress Message Through Write-Progress During Archive Creation.
> Saves The Output TAR File In The Current Working Directory.
> Waits For The User To Press Enter Before Exiting The Program.


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

Read-Host "Processing Please [PRESS] Enter ..."

tar -cf "***.tar" -C "###" "===" | ForEach-Object { Write-Progress -Activity "Creating TAR Archive" -Status "Processing..." -PercentComplete 50 }

# ===================================================================================================================================
# End Session --- End Script
# ===================================================================================================================================

Read-Host "Please [PRESS] Enter For End Program ..."
```

