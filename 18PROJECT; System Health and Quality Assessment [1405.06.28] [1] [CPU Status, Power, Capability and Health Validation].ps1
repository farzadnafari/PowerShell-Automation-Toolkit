# ============================================================================
# PROJECT
# ============================================================================
# Project Name : System Health and Quality Assessment
# Module       : 05 - CPU Status, Power, Capability and Health Validation
# Version      : 1.0
#
# PURPOSE
# -------
# Dynamically inspect the CPU of the current Windows computer.
#
# This module checks:
#   - CPU manufacturer
#   - CPU model / name
#   - Socket information
#   - Physical core count
#   - Logical processor count
#   - Current clock
#   - Maximum clock
#   - Base clock when available
#   - CPU utilization
#   - Per-core utilization
#   - CPU load behavior
#   - CPU architecture
#   - Virtualization support and current virtualization state
#   - CPU feature information when available
#   - Power plan
#   - Processor power management configuration
#   - Minimum / maximum processor state
#   - AC/DC processor power configuration when available
#   - CPU temperature when exposed by firmware/WMI
#   - CPU thermal zones when available
#   - CPU throttling indicators when available
#   - Windows processor performance counters
#   - Processor-related Windows event errors
#   - Hardware Error Architecture (WHEA) events related to CPU/system hardware
#
# IMPORTANT
# ---------
# This is a diagnostic script.
#
# It does NOT:
#   - Stress test the CPU
#   - Overclock the CPU
#   - Undervolt the CPU
#   - Change BIOS settings
#   - Change Windows power settings
#   - Change CPU affinity
#   - Disable CPU features
#
# SOFTWARE CANNOT PROVE COMPLETE PHYSICAL CPU HEALTH.
#
# A CPU can appear normal through Windows telemetry while still having
# intermittent hardware faults. Therefore this module distinguishes between:
#
#   PASS   = No actionable CPU problem was detected by available telemetry.
#   REVIEW = One or more CPU-related conditions require further inspection.
#   INFO   = A metric was unavailable and cannot be used as proof of failure.
#
# Temperature and some low-level CPU telemetry are hardware/firmware dependent.
# Unsupported telemetry is therefore NOT automatically treated as failure.
# ============================================================================


# ============================================================================
# SECTION 1 - AUTO ELEVATION
# ============================================================================

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$CurrentPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentIdentity)

if (-not $CurrentPrincipal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {

    Write-Host ""
    Write-Host "Administrator privileges are required." -ForegroundColor Yellow
    Write-Host "Restarting the script with Administrator privileges..." -ForegroundColor Yellow
    Write-Host ""

    if (-not $PSCommandPath) {

        Write-Host "ERROR: Unable to determine the current script path." -ForegroundColor Red

        Read-Host "Press Enter to exit"
        Read-Host "Press Enter again to confirm"
        Read-Host "Press Enter one final time to finish"

        exit 1
    }

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

    exit
}


# ============================================================================
# SECTION 2 - EXECUTION POLICY
# ============================================================================

try {

    Set-ExecutionPolicy `
        -Scope Process `
        -ExecutionPolicy Bypass `
        -Force `
        -ErrorAction Stop
}
catch {

    Write-Host `
        "WARNING: Process execution policy could not be changed." `
        -ForegroundColor Yellow
}


# ============================================================================
# SECTION 3 - PROJECT INITIALIZATION
# ============================================================================

$ProjectName = "System Health and Quality Assessment"
$ModuleName  = "05 - CPU Status, Power, Capability and Health Validation"
$Version     = "1.0"

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ProjectPath = Join-Path $DesktopPath $ProjectName

if (-not (Test-Path $ProjectPath)) {

    New-Item `
        -Path $ProjectPath `
        -ItemType Directory `
        -Force |
        Out-Null
}

$ReportBaseName = "05_CPU_Status_Power_Capability_and_Health_Validation"

$TextReportPath = Join-Path `
    $ProjectPath `
    "$ReportBaseName.txt"

$JsonReportPath = Join-Path `
    $ProjectPath `
    "$ReportBaseName.json"


# ============================================================================
# SECTION 4 - HELPER FUNCTIONS
# ============================================================================

$ValidationIssues = New-Object System.Collections.Generic.List[string]
$Warnings = New-Object System.Collections.Generic.List[string]
$Information = New-Object System.Collections.Generic.List[string]

function Add-Issue {

    param(
        [string]$Message
    )

    if (-not [string]::IsNullOrWhiteSpace($Message)) {

        $ValidationIssues.Add($Message)
    }
}

function Add-Warning {

    param(
        [string]$Message
    )

    if (-not [string]::IsNullOrWhiteSpace($Message)) {

        $Warnings.Add($Message)
    }
}

function Add-Information {

    param(
        [string]$Message
    )

    if (-not [string]::IsNullOrWhiteSpace($Message)) {

        $Information.Add($Message)
    }
}

function Get-SafeNumber {

    param(
        $Value
    )

    if ($null -eq $Value) {
        return $null
    }

    try {
        return [double]$Value
    }
    catch {
        return $null
    }
}

function Get-PercentValue {

    param(
        $Value
    )

    try {

        return [Math]::Round(
            [double]$Value,
            2
        )
    }
    catch {

        return $null
    }
}


# ============================================================================
# SECTION 5 - HEADER
# ============================================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " $ProjectName" -ForegroundColor Cyan
Write-Host " $ModuleName" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""


# ============================================================================
# SECTION 6 - SYSTEM IDENTIFICATION
# ============================================================================

$OS = $null
$ComputerSystem = $null

try {

    $OS = Get-CimInstance `
        -ClassName Win32_OperatingSystem `
        -ErrorAction Stop
}
catch {

    Add-Warning "Operating system information could not be retrieved."
}

try {

    $ComputerSystem = Get-CimInstance `
        -ClassName Win32_ComputerSystem `
        -ErrorAction Stop
}
catch {

    Add-Warning "Computer system information could not be retrieved."
}

$SystemInfo = [PSCustomObject]@{

    ComputerName = $env:COMPUTERNAME

    Manufacturer = if ($ComputerSystem) {
        $ComputerSystem.Manufacturer
    }
    else {
        "Unknown"
    }

    Model = if ($ComputerSystem) {
        $ComputerSystem.Model
    }
    else {
        "Unknown"
    }

    OperatingSystem = if ($OS) {
        $OS.Caption
    }
    else {
        "Unknown"
    }

    Architecture = if ($OS) {
        $OS.OSArchitecture
    }
    else {
        "Unknown"
    }
}


# ============================================================================
# SECTION 7 - CPU HARDWARE INFORMATION
# ============================================================================

Write-Host "[1/12] Reading CPU hardware information..." -ForegroundColor White

$CPU = $null

try {

    $CPU = Get-CimInstance `
        -ClassName Win32_Processor `
        -ErrorAction Stop
}
catch {

    Add-Issue "Unable to retrieve Win32_Processor information."
}

$CPUInventory = @()

if ($CPU) {

    foreach ($Processor in $CPU) {

        $CPUInventory += [PSCustomObject]@{

            Name = $Processor.Name

            Manufacturer = $Processor.Manufacturer

            DeviceID = $Processor.DeviceID

            SocketDesignation = $Processor.SocketDesignation

            Description = $Processor.Description

            Architecture = $Processor.Architecture

            AddressWidth = $Processor.AddressWidth

            DataWidth = $Processor.DataWidth

            Family = $Processor.Family

            Model = $Processor.Model

            Stepping = $Processor.Stepping

            Revision = $Processor.Revision

            ProcessorID = $Processor.ProcessorId

            PhysicalCores = $Processor.NumberOfCores

            LogicalProcessors = $Processor.NumberOfLogicalProcessors

            CurrentClockMHz = $Processor.CurrentClockSpeed

            MaxClockMHz = $Processor.MaxClockSpeed

            ExternalClockMHz = $Processor.ExternalClock

            L2CacheKB = $Processor.L2CacheSize

            L3CacheKB = $Processor.L3CacheSize

            Status = $Processor.Status

            Availability = $Processor.Availability

            LoadPercentage = $Processor.LoadPercentage

            VirtualizationFirmwareEnabled =
                $Processor.VirtualizationFirmwareEnabled

            VMMonitorModeExtensions =
                $Processor.VMMonitorModeExtensions

            SecondLevelAddressTranslationExtensions =
                $Processor.SecondLevelAddressTranslationExtensions
        }
    }
}


# ============================================================================
# SECTION 8 - CPU COUNT AND BASIC VALIDATION
# ============================================================================

$TotalPhysicalCores = 0
$TotalLogicalProcessors = 0

foreach ($Processor in $CPUInventory) {

    if ($Processor.PhysicalCores) {

        $TotalPhysicalCores += [int]$Processor.PhysicalCores
    }

    if ($Processor.LogicalProcessors) {

        $TotalLogicalProcessors += [int]$Processor.LogicalProcessors
    }
}

if ($CPUInventory.Count -eq 0) {

    Add-Issue "No CPU information was successfully retrieved."
}

if ($TotalPhysicalCores -le 0) {

    Add-Warning "Physical CPU core count is unavailable."
}

if ($TotalLogicalProcessors -le 0) {

    Add-Warning "Logical processor count is unavailable."
}


# ============================================================================
# SECTION 9 - CPU UTILIZATION
# ============================================================================

Write-Host "[2/12] Measuring CPU utilization..." -ForegroundColor White

$CPUUtilizationSamples = @()

for ($Sample = 1; $Sample -le 3; $Sample++) {

    try {

        $Counters = Get-CimInstance `
            -ClassName Win32_Processor `
            -ErrorAction Stop

        $SampleTotalLoad = 0
        $SampleProcessorCount = 0

        foreach ($Processor in $Counters) {

            if ($null -ne $Processor.LoadPercentage) {

                $SampleTotalLoad += [double]$Processor.LoadPercentage
                $SampleProcessorCount++
            }
        }

        if ($SampleProcessorCount -gt 0) {

            $AverageLoad =
                $SampleTotalLoad / $SampleProcessorCount

            $CPUUtilizationSamples += [PSCustomObject]@{

                Sample = $Sample
                Timestamp = Get-Date
                AverageLoadPercent =
                    [Math]::Round($AverageLoad, 2)
            }
        }
    }
    catch {

        Add-Warning "CPU utilization sample $Sample could not be collected."
    }

    Start-Sleep -Seconds 2
}


$CurrentCPUUtilization = $null

if ($CPUUtilizationSamples.Count -gt 0) {

    $CurrentCPUUtilization =
        [Math]::Round(
            (
                $CPUUtilizationSamples |
                Measure-Object `
                    -Property AverageLoadPercent `
                    -Average
            ).Average,
            2
        )
}


# ============================================================================
# SECTION 10 - PER-PROCESSOR UTILIZATION
# ============================================================================

$PerProcessorUtilization = @()

try {

    $PerProcessorUtilization =
        Get-CimInstance `
            -ClassName Win32_PerfFormattedData_PerfOS_Processor `
            -ErrorAction Stop |
        ForEach-Object {

            [PSCustomObject]@{

                Name = $_.Name

                ProcessorTimePercent =
                    Get-PercentValue $_.PercentProcessorTime

                UserTimePercent =
                    Get-PercentValue $_.PercentUserTime

                PrivilegedTimePercent =
                    Get-PercentValue $_.PercentPrivilegedTime

                InterruptTimePercent =
                    Get-PercentValue $_.PercentInterruptTime

                DPCsQueued = $_.DPCsQueued

                InterruptsPerSec = $_.InterruptsPerSec
            }
        }
}
catch {

    Add-Warning "Per-processor performance counters are unavailable."
}


# ============================================================================
# SECTION 11 - POWER PLAN
# ============================================================================

Write-Host "[3/12] Checking Windows power configuration..." -ForegroundColor White

$PowerPlan = $null
$PowerPlanRaw = $null

try {

    $PowerPlanRaw = powercfg /getactivescheme 2>&1

    $PowerPlanText =
        ($PowerPlanRaw | Out-String).Trim()

    $PowerPlan = $PowerPlanText
}
catch {

    Add-Warning "Active Windows power plan could not be determined."
}


$PowerConfiguration = [ordered]@{

    ActiveScheme = $PowerPlan

    ProcessorMinimumAC = $null
    ProcessorMaximumAC = $null

    ProcessorMinimumDC = $null
    ProcessorMaximumDC = $null

    CurrentProcessorPerformanceAC = $null
    CurrentProcessorPerformanceDC = $null
}


# ============================================================================
# SECTION 12 - PROCESSOR POWER CONFIGURATION
# ============================================================================

Write-Host "[4/12] Reading processor power management settings..." -ForegroundColor White

try {

    $PowerCfgQuery = powercfg /query SCHEME_CURRENT SUB_PROCESSOR 2>&1

    $PowerText = $PowerCfgQuery | Out-String

    $MinACMatch =
        [regex]::Match(
            $PowerText,
            "(?im)Current AC Power Setting Index:\s*0x([0-9a-f]+)"
        )

    $MaxACMatch =
        [regex]::Match(
            $PowerText,
            "(?im)Current AC Power Setting Index:\s*0x([0-9a-f]+)"
        )

    $ProcessorMinimumMatch =
        [regex]::Match(
            $PowerText,
            "(?im)Minimum processor state.*?Current AC Power Setting Index:\s*0x([0-9a-f]+)",
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

    $ProcessorMaximumMatch =
        [regex]::Match(
            $PowerText,
            "(?im)Maximum processor state.*?Current AC Power Setting Index:\s*0x([0-9a-f]+)",
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

    $MinimumDCMatch =
        [regex]::Match(
            $PowerText,
            "(?im)Minimum processor state.*?Current DC Power Setting Index:\s*0x([0-9a-f]+)",
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

    $MaximumDCMatch =
        [regex]::Match(
            $PowerText,
            "(?im)Maximum processor state.*?Current DC Power Setting Index:\s*0x([0-9a-f]+)",
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

    if ($ProcessorMinimumMatch.Success) {

        $PowerConfiguration.ProcessorMinimumAC =
            [Convert]::ToInt32(
                $ProcessorMinimumMatch.Groups[1].Value,
                16
            )
    }

    if ($ProcessorMaximumMatch.Success) {

        $PowerConfiguration.ProcessorMaximumAC =
            [Convert]::ToInt32(
                $ProcessorMaximumMatch.Groups[1].Value,
                16
            )
    }

    if ($MinimumDCMatch.Success) {

        $PowerConfiguration.ProcessorMinimumDC =
            [Convert]::ToInt32(
                $MinimumDCMatch.Groups[1].Value,
                16
            )
    }

    if ($MaximumDCMatch.Success) {

        $PowerConfiguration.ProcessorMaximumDC =
            [Convert]::ToInt32(
                $MaximumDCMatch.Groups[1].Value,
                16
            )
    }
}
catch {

    Add-Warning `
        "Processor power management configuration could not be fully retrieved."
}


# ============================================================================
# SECTION 13 - CPU TEMPERATURE
# ============================================================================

Write-Host "[5/12] Checking available CPU temperature telemetry..." -ForegroundColor White

$TemperatureSensors = @()

try {

    $TemperatureSensors =
        Get-CimInstance `
            -Namespace "root/wmi" `
            -ClassName MSAcpi_ThermalZoneTemperature `
            -ErrorAction Stop |
        ForEach-Object {

            $Celsius = ($_.CurrentTemperature / 10) - 273.15

            [PSCustomObject]@{

                InstanceName = $_.InstanceName

                Celsius = [Math]::Round(
                    $Celsius,
                    2
                )

                Fahrenheit = [Math]::Round(
                    (($Celsius * 9 / 5) + 32),
                    2
                )

                Status = $_.Status
            }
        }
}
catch {

    Add-Information `
        "Direct CPU temperature telemetry is not exposed by the available ACPI WMI interface."
}


# ============================================================================
# SECTION 14 - TEMPERATURE INTERPRETATION
# ============================================================================

$TemperatureAssessment = @()

foreach ($Sensor in $TemperatureSensors) {

    $TemperatureStatus = "INFO"

    if ($Sensor.Celsius -ge 95) {

        $TemperatureStatus = "HIGH"

        Add-Issue (
            "A thermal zone reported approximately " +
            "$($Sensor.Celsius) C."
        )
    }
    elseif ($Sensor.Celsius -ge 85) {

        $TemperatureStatus = "ELEVATED"

        Add-Warning (
            "A thermal zone reported approximately " +
            "$($Sensor.Celsius) C."
        )
    }
    elseif ($Sensor.Celsius -ge 0) {

        $TemperatureStatus = "NORMAL_RANGE"
    }

    $TemperatureAssessment += [PSCustomObject]@{

        InstanceName = $Sensor.InstanceName
        Celsius = $Sensor.Celsius
        Status = $TemperatureStatus
    }
}


# ============================================================================
# SECTION 15 - THERMAL ZONES
# ============================================================================

$ThermalZones = @()

try {

    $ThermalZones =
        Get-CimInstance `
            -ClassName Win32_TemperatureProbe `
            -ErrorAction Stop |
        ForEach-Object {

            [PSCustomObject]@{

                Name = $_.Name

                Description = $_.Description

                DeviceID = $_.DeviceID

                Status = $_.Status

                CurrentReading = $_.CurrentReading

                Resolution = $_.Resolution

                Tolerance = $_.Tolerance

                Accuracy = $_.Accuracy
            }
        }
}
catch {

    Add-Information `
        "Win32_TemperatureProbe did not provide usable CPU thermal information."
}


# ============================================================================
# SECTION 16 - VIRTUALIZATION
# ============================================================================

Write-Host "[6/12] Checking CPU virtualization capabilities..." -ForegroundColor White

$Virtualization = [ordered]@{

    VMMonitorModeExtensions = $null

    SecondLevelAddressTranslationExtensions = $null

    VirtualizationFirmwareEnabled = $null

    HyperVRequirementOutput = $null

    HyperVRequirementsStatus = "UNKNOWN"
}


if ($CPUInventory.Count -gt 0) {

    $Virtualization.VMMonitorModeExtensions =
        $CPUInventory[0].VMMonitorModeExtensions

    $Virtualization.SecondLevelAddressTranslationExtensions =
        $CPUInventory[0].SecondLevelAddressTranslationExtensions

    $Virtualization.VirtualizationFirmwareEnabled =
        $CPUInventory[0].VirtualizationFirmwareEnabled
}


try {

    $HyperVRequirements =
        systeminfo.exe

    $HyperVText =
        $HyperVRequirements | Out-String

    $Virtualization.HyperVRequirementOutput =
        $HyperVText

    if (
        $HyperVText -match
        "VM Monitor Mode Extensions:\s*Yes" -and
        $HyperVText -match
        "Virtualization Enabled In Firmware:\s*Yes"
    ) {

        $Virtualization.HyperVRequirementsStatus =
            "SUPPORTED_AND_ENABLED"
    }
    elseif (
        $HyperVText -match
        "VM Monitor Mode Extensions:\s*Yes"
    ) {

        $Virtualization.HyperVRequirementsStatus =
            "CPU_SUPPORT_DETECTED"
    }
    else {

        $Virtualization.HyperVRequirementsStatus =
            "NOT_CONFIRMED"
    }
}
catch {

    Add-Warning `
        "Hyper-V CPU requirement information could not be retrieved."
}


# ============================================================================
# SECTION 17 - PROCESSOR FEATURE INFORMATION
# ============================================================================

Write-Host "[7/12] Checking CPU feature information..." -ForegroundColor White

$CPUFeatures = [ordered]@{

    Architecture = $null

    AddressWidth = $null

    DataWidth = $null

    VMMonitorModeExtensions = $null

    SLAT = $null

    VirtualizationFirmware = $null
}


if ($CPUInventory.Count -gt 0) {

    $CPUFeatures.Architecture =
        $CPUInventory[0].Architecture

    $CPUFeatures.AddressWidth =
        $CPUInventory[0].AddressWidth

    $CPUFeatures.DataWidth =
        $CPUInventory[0].DataWidth

    $CPUFeatures.VMMonitorModeExtensions =
        $CPUInventory[0].VMMonitorModeExtensions

    $CPUFeatures.SLAT =
        $CPUInventory[0].SecondLevelAddressTranslationExtensions

    $CPUFeatures.VirtualizationFirmware =
        $CPUInventory[0].VirtualizationFirmwareEnabled
}


# ============================================================================
# SECTION 18 - CPU PERFORMANCE COUNTERS
# ============================================================================

$PerformanceCounters = @()

try {

    $PerformanceCounters =
        Get-Counter `
            '\Processor(_Total)\% Processor Time',
            '\Processor(_Total)\% User Time',
            '\Processor(_Total)\% Privileged Time',
            '\Processor(_Total)\Interrupts/sec',
            '\Processor(_Total)\DPC Rate' `
            -ErrorAction Stop |
        Select-Object -ExpandProperty CounterSamples |
        ForEach-Object {

            [PSCustomObject]@{

                Path = $_.Path

                CookedValue = [Math]::Round(
                    $_.CookedValue,
                    2
                )
            }
        }
}
catch {

    Add-Warning `
        "Windows performance counters could not be fully queried."
}


# ============================================================================
# SECTION 19 - CPU STATUS
# ============================================================================

$CPUStatus = "UNKNOWN"

if ($CPUInventory.Count -eq 0) {

    $CPUStatus = "REVIEW"
}
elseif (
    ($CPUInventory |
        Where-Object {
            $_.Status -notin @("OK", "Unknown")
        }).Count -gt 0
) {

    $CPUStatus = "REVIEW"
}
else {

    $CPUStatus = "PASS"
}


# ============================================================================
# SECTION 20 - WHEA HARDWARE ERROR EVENTS
# ============================================================================

Write-Host "[8/12] Checking hardware error events..." -ForegroundColor White

$WHEAEvents = @()

try {

    $RawWHEAEvents =
        Get-WinEvent `
            -FilterHashtable @{
                LogName = "System"
                ProviderName = "Microsoft-Windows-WHEA-Logger"
                StartTime = (Get-Date).AddDays(-30)
            } `
            -ErrorAction Stop |
        Select-Object -First 100

    foreach ($Event in $RawWHEAEvents) {

        $WHEAEvents += [PSCustomObject]@{

            TimeCreated = $Event.TimeCreated

            Id = $Event.Id

            Level = $Event.LevelDisplayName

            Provider = $Event.ProviderName

            Message = $Event.Message
        }
    }
}
catch {

    Add-Information `
        "No WHEA events could be retrieved from the last 30 days or the log is unavailable."
}


$CriticalWHEAEvents = @(
    $WHEAEvents |
    Where-Object {
        $_.Level -in @(
            "Error",
            "Critical"
        )
    }
)

if ($CriticalWHEAEvents.Count -gt 0) {

    Add-Issue (
        "$($CriticalWHEAEvents.Count) WHEA hardware error event(s) " +
        "were detected within the last 30 days."
    )
}


# ============================================================================
# SECTION 21 - PROCESSOR EVENT LOG
# ============================================================================

Write-Host "[9/12] Checking processor-related Windows events..." -ForegroundColor White

$ProcessorEvents = @()

try {

    $RawProcessorEvents =
        Get-WinEvent `
            -FilterHashtable @{
                LogName = "System"
                StartTime = (Get-Date).AddDays(-30)
            } `
            -ErrorAction Stop |
        Where-Object {

            $_.ProviderName -match `
                "Processor|Kernel-Processor-Power|Microsoft-Windows-Kernel-Processor-Power"
        } |
        Select-Object -First 100

    foreach ($Event in $RawProcessorEvents) {

        $ProcessorEvents += [PSCustomObject]@{

            TimeCreated = $Event.TimeCreated

            Id = $Event.Id

            Level = $Event.LevelDisplayName

            Provider = $Event.ProviderName

            Message = $Event.Message
        }
    }
}
catch {

    Add-Information `
        "Processor-specific Windows event information was not available."
}


$ProcessorErrorEvents = @(
    $ProcessorEvents |
    Where-Object {
        $_.Level -in @(
            "Error",
            "Critical"
        )
    }
)

if ($ProcessorErrorEvents.Count -gt 0) {

    Add-Warning (
        "$($ProcessorErrorEvents.Count) processor-related Error/Critical " +
        "event(s) were found within the last 30 days."
    )
}


# ============================================================================
# SECTION 22 - CURRENT CLOCK ANALYSIS
# ============================================================================

Write-Host "[10/12] Analyzing CPU clock behavior..." -ForegroundColor White

$ClockAnalysis = @()

foreach ($Processor in $CPUInventory) {

    $ClockRatio = $null

    if (
        $Processor.MaxClockMHz -gt 0 -and
        $Processor.CurrentClockMHz -gt 0
    ) {

        $ClockRatio =
            [Math]::Round(
                (
                    $Processor.CurrentClockMHz /
                    $Processor.MaxClockMHz
                ) * 100,
                2
            )
    }

    $ClockAnalysis += [PSCustomObject]@{

        ProcessorName = $Processor.Name

        CurrentClockMHz =
            $Processor.CurrentClockMHz

        MaxClockMHz =
            $Processor.MaxClockMHz

        CurrentToMaxPercent =
            $ClockRatio
    }
}


# ============================================================================
# SECTION 23 - THROTTLING INDICATORS
# ============================================================================

$ThrottlingIndicators = @()

try {

    $ThrottleCounters =
        Get-Counter `
            '\Processor Information(_Total)\% Processor Performance',
            '\Processor Information(_Total)\% Processor Utility' `
            -ErrorAction Stop |
        Select-Object -ExpandProperty CounterSamples

    foreach ($Counter in $ThrottleCounters) {

        $ThrottlingIndicators += [PSCustomObject]@{

            Path = $Counter.Path

            Value = [Math]::Round(
                $Counter.CookedValue,
                2
            )
        }
    }
}
catch {

    Add-Information `
        "Processor performance/utility counters are unavailable."
}


# ============================================================================
# SECTION 24 - CPU POWER STATUS
# ============================================================================

$PowerStatus = [ordered]@{

    ActivePlan = $PowerPlan

    MinimumAC = $PowerConfiguration.ProcessorMinimumAC

    MaximumAC = $PowerConfiguration.ProcessorMaximumAC

    MinimumDC = $PowerConfiguration.ProcessorMinimumDC

    MaximumDC = $PowerConfiguration.ProcessorMaximumDC
}


# ============================================================================
# SECTION 25 - CPU CAPABILITY CLASSIFICATION
# ============================================================================

$Capability = [ordered]@{

    PhysicalCoreCount =
        $TotalPhysicalCores

    LogicalProcessorCount =
        $TotalLogicalProcessors

    Supports64Bit =
        ($CPUFeatures.AddressWidth -eq 64)

    SupportsVirtualization =
        ($Virtualization.VMMonitorModeExtensions -eq $true)

    SupportsSLAT =
        ($Virtualization.SecondLevelAddressTranslationExtensions -eq $true)

    VirtualizationFirmwareEnabled =
        ($Virtualization.VirtualizationFirmwareEnabled -eq $true)

    GeneralPurposeSoftwareDevelopment =
        "Supported if required software is compatible with the detected CPU architecture."

    MultithreadedWork =
        "Capability depends on physical/logical processor count and workload."

    GraphicsWork =
        "CPU capability does not determine GPU capability."

    HeavyComputeWork =
        "Requires workload-specific benchmarking for quantitative performance evaluation."
}


# ============================================================================
# SECTION 26 - THERMAL / POWER / STATUS SUMMARY
# ============================================================================

$HealthAssessment = [ordered]@{

    CPUDetected =
        ($CPUInventory.Count -gt 0)

    CPUStatus =
        $CPUStatus

    CurrentAverageLoadPercent =
        $CurrentCPUUtilization

    TemperatureTelemetryAvailable =
        ($TemperatureSensors.Count -gt 0)

    TemperatureSensors =
        $TemperatureAssessment

    WHEAErrorCount =
        $CriticalWHEAEvents.Count

    ProcessorErrorEventCount =
        $ProcessorErrorEvents.Count

    RebootRequired =
        $false

    SoftwareEvidenceOfHardwareFailure =
        if ($CriticalWHEAEvents.Count -gt 0) {
            $true
        }
        else {
            $false
        }
}


# ============================================================================
# SECTION 27 - FINAL VALIDATION
# ============================================================================

Write-Host "[11/12] Building final CPU validation..." -ForegroundColor White

$OverallStatus = "PASS"

if ($ValidationIssues.Count -gt 0) {

    $OverallStatus = "REVIEW"
}

if ($CPUInventory.Count -eq 0) {

    $OverallStatus = "REVIEW"
}


# ============================================================================
# SECTION 28 - REPORT OBJECT
# ============================================================================

$Report = [ordered]@{

    Project = [ordered]@{

        Name =
            $ProjectName

        Module =
            $ModuleName

        Version =
            $Version

        GeneratedAt =
            (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }

    System =
        $SystemInfo

    CPU =
        $CPUInventory

    CPUFeatures =
        $CPUFeatures

    Capability =
        $Capability

    Utilization = [ordered]@{

        CurrentAverageLoadPercent =
            $CurrentCPUUtilization

        Samples =
            $CPUUtilizationSamples

        PerProcessor =
            $PerProcessorUtilization
    }

    ClockAnalysis =
        $ClockAnalysis

    Power =
        $PowerStatus

    PerformanceCounters =
        $PerformanceCounters

    ThrottlingIndicators =
        $ThrottlingIndicators

    Temperature = [ordered]@{

        Sensors =
            $TemperatureSensors

        Assessment =
            $TemperatureAssessment

        ThermalZones =
            $ThermalZones
    }

    Virtualization =
        $Virtualization

    WHEAEvents =
        $WHEAEvents

    CriticalWHEAEvents =
        $CriticalWHEAEvents

    ProcessorEvents =
        $ProcessorEvents

    ProcessorErrorEvents =
        $ProcessorErrorEvents

    HealthAssessment =
        $HealthAssessment

    Validation = [ordered]@{

        OverallStatus =
            $OverallStatus

        Issues =
            @($ValidationIssues)

        Warnings =
            @($Warnings)

        Information =
            @($Information)
    }
}


# ============================================================================
# SECTION 29 - JSON REPORT
# ============================================================================

Write-Host "[12/12] Saving CPU reports..." -ForegroundColor White

try {

    $Report |
        ConvertTo-Json -Depth 15 |
        Set-Content `
            -Path $JsonReportPath `
            -Encoding UTF8 `
            -Force
}
catch {

    Write-Host ""
    Write-Host "ERROR: JSON report could not be created." -ForegroundColor Red
}


# ============================================================================
# SECTION 30 - HUMAN READABLE REPORT
# ============================================================================

$ReportLines = New-Object System.Collections.Generic.List[string]

$ReportLines.Add("============================================================")
$ReportLines.Add("SYSTEM HEALTH AND QUALITY ASSESSMENT")
$ReportLines.Add("05 - CPU STATUS, POWER, CAPABILITY AND HEALTH VALIDATION")
$ReportLines.Add("============================================================")
$ReportLines.Add("")
$ReportLines.Add(
    "Generated: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
)
$ReportLines.Add("")

$ReportLines.Add("SYSTEM")
$ReportLines.Add("------------------------------------------------------------")
$ReportLines.Add("Computer Name : $($SystemInfo.ComputerName)")
$ReportLines.Add("Manufacturer  : $($SystemInfo.Manufacturer)")
$ReportLines.Add("Model         : $($SystemInfo.Model)")
$ReportLines.Add("Operating Sys.: $($SystemInfo.OperatingSystem)")
$ReportLines.Add("Architecture  : $($SystemInfo.Architecture)")
$ReportLines.Add("")

$ReportLines.Add("CPU")
$ReportLines.Add("------------------------------------------------------------")

foreach ($Processor in $CPUInventory) {

    $ReportLines.Add(
        "Name              : $($Processor.Name)"
    )

    $ReportLines.Add(
        "Manufacturer      : $($Processor.Manufacturer)"
    )

    $ReportLines.Add(
        "Socket            : $($Processor.SocketDesignation)"
    )

    $ReportLines.Add(
        "Physical Cores    : $($Processor.PhysicalCores)"
    )

    $ReportLines.Add(
        "Logical Processors: $($Processor.LogicalProcessors)"
    )

    $ReportLines.Add(
        "Current Clock MHz : $($Processor.CurrentClockMHz)"
    )

    $ReportLines.Add(
        "Maximum Clock MHz : $($Processor.MaxClockMHz)"
    )

    $ReportLines.Add(
        "L2 Cache KB       : $($Processor.L2CacheKB)"
    )

    $ReportLines.Add(
        "L3 Cache KB       : $($Processor.L3CacheKB)"
    )

    $ReportLines.Add(
        "Status            : $($Processor.Status)"
    )

    $ReportLines.Add("")
}

$ReportLines.Add("CPU UTILIZATION")
$ReportLines.Add("------------------------------------------------------------")
$ReportLines.Add(
    "Average Current Load: $CurrentCPUUtilization %"
)
$ReportLines.Add("")

foreach ($Sample in $CPUUtilizationSamples) {

    $ReportLines.Add(
        "Sample $($Sample.Sample) | " +
        "$($Sample.Timestamp) | " +
        "$($Sample.AverageLoadPercent) %"
    )
}

$ReportLines.Add("")
$ReportLines.Add("POWER")
$ReportLines.Add("------------------------------------------------------------")
$ReportLines.Add(
    "Active Power Plan : $PowerPlan"
)
$ReportLines.Add(
    "Minimum AC        : $($PowerConfiguration.ProcessorMinimumAC)"
)
$ReportLines.Add(
    "Maximum AC        : $($PowerConfiguration.ProcessorMaximumAC)"
)
$ReportLines.Add(
    "Minimum DC        : $($PowerConfiguration.ProcessorMinimumDC)"
)
$ReportLines.Add(
    "Maximum DC        : $($PowerConfiguration.ProcessorMaximumDC)"
)
$ReportLines.Add("")

$ReportLines.Add("VIRTUALIZATION")
$ReportLines.Add("------------------------------------------------------------")
$ReportLines.Add(
    "VM Monitor Extensions : $($Virtualization.VMMonitorModeExtensions)"
)
$ReportLines.Add(
    "SLAT                  : $($Virtualization.SecondLevelAddressTranslationExtensions)"
)
$ReportLines.Add(
    "Virtualization Firmware: $($Virtualization.VirtualizationFirmwareEnabled)"
)
$ReportLines.Add(
    "Hyper-V Status        : $($Virtualization.HyperVRequirementsStatus)"
)
$ReportLines.Add("")

$ReportLines.Add("TEMPERATURE")
$ReportLines.Add("------------------------------------------------------------")

if ($TemperatureAssessment.Count -eq 0) {

    $ReportLines.Add(
        "CPU temperature telemetry was not available through the tested Windows interfaces."
    )

}
else {

    foreach ($Temperature in $TemperatureAssessment) {

        $ReportLines.Add(
            "$($Temperature.InstanceName) | " +
            "$($Temperature.Celsius) C | " +
            "Status: $($Temperature.Status)"
        )
    }
}

$ReportLines.Add("")
$ReportLines.Add("HARDWARE ERROR EVENTS")
$ReportLines.Add("------------------------------------------------------------")
$ReportLines.Add(
    "WHEA Events (30 days)       : $($WHEAEvents.Count)"
)
$ReportLines.Add(
    "WHEA Error/Critical Events  : $($CriticalWHEAEvents.Count)"
)
$ReportLines.Add(
    "Processor Error Events      : $($ProcessorErrorEvents.Count)"
)
$ReportLines.Add("")

$ReportLines.Add("CPU CAPABILITY")
$ReportLines.Add("------------------------------------------------------------")
$ReportLines.Add(
    "Physical Cores        : $TotalPhysicalCores"
)
$ReportLines.Add(
    "Logical Processors    : $TotalLogicalProcessors"
)
$ReportLines.Add(
    "64-bit Support        : $($Capability.Supports64Bit)"
)
$ReportLines.Add(
    "Virtualization Support: $($Capability.SupportsVirtualization)"
)
$ReportLines.Add(
    "SLAT Support          : $($Capability.SupportsSLAT)"
)
$ReportLines.Add(
    "Virtualization Enabled: $($Capability.VirtualizationFirmwareEnabled)"
)
$ReportLines.Add("")

$ReportLines.Add("FINAL VALIDATION")
$ReportLines.Add("------------------------------------------------------------")
$ReportLines.Add(
    "Overall Status: $OverallStatus"
)
$ReportLines.Add("")

if ($ValidationIssues.Count -eq 0) {

    $ReportLines.Add("Issues:")
    $ReportLines.Add("None")

}
else {

    $ReportLines.Add("Issues:")

    $IssueNumber = 1

    foreach ($Issue in $ValidationIssues) {

        $ReportLines.Add(
            "$IssueNumber. $Issue"
        )

        $IssueNumber++
    }
}

$ReportLines.Add("")

if ($Warnings.Count -eq 0) {

    $ReportLines.Add("Warnings:")
    $ReportLines.Add("None")

}
else {

    $ReportLines.Add("Warnings:")

    $WarningNumber = 1

    foreach ($Warning in $Warnings) {

        $ReportLines.Add(
            "$WarningNumber. $Warning"
        )

        $WarningNumber++
    }
}

$ReportLines.Add("")

if ($Information.Count -eq 0) {

    $ReportLines.Add("Information:")
    $ReportLines.Add("None")

}
else {

    $ReportLines.Add("Information:")

    $InformationNumber = 1

    foreach ($Info in $Information) {

        $ReportLines.Add(
            "$InformationNumber. $Info"
        )

        $InformationNumber++
    }
}

$ReportLines.Add("")
$ReportLines.Add("============================================================")
$ReportLines.Add("END OF REPORT")
$ReportLines.Add("============================================================")


try {

    $ReportLines |
        Set-Content `
            -Path $TextReportPath `
            -Encoding UTF8 `
            -Force
}
catch {

    Write-Host ""
    Write-Host "ERROR: Text report could not be created." -ForegroundColor Red
}


# ============================================================================
# SECTION 31 - CONSOLE SUMMARY
# ============================================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "FINAL CPU VALIDATION" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if ($CPUInventory.Count -gt 0) {

    Write-Host "CPU               : $($CPUInventory[0].Name)"
    Write-Host "Manufacturer      : $($CPUInventory[0].Manufacturer)"
    Write-Host "Physical Cores    : $TotalPhysicalCores"
    Write-Host "Logical Processors: $TotalLogicalProcessors"
    Write-Host "Current Clock     : $($CPUInventory[0].CurrentClockMHz) MHz"
    Write-Host "Maximum Clock     : $($CPUInventory[0].MaxClockMHz) MHz"
}
else {

    Write-Host "CPU information is unavailable."
}

Write-Host ""

Write-Host "Average CPU Load  : $CurrentCPUUtilization %"
Write-Host "Power Plan        : $PowerPlan"
Write-Host "Virtualization    : $($Virtualization.HyperVRequirementsStatus)"
Write-Host "WHEA Errors       : $($CriticalWHEAEvents.Count)"
Write-Host "CPU Error Events  : $($ProcessorErrorEvents.Count)"
Write-Host ""

if ($OverallStatus -eq "PASS") {

    Write-Host "OVERALL STATUS: PASS" -ForegroundColor Green
    Write-Host `
        "No actionable CPU problem was detected by available Windows telemetry." `
        -ForegroundColor Green
}
else {

    Write-Host "OVERALL STATUS: REVIEW" -ForegroundColor Yellow
    Write-Host `
        "One or more CPU-related conditions require review." `
        -ForegroundColor Yellow
}

Write-Host ""

if ($ValidationIssues.Count -gt 0) {

    Write-Host "CPU Issues:" -ForegroundColor Yellow

    $Counter = 1

    foreach ($Issue in $ValidationIssues) {

        Write-Host "$Counter. $Issue"

        $Counter++
    }

    Write-Host ""
}

Write-Host "Reports saved to:" -ForegroundColor Cyan
Write-Host $ProjectPath
Write-Host ""

Write-Host "Text Report:" -ForegroundColor Cyan
Write-Host $TextReportPath
Write-Host ""

Write-Host "JSON Report:" -ForegroundColor Cyan
Write-Host $JsonReportPath
Write-Host ""


# ============================================================================
# SECTION 32 - FINAL PAUSE
# ============================================================================

Read-Host "Press Enter to continue"
Read-Host "Press Enter again to continue"
Read-Host "Press Enter one final time to finish"