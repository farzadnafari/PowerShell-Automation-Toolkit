
> [!INFO] سازنده نسخه پرتابل نرم‌افزار (Clean Portable Software Builder)
> این اسکریپت با هدف آماده‌سازی نسخه‌های پرتابل و مستقل از نرم‌افزارهای نصب‌شده طراحی شده است.
> امکان پردازش یک پوشه نرم‌افزاری به‌صورت مستقل و تولید خروجی در مسیر دلخواه را فراهم می‌کند.
> قابلیت پردازش گروهی چندین نرم‌افزار در قالب حالت پردازش دسته‌ای در فهرست قابلیت‌ها معرفی شده است.
> مسیرهای نرم‌افزار را برای شناسایی فایل اجرایی اصلی برنامه بررسی می‌کند.
> قابلیت بررسی اولیه سازگاری نرم‌افزار و وابستگی‌های آن را در نظر گرفته است.
> فایل‌های نرم‌افزار را به‌صورت بازگشتی استخراج می‌کند و برخی فایل‌های کش، موقت و گزارش را کنار می‌گذارد.
> یک پوشه اختصاصی برای نگهداری داده‌های مستقل نسخه پرتابل ایجاد می‌کند.
> یک لانچر اختصاصی PowerShell برای اجرای نرم‌افزار با هدایت متغیرهای محیطی و مسیر پروفایل کاربر ایجاد می‌کند.
> گزارش فرایند ساخت را در قالب CSV تولید می‌کند و وضعیت پردازش و خطاهای هر نرم‌افزار را ثبت می‌کند.


> [!INFO] Clean Portable Software Builder
> This script is designed to prepare portable versions of existing installed software.
> It supports processing a single software directory and saving the resulting output to a specified location.
> Batch processing is listed as a feature for handling multiple software applications.
> It examines software directories to identify the application's executable file.
> It includes basic compatibility and dependency screening.
> It recursively extracts software files while excluding selected cache, temporary, and log files.
> It creates a dedicated directory for storing portable application data.
> It generates a custom PowerShell launcher that redirects environment variables and user profile paths.
> It generates a CSV build report and provides individual software processing statuses and basic failure reporting.


```
# ============================================================
#              CLEAN PORTABLE SOFTWARE BUILDER
# ============================================================
#
# DESCRIPTION:
# This script attempts to prepare clean, self-contained
# software folders from existing application installations.
#
# Its primary objective is to create a separate application
# directory with a fresh, initially empty user-data structure
# and a custom PowerShell launcher.
#
# FEATURES:
# - Single Software Processing Mode.
# - Batch Software Processing Mode.
# - Automatic Application Executable Detection.
# - Basic Compatibility and Dependency Screening.
# - Recursive Software File Extraction.
# - Exclusion of Selected Cache, Temporary, and Log Files.
# - Creation of a Dedicated Portable Data Directory.
# - Creation of a Custom Portable Application Launcher.
# - Temporary and User Profile Environment Redirection.
# - Automatic CSV Build Report Generation.
# - Individual Software Processing Status.
# - Basic Error Handling and Failure Reporting.
#
# SINGLE MODE:
# - Select one installed software directory.
# - Specify the output directory.
# - Analyze and process the selected application.
#
# BATCH MODE:
# - Select a parent directory containing multiple
#   software installation folders.
# - Specify an output parent directory.
# - Automatically process each immediate subdirectory.
#
# CLEAN PROFILE STRUCTURE:
# - Data\Roaming
# - Data\Local
# - Data\Temp
#
# IMPORTANT NOTES:
# - This script is an experimental portable preparation tool.
# - It does not guarantee true portable conversion.
# - A copied application is not automatically independent
#   of its original Windows installation.
# - Registry virtualization is not implemented.
# - Windows services, drivers, system components, and external
#   dependencies are not automatically extracted or packaged.
# - Environment variable redirection does not guarantee that
#   every application stores its data inside the portable
#   directory.
# - Excluded files and directories may contain information
#   required by certain applications.
# - Independent execution must be tested in a clean environment.
#
# STATUS DEFINITIONS:
# - REJECTED: Application failed basic compatibility checks.
# - FAILED: An error occurred during processing.
# - NEEDS_TEST: Initial portable package created, but
#   independent execution has not been verified.
#
# REQUIREMENTS:
# - Windows operating system.
# - Windows PowerShell 5.1 or later.
# - Robocopy utility.
#
# ============================================================
# VERSION: 1.0
# PLATFORM: Windows
# LANGUAGE: PowerShell
# ============================================================

$ErrorActionPreference = "Stop"

$script:Report = @()

# ------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------

$ExcludedDirectories = @(
    "Cache",
    "Caches",
    "Logs",
    "CrashDumps",
    "Crash Reports",
    "Temp",
    "Temporary",
    "History",
    "GPUCache",
    "Code Cache",
    "Service Worker",
    "User Data",
    "Profiles",
    "Crashpad"
)

$ExcludedFiles = @(
    "*.log",
    "*.dmp",
    "*.tmp",
    "*.bak",
    "*.old"
)

# ------------------------------------------------------------
# UI
# ------------------------------------------------------------

function Show-Header {

    Clear-Host

    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "             PORTABLE SOFTWARE BUILDER" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Read-FolderPath {

    param(
        [string]$Message,
        [bool]$MustExist = $true
    )

    while ($true) {

        $path = Read-Host $Message

        if ([string]::IsNullOrWhiteSpace($path)) {
            Write-Host "Invalid path." -ForegroundColor Red
            continue
        }

        $path = [Environment]::ExpandEnvironmentVariables(
            $path.Trim().Trim('"')
        )

        if ($MustExist -and
            !(Test-Path -LiteralPath $path -PathType Container)) {

            Write-Host "Folder not found." -ForegroundColor Red
            continue
        }

        try {
            return [System.IO.Path]::GetFullPath($path)
        }
        catch {
            Write-Host "Invalid folder path." -ForegroundColor Red
        }
    }
}

# ------------------------------------------------------------
# SOFTWARE ANALYSIS
# ------------------------------------------------------------

function Get-SoftwareExecutable {

    param(
        [string]$SoftwarePath
    )

    $files = @(
        Get-ChildItem -LiteralPath $SoftwarePath `
            -Filter "*.exe" -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -notmatch
            '^(unins|uninstall|setup|install|update|updater|crash|report|repair|helper|vc_redist)' -and
            $_.FullName -notmatch '\\(uninstall|update|updater|installer|setup|crash|temp)\\'
        }
    )

    if ($files.Count -eq 0) {
        return $null
    }

    # Prefer the largest application executable.
    return ($files | Sort-Object Length -Descending |
        Select-Object -First 1)
}

function Test-SoftwareCompatibility {

    param(
        [string]$SoftwarePath
    )

    $warnings = @()

    # Detect kernel drivers.
    $drivers = @(
        Get-ChildItem -LiteralPath $SoftwarePath `
            -Filter "*.sys" -File -Recurse `
            -ErrorAction SilentlyContinue
    )

    if ($drivers.Count -gt 0) {
        $warnings += "Kernel drivers detected."
    }

    # Detect INF installation components.
    $infFiles = @(
        Get-ChildItem -LiteralPath $SoftwarePath `
            -Filter "*.inf" -File -Recurse `
            -ErrorAction SilentlyContinue
    )

    if ($infFiles.Count -gt 0) {
        $warnings += "Windows driver/INF components detected."
    }

    # Detect service installation scripts.
    $serviceFiles = @(
        Get-ChildItem -LiteralPath $SoftwarePath -File -Recurse `
            -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match 'service.*\.(exe|bat|cmd|ps1)$'
        }
    )

    if ($serviceFiles.Count -gt 0) {
        $warnings += "Possible Windows service components detected."
    }

    return $warnings
}

# ------------------------------------------------------------
# CLEAN COPY
# ------------------------------------------------------------

function Copy-SoftwareFiles {

    param(
        [string]$Source,
        [string]$Destination
    )

    $excludeDirs = @(
        $ExcludedDirectories |
        ForEach-Object {
            Join-Path $Source $_
        }
    )

    $robocopyArgs = @(
        $Source
        $Destination
        "/E"
        "/COPY:DAT"
        "/DCOPY:DAT"
        "/R:2"
        "/W:2"
        "/XJ"
        "/XD"
    )

    $robocopyArgs += $excludeDirs
    $robocopyArgs += @("/XF") + $ExcludedFiles
    $robocopyArgs += @(
        "/NFL",
        "/NDL",
        "/NP",
        "/NJH",
        "/NJS"
    )

    & robocopy.exe @robocopyArgs | Out-Null

    if ($LASTEXITCODE -gt 7) {
        throw "File copy failed. Robocopy exit code: $LASTEXITCODE"
    }
}

# ------------------------------------------------------------
# PORTABLE LAUNCHER
# ------------------------------------------------------------

function New-PortableLauncher {

    param(
        [string]$Destination,
        [string]$ExecutableRelativePath
    )

    $launcherPath = Join-Path $Destination "Start-Portable.ps1"

    $launcher = @'
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

$Data = Join-Path $Root "Data"
$AppData = Join-Path $Data "Roaming"
$LocalData = Join-Path $Data "Local"
$TempData = Join-Path $Data "Temp"

New-Item -ItemType Directory -Force -Path `
    $AppData, $LocalData, $TempData | Out-Null

$env:APPDATA = $AppData
$env:LOCALAPPDATA = $LocalData
$env:TEMP = $TempData
$env:TMP = $TempData

$Executable = Join-Path $Root '__EXECUTABLE__'

if (!(Test-Path -LiteralPath $Executable)) {
    Write-Host "Application executable not found." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

try {
    Start-Process -FilePath $Executable -WorkingDirectory (Split-Path $Executable)
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    Read-Host "Press Enter to exit"
}
'@

    $launcher = $launcher.Replace(
        '__EXECUTABLE__',
        $ExecutableRelativePath
    )

    Set-Content -LiteralPath $launcherPath `
        -Value $launcher -Encoding UTF8
}

# ------------------------------------------------------------
# REPORT
# ------------------------------------------------------------

function Add-Report {

    param(
        [string]$Name,
        [string]$Source,
        [string]$Destination,
        [string]$Status,
        [string]$Details
    )

    $script:Report += [PSCustomObject]@{
        Software    = $Name
        Source      = $Source
        Destination = $Destination
        Status      = $Status
        Details     = $Details
        Date        = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

function Save-Report {

    param([string]$OutputRoot)

    $reportPath = Join-Path $OutputRoot "Portable-Build-Report.csv"

    $script:Report | Export-Csv `
        -LiteralPath $reportPath `
        -NoTypeInformation `
        -Encoding UTF8

    Write-Host ""
    Write-Host "Report saved: $reportPath" -ForegroundColor Cyan
}

# ------------------------------------------------------------
# BUILD ENGINE
# ------------------------------------------------------------

function Build-PortableSoftware {

    param(
        [string]$Source,
        [string]$OutputRoot
    )

    $name = Split-Path $Source -Leaf

    $destination = Join-Path $OutputRoot $name

    Write-Host ""
    Write-Host "Processing: $name" -ForegroundColor Yellow

    try {

        $exe = Get-SoftwareExecutable -SoftwarePath $Source

        if ($null -eq $exe) {

            Add-Report $name $Source $destination `
                "REJECTED" "No application executable found."

            Write-Host "[REJECTED] No executable found." -ForegroundColor Red
            return
        }

        $warnings = @(Test-SoftwareCompatibility -SoftwarePath $Source)

        if ($warnings.Count -gt 0) {

            $details = $warnings -join " "

            Add-Report $name $Source $destination `
                "REJECTED" $details

            Write-Host "[REJECTED] $details" -ForegroundColor Red
            return
        }

        if (Test-Path -LiteralPath $destination) {

            Write-Host "Output already exists: $destination" -ForegroundColor Red

            Add-Report $name $Source $destination `
                "REJECTED" "Output directory already exists."

            return
        }

        New-Item -ItemType Directory -Path $destination -Force |
            Out-Null

        Copy-SoftwareFiles `
            -Source $Source `
            -Destination $destination

        $relativeExe = $exe.FullName.Substring(
            $Source.TrimEnd('\').Length
        ).TrimStart('\')

        $copiedExe = Join-Path $destination $relativeExe

        if (!(Test-Path -LiteralPath $copiedExe)) {
            throw "Main executable was not copied."
        }

        New-PortableLauncher `
            -Destination $destination `
            -ExecutableRelativePath $relativeExe

        # Create an initially empty user profile.
        New-Item -ItemType Directory -Force -Path `
            (Join-Path $destination "Data\Roaming"),
            (Join-Path $destination "Data\Local"),
            (Join-Path $destination "Data\Temp") |
            Out-Null

        Add-Report $name $Source $destination `
            "NEEDS_TEST" "Clean-profile launcher created. Independent execution not verified."

        Write-Host "[READY FOR TESTING] $name" -ForegroundColor Green
    }
    catch {

        Add-Report $name $Source $destination `
            "FAILED" $_.Exception.Message

        Write-Host "[FAILED] $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# SINGLE MODE
# ------------------------------------------------------------

function Start-SingleMode {

    Write-Host ""
    Write-Host "========== SINGLE SOFTWARE ==========" -ForegroundColor Cyan

    $source = Read-FolderPath "Software folder path"
    $output = Read-FolderPath "Output folder path" $false

    if (!(Test-Path -LiteralPath $output)) {
        New-Item -ItemType Directory -Path $output -Force |
            Out-Null
    }

    Build-PortableSoftware $source $output

    Save-Report $output
}

# ------------------------------------------------------------
# BATCH MODE
# ------------------------------------------------------------

function Start-BatchMode {

    Write-Host ""
    Write-Host "========== BATCH SOFTWARE ==========" -ForegroundColor Cyan

    $sourceRoot = Read-FolderPath "Parent software folder path"
    $outputRoot = Read-FolderPath "Output parent folder path" $false

    if ([System.IO.Path]::GetFullPath($sourceRoot).TrimEnd('\') -eq
        [System.IO.Path]::GetFullPath($outputRoot).TrimEnd('\')) {

        Write-Host "Source and output cannot be identical." -ForegroundColor Red
        return
    }

    if (!(Test-Path -LiteralPath $outputRoot)) {
        New-Item -ItemType Directory -Path $outputRoot -Force |
            Out-Null
    }

    $folders = @(
        Get-ChildItem -LiteralPath $sourceRoot -Directory -Force
    )

    if ($folders.Count -eq 0) {
        Write-Host "No software folders found." -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "Found $($folders.Count) folders." -ForegroundColor Green

    foreach ($folder in $folders) {

        Build-PortableSoftware `
            -Source $folder.FullName `
            -OutputRoot $outputRoot
    }

    Save-Report $outputRoot
}

# ------------------------------------------------------------
# MAIN MENU
# ------------------------------------------------------------

while ($true) {

    Show-Header

    Write-Host "1. Build One Portable Software" -ForegroundColor White
    Write-Host "2. Build Multiple Portable Software" -ForegroundColor White
    Write-Host "0. Exit" -ForegroundColor Red

    Write-Host ""

    $choice = Read-Host "Select option"

    switch ($choice) {

        "1" {
            Start-SingleMode
        }

        "2" {
            Start-BatchMode
        }

        "0" {
            break
        }

        default {
            Write-Host "Invalid selection." -ForegroundColor Red
        }
    }

    if ($choice -ne "0") {
        Write-Host ""
        Read-Host "Press Enter to continue"
    }
}

Write-Host "Portable Builder closed." -ForegroundColor Green
```

