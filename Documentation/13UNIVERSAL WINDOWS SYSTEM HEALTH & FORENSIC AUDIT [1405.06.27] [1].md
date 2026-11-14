
> [!INFO] ممیزی جامع و یکپارچه سلامت و بررسی جرم‌شناختی سیستم ویندوز
> سازگاری اسکریپت را برای سیستم‌های مختلف Windows 10 و Windows 11 با معماری تشخیصی مستقل از سخت‌افزار در نظر می‌گیرد.
> دسترسی Administrator را بررسی کرده و در صورت نیاز، اسکریپت را با مجوز مدیریتی مجدداً اجرا می‌کند.
> محدودیت Execution Policy را فقط برای پردازش فعلی PowerShell دور می‌زند و سیاست دائمی سیستم را تغییر نمی‌دهد.
> اطلاعات تشخیصی سیستم را با هدف شناسایی مشکلات سخت‌افزاری، نرم‌افزاری و پیکربندی ویندوز جمع‌آوری می‌کند.
> نتایج بررسی‌ها را در شش وضعیت OK، INFO، WARNING، CRITICAL، NOT AVAILABLE و ERROR دسته‌بندی می‌کند.
> گزارش‌های متنی TXT، خلاصه مدیریتی SUMMARY، اطلاعات ساختاریافته JSON و گزارش خطاها ERROR را تولید می‌کند.
> وضعیت Registry، Services، Startup، Scheduled Tasks و تنظیمات Boot را بدون تغییر در محدوده ممیزی قرار می‌دهد.
> تنظیمات BIOS، UEFI، Defender، Firewall، Windows Update، Page File، Group Policy و Network را برای بررسی در نظر می‌گیرد.
> قابلیت اجرای اسکن‌های تشخیصی SFC، DISM و CHKDSK را بدون درخواست عملیات تعمیر یا اصلاح سیستم پیش‌بینی می‌کند.
> اسکن‌های سلامت ممکن است موقتاً مصرف CPU و Disk را افزایش دهند؛ اسکریپت برای تشخیص طراحی شده و عملیات حذف فایل یا حذف نرم‌افزار انجام نمی‌دهد.


> [!INFO] Universal Windows System Health And Forensic Audit
> Supports Different Windows 10 And Windows 11 Computers And Laptops Through A Hardware-Independent Diagnostic Design.
> Checks Administrator Privileges And Automatically Relaunches The Script With Administrative Permissions When Required.
> Bypasses Execution Policy Restrictions Only For The Current PowerShell Process Without Permanently Changing System Policy.
> Collects System Diagnostic Information To Identify Potential Hardware, Software, And Windows Configuration Issues.
> Classifies Diagnostic Results Into Six Categories: OK, INFO, WARNING, CRITICAL, NOT AVAILABLE, And ERROR.
> Generates TXT Reports, Management Summaries, Structured JSON Data, And Error Reports.
> Includes Registry, Services, Startup, Scheduled Tasks, And Boot Configuration In Its Read-Only Audit Scope.
> Examines BIOS, UEFI, Defender, Firewall, Windows Update, Page File, Group Policy, And Network Configuration.
> Includes Diagnostic SFC, DISM, And CHKDSK Scans Without Requesting System Repair Or Modification Operations.
> Health Scans May Temporarily Increase CPU And Disk Usage; The Script Is Designed For Diagnosis And Does Not Delete Files Or Uninstall Software.


```
<#
===============================================================================
 UNIVERSAL WINDOWS SYSTEM HEALTH & FORENSIC AUDIT
 Windows 10 / Windows 11
 PowerShell 5.1 Compatible
 READ-ONLY DIAGNOSTIC AUDIT

 DESIGN GOALS
 ------------------------------------------------------------------------------
 - Works across different Windows 10/11 PCs and laptops
 - No permanent system configuration changes
 - Automatic Administrator elevation
 - Process-level ExecutionPolicy Bypass
 - Hardware-independent / capability-aware
 - Produces TXT + SUMMARY + JSON + ERROR reports
 - Distinguishes:
      OK
      INFO
      WARNING
      CRITICAL
      NOT AVAILABLE
      ERROR

 IMPORTANT
 ------------------------------------------------------------------------------
 This script is diagnostic. It does NOT intentionally:
 - modify Registry settings
 - change Services
 - change Startup
 - modify Scheduled Tasks
 - modify BCD
 - modify BIOS / UEFI
 - change Defender configuration
 - change Firewall configuration
 - change Windows Update configuration
 - change Page File configuration
 - change Group Policy
 - change Network configuration
 - repair Windows
 - delete files
 - uninstall software

 NOTE
 ------------------------------------------------------------------------------
 SFC / DISM / CHKDSK are diagnostic scans.
 They can temporarily consume CPU / disk resources while running.
 They do not request repair operations in this script.

 AUTHOR
 ------------------------------------------------------------------------------
 Universal System Diagnostic Audit
#>


# ============================================================================
# 0. SELF-ELEVATION
# ============================================================================

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()

$Principal = New-Object `
    Security.Principal.WindowsPrincipal($CurrentIdentity)

$IsAdministrator = $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdministrator) {

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host " ADMINISTRATOR PRIVILEGES REQUIRED" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""

    $ScriptPath = $MyInvocation.MyCommand.Path

    if (-not $ScriptPath) {

        Write-Host "[ERROR] Script path could not be detected." -ForegroundColor Red
        pause
        exit 1
    }

    Write-Host "[INFO] Restarting as Administrator..." -ForegroundColor Cyan
    Write-Host ""

    Start-Process `
        -FilePath "powershell.exe" `
        -ArgumentList @(
            "-NoProfile"
            "-ExecutionPolicy"
            "Bypass"
            "-File"
            "`"$ScriptPath`""
        ) `
        -Verb RunAs

    exit
}


# ============================================================================
# 1. PROCESS EXECUTION POLICY
# ============================================================================

try {

    Set-ExecutionPolicy `
        -Scope Process `
        -ExecutionPolicy Bypass `
        -Force `
        -ErrorAction SilentlyContinue

}
catch {}


# ============================================================================
# 2. INITIALIZATION
# ============================================================================

$ErrorActionPreference = "Continue"

$StartTime = Get-Date

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

$Desktop = [Environment]::GetFolderPath("Desktop")

$RootFolder = Join-Path `
    $Desktop `
    "WINDOWS_SYSTEM_AUDIT_$TimeStamp"

New-Item `
    -Path $RootFolder `
    -ItemType Directory `
    -Force `
    -ErrorAction SilentlyContinue |
    Out-Null


$ReportFile = Join-Path `
    $RootFolder `
    "FULL_SYSTEM_REPORT.txt"

$SummaryFile = Join-Path `
    $RootFolder `
    "SUMMARY.txt"

$ErrorFile = Join-Path `
    $RootFolder `
    "ERRORS.txt"

$JsonFile = Join-Path `
    $RootFolder `
    "AUDIT_DATA.json"


# ============================================================================
# 3. DATA STRUCTURES
# ============================================================================

$Report = New-Object System.Collections.Generic.List[string]

$Errors = New-Object System.Collections.Generic.List[string]

$Findings = New-Object System.Collections.Generic.List[object]

$Statistics = [ordered]@{
    OK             = 0
    INFO           = 0
    WARNING        = 0
    CRITICAL       = 0
    ERROR          = 0
    NOT_AVAILABLE  = 0
}


# ============================================================================
# 4. REPORT ENGINE
# ============================================================================

function Write-Report {

    param(
        [string]$Text
    )

    $Report.Add($Text)

    $Text |
        Out-File `
            -FilePath $ReportFile `
            -Append `
            -Encoding UTF8
}


function Section {

    param(
        [string]$Title
    )

    Write-Report ""
    Write-Report "======================================================================"
    Write-Report " $Title"
    Write-Report "======================================================================"
}


function Add-Finding {

    param(
        [ValidateSet(
            "OK",
            "INFO",
            "WARNING",
            "CRITICAL",
            "ERROR",
            "NOT AVAILABLE"
        )]
        [string]$Severity,

        [string]$Category,

        [string]$Title,

        [string]$Evidence,

        [string]$Recommendation = "",

        [string]$Confidence = "N/A"
    )

    switch ($Severity) {

        "OK" {
            $Statistics.OK++
        }

        "INFO" {
            $Statistics.INFO++
        }

        "WARNING" {
            $Statistics.WARNING++
        }

        "CRITICAL" {
            $Statistics.CRITICAL++
        }

        "ERROR" {
            $Statistics.ERROR++
        }

        "NOT AVAILABLE" {
            $Statistics.NOT_AVAILABLE++
        }
    }


    $Finding = [PSCustomObject][ordered]@{

        Time           = Get-Date
        Severity       = $Severity
        Category       = $Category
        Title          = $Title
        Evidence       = $Evidence
        Recommendation = $Recommendation
        Confidence     = $Confidence
    }

    $Findings.Add($Finding)


    Write-Report ""
    Write-Report "[$Severity] $Title"
    Write-Report "Category    : $Category"
    Write-Report "Evidence    : $Evidence"

    if ($Recommendation) {
        Write-Report "Recommendation : $Recommendation"
    }

    if ($Confidence -ne "N/A") {
        Write-Report "Confidence  : $Confidence"
    }
}


function Add-Info {

    param(
        [string]$Text
    )

    Add-Finding `
        -Severity "INFO" `
        -Category "GENERAL" `
        -Title $Text `
        -Evidence $Text
}


function Add-ErrorRecord {

    param(
        [string]$Text
    )

    $Errors.Add($Text)

    Add-Finding `
        -Severity "ERROR" `
        -Category "SCRIPT" `
        -Title "Script error" `
        -Evidence $Text
}


function Run-Test {

    param(
        [string]$Name,
        [scriptblock]$Script
    )

    $TestStart = Get-Date

    Write-Report ""
    Write-Report "------------------------------------------------------------------"
    Write-Report "TEST: $Name"
    Write-Report "------------------------------------------------------------------"

    try {

        & $Script

    }
    catch {

        $Message = $_.Exception.Message

        Add-ErrorRecord `
            "$Name failed: $Message"
    }

    $Duration = ((Get-Date) - $TestStart).TotalSeconds

    Write-Report ""
    Write-Report "[TEST COMPLETE] $Name"
    Write-Report "Duration: $([math]::Round($Duration,2)) seconds"
}


# ============================================================================
# 5. HELPER FUNCTIONS
# ============================================================================

function Format-GB {

    param(
        [double]$Bytes
    )

    if ($Bytes -le 0) {
        return "N/A"
    }

    return "$([math]::Round($Bytes / 1GB,2)) GB"
}


function Format-MB {

    param(
        [double]$Bytes
    )

    if ($Bytes -le 0) {
        return "N/A"
    }

    return "$([math]::Round($Bytes / 1MB,2)) MB"
}


function Test-CommandAvailable {

    param(
        [string]$Command
    )

    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}


function Add-CommandOutput {

    param(
        [string[]]$Output
    )

    foreach ($Line in $Output) {

        if ($null -ne $Line) {
            Write-Report "$Line"
        }
    }
}


# ============================================================================
# 6. HEADER
# ============================================================================

Section "AUDIT HEADER"

Write-Report "Universal Windows System Health & Forensic Audit"
Write-Report "Audit Started       : $StartTime"
Write-Report "Computer            : $env:COMPUTERNAME"
Write-Report "User                : $env:USERNAME"
Write-Report "PowerShell          : $($PSVersionTable.PSVersion)"
Write-Report "PowerShell Edition  : $($PSVersionTable.PSEdition)"
Write-Report "Administrator       : $IsAdministrator"
Write-Report "Operating System    : Windows"
Write-Report "Mode                : READ-ONLY DIAGNOSTIC"
Write-Report "Output Folder       : $RootFolder"


# ============================================================================
# 7. OPERATING SYSTEM
# ============================================================================

Run-Test "Operating System" {

    Section "OPERATING SYSTEM"

    $OS = Get-CimInstance Win32_OperatingSystem

    Write-Report "Caption             : $($OS.Caption)"
    Write-Report "Version             : $($OS.Version)"
    Write-Report "Build               : $($OS.BuildNumber)"
    Write-Report "Architecture        : $($OS.OSArchitecture)"
    Write-Report "Install Date        : $($OS.InstallDate)"
    Write-Report "Last Boot           : $($OS.LastBootUpTime)"
    Write-Report "System Drive        : $($OS.SystemDrive)"
    Write-Report "Windows Directory   : $($OS.WindowsDirectory)"

    $Uptime = (Get-Date) - $OS.LastBootUpTime

    Write-Report "Current Uptime      : $($Uptime.Days) days $($Uptime.Hours) hours $($Uptime.Minutes) minutes"

    Add-Finding `
        -Severity "OK" `
        -Category "OS" `
        -Title "Windows information collected" `
        -Evidence "$($OS.Caption), Build $($OS.BuildNumber)"
}


# ============================================================================
# 8. COMPUTER / MOTHERBOARD / BIOS
# ============================================================================

Run-Test "Computer and Firmware" {

    Section "COMPUTER / MOTHERBOARD / BIOS"

    $CS = Get-CimInstance Win32_ComputerSystem

    $Board = Get-CimInstance Win32_BaseBoard

    $BIOS = Get-CimInstance Win32_BIOS


    Write-Report "Computer Manufacturer : $($CS.Manufacturer)"
    Write-Report "Computer Model        : $($CS.Model)"
    Write-Report "System Type           : $($CS.SystemType)"
    Write-Report "Total RAM             : $(Format-GB $CS.TotalPhysicalMemory)"

    Write-Report ""
    Write-Report "Motherboard:"
    Write-Report "Manufacturer          : $($Board.Manufacturer)"
    Write-Report "Product               : $($Board.Product)"
    Write-Report "Version               : $($Board.Version)"

    Write-Report ""
    Write-Report "BIOS:"
    Write-Report "Manufacturer          : $($BIOS.Manufacturer)"
    Write-Report "Version               : $($BIOS.SMBIOSBIOSVersion)"
    Write-Report "Release Date          : $($BIOS.ReleaseDate)"
    Write-Report "SMBIOS                 : $($BIOS.SMBIOSMajorVersion).$($BIOS.SMBIOSMinorVersion)"

    Add-Finding `
        -Severity "OK" `
        -Category "FIRMWARE" `
        -Title "Computer and firmware inventory collected" `
        -Evidence "$($CS.Manufacturer) $($CS.Model)"
}


# ============================================================================
# 9. CPU
# ============================================================================

Run-Test "CPU" {

    Section "CPU"

    $CPUs = Get-CimInstance Win32_Processor

    foreach ($CPU in $CPUs) {

        Write-Report "----------------------------------------"
        Write-Report "Name                 : $($CPU.Name)"
        Write-Report "Manufacturer         : $($CPU.Manufacturer)"
        Write-Report "Cores                : $($CPU.NumberOfCores)"
        Write-Report "Logical Processors   : $($CPU.NumberOfLogicalProcessors)"
        Write-Report "Max Clock            : $($CPU.MaxClockSpeed) MHz"
        Write-Report "Current Clock        : $($CPU.CurrentClockSpeed) MHz"
        Write-Report "Load                 : $($CPU.LoadPercentage)%"
        Write-Report "L2 Cache             : $($CPU.L2CacheSize) KB"
        Write-Report "L3 Cache             : $($CPU.L3CacheSize) KB"

        if ($CPU.LoadPercentage -ge 95) {

            Add-Finding `
                -Severity "WARNING" `
                -Category "CPU" `
                -Title "CPU load is currently very high" `
                -Evidence "Current CPU load: $($CPU.LoadPercentage)%" `
                -Recommendation "Repeat the performance test while the system is idle to determine whether this is persistent." `
                -Confidence "High"

        }
        else {

            Add-Finding `
                -Severity "OK" `
                -Category "CPU" `
                -Title "CPU instantaneous load is not excessive" `
                -Evidence "Current CPU load: $($CPU.LoadPercentage)%"
        }
    }
}


# ============================================================================
# 10. CPU PERFORMANCE SAMPLING
# ============================================================================

Run-Test "CPU Performance Sampling" {

    Section "CPU PERFORMANCE SAMPLING"

    try {

        $Samples = Get-Counter `
            '\Processor(_Total)\% Processor Time' `
            -SampleInterval 1 `
            -MaxSamples 5

        $Values = @()

        foreach ($Sample in $Samples.CounterSamples) {

            $Value = [math]::Round(
                $Sample.CookedValue,
                2
            )

            $Values += $Value

            Write-Report "CPU Sample : $Value %"
        }

        if ($Values.Count -gt 0) {

            $Average = [math]::Round(
                (($Values | Measure-Object -Average).Average),
                2
            )

            $Maximum = [math]::Round(
                (($Values | Measure-Object -Maximum).Maximum),
                2
            )

            Write-Report ""
            Write-Report "Average CPU : $Average %"
            Write-Report "Maximum CPU : $Maximum %"

            if ($Average -ge 90) {

                Add-Finding `
                    -Severity "WARNING" `
                    -Category "PERFORMANCE" `
                    -Title "High sustained CPU utilization detected during audit" `
                    -Evidence "Average: $Average %, Maximum: $Maximum %" `
                    -Recommendation "Repeat the test after closing user applications."
            }
            else {

                Add-Finding `
                    -Severity "OK" `
                    -Category "PERFORMANCE" `
                    -Title "CPU utilization was not persistently excessive during sampling" `
                    -Evidence "Average: $Average %, Maximum: $Maximum %"
            }
        }

    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "PERFORMANCE" `
            -Title "CPU performance counter unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 11. MEMORY
# ============================================================================

Run-Test "Memory" {

    Section "RAM / MEMORY"

    $CS = Get-CimInstance Win32_ComputerSystem

    $OS = Get-CimInstance Win32_OperatingSystem

    $Modules = Get-CimInstance Win32_PhysicalMemory

    $Total = [double]$CS.TotalPhysicalMemory

    $Free = [double]$OS.FreePhysicalMemory * 1KB

    $Used = $Total - $Free

    $UsagePercent = ($Used / $Total) * 100

    Write-Report "Total RAM       : $(Format-GB $Total)"
    Write-Report "Used RAM        : $(Format-GB $Used)"
    Write-Report "Free RAM        : $(Format-GB $Free)"
    Write-Report "Usage           : $([math]::Round($UsagePercent,2))%"


    foreach ($RAM in $Modules) {

        Write-Report ""
        Write-Report "----------------------------------------"
        Write-Report "Manufacturer    : $($RAM.Manufacturer)"
        Write-Report "Part Number     : $($RAM.PartNumber)"
        Write-Report "Capacity        : $(Format-GB $RAM.Capacity)"
        Write-Report "Speed           : $($RAM.Speed) MHz"
        Write-Report "Configured      : $($RAM.ConfiguredClockSpeed) MHz"
        Write-Report "Device Locator  : $($RAM.DeviceLocator)"
        Write-Report "Bank Locator    : $($RAM.BankLabel)"
    }


    if ($UsagePercent -ge 95) {

        Add-Finding `
            -Severity "WARNING" `
            -Category "MEMORY" `
            -Title "Very high RAM utilization" `
            -Evidence "RAM utilization: $([math]::Round($UsagePercent,2))%" `
            -Recommendation "Inspect memory-consuming processes and virtual memory pressure."
    }
    else {

        Add-Finding `
            -Severity "OK" `
            -Category "MEMORY" `
            -Title "RAM utilization is not currently excessive" `
            -Evidence "RAM utilization: $([math]::Round($UsagePercent,2))%"
    }
}


# ============================================================================
# 12. MEMORY DIAGNOSTIC HISTORY
# ============================================================================

Run-Test "Memory Diagnostic History" {

    Section "WINDOWS MEMORY DIAGNOSTIC"

    try {

        $Events = Get-WinEvent `
            -FilterHashtable @{
                LogName = "System"
                ProviderName = "Microsoft-Windows-MemoryDiagnostics-Results"
            } `
            -MaxEvents 10 `
            -ErrorAction Stop

        if ($Events) {

            foreach ($Event in $Events) {

                Write-Report "----------------------------------------"
                Write-Report "Time      : $($Event.TimeCreated)"
                Write-Report "ID        : $($Event.Id)"
                Write-Report "Message   : $($Event.Message)"
            }

            Add-Finding `
                -Severity "INFO" `
                -Category "MEMORY" `
                -Title "Windows Memory Diagnostic history found" `
                -Evidence "$($Events.Count) result event(s) found"
        }
        else {

            Add-Finding `
                -Severity "NOT AVAILABLE" `
                -Category "MEMORY" `
                -Title "No Windows Memory Diagnostic result found" `
                -Evidence "No historical memory diagnostic event was available." `
                -Recommendation "This does not indicate faulty RAM. A memory test would be required for hardware verification."
        }
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "MEMORY" `
            -Title "Memory diagnostic history unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 13. PHYSICAL DISKS
# ============================================================================

Run-Test "Physical Storage" {

    Section "PHYSICAL STORAGE"

    $Disks = Get-CimInstance Win32_DiskDrive

    foreach ($Disk in $Disks) {

        Write-Report "----------------------------------------"
        Write-Report "Model           : $($Disk.Model)"
        Write-Report "Manufacturer    : $($Disk.Manufacturer)"
        Write-Report "Interface       : $($Disk.InterfaceType)"
        Write-Report "Media Type      : $($Disk.MediaType)"
        Write-Report "Size            : $(Format-GB $Disk.Size)"
        Write-Report "Partitions      : $($Disk.Partitions)"
        Write-Report "Status          : $($Disk.Status)"
        Write-Report "PNP ID           : $($Disk.PNPDeviceID)"

        if ($Disk.Status -and $Disk.Status -ne "OK") {

            Add-Finding `
                -Severity "CRITICAL" `
                -Category "STORAGE" `
                -Title "Physical disk reports a non-OK status" `
                -Evidence "$($Disk.Model) -> $($Disk.Status)" `
                -Recommendation "Inspect storage health counters and hardware connections." `
                -Confidence "High"
        }
    }
}


# ============================================================================
# 14. STORAGE HEALTH / RELIABILITY COUNTERS
# ============================================================================

Run-Test "Storage Reliability" {

    Section "STORAGE HEALTH / RELIABILITY"

    try {

        $PhysicalDisks = Get-PhysicalDisk `
            -ErrorAction Stop

        foreach ($Disk in $PhysicalDisks) {

            Write-Report "----------------------------------------"
            Write-Report "Friendly Name      : $($Disk.FriendlyName)"
            Write-Report "Media Type         : $($Disk.MediaType)"
            Write-Report "Bus Type           : $($Disk.BusType)"
            Write-Report "Health Status      : $($Disk.HealthStatus)"
            Write-Report "Operational Status : $($Disk.OperationalStatus)"
            Write-Report "Size               : $(Format-GB $Disk.Size)"
            Write-Report "Firmware           : $($Disk.FirmwareVersion)"


            if ($Disk.HealthStatus -ne "Healthy") {

                Add-Finding `
                    -Severity "CRITICAL" `
                    -Category "STORAGE" `
                    -Title "Storage device is not reporting Healthy" `
                    -Evidence "$($Disk.FriendlyName): $($Disk.HealthStatus)" `
                    -Recommendation "Investigate storage health before relying on the device."
            }
            else {

                Add-Finding `
                    -Severity "OK" `
                    -Category "STORAGE" `
                    -Title "Storage device reports Healthy" `
                    -Evidence "$($Disk.FriendlyName)"
            }


            try {

                $Counter = Get-StorageReliabilityCounter `
                    -PhysicalDisk $Disk `
                    -ErrorAction Stop

                Write-Report ""
                Write-Report "Storage Reliability Counters:"

                Write-Report "Temperature            : $($Counter.Temperature)"
                Write-Report "Temperature Max        : $($Counter.TemperatureMax)"
                Write-Report "Wear                   : $($Counter.Wear)"
                Write-Report "Read Errors Total      : $($Counter.ReadErrorsTotal)"
                Write-Report "Write Errors Total     : $($Counter.WriteErrorsTotal)"
                Write-Report "Read Latency Max       : $($Counter.ReadLatencyMax)"
                Write-Report "Write Latency Max      : $($Counter.WriteLatencyMax)"
                Write-Report "Flush Latency Max      : $($Counter.FlushLatencyMax)"
                Write-Report "Power On Hours         : $($Counter.PowerOnHours)"
                Write-Report "Unsafe Shutdown Count  : $($Counter.UnsafeShutdownCount)"
                Write-Report "Media Errors           : $($Counter.MediaErrors)"
                Write-Report "Read Bytes             : $($Counter.ReadBytes)"
                Write-Report "Written Bytes          : $($Counter.WriteBytes)"

            }
            catch {

                Write-Report "Storage reliability counters: Not available on this system."
            }
        }

    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "STORAGE" `
            -Title "Storage reliability API unavailable" `
            -Evidence $_.Exception.Message `
            -Recommendation "This may be normal depending on storage controller and Windows support."
    }
}


# ============================================================================
# 15. VOLUMES
# ============================================================================

Run-Test "Volumes" {

    Section "VOLUMES / FILE SYSTEM"

    try {

        $Volumes = Get-Volume -ErrorAction Stop

        foreach ($Volume in $Volumes) {

            Write-Report "----------------------------------------"
            Write-Report "Drive Letter     : $($Volume.DriveLetter)"
            Write-Report "File System      : $($Volume.FileSystem)"
            Write-Report "Label            : $($Volume.FileSystemLabel)"
            Write-Report "Health           : $($Volume.HealthStatus)"
            Write-Report "Size             : $(Format-GB $Volume.Size)"
            Write-Report "Free             : $(Format-GB $Volume.SizeRemaining)"

            if ($Volume.Size -gt 0) {

                $FreePercent =
                    ($Volume.SizeRemaining / $Volume.Size) * 100

                Write-Report "Free Percentage  : $([math]::Round($FreePercent,2))%"

                if ($FreePercent -lt 10) {

                    Add-Finding `
                        -Severity "WARNING" `
                        -Category "STORAGE" `
                        -Title "Volume has very low free space" `
                        -Evidence "$($Volume.DriveLetter): has $([math]::Round($FreePercent,2))% free space" `
                        -Recommendation "Free disk space. Very low free space can affect updates, temporary files and application performance."
                }
            }

            if (
                $Volume.HealthStatus -and
                $Volume.HealthStatus -ne "Healthy"
            ) {

                Add-Finding `
                    -Severity "WARNING" `
                    -Category "FILESYSTEM" `
                    -Title "Volume health status is not Healthy" `
                    -Evidence "$($Volume.DriveLetter): $($Volume.HealthStatus)"
            }
        }
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "FILESYSTEM" `
            -Title "Volume information unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 16. CHKDSK
# ============================================================================

Run-Test "CHKDSK Read-Only Scan" {

    Section "CHKDSK / FILE SYSTEM INTEGRITY"

    if (Test-CommandAvailable "chkdsk.exe") {

        $Drive = $env:SystemDrive

        Write-Report "Command: chkdsk $Drive /scan"
        Write-Report "Mode: Diagnostic / No /F repair requested"

        $Output = & chkdsk.exe "$Drive" /scan 2>&1

        Add-CommandOutput $Output

        Add-Finding `
            -Severity "INFO" `
            -Category "FILESYSTEM" `
            -Title "CHKDSK scan completed" `
            -Evidence "Read-only online scan executed on $Drive"
    }
    else {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "FILESYSTEM" `
            -Title "CHKDSK unavailable" `
            -Evidence "chkdsk.exe was not found."
    }
}


# ============================================================================
# 17. SFC
# ============================================================================

Run-Test "System File Checker" {

    Section "WINDOWS SYSTEM FILE CHECKER"

    if (Test-CommandAvailable "sfc.exe") {

        Write-Report "Command: sfc /verifyonly"

        $Output = & sfc.exe /verifyonly 2>&1

        Add-CommandOutput $Output

        Add-Finding `
            -Severity "INFO" `
            -Category "WINDOWS" `
            -Title "SFC verification completed" `
            -Evidence "Protected Windows system files were verified without repair."
    }
}


# ============================================================================
# 18. DISM
# ============================================================================

Run-Test "DISM Component Store" {

    Section "DISM COMPONENT STORE"

    if (Test-CommandAvailable "DISM.exe") {

        Write-Report "Command: DISM /Online /Cleanup-Image /ScanHealth"

        $Output = & DISM.exe `
            /Online `
            /Cleanup-Image `
            /ScanHealth `
            2>&1

        Add-CommandOutput $Output

        Add-Finding `
            -Severity "INFO" `
            -Category "WINDOWS" `
            -Title "DISM component store scan completed" `
            -Evidence "Online component store was scanned without repair."
    }
}


# ============================================================================
# 19. UEFI / SECURE BOOT
# ============================================================================

Run-Test "UEFI Secure Boot" {

    Section "UEFI / SECURE BOOT"

    try {

        $FirmwareType = (
            Get-ItemProperty `
                "HKLM:\SYSTEM\CurrentControlSet\Control" `
                -Name PEFirmwareType `
                -ErrorAction Stop
        ).PEFirmwareType


        switch ($FirmwareType) {

            1 {

                Write-Report "Firmware Type: Legacy BIOS"

                Add-Finding `
                    -Severity "INFO" `
                    -Category "BOOT" `
                    -Title "System is using Legacy BIOS mode" `
                    -Evidence "PEFirmwareType = 1"
            }

            2 {

                Write-Report "Firmware Type: UEFI"

                try {

                    $SecureBoot = Confirm-SecureBootUEFI

                    Write-Report "Secure Boot: $SecureBoot"

                    if ($SecureBoot) {

                        Add-Finding `
                            -Severity "OK" `
                            -Category "SECURITY" `
                            -Title "Secure Boot is enabled" `
                            -Evidence "UEFI Secure Boot returned True"
                    }
                    else {

                        Add-Finding `
                            -Severity "WARNING" `
                            -Category "SECURITY" `
                            -Title "Secure Boot is disabled" `
                            -Evidence "UEFI detected but Secure Boot returned False"
                    }

                }
                catch {

                    Add-Finding `
                        -Severity "NOT AVAILABLE" `
                        -Category "SECURITY" `
                        -Title "Secure Boot state unavailable" `
                        -Evidence $_.Exception.Message
                }
            }

            default {

                Add-Finding `
                    -Severity "NOT AVAILABLE" `
                    -Category "BOOT" `
                    -Title "Firmware type could not be determined" `
                    -Evidence "$FirmwareType"
            }
        }
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "BOOT" `
            -Title "Firmware information unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 20. TPM
# ============================================================================

Run-Test "TPM" {

    Section "TPM / TRUSTED PLATFORM MODULE"

    try {

        $TPM = Get-Tpm

        Write-Report "TPM Present       : $($TPM.TpmPresent)"
        Write-Report "TPM Ready         : $($TPM.TpmReady)"
        Write-Report "TPM Enabled       : $($TPM.TpmEnabled)"
        Write-Report "TPM Activated     : $($TPM.TpmActivated)"
        Write-Report "Manufacturer ID   : $($TPM.ManufacturerId)"
        Write-Report "Manufacturer Ver. : $($TPM.ManufacturerVersion)"

        if ($TPM.TpmPresent -and $TPM.TpmReady) {

            Add-Finding `
                -Severity "OK" `
                -Category "SECURITY" `
                -Title "TPM is present and ready" `
                -Evidence "TPM Present=True, Ready=True"
        }
        elseif (-not $TPM.TpmPresent) {

            Add-Finding `
                -Severity "INFO" `
                -Category "SECURITY" `
                -Title "TPM was not detected" `
                -Evidence "TPM Present=False"
        }
        else {

            Add-Finding `
                -Severity "WARNING" `
                -Category "SECURITY" `
                -Title "TPM is present but not ready" `
                -Evidence "TPM Present=True, Ready=False"
        }
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "SECURITY" `
            -Title "TPM information unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 21. GPU
# ============================================================================

Run-Test "GPU" {

    Section "GRAPHICS / GPU"

    $GPUs = Get-CimInstance Win32_VideoController

    foreach ($GPU in $GPUs) {

        Write-Report "----------------------------------------"
        Write-Report "Name              : $($GPU.Name)"
        Write-Report "Adapter RAM       : $(Format-GB $GPU.AdapterRAM)"
        Write-Report "Driver Version    : $($GPU.DriverVersion)"
        Write-Report "Driver Date       : $($GPU.DriverDate)"
        Write-Report "Video Processor   : $($GPU.VideoProcessor)"
        Write-Report "Resolution        : $($GPU.CurrentHorizontalResolution)x$($GPU.CurrentVerticalResolution)"
        Write-Report "Refresh Rate      : $($GPU.CurrentRefreshRate)"
        Write-Report "Status            : $($GPU.Status)"

        if ($GPU.Status -and $GPU.Status -ne "OK") {

            Add-Finding `
                -Severity "WARNING" `
                -Category "GPU" `
                -Title "GPU reports a non-OK status" `
                -Evidence "$($GPU.Name): $($GPU.Status)"
        }
        else {

            Add-Finding `
                -Severity "OK" `
                -Category "GPU" `
                -Title "GPU device reports OK" `
                -Evidence "$($GPU.Name)"
        }
    }
}


# ============================================================================
# 22. DRIVER HEALTH
# ============================================================================

Run-Test "Drivers" {

    Section "DRIVERS"

    try {

        $Devices = Get-CimInstance Win32_PnPEntity

        $ProblemDevices =
            $Devices |
            Where-Object {
                $_.ConfigManagerErrorCode -ne 0
            }

        Write-Report "Total PNP Devices : $($Devices.Count)"
        Write-Report "Problem Devices   : $($ProblemDevices.Count)"

        foreach ($Device in $ProblemDevices) {

            Write-Report "----------------------------------------"
            Write-Report "Name       : $($Device.Name)"
            Write-Report "Device ID  : $($Device.DeviceID)"
            Write-Report "Error Code : $($Device.ConfigManagerErrorCode)"
            Write-Report "Status     : $($Device.Status)"

            Add-Finding `
                -Severity "WARNING" `
                -Category "DRIVER" `
                -Title "Device Manager reports a problem device" `
                -Evidence "$($Device.Name), Error Code $($Device.ConfigManagerErrorCode)" `
                -Recommendation "Inspect the device in Device Manager and review its driver."
        }

        if ($ProblemDevices.Count -eq 0) {

            Add-Finding `
                -Severity "OK" `
                -Category "DRIVER" `
                -Title "No PNP configuration errors detected" `
                -Evidence "ConfigManagerErrorCode = 0 for enumerated devices."
        }


        $SignedDrivers =
            Get-CimInstance Win32_PnPSignedDriver |
            Where-Object {
                $_.DeviceName
            }


        Write-Report ""
        Write-Report "SIGNED DRIVER INVENTORY"

        foreach ($Driver in $SignedDrivers) {

            Write-Report "----------------------------------------"
            Write-Report "Device       : $($Driver.DeviceName)"
            Write-Report "Manufacturer : $($Driver.Manufacturer)"
            Write-Report "Version      : $($Driver.DriverVersion)"
            Write-Report "Date         : $($Driver.DriverDate)"
            Write-Report "Provider     : $($Driver.DriverProviderName)"
            Write-Report "Signer       : $($Driver.Signer)"
            Write-Report "INF          : $($Driver.InfName)"
        }
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "DRIVER" `
            -Title "Driver inventory could not be completed" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 23. PAGEFILE
# ============================================================================

Run-Test "Virtual Memory" {

    Section "PAGE FILE / VIRTUAL MEMORY"

    try {

        $PageFiles = Get-CimInstance Win32_PageFileUsage

        foreach ($Page in $PageFiles) {

            Write-Report "----------------------------------------"
            Write-Report "Name          : $($Page.Name)"
            Write-Report "Allocated MB  : $($Page.AllocatedBaseSize)"
            Write-Report "Current Usage : $($Page.CurrentUsage)"
            Write-Report "Peak Usage    : $($Page.PeakUsage)"
        }


        $CS = Get-CimInstance Win32_ComputerSystem

        Write-Report ""
        Write-Report "Automatic Pagefile: $($CS.AutomaticManagedPagefile)"

        Add-Finding `
            -Severity "INFO" `
            -Category "MEMORY" `
            -Title "Virtual memory configuration collected" `
            -Evidence "Pagefile information available."
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "MEMORY" `
            -Title "Pagefile information unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 24. SERVICES
# ============================================================================

Run-Test "Services" {

    Section "WINDOWS SERVICES"

    try {

        $Services = Get-CimInstance Win32_Service

        Write-Report "Total Services : $($Services.Count)"

        $Running =
            $Services |
            Where-Object {
                $_.State -eq "Running"
            }

        Write-Report "Running        : $($Running.Count)"

        Write-Report ""
        Write-Report "THIRD-PARTY / NON-MICROSOFT SERVICES"

        $ThirdParty =
            $Services |
            Where-Object {
                $_.PathName -and
                $_.PathName -notmatch '(?i)\\Windows\\|Microsoft'
            }

        foreach ($Service in $ThirdParty) {

            Write-Report "----------------------------------------"
            Write-Report "Name         : $($Service.Name)"
            Write-Report "Display      : $($Service.DisplayName)"
            Write-Report "State        : $($Service.State)"
            Write-Report "Start Mode   : $($Service.StartMode)"
            Write-Report "Path         : $($Service.PathName)"
        }

        Add-Finding `
            -Severity "INFO" `
            -Category "SERVICES" `
            -Title "Service inventory collected" `
            -Evidence "$($Services.Count) services enumerated."
    }
    catch {

        Add-Finding `
            -Severity "ERROR" `
            -Category "SERVICES" `
            -Title "Service inventory failed" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 25. STARTUP
# ============================================================================

Run-Test "Startup Inventory" {

    Section "STARTUP ITEMS"

    try {

        $Startup = Get-CimInstance Win32_StartupCommand

        Write-Report "Startup Entries: $($Startup.Count)"

        foreach ($Item in $Startup) {

            Write-Report "----------------------------------------"
            Write-Report "Name     : $($Item.Name)"
            Write-Report "Command  : $($Item.Command)"
            Write-Report "Location : $($Item.Location)"
            Write-Report "User     : $($Item.User)"
        }

        Add-Finding `
            -Severity "INFO" `
            -Category "STARTUP" `
            -Title "Startup inventory collected" `
            -Evidence "$($Startup.Count) startup entries detected."
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "STARTUP" `
            -Title "Startup inventory unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 26. SCHEDULED TASKS
# ============================================================================

Run-Test "Scheduled Tasks" {

    Section "SCHEDULED TASKS"

    try {

        $Tasks = Get-ScheduledTask

        $RunningTasks =
            $Tasks |
            Where-Object {
                $_.State -eq "Running"
            }

        Write-Report "Total Tasks     : $($Tasks.Count)"
        Write-Report "Running Tasks   : $($RunningTasks.Count)"

        Write-Report ""
        Write-Report "RUNNING TASKS"

        foreach ($Task in $RunningTasks) {

            Write-Report "----------------------------------------"
            Write-Report "Task : $($Task.TaskName)"
            Write-Report "Path : $($Task.TaskPath)"
            Write-Report "State: $($Task.State)"
        }

        Add-Finding `
            -Severity "INFO" `
            -Category "TASKS" `
            -Title "Scheduled task inventory collected" `
            -Evidence "$($Tasks.Count) scheduled tasks enumerated."
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "TASKS" `
            -Title "Scheduled task inventory unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 27. PROCESSES
# ============================================================================

Run-Test "Processes" {

    Section "CURRENT PROCESSES"

    try {

        $Processes = Get-Process

        Write-Report "Process Count: $($Processes.Count)"

        Write-Report ""
        Write-Report "TOP MEMORY CONSUMERS"

        $TopMemory =
            $Processes |
            Sort-Object WorkingSet64 -Descending |
            Select-Object -First 20

        foreach ($Process in $TopMemory) {

            try {

                Write-Report "$($Process.ProcessName) | PID=$($Process.Id) | RAM=$([math]::Round($Process.WorkingSet64 / 1MB,2)) MB"

            }
            catch {}
        }


        Write-Report ""
        Write-Report "TOP CPU-TIME CONSUMERS"

        $TopCPU =
            $Processes |
            Sort-Object CPU -Descending |
            Select-Object -First 20

        foreach ($Process in $TopCPU) {

            try {

                Write-Report "$($Process.ProcessName) | PID=$($Process.Id) | CPU Time=$([math]::Round($Process.CPU,2)) sec"

            }
            catch {}
        }

        Add-Finding `
            -Severity "INFO" `
            -Category "PERFORMANCE" `
            -Title "Process resource snapshot collected" `
            -Evidence "$($Processes.Count) processes observed."
    }
    catch {

        Add-Finding `
            -Severity "ERROR" `
            -Category "PERFORMANCE" `
            -Title "Process analysis failed" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 28. NETWORK
# ============================================================================

Run-Test "Network" {

    Section "NETWORK CONFIGURATION"

    try {

        $Adapters = Get-NetAdapter

        foreach ($Adapter in $Adapters) {

            Write-Report "----------------------------------------"
            Write-Report "Name          : $($Adapter.Name)"
            Write-Report "Description   : $($Adapter.InterfaceDescription)"
            Write-Report "Status        : $($Adapter.Status)"
            Write-Report "Link Speed    : $($Adapter.LinkSpeed)"
            Write-Report "MAC           : $($Adapter.MacAddress)"
        }


        Write-Report ""
        Write-Report "IP CONFIGURATION"

        $Configurations = Get-NetIPConfiguration

        foreach ($Config in $Configurations) {

            Write-Report "----------------------------------------"
            Write-Report "Interface : $($Config.InterfaceAlias)"
            Write-Report "IPv4      : $($Config.IPv4Address.IPAddress -join ', ')"
            Write-Report "Gateway   : $($Config.IPv4DefaultGateway.NextHop)"
            Write-Report "DNS       : $($Config.DNSServer.ServerAddresses -join ', ')"
        }

        Add-Finding `
            -Severity "INFO" `
            -Category "NETWORK" `
            -Title "Network configuration collected" `
            -Evidence "$($Adapters.Count) network adapters enumerated."
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "NETWORK" `
            -Title "Network configuration unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 29. NETWORK CONNECTIVITY
# ============================================================================

Run-Test "Network Connectivity" {

    Section "NETWORK CONNECTIVITY"

    $Targets = @(
        "1.1.1.1",
        "8.8.8.8"
    )

    foreach ($Target in $Targets) {

        try {

            $Result = Test-Connection `
                -ComputerName $Target `
                -Count 2 `
                -Quiet `
                -ErrorAction SilentlyContinue

            Write-Report "$Target -> Reachable: $Result"

        }
        catch {

            Write-Report "$Target -> Test unavailable"
        }
    }

    Add-Finding `
        -Severity "INFO" `
        -Category "NETWORK" `
        -Title "Basic network connectivity test completed" `
        -Evidence "ICMP reachability was tested against public endpoints."
}


# ============================================================================
# 30. FIREWALL
# ============================================================================

Run-Test "Firewall" {

    Section "WINDOWS FIREWALL"

    try {

        $Profiles = Get-NetFirewallProfile

        foreach ($Profile in $Profiles) {

            Write-Report "----------------------------------------"
            Write-Report "Profile        : $($Profile.Name)"
            Write-Report "Enabled        : $($Profile.Enabled)"
            Write-Report "Inbound        : $($Profile.DefaultInboundAction)"
            Write-Report "Outbound       : $($Profile.DefaultOutboundAction)"
        }

        $Disabled =
            $Profiles |
            Where-Object {
                -not $_.Enabled
            }

        if ($Disabled.Count -gt 0) {

            Add-Finding `
                -Severity "WARNING" `
                -Category "SECURITY" `
                -Title "One or more Windows Firewall profiles are disabled" `
                -Evidence "$($Disabled.Name -join ', ')"
        }
        else {

            Add-Finding `
                -Severity "OK" `
                -Category "SECURITY" `
                -Title "Windows Firewall profiles are enabled" `
                -Evidence "All enumerated profiles are enabled."
        }
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "SECURITY" `
            -Title "Firewall information unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 31. DEFENDER
# ============================================================================

Run-Test "Microsoft Defender" {

    Section "MICROSOFT DEFENDER"

    try {

        $Defender = Get-MpComputerStatus

        Write-Report "Antivirus Enabled       : $($Defender.AntivirusEnabled)"
        Write-Report "Antivirus Active        : $($Defender.AntivirusActive)"
        Write-Report "Real-Time Protection    : $($Defender.RealTimeProtectionEnabled)"
        Write-Report "Behavior Monitor        : $($Defender.BehaviorMonitorEnabled)"
        Write-Report "IOAV                    : $($Defender.IOAVProtectionEnabled)"
        Write-Report "AMSI                    : $($Defender.AMServiceEnabled)"
        Write-Report "NIS                     : $($Defender.NISEnabled)"
        Write-Report "Engine                  : $($Defender.AMEngineVersion)"
        Write-Report "Product                 : $($Defender.AMProductVersion)"
        Write-Report "Signature               : $($Defender.AntivirusSignatureVersion)"
        Write-Report "Signature Age           : $($Defender.AntivirusSignatureAge) days"
        Write-Report "Last Quick Scan         : $($Defender.QuickScanStartTime)"
        Write-Report "Last Full Scan          : $($Defender.FullScanStartTime)"


        if ($Defender.RealTimeProtectionEnabled) {

            Add-Finding `
                -Severity "OK" `
                -Category "SECURITY" `
                -Title "Microsoft Defender real-time protection is enabled" `
                -Evidence "RealTimeProtectionEnabled=True"
        }
        else {

            Add-Finding `
                -Severity "WARNING" `
                -Category "SECURITY" `
                -Title "Microsoft Defender real-time protection is disabled" `
                -Evidence "RealTimeProtectionEnabled=False"
        }
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "SECURITY" `
            -Title "Microsoft Defender status unavailable" `
            -Evidence $_.Exception.Message `
            -Recommendation "If another antivirus is installed, verify the active security provider through Windows Security."
    }
}


# ============================================================================
# 32. SECURITY CENTER
# ============================================================================

Run-Test "Security Center" {

    Section "SECURITY CENTER"

    try {

        $Products = Get-CimInstance `
            -Namespace root/SecurityCenter2 `
            -ClassName AntiVirusProduct `
            -ErrorAction Stop

        foreach ($Product in $Products) {

            Write-Report "----------------------------------------"
            Write-Report "Product       : $($Product.displayName)"
            Write-Report "Executable    : $($Product.pathToSignedProductExe)"
            Write-Report "Product State : $($Product.productState)"
        }

        Add-Finding `
            -Severity "INFO" `
            -Category "SECURITY" `
            -Title "Registered antivirus products collected" `
            -Evidence "$($Products.Count) product(s) registered with Windows Security Center."
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "SECURITY" `
            -Title "Security Center information unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 33. WINDOWS UPDATE
# ============================================================================

Run-Test "Windows Update State" {

    Section "WINDOWS UPDATE"

    try {

        $Services = Get-Service `
            -Name wuauserv,bits,UsoSvc `
            -ErrorAction SilentlyContinue

        foreach ($Service in $Services) {

            Write-Report "----------------------------------------"
            Write-Report "Service    : $($Service.Name)"
            Write-Report "Status     : $($Service.Status)"
            Write-Report "Start Type : $($Service.StartType)"
        }


        Write-Report ""
        Write-Report "RECENT INSTALLED HOTFIXES"

        $Hotfixes =
            Get-HotFix |
            Sort-Object InstalledOn -Descending |
            Select-Object -First 30

        foreach ($Hotfix in $Hotfixes) {

            Write-Report "$($Hotfix.HotFixID) | $($Hotfix.InstalledOn) | $($Hotfix.Description)"
        }


        $Latest =
            $Hotfixes |
            Where-Object {
                $_.InstalledOn
            } |
            Select-Object -First 1

        if ($Latest) {

            Add-Finding `
                -Severity "INFO" `
                -Category "UPDATE" `
                -Title "Recent Windows hotfix inventory collected" `
                -Evidence "Latest locally reported HotFix: $($Latest.HotFixID), $($Latest.InstalledOn)"
        }

    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "UPDATE" `
            -Title "Windows update inventory unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 34. PENDING REBOOT
# ============================================================================

Run-Test "Pending Reboot Detection" {

    Section "PENDING REBOOT"

    $Pending = $false

    try {

        $Paths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        )

        foreach ($Path in $Paths) {

            if (Test-Path $Path) {

                $Pending = $true

                Write-Report "Pending reboot indicator: $Path"
            }
        }


        try {

            $SessionManager =
                Get-ItemProperty `
                    "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" `
                    -ErrorAction Stop

            if ($SessionManager.PendingFileRenameOperations) {

                $Pending = $true

                Write-Report "PendingFileRenameOperations detected."
            }

        }
        catch {}


        if ($Pending) {

            Add-Finding `
                -Severity "WARNING" `
                -Category "UPDATE" `
                -Title "Windows reports a pending reboot" `
                -Evidence "One or more reboot-required indicators were detected." `
                -Recommendation "Restart Windows when convenient and rerun the audit."
        }
        else {

            Add-Finding `
                -Severity "OK" `
                -Category "UPDATE" `
                -Title "No common pending-reboot indicators detected" `
                -Evidence "Known reboot registry indicators were not found."
        }
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "UPDATE" `
            -Title "Pending reboot state could not be fully determined" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 35. EVENT LOG HEALTH
# ============================================================================

Run-Test "Event Logs" {

    Section "EVENT LOG HEALTH"

    $Logs = @(
        "System",
        "Application"
    )

    foreach ($Log in $Logs) {

        try {

            $Events =
                Get-WinEvent `
                    -FilterHashtable @{
                        LogName   = $Log
                        Level     = 1,2,3
                        StartTime = (Get-Date).AddDays(-7)
                    } `
                    -MaxEvents 200 `
                    -ErrorAction Stop

            Write-Report ""
            Write-Report "LOG: $Log"
            Write-Report "Events in last 7 days: $($Events.Count)"

            foreach ($Event in ($Events | Select-Object -First 50)) {

                Write-Report "----------------------------------------"
                Write-Report "Time     : $($Event.TimeCreated)"
                Write-Report "Provider : $($Event.ProviderName)"
                Write-Report "ID       : $($Event.Id)"
                Write-Report "Level    : $($Event.LevelDisplayName)"
                Write-Report "Message  : $($Event.Message)"
            }

            Add-Finding `
                -Severity "INFO" `
                -Category "EVENTS" `
                -Title "$Log event log reviewed" `
                -Evidence "$($Events.Count) warning/error/critical events sampled from the last 7 days."
        }
        catch {

            Add-Finding `
                -Severity "NOT AVAILABLE" `
                -Category "EVENTS" `
                -Title "$Log event log unavailable" `
                -Evidence $_.Exception.Message
        }
    }
}


# ============================================================================
# 36. HARDWARE / WHEA / STORAGE EVENTS
# ============================================================================

Run-Test "Hardware Error Events" {

    Section "HARDWARE / STORAGE / KERNEL EVENTS"

    try {

        $Events =
            Get-WinEvent `
                -FilterHashtable @{
                    LogName   = "System"
                    StartTime = (Get-Date).AddDays(-30)
                } `
                -MaxEvents 3000 `
                -ErrorAction Stop |
            Where-Object {

                $_.ProviderName -match `
                "WHEA|Disk|Ntfs|storahci|stornvme|volmgr|Kernel-Power|Kernel-Boot"
            }


        Write-Report "Relevant events found: $($Events.Count)"

        foreach ($Event in ($Events | Select-Object -First 100)) {

            Write-Report "----------------------------------------"
            Write-Report "Time     : $($Event.TimeCreated)"
            Write-Report "Provider : $($Event.ProviderName)"
            Write-Report "ID       : $($Event.Id)"
            Write-Report "Level    : $($Event.LevelDisplayName)"
            Write-Report "Message  : $($Event.Message)"
        }


        if ($Events.Count -eq 0) {

            Add-Finding `
                -Severity "OK" `
                -Category "HARDWARE" `
                -Title "No selected hardware/storage event patterns found" `
                -Evidence "No matching events were found in the last 30 days."
        }
        else {

            Add-Finding `
                -Severity "WARNING" `
                -Category "HARDWARE" `
                -Title "Hardware/storage-related event patterns were found" `
                -Evidence "$($Events.Count) matching event(s) were found in the last 30 days." `
                -Recommendation "Review the detailed event section. Event presence alone does not prove hardware failure." `
                -Confidence "Moderate"
        }
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "HARDWARE" `
            -Title "Hardware event analysis unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 37. CRASH / BSOD
# ============================================================================

Run-Test "Crash and BugCheck History" {

    Section "CRASH / BSOD / BUGCHECK HISTORY"

    try {

        $Events =
            Get-WinEvent `
                -FilterHashtable @{
                    LogName   = "System"
                    Id        = 41,1001,6008
                    StartTime = (Get-Date).AddDays(-30)
                } `
                -MaxEvents 100 `
                -ErrorAction Stop


        Write-Report "Crash-related events: $($Events.Count)"

        foreach ($Event in $Events) {

            Write-Report "----------------------------------------"
            Write-Report "Time     : $($Event.TimeCreated)"
            Write-Report "Provider : $($Event.ProviderName)"
            Write-Report "ID       : $($Event.Id)"
            Write-Report "Message  : $($Event.Message)"
        }


        if ($Events.Count -eq 0) {

            Add-Finding `
                -Severity "OK" `
                -Category "STABILITY" `
                -Title "No selected recent crash indicators detected" `
                -Evidence "No Event ID 41, 1001 or 6008 records were found in the last 30 days."
        }
        else {

            Add-Finding `
                -Severity "WARNING" `
                -Category "STABILITY" `
                -Title "Recent crash/unexpected shutdown indicators detected" `
                -Evidence "$($Events.Count) relevant event(s) found." `
                -Recommendation "Review timestamps and correlate with WHEA, storage, driver and application events." `
                -Confidence "Moderate"
        }
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "STABILITY" `
            -Title "Crash history unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 38. RELIABILITY MONITOR DATA
# ============================================================================

Run-Test "Reliability History" {

    Section "RELIABILITY MONITOR HISTORY"

    try {

        $Records =
            Get-CimInstance `
                -ClassName Win32_ReliabilityRecords `
                -ErrorAction Stop |
            Sort-Object TimeGenerated -Descending |
            Select-Object -First 100


        Write-Report "Reliability records sampled: $($Records.Count)"

        foreach ($Record in $Records) {

            Write-Report "----------------------------------------"
            Write-Report "Time       : $($Record.TimeGenerated)"
            Write-Report "Source     : $($Record.SourceName)"
            Write-Report "Event ID   : $($Record.EventIdentifier)"
            Write-Report "Product    : $($Record.ProductName)"
            Write-Report "Message    : $($Record.Message)"
        }


        Add-Finding `
            -Severity "INFO" `
            -Category "STABILITY" `
            -Title "Windows Reliability history collected" `
            -Evidence "$($Records.Count) records sampled."
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "STABILITY" `
            -Title "Reliability Monitor WMI data unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 39. BOOT / BCD
# ============================================================================

Run-Test "Boot Configuration" {

    Section "BOOT / BCD"

    if (Test-CommandAvailable "bcdedit.exe") {

        $Output = & bcdedit.exe /enum all 2>&1

        Add-CommandOutput $Output

        Add-Finding `
            -Severity "INFO" `
            -Category "BOOT" `
            -Title "BCD configuration collected" `
            -Evidence "Boot Configuration Data was enumerated."
    }
}


# ============================================================================
# 40. POWER PLAN
# ============================================================================

Run-Test "Power Configuration" {

    Section "POWER CONFIGURATION"

    try {

        $PowerPlan = powercfg /getactivescheme 2>&1

        Add-CommandOutput $PowerPlan

        Add-Finding `
            -Severity "INFO" `
            -Category "POWER" `
            -Title "Active Windows power plan collected" `
            -Evidence "Current power scheme was queried."
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "POWER" `
            -Title "Power configuration unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 41. BATTERY
# ============================================================================

Run-Test "Battery Health" {

    Section "BATTERY HEALTH"

    try {

        $Battery = Get-CimInstance Win32_Battery

        if ($Battery) {

            foreach ($B in $Battery) {

                Write-Report "----------------------------------------"
                Write-Report "Name                : $($B.Name)"
                Write-Report "Status              : $($B.Status)"
                Write-Report "Battery Status      : $($B.BatteryStatus)"
                Write-Report "Estimated Charge    : $($B.EstimatedChargeRemaining)%"
                Write-Report "Estimated Runtime   : $($B.EstimatedRunTime) minutes"
            }

        }
        else {

            Add-Finding `
                -Severity "INFO" `
                -Category "BATTERY" `
                -Title "No battery device reported" `
                -Evidence "This may be a desktop system."
        }


        # Attempt to obtain deeper battery capacity information.
        try {

            $Static =
                Get-CimInstance `
                    -Namespace root/wmi `
                    -ClassName BatteryStaticData `
                    -ErrorAction Stop

            $Full =
                Get-CimInstance `
                    -Namespace root/wmi `
                    -ClassName BatteryFullChargedCapacity `
                    -ErrorAction Stop


            foreach ($S in $Static) {

                Write-Report ""
                Write-Report "Battery Static Data:"
                Write-Report "Designed Capacity: $($S.DesignedCapacity) mWh"
                Write-Report "Chemistry        : $($S.Chemistry)"
            }


            foreach ($F in $Full) {

                Write-Report "Full Charged Capacity: $($F.FullChargedCapacity) mWh"
            }


            if ($Static -and $Full) {

                $Design =
                    ($Static | Measure-Object DesignedCapacity -Sum).Sum

                $FullCapacity =
                    ($Full | Measure-Object FullChargedCapacity -Sum).Sum


                if ($Design -gt 0 -and $FullCapacity -gt 0) {

                    $BatteryHealth =
                        ($FullCapacity / $Design) * 100

                    Write-Report ""
                    Write-Report "Estimated Battery Health: $([math]::Round($BatteryHealth,2))%"


                    if ($BatteryHealth -lt 60) {

                        Add-Finding `
                            -Severity "WARNING" `
                            -Category "BATTERY" `
                            -Title "Battery capacity appears substantially degraded" `
                            -Evidence "Estimated full-charge capacity is $([math]::Round($BatteryHealth,2))% of design capacity." `
                            -Recommendation "Consider battery replacement if runtime is inadequate." `
                            -Confidence "Moderate"
                    }
                    else {

                        Add-Finding `
                            -Severity "INFO" `
                            -Category "BATTERY" `
                            -Title "Battery capacity is measurable" `
                            -Evidence "Estimated capacity retention: $([math]::Round($BatteryHealth,2))%"
                    }
                }
            }
        }
        catch {

            Add-Finding `
                -Severity "NOT AVAILABLE" `
                -Category "BATTERY" `
                -Title "Detailed battery capacity counters unavailable" `
                -Evidence $_.Exception.Message `
                -Recommendation "Battery telemetry availability depends on the laptop manufacturer and ACPI implementation."
        }

    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "BATTERY" `
            -Title "Battery information unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 42. THERMAL
# ============================================================================

Run-Test "Thermal Information" {

    Section "THERMAL / TEMPERATURE"

    $ThermalFound = $false


    # ACPI thermal zones.
    try {

        $ThermalZones =
            Get-CimInstance `
                -Namespace root/wmi `
                -ClassName MSAcpi_ThermalZoneTemperature `
                -ErrorAction Stop

        foreach ($Zone in $ThermalZones) {

            $ThermalFound = $true

            $Celsius =
                ($Zone.CurrentTemperature / 10) - 273.15

            Write-Report "----------------------------------------"
            Write-Report "Instance : $($Zone.InstanceName)"
            Write-Report "Temp     : $([math]::Round($Celsius,1)) C"
        }

    }
    catch {}


    # Storage temperature.
    try {

        $PhysicalDisks =
            Get-PhysicalDisk `
                -ErrorAction Stop

        foreach ($Disk in $PhysicalDisks) {

            try {

                $Counter =
                    Get-StorageReliabilityCounter `
                        -PhysicalDisk $Disk `
                        -ErrorAction Stop

                if ($Counter.Temperature) {

                    $ThermalFound = $true

                    Write-Report ""
                    Write-Report "Storage Temperature:"
                    Write-Report "$($Disk.FriendlyName): $($Counter.Temperature) C"
                }
            }
            catch {}
        }
    }
    catch {}


    if ($ThermalFound) {

        Add-Finding `
            -Severity "INFO" `
            -Category "THERMAL" `
            -Title "Some thermal telemetry was available" `
            -Evidence "Temperature data was collected from one or more Windows hardware interfaces." `
            -Recommendation "ACPI thermal zones are not universally equivalent to CPU/GPU package temperature."
    }
    else {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "THERMAL" `
            -Title "Reliable system-wide thermal telemetry was unavailable" `
            -Evidence "Windows did not expose usable thermal sensors through the queried interfaces." `
            -Recommendation "For deeper thermal diagnostics, manufacturer-specific telemetry or dedicated hardware monitoring software may be required."
    }
}


# ============================================================================
# 43. SYSTEM RESTORE
# ============================================================================

Run-Test "System Restore" {

    Section "SYSTEM RESTORE"

    try {

        $RestorePoints =
            Get-CimInstance `
                -Namespace root/default `
                -ClassName SystemRestore `
                -ErrorAction Stop

        Write-Report "Restore Points: $($RestorePoints.Count)"

        foreach ($RP in (
            $RestorePoints |
            Sort-Object CreationTime -Descending |
            Select-Object -First 10
        )) {

            Write-Report "----------------------------------------"
            Write-Report "Sequence    : $($RP.SequenceNumber)"
            Write-Report "Description : $($RP.Description)"
            Write-Report "Created     : $($RP.CreationTime)"
        }


        if ($RestorePoints.Count -eq 0) {

            Add-Finding `
                -Severity "INFO" `
                -Category "RECOVERY" `
                -Title "No System Restore Points were found" `
                -Evidence "Restore point count = 0"
        }
        else {

            Add-Finding `
                -Severity "OK" `
                -Category "RECOVERY" `
                -Title "System Restore points are available" `
                -Evidence "$($RestorePoints.Count) restore point(s) found."
        }
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "RECOVERY" `
            -Title "System Restore information unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 44. WINDOWS LICENSING
# ============================================================================

Run-Test "Windows Activation" {

    Section "WINDOWS ACTIVATION"

    try {

        $Licenses =
            Get-CimInstance SoftwareLicensingProduct |
            Where-Object {
                $_.PartialProductKey -and
                $_.Name -like "Windows*"
            }

        foreach ($License in $Licenses) {

            Write-Report "----------------------------------------"
            Write-Report "Name          : $($License.Name)"
            Write-Report "Description   : $($License.Description)"
            Write-Report "LicenseStatus : $($License.LicenseStatus)"
            Write-Report "Partial Key   : $($License.PartialProductKey)"
        }


        $Licensed =
            $Licenses |
            Where-Object {
                $_.LicenseStatus -eq 1
            }

        if ($Licensed) {

            Add-Finding `
                -Severity "OK" `
                -Category "LICENSING" `
                -Title "Windows license status includes an activated Windows product" `
                -Evidence "LicenseStatus = 1 was detected."
        }
        else {

            Add-Finding `
                -Severity "WARNING" `
                -Category "LICENSING" `
                -Title "No activated Windows license was detected by this query" `
                -Evidence "No Windows SoftwareLicensingProduct entry with LicenseStatus=1 was found."
        }
    }
    catch {

        Add-Finding `
            -Severity "NOT AVAILABLE" `
            -Category "LICENSING" `
            -Title "Windows activation state unavailable" `
            -Evidence $_.Exception.Message
    }
}


# ============================================================================
# 45. WMI
# ============================================================================

Run-Test "WMI Health" {

    Section "WMI / CIM HEALTH"

    try {

        $Test =
            Get-CimInstance `
                Win32_OperatingSystem `
                -ErrorAction Stop

        if ($Test) {

            Add-Finding `
                -Severity "OK" `
                -Category "WINDOWS" `
                -Title "WMI/CIM query infrastructure responded normally" `
                -Evidence "Win32_OperatingSystem query succeeded."
        }
    }
    catch {

        Add-Finding `
            -Severity "CRITICAL" `
            -Category "WINDOWS" `
            -Title "WMI/CIM query infrastructure returned an error" `
            -Evidence $_.Exception.Message `
            -Recommendation "Investigate WMI/CIM infrastructure before relying on hardware inventory results."
    }
}


# ============================================================================
# 46. CORE WINDOWS PATHS
# ============================================================================

Run-Test "Core Windows Paths" {

    Section "CORE WINDOWS PATHS"

    $Paths = @(
        $env:windir,
        "$env:windir\System32",
        "$env:windir\System32\drivers",
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)}
    )

    foreach ($Path in $Paths) {

        if ($Path) {

            if (Test-Path $Path) {

                Write-Report "[OK] $Path"

            }
            else {

                Add-Finding `
                    -Severity "WARNING" `
                    -Category "WINDOWS" `
                    -Title "Expected system path not found" `
                    -Evidence $Path
            }
        }
    }
}


# ============================================================================
# 47. ENVIRONMENT
# ============================================================================

Run-Test "Environment" {

    Section "ENVIRONMENT"

    Write-Report "TEMP       : $env:TEMP"
    Write-Report "TMP        : $env:TMP"
    Write-Report "SystemRoot : $env:SystemRoot"
    Write-Report "ProgramFiles: $env:ProgramFiles"
    Write-Report "PATH:"
    Write-Report $env:PATH

    Add-Finding `
        -Severity "INFO" `
        -Category "SYSTEM" `
        -Title "Environment information collected" `
        -Evidence "System environment variables were read."
}


# ============================================================================
# 48. FINAL ANALYSIS
# ============================================================================

Section "FINAL AUDIT ANALYSIS"

$EndTime = Get-Date

$Duration =
    ($EndTime - $StartTime).TotalSeconds


Write-Report ""
Write-Report "AUDIT DURATION : $([math]::Round($Duration,2)) seconds"

Write-Report ""
Write-Report "FINDING COUNTS"
Write-Report "----------------------------------------"
Write-Report "OK             : $($Statistics.OK)"
Write-Report "INFO           : $($Statistics.INFO)"
Write-Report "WARNING        : $($Statistics.WARNING)"
Write-Report "CRITICAL       : $($Statistics.CRITICAL)"
Write-Report "ERROR          : $($Statistics.ERROR)"
Write-Report "NOT AVAILABLE  : $($Statistics.NOT_AVAILABLE)"


Write-Report ""
Write-Report "IMPORTANT INTERPRETATION RULES"
Write-Report "----------------------------------------"
Write-Report "1. A warning is not automatically a hardware failure."
Write-Report "2. Event log entries must be correlated with timestamps and other evidence."
Write-Report "3. SMART/Storage health is an indicator, not absolute proof of hardware health."
Write-Report "4. CPU/RAM utilization is a snapshot and does not prove a persistent performance problem."
Write-Report "5. Thermal information depends heavily on manufacturer ACPI implementation."
Write-Report "6. Absence of a diagnostic record does not prove that the component is perfect."
Write-Report "7. NOT AVAILABLE means Windows did not expose that telemetry through the queried interface."


# ============================================================================
# 49. TOP FINDINGS
# ============================================================================

Write-Report ""
Write-Report "TOP WARNING / CRITICAL FINDINGS"
Write-Report "----------------------------------------"

$ImportantFindings =
    $Findings |
    Where-Object {
        $_.Severity -eq "CRITICAL" -or
        $_.Severity -eq "WARNING"
    }

if ($ImportantFindings.Count -eq 0) {

    Write-Report "No WARNING or CRITICAL findings were generated."

}
else {

    foreach ($Finding in $ImportantFindings) {

        Write-Report ""
        Write-Report "[$($Finding.Severity)] $($Finding.Title)"
        Write-Report "Category       : $($Finding.Category)"
        Write-Report "Evidence       : $($Finding.Evidence)"

        if ($Finding.Recommendation) {

            Write-Report "Recommendation : $($Finding.Recommendation)"
        }
    }
}


# ============================================================================
# 50. JSON EXPORT
# ============================================================================

try {

    $JsonData = [ordered]@{

        Audit = [ordered]@{

            Computer     = $env:COMPUTERNAME
            User         = $env:USERNAME
            StartTime    = $StartTime
            EndTime      = $EndTime
            DurationSec  = [math]::Round($Duration,2)
            PowerShell   = "$($PSVersionTable.PSVersion)"
            Administrator= $IsAdministrator
            Mode         = "READ-ONLY"
        }

        Statistics = $Statistics

        Findings = $Findings
    }


    $JsonData |
        ConvertTo-Json `
            -Depth 8 |
        Out-File `
            -FilePath $JsonFile `
            -Encoding UTF8

}
catch {

    $Errors.Add(
        "JSON export failed: $($_.Exception.Message)"
    )
}


# ============================================================================
# 51. ERROR REPORT
# ============================================================================

if ($Errors.Count -gt 0) {

    $Errors |
        Out-File `
            -FilePath $ErrorFile `
            -Encoding UTF8

}
else {

    "No script-level errors were recorded." |
        Out-File `
            -FilePath $ErrorFile `
            -Encoding UTF8
}


# ============================================================================
# 52. SUMMARY
# ============================================================================

$OverallState = "NO MAJOR FINDING"

if ($Statistics.CRITICAL -gt 0) {

    $OverallState = "CRITICAL FINDINGS PRESENT"

}
elseif ($Statistics.WARNING -gt 0) {

    $OverallState = "WARNINGS REQUIRE REVIEW"

}


@"
======================================================================
UNIVERSAL WINDOWS SYSTEM AUDIT - SUMMARY
======================================================================

Computer       : $env:COMPUTERNAME
User           : $env:USERNAME
Audit Start    : $StartTime
Audit End      : $EndTime
Duration       : $([math]::Round($Duration,2)) seconds

OVERALL STATE
======================================================================

$OverallState


FINDINGS
======================================================================

OK             : $($Statistics.OK)
INFO           : $($Statistics.INFO)
WARNING        : $($Statistics.WARNING)
CRITICAL       : $($Statistics.CRITICAL)
ERROR          : $($Statistics.ERROR)
NOT AVAILABLE  : $($Statistics.NOT_AVAILABLE)


INTERPRETATION
======================================================================

This report is diagnostic.

It does not claim that hardware is 100% healthy merely because
no errors were detected.

"NOT AVAILABLE" means the current Windows installation,
driver, firmware or hardware did not expose the requested
telemetry through the standard interfaces used by this audit.


OUTPUT FILES
======================================================================

FULL REPORT:
$ReportFile

SUMMARY:
$SummaryFile

ERRORS:
$ErrorFile

MACHINE-READABLE DATA:
$JsonFile


READ-ONLY NOTICE
======================================================================

No intentional permanent configuration changes were performed.

The script may temporarily consume CPU, memory and disk resources
while running SFC, DISM, CHKDSK and diagnostic queries.

======================================================================
"@ |
    Out-File `
        -FilePath $SummaryFile `
        -Encoding UTF8


# ============================================================================
# 53. CONSOLE OUTPUT
# ============================================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " UNIVERSAL WINDOWS SYSTEM AUDIT COMPLETED" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if ($Statistics.CRITICAL -gt 0) {

    Write-Host "[RESULT] CRITICAL FINDINGS PRESENT" -ForegroundColor Red

}
elseif ($Statistics.WARNING -gt 0) {

    Write-Host "[RESULT] WARNINGS REQUIRE REVIEW" -ForegroundColor Yellow

}
else {

    Write-Host "[RESULT] NO MAJOR FINDING DETECTED" -ForegroundColor Green
}

Write-Host ""

Write-Host "OK            : $($Statistics.OK)"
Write-Host "INFO          : $($Statistics.INFO)"
Write-Host "WARNING       : $($Statistics.WARNING)" -ForegroundColor Yellow
Write-Host "CRITICAL      : $($Statistics.CRITICAL)" -ForegroundColor Red
Write-Host "ERROR         : $($Statistics.ERROR)" -ForegroundColor Red
Write-Host "NOT AVAILABLE : $($Statistics.NOT_AVAILABLE)"

Write-Host ""

Write-Host "REPORT FOLDER:" -ForegroundColor Cyan
Write-Host $RootFolder

Write-Host ""
Write-Host "FULL REPORT:" -ForegroundColor Cyan
Write-Host $ReportFile

Write-Host ""
Write-Host "SUMMARY:" -ForegroundColor Cyan
Write-Host $SummaryFile

Write-Host ""
Write-Host "JSON DATA:" -ForegroundColor Cyan
Write-Host $JsonFile

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " READ-ONLY DIAGNOSTIC AUDIT FINISHED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

pause
```

