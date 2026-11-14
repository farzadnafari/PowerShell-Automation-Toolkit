
> [!INFO] استخراج فایل‌ها و پوشه‌ها از آرشیو TAR
> در صورت نیاز، اسکریپت را با دسترسی Administrator مجدداً اجرا می‌کند.
> پیش از شروع عملیات استخراج، برای تأیید و آماده‌سازی کاربر منتظر فشردن کلید Enter می‌ماند.
> با استفاده از ابزار داخلی TAR ویندوز، محتویات آرشیو با پسوند TAR را استخراج می‌کند.
> مسیر فایل TAR ورودی را دریافت کرده و آرشیو موردنظر را برای استخراج مشخص می‌کند.
> پوشه مقصد استخراج را در صورت وجود نداشتن، به‌صورت خودکار ایجاد می‌کند.
> تمام فایل‌ها و زیرپوشه‌های موجود در آرشیو را استخراج می‌کند.
> ساختار کامل پوشه‌ها و مسیرهای داخلی را مطابق ساختار اصلی آرشیو حفظ می‌کند.
> هنگام اجرای دستور استخراج، پیام پیشرفت عملیات را از طریق Write-Progress نمایش می‌دهد.
> با استفاده از گزینه Force، در صورت وجود پوشه مقصد، از خطای ایجاد مجدد آن جلوگیری می‌کند.
> پس از پایان اجرای دستور، برای خروج از برنامه منتظر فشردن کلید Enter می‌ماند.


> [!INFO] Extracting Files And Folders From A TAR Archive
> Relaunches The Script With Administrator Privileges When Necessary.
> Waits For The User To Press Enter Before Starting The Extraction Process.
> Uses The Built-In Windows TAR Utility To Extract The Contents Of A TAR Archive.
> Receives The Input TAR File Path And Specifies The Archive To Be Extracted.
> Automatically Creates The Destination Directory If It Does Not Already Exist.
> Extracts All Files And Subdirectories From The Archive.
> Preserves The Complete Directory Structure And Internal Paths According To The Original Archive.
> Displays An Operation Progress Message Through Write-Progress During The Extraction Command.
> Uses The Force Option To Prevent Errors When The Destination Directory Already Exists.
> Waits For The User To Press Enter Before Exiting The Program.


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

Read-Host "Processing Please [PRESS] Enter ..."

New-Item -ItemType Directory -Path "###" -Force

tar -xf "***.tar" -C "###" | ForEach-Object { Write-Progress -Activity "Creating TAR Archive" -Status "Processing..." -PercentComplete 50 }

# ===================================================================================================================================
# End Session --- End Script
# ===================================================================================================================================

Read-Host "Please [PRESS] Enter For End Program ..."
```

