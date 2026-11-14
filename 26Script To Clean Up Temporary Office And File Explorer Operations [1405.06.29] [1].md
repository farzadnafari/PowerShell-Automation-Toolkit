
> [!INFO] پاک‌سازی اطلاعات Recent و تاریخچه فعالیت‌های Microsoft Office
> سطح دسترسی Administrator را بررسی کرده و در صورت نیاز، برنامه را با دسترسی مدیر سیستم مجدداً اجرا می‌کند.
> محدودیت ExecutionPolicy را برای نشست فعلی PowerShell به‌صورت موقت دور می‌زند.
> اطلاعات Recent و داده‌های تاریخچه مرتبط با Microsoft Office را برای حساب کاربری فعلی شناسایی می‌کند.
> فایل‌ها و اطلاعات مربوط به فهرست اسناد اخیراً بازشده در برنامه‌های Office را پاک‌سازی می‌کند.
> میانبرهای مرتبط با اسناد و فعالیت‌های اخیر Office را در بخش Recent ویندوز شناسایی و حذف می‌کند.
> هدف اصلی، حذف آثار دسترسی اخیر به اسناد Office و پاک‌سازی فهرست فایل‌های اخیراً استفاده‌شده است.
> عملیات پاک‌سازی به اطلاعات Recent و History مرتبط با کاربر فعلی محدود می‌شود.
> این اسکریپت برای مدیریت داده‌های تاریخچه Office طراحی شده و به‌معنای حذف اسناد اصلی یا فایل‌های شخصی نیست.
> پس از پایان عملیات، برای سه بار فشردن کلید Enter منتظر می‌ماند و سپس از محیط PowerShell خارج می‌شود.


> [!INFO] پاک‌سازی اطلاعات Recent و تاریخچه فعالیت‌های Microsoft Office
> سطح دسترسی Administrator را بررسی کرده و در صورت نیاز، برنامه را با دسترسی مدیر سیستم مجدداً اجرا می‌کند.
> محدودیت ExecutionPolicy را برای نشست فعلی PowerShell به‌صورت موقت دور می‌زند.
> اطلاعات Recent و داده‌های تاریخچه مرتبط با Microsoft Office را برای حساب کاربری فعلی شناسایی می‌کند.
> فایل‌ها و اطلاعات مربوط به فهرست اسناد اخیراً بازشده در برنامه‌های Office را پاک‌سازی می‌کند.
> میانبرهای مرتبط با اسناد و فعالیت‌های اخیر Office را در بخش Recent ویندوز شناسایی و حذف می‌کند.
> هدف اصلی، حذف آثار دسترسی اخیر به اسناد Office و پاک‌سازی فهرست فایل‌های اخیراً استفاده‌شده است.
> عملیات پاک‌سازی به اطلاعات Recent و History مرتبط با کاربر فعلی محدود می‌شود.
> این اسکریپت برای مدیریت داده‌های تاریخچه Office طراحی شده و به‌معنای حذف اسناد اصلی یا فایل‌های شخصی نیست.
> پس از پایان عملیات، برای سه بار فشردن کلید Enter منتظر می‌ماند و سپس از محیط PowerShell خارج می‌شود.


```
# ============================================================================
#                         MICROSOFT OFFICE CLEANUP
# ============================================================================
#
# Purpose:
#   Clean Microsoft Office Recent and History data for the current user.
#
# Features:
#   - Automatic Administrator elevation
#   - ExecutionPolicy Bypass
#   - Office Recent data cleanup
#   - Office-related Recent shortcuts cleanup
#   - Three ENTER confirmations before exit
#
# ============================================================================

$ErrorActionPreference = "SilentlyContinue"

# ============================================================================
# [1] Administrator Check
# ============================================================================

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

if (-not $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {

    Write-Host ""
    Write-Host "Administrator privileges are required." -ForegroundColor Yellow
    Write-Host "Restarting as Administrator..." -ForegroundColor Cyan
    Write-Host ""

    $ScriptPath = $MyInvocation.MyCommand.Path

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

    exit
}

# ============================================================================
# [2] Header
# ============================================================================

Clear-Host

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "                  MICROSOFT OFFICE CLEANUP" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Administrator Access : OK" -ForegroundColor Green
Write-Host "ExecutionPolicy Bypass : ENABLED" -ForegroundColor Green
Write-Host ""

# ============================================================================
# [3] Office MRU Registry Cleanup
# ============================================================================

Write-Host "[1/4] Cleaning Microsoft Office Recent History..." -ForegroundColor Yellow

$OfficePaths = @(
    "HKCU:\Software\Microsoft\Office\16.0\Word\File MRU",
    "HKCU:\Software\Microsoft\Office\16.0\Excel\File MRU",
    "HKCU:\Software\Microsoft\Office\16.0\PowerPoint\File MRU",
    "HKCU:\Software\Microsoft\Office\16.0\Access\File MRU",
    "HKCU:\Software\Microsoft\Office\16.0\OneNote\File MRU"
)

foreach ($Path in $OfficePaths) {

    if (Test-Path $Path) {

        Get-ItemProperty -Path $Path |
            Select-Object -Property * |
            ForEach-Object {
                $_.PSObject.Properties |
                    Where-Object {
                        $_.Name -notmatch "^PS"
                    } |
                    ForEach-Object {
                        Remove-ItemProperty `
                            -Path $Path `
                            -Name $_.Name `
                            -Force `
                            -ErrorAction SilentlyContinue
                    }
            }

        Write-Host "  Cleaned: $Path" -ForegroundColor Green
    }
}

# ============================================================================
# [4] Office Recent Folder Cleanup
# ============================================================================

Write-Host ""
Write-Host "[2/4] Cleaning Office Recent folders..." -ForegroundColor Yellow

$OfficeRecentLocations = @(
    "$env:APPDATA\Microsoft\Office\Recent",
    "$env:LOCALAPPDATA\Microsoft\Office\16.0\OfficeFileCache"
)

foreach ($Location in $OfficeRecentLocations) {

    if (Test-Path $Location) {

        Get-ChildItem `
            -Path $Location `
            -Force `
            -ErrorAction SilentlyContinue |
            Remove-Item `
                -Force `
                -Recurse `
                -ErrorAction SilentlyContinue

        Write-Host "  Cleaned: $Location" -ForegroundColor Green
    }
}

# ============================================================================
# [5] Windows Recent Office Shortcuts
# ============================================================================

Write-Host ""
Write-Host "[3/4] Cleaning Office-related Recent shortcuts..." -ForegroundColor Yellow

$RecentFolder = "$env:APPDATA\Microsoft\Windows\Recent"

if (Test-Path $RecentFolder) {

    Get-ChildItem `
        -Path $RecentFolder `
        -Force `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Extension -in ".lnk", ".url"
        } |
        ForEach-Object {

            $Name = $_.Name.ToLower()

            if (
                $Name -match "word" -or
                $Name -match "excel" -or
                $Name -match "powerpoint" -or
                $Name -match "outlook" -or
                $Name -match "access" -or
                $Name -match "onenote"
            ) {
                Remove-Item `
                    -Path $_.FullName `
                    -Force `
                    -ErrorAction SilentlyContinue
            }
        }

    Write-Host "  Office-related shortcuts processed." -ForegroundColor Green
}

# ============================================================================
# [6] Final Status
# ============================================================================

Write-Host ""
Write-Host "[4/4] Cleanup completed successfully." -ForegroundColor Green
Write-Host ""

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "                       CLEANUP FINISHED" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Three ENTER confirmations
# ============================================================================

Read-Host "Press ENTER (1/3)"
Read-Host "Press ENTER (2/3)"
Read-Host "Press ENTER (3/3)"

Write-Host ""
Write-Host "Exiting..." -ForegroundColor Cyan

Start-Sleep -Seconds 1
```

