# =====================================================================
# نام اسکریپت: Find-FoldersByFileExtension.ps1
# =====================================================================
# توضیحات:
# این اسکریپت پوشه‌ای را که کاربر مشخص می‌کند به صورت بازگشتی جست‌وجو
# می‌کند و تمام پوشه‌هایی را که حداقل یک فایل با پسوند موردنظر دارند
# شناسایی می‌کند.
#
# قابلیت‌های اسکریپت:
# 1. بررسی دسترسی Administrator و درخواست ارتقای دسترسی در صورت نیاز.
# 2. دریافت مسیر پوشه اصلی از کاربر.
# 3. دریافت پسوند فایل مورد جست‌وجو، مانند mp3 یا txt یا pdf.
# 4. جست‌وجوی فایل‌ها در پوشه اصلی و تمام زیرپوشه‌ها.
# 5. ثبت آدرس کامل هر پوشه دارای فایل موردنظر در یک فایل TXT.
# 6. جلوگیری از ثبت چندباره آدرس یک پوشه در گزارش.
# 7. ذخیره گزارش در پوشه اصلی انتخاب‌شده توسط کاربر.
# 8. مدیریت خطاهای احتمالی هنگام دسترسی به پوشه‌ها.
# 9. انتظار برای فشردن سه مرتبه کلید Enter پیش از بسته شدن پنجره.
#
# نکته:
# این اسکریپت هیچ فایلی را حذف یا تغییر نمی‌دهد.
# فایل‌های مخفی و معمولی در جست‌وجو لحاظ می‌شوند.
# در صورت نداشتن مجوز دسترسی به بعضی پوشه‌ها، جست‌وجو ادامه می‌یابد.
# =====================================================================


# ---------------------------------------------------------------------
# مرحله 1: بررسی دسترسی Administrator
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
        Write-Host "The script cannot continue without the required access."
        Read-Host "Press Enter to close"
        exit
    }
}


# ---------------------------------------------------------------------
# مرحله 2: تنظیم ظاهر پنجره
# ---------------------------------------------------------------------

$Host.UI.RawUI.WindowTitle = "File Extension Folder Search"

Clear-Host

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "       FILE EXTENSION FOLDER SEARCH           " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""


# ---------------------------------------------------------------------
# مرحله 3: دریافت مسیر پوشه اصلی
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


# تبدیل مسیر به مسیر کامل
$RootPath = (Resolve-Path -LiteralPath $RootPath).Path


# ---------------------------------------------------------------------
# مرحله 4: دریافت پسوند فایل مورد جست‌وجو
# ---------------------------------------------------------------------

do {
    $Extension = Read-Host "Enter the file extension (example: mp3, txt, pdf)"

    $Extension = $Extension.Trim()

    # حذف نقطه ابتدایی پسوند، در صورت وارد کردن آن
    $Extension = $Extension.TrimStart('.')

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
# مرحله 5: آماده‌سازی فایل گزارش
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
# مرحله 6: جست‌وجوی پوشه‌ها و فایل‌های موردنظر
# ---------------------------------------------------------------------

$MatchedFolders = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)

$SearchErrors = @()

try {
    # بررسی فایل‌های موجود در پوشه اصلی و تمام زیرپوشه‌ها
    $FoundFiles = Get-ChildItem `
        -LiteralPath $RootPath `
        -File `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue `
        -ErrorVariable +SearchErrors

    foreach ($File in $FoundFiles) {

        # مقایسه پسوند فایل بدون حساسیت به بزرگی و کوچکی حروف
        if ($File.Extension -ieq ".$Extension") {

            # ذخیره آدرس پوشه‌ای که فایل در آن قرار دارد
            [void]$MatchedFolders.Add($File.DirectoryName)
        }
    }
}
catch {
    $SearchErrors += $_
}


# ---------------------------------------------------------------------
# مرحله 7: نوشتن گزارش متنی
# ---------------------------------------------------------------------

$ReportLines = @(
    "FILE EXTENSION SEARCH REPORT"
    "=============================================="
    "Search date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Root folder: $RootPath"
    "File extension: .$Extension"
    "Number of matching folders: $($MatchedFolders.Count)"
    "=============================================="
    ""
)

if ($MatchedFolders.Count -gt 0) {

    $SortedFolders = @($MatchedFolders) | Sort-Object

    $ReportLines += "MATCHING FOLDERS:"
    $ReportLines += ""

    foreach ($Folder in $SortedFolders) {
        $ReportLines += $Folder
    }
}
else {
    $ReportLines += "No folders containing the requested file extension were found."
}

$ReportLines += ""
$ReportLines += "=============================================="
$ReportLines += "Search completed."

if ($SearchErrors.Count -gt 0) {
    $ReportLines += ""
    $ReportLines += "WARNING: Some folders could not be accessed."
    $ReportLines += "Number of reported access/search errors: $($SearchErrors.Count)"
}

try {
    $ReportLines | Set-Content -LiteralPath $ReportPath -Encoding UTF8 -ErrorAction Stop

    Write-Host "Search completed successfully." -ForegroundColor Green
    Write-Host "Matching folders: $($MatchedFolders.Count)" -ForegroundColor Green
    Write-Host "Report saved to:" -ForegroundColor Cyan
    Write-Host $ReportPath -ForegroundColor White
}
catch {
    Write-Host "Failed to save the report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}


# ---------------------------------------------------------------------
# مرحله 8: نمایش هشدارهای احتمالی
# ---------------------------------------------------------------------

if ($SearchErrors.Count -gt 0) {
    Write-Host ""
    Write-Host "Warning: Some folders may not have been searched." -ForegroundColor Yellow
    Write-Host "Check permissions if you need a more complete search." -ForegroundColor Yellow
}


# ---------------------------------------------------------------------
# مرحله 9: انتظار برای سه مرتبه فشردن Enter
# ---------------------------------------------------------------------

Write-Host ""
Write-Host "The script has finished." -ForegroundColor Cyan
Write-Host "Press Enter three times to close this window." -ForegroundColor Yellow

for ($i = 1; $i -le 3; $i++) {
    [void](Read-Host "Press Enter ($i/3)")
}