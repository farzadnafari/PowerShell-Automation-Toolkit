
> [!INFO] ممیزی جامع سلامت و بررسی جرم‌شناختی سیستم ویندوز
> دسترسی Administrator را بررسی کرده و در صورت نیاز، اسکریپت را با دسترسی مدیریتی مجدداً اجرا می‌کند.
> در زمان اجرای مجدد، محدودیت Execution Policy را برای همان پردازش PowerShell دور می‌زند، بدون تغییر دائمی سیاست سیستم.
> اطلاعات اولیه سیستم شامل زمان اجرای ممیزی، مسیر Desktop و مسیر پوشه اصلی گزارش‌ها را آماده می‌کند.
> با هدف بررسی جامع وضعیت ویندوز 10 و 11، اطلاعات تشخیصی سیستم را جمع‌آوری می‌کند.
> ساختار اسکریپت به‌صورت Read-Only طراحی شده و قصد تغییر رجیستری، سرویس‌ها، تنظیمات Startup و وظایف زمان‌بندی‌شده را ندارد.
> پیکربندی Boot، تنظیمات BIOS و UEFI، Windows Defender و Firewall را بدون تغییر بررسی می‌کند.
> وضعیت Windows Update، Page File، Group Policy و پیکربندی شبکه را برای شناسایی مشکلات احتمالی در نظر می‌گیرد.
> قابلیت اجرای بررسی‌های سلامت و اسکن‌های تشخیصی فقط‌خواندنی را برای ارزیابی وضعیت سیستم فراهم می‌کند.
> اطلاعات ممیزی را با ساختار پوشه‌بندی مشخص و بر اساس زمان اجرا سازمان‌دهی می‌کند.
> این کد ارسالی فقط بخش ابتدایی ممیزی است و جزئیات بررسی‌ها و گزارش‌های نهایی در ادامه اسکریپت مشخص خواهند شد.


> [!INFO] Comprehensive Windows System Health And Forensic Audit
> Checks Administrator Privileges And Relaunches The Script With Administrative Permissions When Necessary.
> Temporarily Bypasses Execution Policy Restrictions For The Current PowerShell Process Without Permanently Changing System Policy.
> Prepares Initial System Information, Including Audit Timestamp, Desktop Location, And The Main Report Directory.
> Collects Diagnostic Information To Perform A Comprehensive Assessment Of Windows 10 And Windows 11.
> Uses A Read-Only Design And Does Not Intentionally Modify The Registry, Services, Startup Settings, Or Scheduled Tasks.
> Examines Boot Configuration, BIOS And UEFI Settings, Windows Defender, And Firewall Without Making Changes.
> Includes Windows Update, Page File, Group Policy, And Network Configuration In Its Intended Diagnostic Scope.
> Provides A Framework For Running Read-Only Health Checks And Diagnostic Scans To Identify Potential System Issues.
> Organizes Audit Information Using A Structured Directory Layout Based On The Execution Timestamp.
> Only The Initial Part Of The Audit Script Has Been Provided; The Detailed Checks And Final Reports Depend On The Remaining Code.


```
<#
===========================================================================
 FULL SYSTEM HEALTH / FORENSIC AUDIT
 Windows 10 / Windows 11
 PowerShell 5.1 Compatible
 READ-ONLY DIAGNOSTIC SCRIPT

 IMPORTANT:
 This script DOES NOT intentionally modify:
 - Registry
 - Services
 - Startup
 - Scheduled Tasks
 - Boot Configuration
 - BIOS / UEFI
 - Defender
 - Firewall
 - Windows Update
 - Page File
 - Group Policy
 - Network configuration

 It only collects diagnostic information and runs read-only health scans.
===========================================================================

 Author: System Diagnostic Audit
 Mode: READ-ONLY
=========================================================================== #>


# ============================================================
# 0. SELF-ELEVATION + EXECUTION POLICY BYPASS
# ============================================================

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

$IsAdministrator = $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdministrator) {

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host " ADMINISTRATOR PRIVILEGES REQUIRED" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[INFO] Restarting script as Administrator..." -ForegroundColor Cyan

    $ScriptPath = $MyInvocation.MyCommand.Path

    if (-not $ScriptPath) {
        Write-Host "[ERROR] Script path could not be detected." -ForegroundColor Red
        pause
        exit 1
    }

    Start-Process `
        -FilePath "powershell.exe" `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" `
        -Verb RunAs

    exit
}


# ============================================================
# 1. EXECUTION POLICY BYPASS FOR CURRENT PROCESS
# ============================================================

try {
    Set-ExecutionPolicy `
        -Scope Process `
        -ExecutionPolicy Bypass `
        -Force `
        -ErrorAction SilentlyContinue
}
catch {}


# ============================================================
# 2. INITIALIZATION
# ============================================================

$ErrorActionPreference = "Continue"

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

$Desktop = [Environment]::GetFolderPath("Desktop")

$RootFolder = Join-Path `
    $Desktop `
```

