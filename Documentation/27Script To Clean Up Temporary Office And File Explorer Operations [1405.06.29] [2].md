
> [!INFO] پاک‌سازی گسترده تاریخچه، حافظه موقت و کش Microsoft Office و Windows
> دسترسی Administrator را بررسی کرده و در صورت نیاز، اسکریپت را با دسترسی مدیر سیستم مجدداً اجرا می‌کند.
> محدودیت ExecutionPolicy را برای نشست فعلی PowerShell به‌صورت موقت دور می‌زند.
> پردازش‌های فعال Microsoft Office را برای فراهم‌کردن امکان پاک‌سازی متوقف می‌کند.
> اطلاعات MRU آفیس شامل فهرست اسناد و فایل‌های اخیراً استفاده‌شده را پاک‌سازی می‌کند.
> اطلاعات Recent ویندوز و میانبرهای مربوط به فایل‌ها و فعالیت‌های اخیر را حذف می‌کند.
> حافظه‌های موقت و کش‌های قابل بازسازی Microsoft Office را پاک‌سازی می‌کند.
> فایل‌های موقت حساب کاربری فعلی را از پوشه TEMP حذف می‌کند.
> کش تصاویر بندانگشتی و آیکون‌های ویندوز را پاک‌سازی کرده و سپس محیط Windows Explorer را تازه‌سازی می‌کند.
> پس از پایان عملیات، سه مرتبه برای فشردن کلید Enter منتظر می‌ماند و سپس به‌طور کامل از محیط PowerShell خارج می‌شود.


> [!INFO] Aggressive Microsoft Office And Windows History, Cache, And Temporary Data Cleanup
> Checks Administrator Privileges And Automatically Restarts The Script With Elevated Permissions When Necessary.
> Temporarily Bypasses The ExecutionPolicy Restriction For The Current PowerShell Session.
> Terminates Active Microsoft Office Processes To Facilitate The Cleanup Operations.
> Cleans Office MRU Data, Including Lists Of Recently Used And Accessed Documents.
> Removes Windows Recent Items Data And Shortcuts Associated With Recently Accessed Files And Activities.
> Cleans Rebuildable Microsoft Office Temporary Data And Cache Files.
> Removes Temporary Files Belonging To The Current User From The TEMP Directory.
> Clears Windows Thumbnail And Icon Caches, Then Refreshes The Windows Explorer Environment.
> Waits For Three Enter Key Presses After Completing The Cleanup Operations And Then Fully Exits PowerShell.


```
# ============================================================================
#                  AGGRESSIVE OFFICE AND WINDOWS CLEANUP
# ============================================================================
#
# Purpose:
#   Clean removable Office and Windows recent/history/cache data.
#
# Safety:
#   - Does not intentionally delete personal documents.
#   - Does not delete Office documents.
#   - Does not disable Windows services.
#   - Does not permanently run in the background.
#
# Features:
#   - Automatic Administrator elevation
#   - ExecutionPolicy Bypass
#   - Office process termination
#   - Office MRU cleanup
#   - Windows Recent cleanup
#   - Rebuildable Office cache cleanup
#   - User TEMP cleanup
#   - Thumbnail and icon cache cleanup
#   - Explorer refresh
#   - Three ENTER confirmations
#   - Complete PowerShell exit after completion
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
Write-Host "              AGGRESSIVE OFFICE AND WINDOWS CLEANUP" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Administrator Access : OK" -ForegroundColor Green
Write-Host "ExecutionPolicy Bypass : ENABLED" -ForegroundColor Green
Write-Host ""

# ============================================================================
# [3] Stop Office Processes
# ============================================================================

Write-Host "[1/7] Closing Microsoft Office processes..." -ForegroundColor Yellow

$OfficeProcesses = @(
    "WINWORD",
    "EXCEL",
    "POWERPNT",
    "OUTLOOK",
    "ONENOTE",
    "MSACCESS",
    "MSPUB",
    "VISIO",
    "LYNC",
    "Teams"
)

foreach ($ProcessName in $OfficeProcesses) {

    Get-Process -Name $ProcessName -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
}

Start-Sleep -Seconds 2

Write-Host "  Office processes closed." -ForegroundColor Green

# ============================================================================
# [4] Office MRU Registry Cleanup
# ============================================================================

Write-Host ""
Write-Host "[2/7] Cleaning Microsoft Office MRU history..." -ForegroundColor Yellow

$OfficeRegistryPaths = @(
    "HKCU:\Software\Microsoft\Office\16.0\Word\File MRU",
    "HKCU:\Software\Microsoft\Office\16.0\Excel\File MRU",
    "HKCU:\Software\Microsoft\Office\16.0\PowerPoint\File MRU",
    "HKCU:\Software\Microsoft\Office\16.0\Outlook\File MRU",
    "HKCU:\Software\Microsoft\Office\16.0\Access\File MRU",
    "HKCU:\Software\Microsoft\Office\16.0\OneNote\File MRU"
)

foreach ($Path in $OfficeRegistryPaths) {

    if (Test-Path $Path) {

        $Properties = (Get-ItemProperty -Path $Path).PSObject.Properties

        foreach ($Property in $Properties) {

            if ($Property.Name -notmatch "^PS") {

                Remove-ItemProperty `
                    -Path $Path `
                    -Name $Property.Name `
                    -Force `
                    -ErrorAction SilentlyContinue
            }
        }

        Write-Host "  Cleaned: $Path" -ForegroundColor Green
    }
}

# ============================================================================
# [5] Windows Recent Cleanup
# ============================================================================

Write-Host ""
Write-Host "[3/7] Cleaning Windows Recent history..." -ForegroundColor Yellow

$RecentLocations = @(
    "$env:APPDATA\Microsoft\Windows\Recent",
    "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations",
    "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations"
)

foreach ($Location in $RecentLocations) {

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
# [6] Rebuildable Office Cache Cleanup
# ============================================================================

Write-Host ""
Write-Host "[4/7] Cleaning rebuildable Office cache data..." -ForegroundColor Yellow

$OfficeCacheLocations = @(
    "$env:LOCALAPPDATA\Microsoft\Office\16.0\OfficeFileCache",
    "$env:LOCALAPPDATA\Microsoft\Office\16.0\Wef",
    "$env:LOCALAPPDATA\Microsoft\Office\16.0\WebServiceCache",
    "$env:APPDATA\Microsoft\Office\Recent"
)

foreach ($Location in $OfficeCacheLocations) {

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
# [7] User TEMP Cleanup
# ============================================================================

Write-Host ""
Write-Host "[5/7] Cleaning user temporary files..." -ForegroundColor Yellow

$TempLocations = @(
    $env:TEMP,
    "$env:LOCALAPPDATA\Temp"
)

foreach ($Location in $TempLocations) {

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
# [8] Thumbnail and Icon Cache Cleanup
# ============================================================================

Write-Host ""
Write-Host "[6/7] Cleaning rebuildable thumbnail and icon caches..." -ForegroundColor Yellow

$ExplorerCache = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"

if (Test-Path $ExplorerCache) {

    Get-ChildItem `
        -Path $ExplorerCache `
        -Force `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match "^thumbcache" -or
            $_.Name -match "^iconcache"
        } |
        Remove-Item `
            -Force `
            -ErrorAction SilentlyContinue

    Write-Host "  Thumbnail and icon caches cleaned." -ForegroundColor Green
}

# ============================================================================
# [9] Explorer Refresh
# ============================================================================

Write-Host ""
Write-Host "[7/7] Refreshing Windows Explorer..." -ForegroundColor Yellow

Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2

Start-Process explorer.exe

Start-Sleep -Seconds 3

Write-Host "  Explorer refreshed." -ForegroundColor Green

# ============================================================================
# Final Status
# ============================================================================

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "                    CLEANUP COMPLETED" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Office MRU              : CLEANED" -ForegroundColor Green
Write-Host "Windows Recent          : CLEANED" -ForegroundColor Green
Write-Host "Office Cache            : CLEANED" -ForegroundColor Green
Write-Host "User TEMP               : CLEANED" -ForegroundColor Green
Write-Host "Thumbnail/Icon Cache    : CLEANED" -ForegroundColor Green
Write-Host "Office Processes        : CLOSED" -ForegroundColor Green
Write-Host "Explorer                : REFRESHED" -ForegroundColor Green
Write-Host ""
Write-Host "No intentional deletion of personal documents was performed." -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Three ENTER confirmations
# ============================================================================

Read-Host "Press ENTER (1/3)"
Read-Host "Press ENTER (2/3)"
Read-Host "Press ENTER (3/3)"

# ============================================================================
# Complete Exit
# ============================================================================

Write-Host ""
Write-Host "PowerShell session is shutting down..." -ForegroundColor Cyan

Start-Sleep -Seconds 5

exit
```

