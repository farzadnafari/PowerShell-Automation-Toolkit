# ============================================================================
# PROJECT: System Health and Quality Assessment
# MODULE: 06 - GPU Status, Power, Capability and Health Validation
# VERSION: 1.0
# PURPOSE:
#   Dynamically inspect the installed GPU(s), graphics drivers, graphics
#   capabilities, memory, power/telemetry information, display configuration,
#   hardware status, and recent graphics-related Windows errors.
#
#   This module does NOT perform stress testing, overclocking, undervolting,
#   BIOS changes, driver installation, or configuration changes.
#
#   IMPORTANT:
#   Software telemetry cannot mathematically prove physical GPU health.
#   PASS means that no actionable GPU-related problem was detected through
#   the Windows information and telemetry available to this script.
# ============================================================================

$ErrorActionPreference = "SilentlyContinue"

# ============================================================================
# SECTION 1 - AUTO-ELEVATION
# ============================================================================

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    $ScriptPath = $MyInvocation.MyCommand.Path

    if (-not $ScriptPath) {
        Write-Host ""
        Write-Host "ERROR: This script must be saved as a .ps1 file before execution." -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit
    }

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

    exit
}

# ============================================================================
# SECTION 2 - EXECUTION POLICY
# ============================================================================

try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}
catch {
}

# ============================================================================
# SECTION 3 - PROJECT PATH
# ============================================================================

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ProjectFolder = Join-Path $DesktopPath "System Health and Quality Assessment"

if (-not (Test-Path $ProjectFolder)) {
    New-Item -Path $ProjectFolder -ItemType Directory -Force | Out-Null
}

$ReportTXT = Join-Path $ProjectFolder "06_GPU_Status_Power_Capability_and_Health_Validation.txt"
$ReportJSON = Join-Path $ProjectFolder "06_GPU_Status_Power_Capability_and_Health_Validation.json"

# ============================================================================
# SECTION 4 - HELPER FUNCTIONS
# ============================================================================

$Report = New-Object System.Collections.Generic.List[string]

function Add-ReportLine {
    param([string]$Text = "")
    $Report.Add($Text)
}

function Add-Section {
    param([string]$Title)

    Add-ReportLine ""
    Add-ReportLine ("=" * 78)
    Add-ReportLine $Title
    Add-ReportLine ("=" * 78)
}

function Format-Value {
    param($Value)

    if ($null -eq $Value) {
        return "Not Available"
    }

    if ([string]::IsNullOrWhiteSpace([string]$Value)) {
        return "Not Available"
    }

    return [string]$Value
}

function Convert-BytesToGB {
    param($Bytes)

    if ($null -eq $Bytes) {
        return "Not Available"
    }

    try {
        return ("{0:N2} GB" -f ([double]$Bytes / 1GB))
    }
    catch {
        return "Not Available"
    }
}

function Convert-KBToGB {
    param($KB)

    if ($null -eq $KB) {
        return "Not Available"
    }

    try {
        return ("{0:N2} GB" -f ([double]$KB / 1MB))
    }
    catch {
        return "Not Available"
    }
}

# ============================================================================
# SECTION 5 - SYSTEM IDENTIFICATION
# ============================================================================

$OS = Get-CimInstance Win32_OperatingSystem
$Computer = Get-CimInstance Win32_ComputerSystem

$ComputerName = $env:COMPUTERNAME
$Manufacturer = Format-Value $Computer.Manufacturer
$Model = Format-Value $Computer.Model
$OSName = Format-Value $OS.Caption
$OSVersion = Format-Value $OS.Version
$OSBuild = Format-Value $OS.BuildNumber

# ============================================================================
# SECTION 6 - GPU DISCOVERY
# ============================================================================

$GPUs = @(Get-CimInstance Win32_VideoController)

$GPUResults = New-Object System.Collections.Generic.List[object]

foreach ($GPU in $GPUs) {

    $GPUObject = [ordered]@{

        Name                    = Format-Value $GPU.Name
        Manufacturer            = Format-Value $GPU.AdapterCompatibility
        PNPDeviceID             = Format-Value $GPU.PNPDeviceID
        DriverVersion           = Format-Value $GPU.DriverVersion
        DriverDate              = if ($GPU.DriverDate) {
                                      try {
                                          [Management.ManagementDateTimeConverter]::ToDateTime($GPU.DriverDate)
                                      }
                                      catch {
                                          "Not Available"
                                      }
                                  }
                                  else {
                                      "Not Available"
                                  }
        Status                  = Format-Value $GPU.Status
        Availability            = Format-Value $GPU.Availability
        VideoProcessor          = Format-Value $GPU.VideoProcessor
        VideoModeDescription    = Format-Value $GPU.VideoModeDescription
        CurrentHorizontalRes   = Format-Value $GPU.CurrentHorizontalResolution
        CurrentVerticalRes     = Format-Value $GPU.CurrentVerticalResolution
        CurrentRefreshRate     = Format-Value $GPU.CurrentRefreshRate
        CurrentBitsPerPixel    = Format-Value $GPU.CurrentBitsPerPixel
        AdapterRAM             = Convert-BytesToGB $GPU.AdapterRAM
        DedicatedVideoMemory   = Convert-BytesToGB $GPU.DedicatedVideoMemory
        SharedSystemMemory     = Convert-BytesToGB $GPU.SharedSystemMemory
        ConfigManagerErrorCode = Format-Value $GPU.ConfigManagerErrorCode
        ConfigManagerUserConfig = Format-Value $GPU.ConfigManagerUserConfig
        InfFilename             = Format-Value $GPU.InfFilename
        InfSection              = Format-Value $GPU.InfSection
    }

    $GPUResults.Add([PSCustomObject]$GPUObject)
}

# ============================================================================
# SECTION 7 - DISPLAY / MONITOR INFORMATION
# ============================================================================

$Monitors = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID)

$MonitorResults = New-Object System.Collections.Generic.List[object]

foreach ($Monitor in $Monitors) {

    try {
        $ManufacturerID = (
            $Monitor.ManufacturerName |
            ForEach-Object { [char]$_ }
        ) -join ""

        $ProductCode = (
            $Monitor.ProductCodeID |
            ForEach-Object { [char]$_ }
        ) -join ""

        $SerialNumber = (
            $Monitor.SerialNumberID |
            ForEach-Object { [char]$_ }
        ) -join ""

        $UserFriendlyName = (
            $Monitor.UserFriendlyName |
            ForEach-Object { [char]$_ }
        ) -join ""

        $MonitorResults.Add([PSCustomObject]@{
            Manufacturer = if ($ManufacturerID) { $ManufacturerID } else { "Not Available" }
            ProductCode = if ($ProductCode) { $ProductCode } else { "Not Available" }
            SerialNumber = if ($SerialNumber) { $SerialNumber } else { "Not Available" }
            Name = if ($UserFriendlyName) { $UserFriendlyName } else { "Not Available" }
        })
    }
    catch {
    }
}

# ============================================================================
# SECTION 8 - DIRECTX INFORMATION
# ============================================================================

$DxDiagPath = Join-Path $env:TEMP "GPU_DxDiag_$([guid]::NewGuid().ToString()).txt"

try {
    Start-Process `
        -FilePath "dxdiag.exe" `
        -ArgumentList "/t `"$DxDiagPath`"" `
        -Wait `
        -WindowStyle Hidden

    if (Test-Path $DxDiagPath) {
        $DxDiagText = Get-Content $DxDiagPath -Raw
    }
    else {
        $DxDiagText = ""
    }
}
catch {
    $DxDiagText = ""
}

$DxDiagVersion = "Not Available"
$DxDiagWHQL = "Not Available"

if ($DxDiagText) {

    $DxMatch = [regex]::Match(
        $DxDiagText,
        "DirectX Version:\s*(.+)"
    )

    if ($DxMatch.Success) {
        $DxDiagVersion = $DxMatch.Groups[1].Value.Trim()
    }

    $WHQLMatch = [regex]::Match(
        $DxDiagText,
        "WHQL Logo'd:\s*(.+)"
    )

    if ($WHQLMatch.Success) {
        $DxDiagWHQL = $WHQLMatch.Groups[1].Value.Trim()
    }
}

try {
    Remove-Item $DxDiagPath -Force
}
catch {
}

# ============================================================================
# SECTION 9 - GPU PERFORMANCE COUNTERS
# ============================================================================

$GPUCounterResults = New-Object System.Collections.Generic.List[object]

try {

    $GPUCounters = Get-Counter `
        '\GPU Engine(*)\Utilization Percentage' `
        -ErrorAction Stop

    foreach ($Counter in $GPUCounters.CounterSamples) {

        $GPUCounterResults.Add([PSCustomObject]@{
            InstanceName = $Counter.InstanceName
            UtilizationPercentage = [math]::Round($Counter.CookedValue, 2)
        })
    }
}
catch {
}

# ============================================================================
# SECTION 10 - GPU MEMORY PERFORMANCE
# ============================================================================

$GPUProcessMemory = New-Object System.Collections.Generic.List[object]

try {

    $MemoryCounters = Get-Counter `
        '\GPU Process Memory(*)\Dedicated Usage' `
        -ErrorAction Stop

    foreach ($Counter in $MemoryCounters.CounterSamples) {

        if ($Counter.CookedValue -gt 0) {

            $GPUProcessMemory.Add([PSCustomObject]@{
                InstanceName = $Counter.InstanceName
                DedicatedUsageGB = [math]::Round(
                    ($Counter.CookedValue / 1GB),
                    3
                )
            })
        }
    }
}
catch {
}

# ============================================================================
# SECTION 11 - GPU TEMPERATURE
# ============================================================================

$TemperatureResults = New-Object System.Collections.Generic.List[object]

$TemperatureSources = @(
    "MSAcpi_ThermalZoneTemperature",
    "Win32_TemperatureProbe"
)

foreach ($Source in $TemperatureSources) {

    try {

        if ($Source -eq "MSAcpi_ThermalZoneTemperature") {

            $Zones = Get-CimInstance `
                -Namespace root/wmi `
                -ClassName MSAcpi_ThermalZoneTemperature

            foreach ($Zone in $Zones) {

                if ($Zone.CurrentTemperature) {

                    $Celsius = ($Zone.CurrentTemperature / 10) - 273.15

                    if ($Celsius -gt -50 -and $Celsius -lt 150) {

                        $TemperatureResults.Add([PSCustomObject]@{
                            Source = $Source
                            Name = Format-Value $Zone.InstanceName
                            TemperatureC = [math]::Round($Celsius, 1)
                        })
                    }
                }
            }
        }

        if ($Source -eq "Win32_TemperatureProbe") {

            $Probes = Get-CimInstance Win32_TemperatureProbe

            foreach ($Probe in $Probes) {

                $TemperatureResults.Add([PSCustomObject]@{
                    Source = $Source
                    Name = Format-Value $Probe.Name
                    TemperatureC = Format-Value $Probe.CurrentReading
                })
            }
        }
    }
    catch {
    }
}

# ============================================================================
# SECTION 12 - DISPLAY DRIVER STATUS
# ============================================================================

$DisplayDriverIssues = @()

foreach ($GPU in $GPUs) {

    if ($GPU.ConfigManagerErrorCode -and
        $GPU.ConfigManagerErrorCode -ne 0) {

        $DisplayDriverIssues += [PSCustomObject]@{
            GPU = Format-Value $GPU.Name
            ErrorCode = $GPU.ConfigManagerErrorCode
            Status = "Problem Detected"
        }
    }
}

# ============================================================================
# SECTION 13 - GRAPHICS-RELATED DEVICE ERRORS
# ============================================================================

$DeviceErrors = @()

try {

    $DeviceErrors = @(Get-CimInstance Win32_PnPEntity |
        Where-Object {
            $_.ConfigManagerErrorCode -and
            $_.ConfigManagerErrorCode -ne 0 -and
            (
                $_.Name -match "Display|Graphics|Video|GPU|NVIDIA|AMD|Radeon|Intel"
            )
        } |
        Select-Object Name, Status, ConfigManagerErrorCode, PNPDeviceID
    )
}
catch {
}

# ============================================================================
# SECTION 14 - RECENT GRAPHICS-RELATED SYSTEM EVENTS
# ============================================================================

$GraphicsEvents = @()

try {

    $GraphicsEvents = @(
        Get-WinEvent `
            -FilterHashtable @{
                LogName = "System"
                StartTime = (Get-Date).AddDays(-30)
            } `
            -ErrorAction Stop |
        Where-Object {

            $_.ProviderName -match `
                "Display|nvlddmkm|amdwddmg|amdkmdag|igfx|Graphics|dxgkrnl|Kernel-PnP"

        } |
        Select-Object `
            TimeCreated,
            Id,
            LevelDisplayName,
            ProviderName,
            Message
    )
}
catch {
}

# ============================================================================
# SECTION 15 - DISPLAY DRIVER TIMEOUT / RESET EVENTS
# ============================================================================

$DisplayTimeoutEvents = @()

try {

    $DisplayTimeoutEvents = @(
        Get-WinEvent `
            -FilterHashtable @{
                LogName = "System"
                StartTime = (Get-Date).AddDays(-30)
            } `
            -ErrorAction Stop |
        Where-Object {
            $_.Id -in @(4101, 14, 13, 0x141, 0x117)
        } |
        Select-Object `
            TimeCreated,
            Id,
            LevelDisplayName,
            ProviderName,
            Message
    )
}
catch {
}

# ============================================================================
# SECTION 16 - WHEA HARDWARE EVENTS
# ============================================================================

$WHEAEvents = @()

try {

    $WHEAEvents = @(
        Get-WinEvent `
            -FilterHashtable @{
                LogName = "System"
                StartTime = (Get-Date).AddDays(-30)
            } `
            -ErrorAction Stop |
        Where-Object {
            $_.ProviderName -match "WHEA-Logger"
        } |
        Select-Object `
            TimeCreated,
            Id,
            LevelDisplayName,
            ProviderName,
            Message
    )
}
catch {
}

# ============================================================================
# SECTION 17 - GPU POWER / ENERGY INFORMATION
# ============================================================================

$PowerInformation = @()

try {

    $PowerInformation = @(
        Get-Counter `
            '\GPU Engine(*)\Utilization Percentage' `
            -ErrorAction Stop |
        Select-Object -ExpandProperty CounterSamples |
        Where-Object {
            $_.CookedValue -gt 0
        } |
        ForEach-Object {

            [PSCustomObject]@{
                InstanceName = $_.InstanceName
                UtilizationPercentage = [math]::Round($_.CookedValue, 2)
            }
        }
    )
}
catch {
}

# ============================================================================
# SECTION 18 - GPU CAPABILITY CLASSIFICATION
# ============================================================================

$CapabilityResults = New-Object System.Collections.Generic.List[object]

foreach ($GPU in $GPUs) {

    $NameLower = (Format-Value $GPU.Name).ToLower()

    $Class = "General Graphics"

    if (
        $NameLower -match "rtx|quadro|tesla|a[0-9]{2,3}|radeon pro|firepro|arc pro"
    ) {
        $Class = "Professional / High-End Capable GPU"
    }
    elseif (
        $NameLower -match "gtx|rx [4-9][0-9]{2,3}|radeon [5-9][0-9]{2,3}|arc "
    ) {
        $Class = "Dedicated Performance GPU"
    }
    elseif (
        $NameLower -match "iris|uhd|intel hd|vega|radeon graphics|graphics"
    ) {
        $Class = "Integrated / General-Purpose Graphics"
    }

    $CapabilityResults.Add([PSCustomObject]@{
        GPU = Format-Value $GPU.Name
        Classification = $Class
        DirectXInformation = $DxDiagVersion
        CurrentResolution = if ($GPU.CurrentHorizontalResolution -and
                                $GPU.CurrentVerticalResolution) {
            "$($GPU.CurrentHorizontalResolution)x$($GPU.CurrentVerticalResolution)"
        }
        else {
            "Not Available"
        }
        CurrentRefreshRate = if ($GPU.CurrentRefreshRate) {
            "$($GPU.CurrentRefreshRate) Hz"
        }
        else {
            "Not Available"
        }
        DedicatedMemory = Convert-BytesToGB $GPU.DedicatedVideoMemory
        SharedMemory = Convert-BytesToGB $GPU.SharedSystemMemory
    })
}

# ============================================================================
# SECTION 19 - HEALTH / STATUS EVALUATION
# ============================================================================

$Problems = New-Object System.Collections.Generic.List[string]
$Warnings = New-Object System.Collections.Generic.List[string]
$Information = New-Object System.Collections.Generic.List[string]

if ($GPUs.Count -eq 0) {

    $Problems.Add(
        "No graphics adapter was detected through Win32_VideoController."
    )
}
else {

    foreach ($GPU in $GPUs) {

        if ($GPU.Status -and $GPU.Status -notmatch "^OK$") {

            $Problems.Add(
                "GPU status is not reported as OK: $($GPU.Name) - $($GPU.Status)"
            )
        }

        if ($GPU.ConfigManagerErrorCode -and
            $GPU.ConfigManagerErrorCode -ne 0) {

            $Problems.Add(
                "GPU device manager error detected: $($GPU.Name) - Error Code $($GPU.ConfigManagerErrorCode)"
            )
        }

        if (-not $GPU.DriverVersion) {

            $Warnings.Add(
                "GPU driver version is not available for: $($GPU.Name)"
            )
        }
    }
}

if ($DisplayDriverIssues.Count -gt 0) {

    $Problems.Add(
        "One or more graphics adapters report a non-zero device configuration error."
    )
}

if ($DeviceErrors.Count -gt 0) {

    $Problems.Add(
        "One or more graphics-related Plug and Play devices report configuration errors."
    )
}

if ($DisplayTimeoutEvents.Count -gt 0) {

    $Warnings.Add(
        "$($DisplayTimeoutEvents.Count) display timeout/reset-related event(s) were detected in the last 30 days."
    )
}

if ($WHEAEvents.Count -gt 0) {

    $Warnings.Add(
        "$($WHEAEvents.Count) WHEA hardware event(s) were detected in the last 30 days. These require contextual review."
    )
}

if ($TemperatureResults.Count -eq 0) {

    $Information.Add(
        "GPU-specific temperature telemetry is not available through the standard Windows interfaces."
    )
}

if ($GPUCounterResults.Count -eq 0) {

    $Information.Add(
        "GPU performance-counter telemetry is not available through the current Windows performance-counter interface."
    )
}

$OverallStatus = "PASS"

if ($Problems.Count -gt 0) {
    $OverallStatus = "REVIEW"
}
elseif ($Warnings.Count -gt 0) {
    $OverallStatus = "PASS WITH WARNINGS"
}

# ============================================================================
# SECTION 20 - HUMAN-READABLE REPORT
# ============================================================================

Add-ReportLine "SYSTEM HEALTH AND QUALITY ASSESSMENT"
Add-ReportLine "Module: 06 - GPU Status, Power, Capability and Health Validation"
Add-ReportLine "Version: 1.0"
Add-ReportLine "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

Add-Section "SYSTEM IDENTIFICATION"

Add-ReportLine "Computer Name : $ComputerName"
Add-ReportLine "Manufacturer  : $Manufacturer"
Add-ReportLine "Model         : $Model"
Add-ReportLine "Operating Sys : $OSName"
Add-ReportLine "OS Version    : $OSVersion"
Add-ReportLine "OS Build      : $OSBuild"

Add-Section "GPU INVENTORY"

if ($GPUResults.Count -eq 0) {

    Add-ReportLine "No GPU detected."
}
else {

    $Index = 1

    foreach ($GPU in $GPUResults) {

        Add-ReportLine ""
        Add-ReportLine "GPU #$Index"
        Add-ReportLine "Name                    : $($GPU.Name)"
        Add-ReportLine "Manufacturer            : $($GPU.Manufacturer)"
        Add-ReportLine "Status                  : $($GPU.Status)"
        Add-ReportLine "Availability            : $($GPU.Availability)"
        Add-ReportLine "Video Processor         : $($GPU.VideoProcessor)"
        Add-ReportLine "Driver Version          : $($GPU.DriverVersion)"
        Add-ReportLine "Driver Date             : $($GPU.DriverDate)"
        Add-ReportLine "Dedicated Video Memory  : $($GPU.DedicatedVideoMemory)"
        Add-ReportLine "Shared System Memory    : $($GPU.SharedSystemMemory)"
        Add-ReportLine "Current Resolution      : $($GPU.CurrentHorizontalRes)x$($GPU.CurrentVerticalRes)"
        Add-ReportLine "Current Refresh Rate    : $($GPU.CurrentRefreshRate) Hz"
        Add-ReportLine "Current Bits Per Pixel  : $($GPU.CurrentBitsPerPixel)"
        Add-ReportLine "Configuration Error     : $($GPU.ConfigManagerErrorCode)"
        Add-ReportLine "INF File                : $($GPU.InfFilename)"
        Add-ReportLine "INF Section             : $($GPU.InfSection)"

        $Index++
    }
}

Add-Section "DISPLAY / MONITOR INVENTORY"

if ($MonitorResults.Count -eq 0) {

    Add-ReportLine "Monitor identification information is not available."
}
else {

    $Index = 1

    foreach ($Monitor in $MonitorResults) {

        Add-ReportLine ""
        Add-ReportLine "Monitor #$Index"
        Add-ReportLine "Manufacturer : $($Monitor.Manufacturer)"
        Add-ReportLine "Product Code : $($Monitor.ProductCode)"
        Add-ReportLine "Name         : $($Monitor.Name)"
        Add-ReportLine "Serial       : $($Monitor.SerialNumber)"

        $Index++
    }
}

Add-Section "DIRECTX INFORMATION"

Add-ReportLine "DirectX Version : $DxDiagVersion"
Add-ReportLine "WHQL Information: $DxDiagWHQL"

Add-Section "GPU PERFORMANCE TELEMETRY"

if ($GPUCounterResults.Count -eq 0) {

    Add-ReportLine "GPU utilization telemetry is not available."
}
else {

    foreach ($Counter in $GPUCounterResults) {

        Add-ReportLine (
            "{0} : {1:N2}%" -f
            $Counter.InstanceName,
            $Counter.UtilizationPercentage
        )
    }
}

Add-Section "GPU PROCESS MEMORY"

if ($GPUProcessMemory.Count -eq 0) {

    Add-ReportLine "No active GPU process-memory usage was reported."
}
else {

    foreach ($Memory in $GPUProcessMemory) {

        Add-ReportLine (
            "{0} : {1:N3} GB" -f
            $Memory.InstanceName,
            $Memory.DedicatedUsageGB
        )
    }
}

Add-Section "GPU TEMPERATURE TELEMETRY"

if ($TemperatureResults.Count -eq 0) {

    Add-ReportLine "GPU-specific temperature telemetry is not available."
}
else {

    foreach ($Temperature in $TemperatureResults) {

        Add-ReportLine (
            "{0} | {1} | {2} C" -f
            $Temperature.Source,
            $Temperature.Name,
            $Temperature.TemperatureC
        )
    }
}

Add-Section "GPU CAPABILITY CLASSIFICATION"

foreach ($Capability in $CapabilityResults) {

    Add-ReportLine ""
    Add-ReportLine "GPU: $($Capability.GPU)"
    Add-ReportLine "Classification        : $($Capability.Classification)"
    Add-ReportLine "DirectX Information   : $($Capability.DirectXInformation)"
    Add-ReportLine "Current Resolution    : $($Capability.CurrentResolution)"
    Add-ReportLine "Current Refresh Rate  : $($Capability.CurrentRefreshRate)"
    Add-ReportLine "Dedicated Memory      : $($Capability.DedicatedMemory)"
    Add-ReportLine "Shared System Memory  : $($Capability.SharedMemory)"
}

Add-Section "GRAPHICS DEVICE ERRORS"

if ($DeviceErrors.Count -eq 0) {

    Add-ReportLine "No graphics-related Plug and Play device configuration errors were detected."
}
else {

    foreach ($ErrorItem in $DeviceErrors) {

        Add-ReportLine ""
        Add-ReportLine "Device       : $($ErrorItem.Name)"
        Add-ReportLine "Status       : $($ErrorItem.Status)"
        Add-ReportLine "Error Code   : $($ErrorItem.ConfigManagerErrorCode)"
        Add-ReportLine "PNP Device ID: $($ErrorItem.PNPDeviceID)"
    }
}

Add-Section "DISPLAY TIMEOUT / RESET EVENTS - LAST 30 DAYS"

if ($DisplayTimeoutEvents.Count -eq 0) {

    Add-ReportLine "No matching display timeout/reset events were detected."
}
else {

    foreach ($Event in $DisplayTimeoutEvents) {

        Add-ReportLine ""
        Add-ReportLine "Time     : $($Event.TimeCreated)"
        Add-ReportLine "Event ID : $($Event.Id)"
        Add-ReportLine "Level    : $($Event.LevelDisplayName)"
        Add-ReportLine "Provider : $($Event.ProviderName)"
        Add-ReportLine "Message  : $($Event.Message)"
    }
}

Add-Section "WHEA HARDWARE EVENTS - LAST 30 DAYS"

if ($WHEAEvents.Count -eq 0) {

    Add-ReportLine "No WHEA hardware events were detected."
}
else {

    foreach ($Event in $WHEAEvents) {

        Add-ReportLine ""
        Add-ReportLine "Time     : $($Event.TimeCreated)"
        Add-ReportLine "Event ID : $($Event.Id)"
        Add-ReportLine "Level    : $($Event.LevelDisplayName)"
        Add-ReportLine "Provider : $($Event.ProviderName)"
        Add-ReportLine "Message  : $($Event.Message)"
    }
}

Add-Section "PROBLEMS"

if ($Problems.Count -eq 0) {

    Add-ReportLine "No actionable GPU problem was detected."
}
else {

    $Number = 1

    foreach ($Problem in $Problems) {

        Add-ReportLine "$Number. $Problem"
        $Number++
    }
}

Add-Section "WARNINGS"

if ($Warnings.Count -eq 0) {

    Add-ReportLine "No GPU-related warnings were detected."
}
else {

    $Number = 1

    foreach ($Warning in $Warnings) {

        Add-ReportLine "$Number. $Warning"
        $Number++
    }
}

Add-Section "INFORMATION"

if ($Information.Count -eq 0) {

    Add-ReportLine "No additional information."
}
else {

    $Number = 1

    foreach ($Info in $Information) {

        Add-ReportLine "$Number. $Info"
        $Number++
    }
}

Add-Section "FINAL STATUS"

Add-ReportLine "Overall GPU Assessment: $OverallStatus"

Add-ReportLine ""
Add-ReportLine "Interpretation:"
Add-ReportLine "PASS means no actionable GPU-related problem was detected through"
Add-ReportLine "the Windows hardware, driver, event-log and telemetry interfaces"
Add-ReportLine "used by this module."
Add-ReportLine ""
Add-ReportLine "PASS does NOT mathematically prove physical GPU health."
Add-ReportLine "Physical defects, intermittent faults, thermal problems not exposed"
Add-ReportLine "to Windows, VRAM errors, or load-dependent instability may require"
Add-ReportLine "specialized vendor diagnostics or controlled testing."

Add-ReportLine ""
Add-ReportLine "This module does not perform:"
Add-ReportLine "- GPU stress testing"
Add-ReportLine "- Overclocking"
Add-ReportLine "- Undervolting"
Add-ReportLine "- BIOS modification"
Add-ReportLine "- Driver installation"
Add-ReportLine "- Driver replacement"
Add-ReportLine "- Performance benchmarking"

# ============================================================================
# SECTION 21 - SAVE TXT REPORT
# ============================================================================

try {

    $Report |
        Set-Content `
            -Path $ReportTXT `
            -Encoding UTF8 `
            -Force
}
catch {

    Write-Host ""
    Write-Host "ERROR: Could not save the TXT report." -ForegroundColor Red
}

# ============================================================================
# SECTION 22 - JSON REPORT
# ============================================================================

$JSONReport = [ordered]@{

    Project = "System Health and Quality Assessment"

    Module = [ordered]@{
        ID = "06"
        Name = "GPU Status, Power, Capability and Health Validation"
        Version = "1.0"
    }

    Generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    System = [ordered]@{
        ComputerName = $ComputerName
        Manufacturer = $Manufacturer
        Model = $Model
        OperatingSystem = $OSName
        OSVersion = $OSVersion
        OSBuild = $OSBuild
    }

    GPUs = $GPUResults

    Monitors = $MonitorResults

    DirectX = [ordered]@{
        Version = $DxDiagVersion
        WHQL = $DxDiagWHQL
    }

    GPUUtilization = $GPUCounterResults

    GPUProcessMemory = $GPUProcessMemory

    TemperatureTelemetry = $TemperatureResults

    Capability = $CapabilityResults

    GraphicsDeviceErrors = $DeviceErrors

    DisplayTimeoutEventsLast30Days = $DisplayTimeoutEvents

    WHEAEventsLast30Days = $WHEAEvents

    Problems = $Problems

    Warnings = $Warnings

    Information = $Information

    OverallStatus = $OverallStatus

    ImportantNote = @(
        "Software telemetry cannot mathematically prove physical GPU health.",
        "PASS means no actionable GPU-related problem was detected through the Windows interfaces used by this module.",
        "This module does not perform stress testing, overclocking, undervolting, BIOS changes, or driver installation."
    )
}

try {

    $JSONReport |
        ConvertTo-Json `
            -Depth 8 |
        Set-Content `
            -Path $ReportJSON `
            -Encoding UTF8 `
            -Force
}
catch {

    Write-Host ""
    Write-Host "WARNING: Could not save the JSON report." -ForegroundColor Yellow
}

# ============================================================================
# SECTION 23 - CONSOLE SUMMARY
# ============================================================================

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "SYSTEM HEALTH AND QUALITY ASSESSMENT" -ForegroundColor Cyan
Write-Host "MODULE 06 - GPU STATUS, POWER, CAPABILITY AND HEALTH VALIDATION" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Computer       : $ComputerName"
Write-Host "Manufacturer   : $Manufacturer"
Write-Host "Model          : $Model"
Write-Host "GPU Count      : $($GPUs.Count)"
Write-Host ""

if ($GPUs.Count -gt 0) {

    foreach ($GPU in $GPUs) {

        Write-Host "GPU            : $($GPU.Name)"
        Write-Host "Driver Version : $($GPU.DriverVersion)"
        Write-Host "Driver Date    : $($GPU.DriverDate)"
        Write-Host "Status         : $($GPU.Status)"
        Write-Host "Dedicated RAM  : $(Convert-BytesToGB $GPU.DedicatedVideoMemory)"
        Write-Host "Shared RAM     : $(Convert-BytesToGB $GPU.SharedSystemMemory)"
        Write-Host ""
    }
}

Write-Host "DirectX        : $DxDiagVersion"
Write-Host "GPU Telemetry  : $($GPUCounterResults.Count) counter(s)"
Write-Host "Temp Telemetry : $($TemperatureResults.Count) reading(s)"
Write-Host "GPU Errors     : $($Problems.Count)"
Write-Host "Warnings       : $($Warnings.Count)"
Write-Host ""

if ($OverallStatus -eq "PASS") {

    Write-Host "OVERALL STATUS : PASS" -ForegroundColor Green
}
elseif ($OverallStatus -eq "PASS WITH WARNINGS") {

    Write-Host "OVERALL STATUS : PASS WITH WARNINGS" -ForegroundColor Yellow
}
else {

    Write-Host "OVERALL STATUS : REVIEW REQUIRED" -ForegroundColor Red
}

Write-Host ""
Write-Host "TXT Report  : $ReportTXT"
Write-Host "JSON Report : $ReportJSON"

Write-Host ""
Write-Host "No GPU stress test or configuration change was performed."
Write-Host "PASS does not constitute proof of physical GPU health."

# ============================================================================
# SECTION 24 - THREE SEPARATE ENTER PRESSES
# ============================================================================

Write-Host ""
Read-Host "Press Enter once to finish"

Write-Host ""
Read-Host "Press Enter a second time to finish"

Write-Host ""
Read-Host "Press Enter a third time to finish"

# ============================================================================
# END OF MODULE 06
# ============================================================================