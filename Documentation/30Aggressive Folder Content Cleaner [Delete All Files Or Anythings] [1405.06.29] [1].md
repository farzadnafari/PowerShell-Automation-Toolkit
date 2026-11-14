
> [!INFO] حذف اجباری و بازگشتی تمام محتویات یک پوشه بدون حذف پوشه اصلی
> سطح دسترسی Administrator را بررسی کرده و در صورت نیاز، اسکریپت را با استفاده از UAC مجدداً اجرا می‌کند.
> مسیر پوشه موردنظر را از کاربر دریافت کرده و آن را به‌عنوان مقصد عملیات پاک‌سازی تعیین می‌کند.
> مالکیت فایل‌ها و زیرپوشه‌های موجود را با هدف فراهم‌کردن امکان حذف فایل‌های محافظت‌شده دریافت می‌کند.
> برای گروه Administrators دسترسی Full Control ایجاد می‌کند تا محدودیت‌های دسترسی مانع عملیات حذف نشوند.
> ویژگی‌های Hidden، System و ReadOnly فایل‌ها و پوشه‌ها را حذف می‌کند.
> تمام فایل‌ها و زیرپوشه‌های مسیر انتخاب‌شده را به‌صورت بازگشتی شناسایی می‌کند.
> محتویات پوشه را به‌صورت مستقیم و دائمی حذف می‌کند و از Recycle Bin استفاده نمی‌کند.
> پوشه اصلی انتخاب‌شده حفظ می‌شود و فقط محتویات داخلی آن مورد هدف عملیات قرار می‌گیرند.
> فایل‌هایی که توسط پردازش‌های فعال در حال استفاده هستند ممکن است حتی با دسترسی Administrator حذف نشوند.
> پس از پایان عملیات، برای خروج از محیط PowerShell سه بار درخواست فشردن کلید Enter نمایش داده می‌شود.


> [!INFO] Aggressive Recursive Folder Content Deletion Without Removing The Root Directory
> Checks Administrator Privileges And Automatically Restarts The Script Through UAC When Elevated Permissions Are Required.
> Requests The Target Folder Path From The User And Defines It As The Cleanup Destination.
> Takes Ownership Of Files And Subdirectories To Facilitate The Removal Of Access-Protected Items.
> Grants Full Control Permissions To The Administrators Group To Reduce Permission-Related Deletion Restrictions.
> Removes Hidden, System, And ReadOnly Attributes From Files And Directories.
> Recursively Identifies All Files And Subdirectories Within The Selected Folder.
> Permanently Deletes Folder Contents Directly Without Sending Items To The Recycle Bin.
> Preserves The Selected Root Directory And Targets Only Its Internal Contents.
> Files Currently In Use By Active Processes May Remain Undeleted Even With Administrator Privileges.
> Displays Three Enter Key Confirmation Prompts Before Exiting The PowerShell Environment.


```
# ============================================================
# AGGRESSIVE FOLDER CONTENT CLEANER
# ============================================================
#
# این اسکریپت برای حذف کامل و اجباری تمام محتویات یک پوشه
# طراحی شده است.
#
# ویژگی‌ها:
#   1. بررسی می‌کند PowerShell با Administrator اجرا شده باشد.
#   2. در صورت نبود دسترسی Administrator، خودش با UAC دوباره اجرا می‌شود.
#   3. مسیر پوشه را از کاربر دریافت می‌کند.
#   4. مالکیت فایل‌ها و پوشه‌ها را می‌گیرد.
#   5. دسترسی Full Control برای Administrators ایجاد می‌کند.
#   6. Attributeهای Hidden / System / ReadOnly را حذف می‌کند.
#   7. تمام فایل‌ها و Subfolderها را Recursive حذف می‌کند.
#   8. حذف مستقیماً انجام می‌شود و وارد Recycle Bin نمی‌شود.
#   9. خود پوشه اصلی که مسیر آن وارد شده حذف نمی‌شود.
#  10. در پایان برای خروج، سه بار Enter درخواست می‌کند.
#
# توجه:
#   فایل‌هایی که توسط یک Process در حال استفاده هستند ممکن است
#   حتی با Administrator نیز قابل حذف نباشند.
#
# ============================================================


# ------------------------------------------------------------
# مرحله 1 - بررسی Administrator
# ------------------------------------------------------------

$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

$isAdmin = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host " Administrator permission required" -ForegroundColor Yellow
    Write-Host " Restarting PowerShell as Administrator..." -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host ""

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

    exit
}


# ------------------------------------------------------------
# مرحله 2 - نمایش عنوان
# ------------------------------------------------------------

Clear-Host

Write-Host "============================================================" -ForegroundColor Red
Write-Host "        AGGRESSIVE FOLDER CONTENT CLEANER" -ForegroundColor Red
Write-Host "============================================================" -ForegroundColor Red
Write-Host ""
Write-Host "PowerShell is running as ADMINISTRATOR." -ForegroundColor Green
Write-Host ""
Write-Host "WARNING:" -ForegroundColor Yellow
Write-Host "Everything INSIDE the selected folder will be permanently deleted." -ForegroundColor Yellow
Write-Host "The selected folder itself will NOT be deleted." -ForegroundColor Yellow
Write-Host ""


# ------------------------------------------------------------
# مرحله 3 - دریافت مسیر
# ------------------------------------------------------------

$TargetPath = Read-Host "Enter the folder path to CLEAN"

if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    Write-Host ""
    Write-Host "No path entered. Exiting..." -ForegroundColor Red
    Read-Host "Press Enter"
    exit
}


# ------------------------------------------------------------
# مرحله 4 - تبدیل مسیر به مسیر کامل
# ------------------------------------------------------------

try {
    $TargetPath = [System.IO.Path]::GetFullPath($TargetPath)
}
catch {
    Write-Host ""
    Write-Host "Invalid path." -ForegroundColor Red
    Read-Host "Press Enter"
    exit
}


# ------------------------------------------------------------
# مرحله 5 - بررسی وجود مسیر
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $TargetPath -PathType Container)) {

    Write-Host ""
    Write-Host "Folder does not exist:" -ForegroundColor Red
    Write-Host $TargetPath -ForegroundColor Yellow
    Write-Host ""

    Read-Host "Press Enter"
    exit
}


# ------------------------------------------------------------
# مرحله 6 - محافظت در برابر مسیرهای بسیار خطرناک
# ------------------------------------------------------------

$FullTarget = $TargetPath.TrimEnd('\')

$DangerousPaths = @(
    "C:\",
    "C:\Windows",
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\ProgramData",
    "C:\Users"
)

foreach ($DangerousPath in $DangerousPaths) {

    if ($FullTarget -ieq $DangerousPath) {

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host " DANGEROUS PATH BLOCKED" -ForegroundColor Red
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "This script will not clean this system-critical folder:" -ForegroundColor Yellow
        Write-Host $FullTarget -ForegroundColor Yellow
        Write-Host ""

        Read-Host "Press Enter"
        exit
    }
}


# ------------------------------------------------------------
# مرحله 7 - تأیید نهایی
# ------------------------------------------------------------

Write-Host ""
Write-Host "TARGET:" -ForegroundColor Cyan
Write-Host $FullTarget -ForegroundColor White
Write-Host ""

Write-Host "EVERYTHING INSIDE THIS FOLDER WILL BE DELETED." -ForegroundColor Red
Write-Host "THE FOLDER ITSELF WILL REMAIN." -ForegroundColor Yellow
Write-Host ""

$Confirmation = Read-Host "Type DELETE to continue"

if ($Confirmation -cne "DELETE") {

    Write-Host ""
    Write-Host "Operation cancelled." -ForegroundColor Green
    Write-Host ""

    Read-Host "Press Enter"
    exit
}


# ------------------------------------------------------------
# مرحله 8 - شروع عملیات
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Red
Write-Host " STARTING AGGRESSIVE CLEANUP" -ForegroundColor Red
Write-Host "============================================================" -ForegroundColor Red
Write-Host ""


# ------------------------------------------------------------
# مرحله 9 - گرفتن Ownership
# ------------------------------------------------------------

Write-Host "[1/5] Taking ownership..." -ForegroundColor Cyan

takeown.exe /F "$FullTarget" /R /D Y 2>$null | Out-Null


# ------------------------------------------------------------
# مرحله 10 - دادن Full Control
# ------------------------------------------------------------

Write-Host "[2/5] Granting Administrators Full Control..." -ForegroundColor Cyan

icacls.exe "$FullTarget" `
    /grant Administrators:F `
    /T `
    /C `
    2>$null | Out-Null


# ------------------------------------------------------------
# مرحله 11 - حذف Attributeهای مزاحم
# ------------------------------------------------------------

Write-Host "[3/5] Removing Hidden/System/ReadOnly attributes..." -ForegroundColor Cyan

attrib.exe -H -S -R "$FullTarget\*" /S /D 2>$null | Out-Null


# ------------------------------------------------------------
# مرحله 12 - حذف فایل‌ها و پوشه‌ها
# ------------------------------------------------------------

Write-Host "[4/5] Deleting contents..." -ForegroundColor Cyan
Write-Host ""

$Items = Get-ChildItem `
    -LiteralPath $FullTarget `
    -Force `
    -ErrorAction SilentlyContinue

$Total = $Items.Count
$Current = 0

foreach ($Item in $Items) {

    $Current++

    Write-Progress `
        -Activity "Aggressive deletion" `
        -Status "$Current / $Total : $($Item.Name)" `
        -PercentComplete $(if ($Total -gt 0) {
            [math]::Min(100, ($Current / $Total) * 100)
        } else {
            100
        })

    try {

        # برداشتن Attributeهای محافظتی
        if (-not $Item.PSIsContainer) {
            attrib.exe -H -S -R "$($Item.FullName)" 2>$null | Out-Null
        }

        # حذف اجباری
        Remove-Item `
            -LiteralPath $Item.FullName `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue

    }
    catch {
        # ادامه دادن حتی در صورت خطا
        continue
    }
}

Write-Progress `
    -Activity "Aggressive deletion" `
    -Completed


# ------------------------------------------------------------
# مرحله 13 - تلاش نهایی برای موارد باقی‌مانده
# ------------------------------------------------------------

Write-Host ""
Write-Host "[5/5] Performing final cleanup pass..." -ForegroundColor Cyan

Start-Sleep -Milliseconds 500

$Remaining = Get-ChildItem `
    -LiteralPath $FullTarget `
    -Force `
    -ErrorAction SilentlyContinue

foreach ($Item in $Remaining) {

    try {

        attrib.exe -H -S -R "$($Item.FullName)" /S /D 2>$null | Out-Null

        Remove-Item `
            -LiteralPath $Item.FullName `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue

    }
    catch {
        continue
    }
}


# ------------------------------------------------------------
# مرحله 14 - بررسی نتیجه
# ------------------------------------------------------------

$StillThere = Get-ChildItem `
    -LiteralPath $FullTarget `
    -Force `
    -ErrorAction SilentlyContinue


Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " CLEANUP FINISHED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

if ($null -eq $StillThere -or $StillThere.Count -eq 0) {

    Write-Host "SUCCESS: Folder is completely empty." -ForegroundColor Green

}
else {

    Write-Host "WARNING: Some items could not be deleted." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Remaining items:" -ForegroundColor Yellow

    foreach ($Item in $StillThere) {
        Write-Host "  $($Item.FullName)" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "These items are probably locked by another process," -ForegroundColor Yellow
    Write-Host "protected by the operating system, or otherwise in use." -ForegroundColor Yellow
}


# ------------------------------------------------------------
# مرحله 15 - سه بار Enter برای خروج
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Press ENTER three times to exit." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Read-Host
Read-Host
Read-Host
```

