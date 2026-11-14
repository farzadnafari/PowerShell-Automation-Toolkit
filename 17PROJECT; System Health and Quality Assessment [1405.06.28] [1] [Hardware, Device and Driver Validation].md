
> [!INFO] اعتبارسنجی سخت‌افزار، دستگاه‌ها و درایورهای ویندوز
> تمامی دستگاه‌های سخت‌افزاری شناسایی‌شده توسط سیستم و تجهیزات متصل را به‌صورت پویا بررسی می‌کند.
> وضعیت عملکرد دستگاه‌ها و کدهای خطای گزارش‌شده توسط Windows را استخراج و ارزیابی می‌کند.
> دستگاه‌های ناشناخته، غیرفعال و دارای مشکل سخت‌افزاری یا شناسایی را شناسایی می‌کند.
> اطلاعات درایورها شامل سازنده، نسخه، تاریخ انتشار و مشخصات فایل INF را جمع‌آوری می‌کند.
> کلاس‌های مختلف سخت‌افزاری شامل GPU، نمایشگر، صدا، میکروفون، شبکه و Bluetooth را بررسی می‌کند.
> کنترلرها و تجهیزات USB، حافظه‌های ذخیره‌سازی، دوربین‌ها و دستگاه‌های تصویربرداری را ارزیابی می‌کند.
> دستگاه‌های سیستمی، HID، چاپگرها و سایر تجهیزات Plug and Play را بررسی می‌کند.
> رویدادهای مرتبط با دستگاه‌ها و درایورها را در گزارش‌های Windows Event Log بررسی می‌کند.
> سلامت واقعی دستگاه‌ها را بر اساس وضعیت و کدهای خطا ارزیابی می‌کند و صرفاً نصب بودن درایور را نشانه سلامت نمی‌داند.
> صرفاً اطلاعات تشخیصی جمع‌آوری می‌کند و هیچ درایور یا تنظیمات سخت‌افزاری را تغییر نمی‌دهد.


> [!INFO] Hardware, Device And Driver Validation
> Dynamically Inspects All Hardware Devices Detected By Windows And Connected Equipment.
> Collects And Evaluates Device Operational Status And Windows-Reported Problem Codes.
> Identifies Unknown, Disabled, And Hardware Devices With Detection Or Operational Problems.
> Collects Driver Information Including Provider, Version, Release Date, And INF File Details.
> Examines Different Hardware Categories Including GPU, Display, Audio, Microphone, Network, And Bluetooth.
> Evaluates USB Controllers And Devices, Storage Devices, Cameras, And Imaging Equipment.
> Inspects System Devices, HID Devices, Printers, And Other Plug And Play Hardware.
> Examines Windows Event Logs For Relevant Device And Driver Events.
> Evaluates Actual Device Health Using Operational Status And Problem Codes Instead Of Assuming Installed Drivers Indicate Healthy Hardware.
> Collects Diagnostic Information Only And Does Not Modify Drivers Or Hardware Configuration.


```
# ============================================================================
# PROJECT
# ============================================================================
# Project Name : System Health and Quality Assessment
# Module       : 04 - Hardware, Device and Driver Validation
# Version      : 1.0
#
# PURPOSE
# -------
# Dynamically inspect the hardware devices and installed drivers of the
# current Windows computer.
#
# This module checks:
#   - Plug and Play device detection
#   - Device status
#   - Device problem codes
#   - Unknown devices
#   - Disabled devices
#   - Driver provider
#   - Driver version
#   - Driver date
#   - Driver INF information
#   - Device classes
#   - Display / GPU devices
#   - Audio devices
#   - Microphone / capture devices
#   - USB devices and controllers
#   - Network adapters
#   - Bluetooth devices
#   - Storage devices and controllers
#   - Cameras / imaging devices
#   - System devices
#   - HID devices
#   - Printers
#   - Relevant device-related Windows events
#
# IMPORTANT
# ---------
# This script is diagnostic only.
# It does NOT:
#   - Install drivers
#   - Update drivers
#   - Remove drivers
#   - Disable devices
#   - Enable devices
#   - Modify hardware configuration
#
# A driver being installed does not automatically mean that the hardware
# is fully healthy. This module therefore evaluates device status and
# Windows-reported problem codes separately from driver presence.
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
        Read-Host "Press Enter again to confirm exit"
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
$ModuleName  = "04 - Hardware, Device and Driver Validation"
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

$ReportBaseName = "04_Hardware_Device_and_Driver_Validation"

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

function Get-DeviceClassName {

    param(
        [string]$Class
    )

    if ([string]::IsNullOrWhiteSpace($Class)) {

        return "Unknown"
    }

    return $Class
}

function Get-DeviceProblemDescription {

    param(
        [int]$Code
    )

    switch ($Code) {

        0  { return "No problem" }
        1  { return "Device is not configured correctly" }
        2  { return "Windows cannot load the driver" }
        3  { return "Driver may be corrupted or system resources may be insufficient" }
        4  { return "Device is not functioning correctly" }
        5  { return "Device requires additional resources" }
        6  { return "Configuration conflict" }
        7  { return "Device cannot be filtered" }
        8  { return "Driver loader failed" }
        9  { return "Device is not responding" }
        10 { return "Device cannot start" }
        11 { return "Device failed" }
        12 { return "Device cannot find sufficient resources" }
        13 { return "Windows cannot verify required resources" }
        14 { return "Device requires restart" }
        15 { return "Device is not present or not functioning" }
        16 { return "Device is not configured correctly" }
        17 { return "Device driver installation is incomplete" }
        18 { return "Driver reinstallation required" }
        19 { return "Device registry configuration problem" }
        20 { return "VxD loader failure" }
        21 { return "System failure; restart required" }
        22 { return "Device is disabled" }
        23 { return "System resource conflict" }
        24 { return "Device is not present, malfunctioning, or driver is incomplete" }
        25 { return "Windows is still setting up the device" }
        26 { return "Windows is still setting up the device" }
        27 { return "Device does not have a valid log configuration" }
        28 { return "Device drivers are not installed" }
        29 { return "Device is disabled by firmware" }
        30 { return "Device is using an IRQ resource that another device is using" }
        31 { return "Windows cannot load the required drivers" }

        default {
            return "Unknown device problem code"
        }
    }
}


# ============================================================================
# SECTION 5 - SYSTEM IDENTIFICATION
# ============================================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " $ProjectName" -ForegroundColor Cyan
Write-Host " $ModuleName" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$OS = $null
$ComputerSystem = $null

try {

    $OS = Get-CimInstance `
        -ClassName Win32_OperatingSystem `
        -ErrorAction Stop
}
catch {

    Add-Issue "Unable to read operating system information."
}

try {

    $ComputerSystem = Get-CimInstance `
        -ClassName Win32_ComputerSystem `
        -ErrorAction Stop
}
catch {

    Add-Issue "Unable to read computer system information."
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

    Version = if ($OS) {
        $OS.Version
    }
    else {
        "Unknown"
    }

    Build = if ($OS) {
        $OS.BuildNumber
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
# SECTION 6 - COMPLETE PNP DEVICE INVENTORY
# ============================================================================

Write-Host "[1/10] Enumerating Plug and Play devices..." -ForegroundColor White

$PnPDevices = @()

try {

    $RawDevices = Get-CimInstance `
        -ClassName Win32_PnPEntity `
        -ErrorAction Stop

    foreach ($Device in $RawDevices) {

        $ProblemCode = 0

        if ($null -ne $Device.ConfigManagerErrorCode) {

            $ProblemCode = [int]$Device.ConfigManagerErrorCode
        }

        $StatusText = if ($ProblemCode -eq 0) {
            "OK"
        }
        else {
            "PROBLEM"
        }

        $PnPDevices += [PSCustomObject]@{

            Name                  = $Device.Name
            Caption               = $Device.Caption
            DeviceID              = $Device.DeviceID
            PNPClass              = Get-DeviceClassName $Device.PNPClass
            Manufacturer          = $Device.Manufacturer
            Status                = $StatusText
            ConfigManagerErrorCode = $ProblemCode
            ProblemDescription    = Get-DeviceProblemDescription $ProblemCode
            Present               = $Device.Present
            Service               = $Device.Service
            DriverVersion         = $Device.DriverVersion
            DriverDate            = $Device.DriverDate
            INFName               = $Device.INFName
            CompatibleID         = if ($Device.CompatibleID) {
                ($Device.CompatibleID -join "; ")
            }
            else {
                ""
            }
            HardwareID            = if ($Device.HardwareID) {
                ($Device.HardwareID -join "; ")
            }
            else {
                ""
            }
        }
    }
}
catch {

    Add-Issue "Unable to enumerate Plug and Play devices."
}


# ============================================================================
# SECTION 7 - DEVICE STATUS ANALYSIS
# ============================================================================

$ProblemDevices = @(
    $PnPDevices |
    Where-Object {
        $_.ConfigManagerErrorCode -ne 0
    }
)

$DisabledDevices = @(
    $PnPDevices |
    Where-Object {
        $_.ConfigManagerErrorCode -eq 22
    }
)

$UnknownDevices = @(
    $PnPDevices |
    Where-Object {
        $_.PNPClass -eq "Unknown" -or
        [string]::IsNullOrWhiteSpace($_.PNPClass)
    }
)

$MissingDriverDevices = @(
    $PnPDevices |
    Where-Object {
        $_.ConfigManagerErrorCode -eq 28
    }
)

$DriverProblemDevices = @(
    $PnPDevices |
    Where-Object {
        $_.ConfigManagerErrorCode -in @(
            2,3,4,8,10,11,17,18,19,24,28,31
        )
    }
)

if ($ProblemDevices.Count -gt 0) {

    Add-Issue (
        "Windows reports $($ProblemDevices.Count) device(s) " +
        "with non-zero ConfigManagerErrorCode."
    )
}

if ($MissingDriverDevices.Count -gt 0) {

    Add-Issue (
        "$($MissingDriverDevices.Count) device(s) " +
        "are reported without a required driver."
    )
}


# ============================================================================
# SECTION 8 - DEVICE CLASS SUMMARY
# ============================================================================

Write-Host "[2/10] Building device class summary..." -ForegroundColor White

$DeviceClassSummary = @(
    $PnPDevices |
    Group-Object PNPClass |
    Sort-Object Name |
    ForEach-Object {

        $ClassDevices = $_.Group

        [PSCustomObject]@{

            ClassName = $_.Name

            TotalDevices = $ClassDevices.Count

            HealthyDevices = @(
                $ClassDevices |
                Where-Object {
                    $_.ConfigManagerErrorCode -eq 0
                }
            ).Count

            ProblemDevices = @(
                $ClassDevices |
                Where-Object {
                    $_.ConfigManagerErrorCode -ne 0
                }
            ).Count

            DisabledDevices = @(
                $ClassDevices |
                Where-Object {
                    $_.ConfigManagerErrorCode -eq 22
                }
            ).Count
        }
    }
)


# ============================================================================
# SECTION 9 - DISPLAY / GPU DEVICES
# ============================================================================

Write-Host "[3/10] Checking display and graphics devices..." -ForegroundColor White

$DisplayDevices = @()

try {

    $DisplayDevices = Get-CimInstance `
        -ClassName Win32_VideoController `
        -ErrorAction Stop |
        ForEach-Object {

            [PSCustomObject]@{

                Name                = $_.Name
                AdapterCompatibility = $_.AdapterCompatibility
                VideoProcessor      = $_.VideoProcessor
                DriverVersion       = $_.DriverVersion
                DriverDate          = $_.DriverDate
                AdapterRAM          = $_.AdapterRAM
                VideoModeDescription = $_.VideoModeDescription
                CurrentHorizontalResolution = $_.CurrentHorizontalResolution
                CurrentVerticalResolution   = $_.CurrentVerticalResolution
                CurrentRefreshRate          = $_.CurrentRefreshRate
                Status              = $_.Status
                Availability        = $_.Availability
                PNPDeviceID         = $_.PNPDeviceID
                ConfigManagerErrorCode = $_.ConfigManagerErrorCode
            }
        }
}
catch {

    Add-Warning "Display adapter information could not be fully retrieved."
}


$DisplayProblems = @(
    $DisplayDevices |
    Where-Object {
        $_.ConfigManagerErrorCode -ne 0
    }
)

if ($DisplayProblems.Count -gt 0) {

    Add-Issue (
        "$($DisplayProblems.Count) display adapter(s) report a device problem."
    )
}


# ============================================================================
# SECTION 10 - AUDIO DEVICES
# ============================================================================

Write-Host "[4/10] Checking audio and microphone devices..." -ForegroundColor White

$AudioDevices = @()

try {

    $AudioDevices = @(
        $PnPDevices |
        Where-Object {

            $_.PNPClass -match `
                "MEDIA|Audio|AudioEndpoint"
        }
    )
}
catch {

    Add-Warning "Audio device information could not be fully classified."
}


$AudioProblems = @(
    $AudioDevices |
    Where-Object {
        $_.ConfigManagerErrorCode -ne 0
    }
)

if ($AudioProblems.Count -gt 0) {

    Add-Issue (
        "$($AudioProblems.Count) audio-related device(s) report a problem."
    )
}


# ============================================================================
# SECTION 11 - MICROPHONE / CAPTURE DEVICE DETECTION
# ============================================================================

$CaptureDevices = @()

try {

    $CaptureDevices = @(
        Get-CimInstance `
            -ClassName Win32_PnPEntity `
            -ErrorAction Stop |
        Where-Object {

            $_.Name -match `
                "Microphone|Mic|Audio Capture|Webcam|Camera|Integrated Camera|HD Camera"
        } |
        ForEach-Object {

            $ProblemCode = 0

            if ($null -ne $_.ConfigManagerErrorCode) {

                $ProblemCode = [int]$_.ConfigManagerErrorCode
            }

            [PSCustomObject]@{

                Name = $_.Name
                DeviceID = $_.DeviceID
                Manufacturer = $_.Manufacturer
                PNPClass = $_.PNPClass
                Status = if ($ProblemCode -eq 0) {
                    "OK"
                }
                else {
                    "PROBLEM"
                }
                ConfigManagerErrorCode = $ProblemCode
                ProblemDescription =
                    Get-DeviceProblemDescription $ProblemCode
                DriverVersion = $_.DriverVersion
                DriverDate = $_.DriverDate
            }
        }
    )
}
catch {

    Add-Warning "Microphone and capture-device enumeration was not fully available."
}


$CaptureProblems = @(
    $CaptureDevices |
    Where-Object {
        $_.ConfigManagerErrorCode -ne 0
    }
)

if ($CaptureProblems.Count -gt 0) {

    Add-Issue (
        "$($CaptureProblems.Count) microphone/capture-related " +
        "device(s) report a problem."
    )
}


# ============================================================================
# SECTION 12 - USB DEVICES
# ============================================================================

Write-Host "[5/10] Checking USB devices and controllers..." -ForegroundColor White

$USBDevices = @(
    $PnPDevices |
    Where-Object {

        $_.PNPClass -match "USB" -or
        $_.Name -match "USB"
    }
)

$USBProblems = @(
    $USBDevices |
    Where-Object {
        $_.ConfigManagerErrorCode -ne 0
    }
)

if ($USBProblems.Count -gt 0) {

    Add-Issue (
        "$($USBProblems.Count) USB-related device(s) report a problem."
    )
}


# ============================================================================
# SECTION 13 - NETWORK DEVICES
# ============================================================================

Write-Host "[6/10] Checking network adapters..." -ForegroundColor White

$NetworkDevices = @()

try {

    $NetworkDevices = Get-CimInstance `
        -ClassName Win32_NetworkAdapter `
        -ErrorAction Stop |
        ForEach-Object {

            [PSCustomObject]@{

                Name = $_.Name
                Manufacturer = $_.Manufacturer
                AdapterType = $_.AdapterType
                MACAddress = $_.MACAddress
                NetConnectionID = $_.NetConnectionID
                NetEnabled = $_.NetEnabled
                PhysicalAdapter = $_.PhysicalAdapter
                Speed = $_.Speed
                DriverVersion = $_.DriverVersion
                PNPDeviceID = $_.PNPDeviceID
                Status = $_.Status
                Availability = $_.Availability
            }
        }
}
catch {

    Add-Warning "Network adapter information could not be fully retrieved."
}


$NetworkPnPProblems = @(
    $PnPDevices |
    Where-Object {
        $_.PNPClass -match "NET" -and
        $_.ConfigManagerErrorCode -ne 0
    }
)

if ($NetworkPnPProblems.Count -gt 0) {

    Add-Issue (
        "$($NetworkPnPProblems.Count) network device(s) report a PnP problem."
    )
}


# ============================================================================
# SECTION 14 - BLUETOOTH DEVICES
# ============================================================================

Write-Host "[7/10] Checking Bluetooth devices..." -ForegroundColor White

$BluetoothDevices = @(
    $PnPDevices |
    Where-Object {

        $_.Name -match "Bluetooth" -or
        $_.PNPClass -match "Bluetooth"
    }
)

$BluetoothProblems = @(
    $BluetoothDevices |
    Where-Object {
        $_.ConfigManagerErrorCode -ne 0
    }
)

if ($BluetoothProblems.Count -gt 0) {

    Add-Issue (
        "$($BluetoothProblems.Count) Bluetooth-related device(s) report a problem."
    )
}


# ============================================================================
# SECTION 15 - STORAGE DEVICES
# ============================================================================

Write-Host "[8/10] Checking storage devices and controllers..." -ForegroundColor White

$StorageDevices = @()

try {

    $PhysicalDisks = Get-CimInstance `
        -ClassName Win32_DiskDrive `
        -ErrorAction Stop |
        ForEach-Object {

            [PSCustomObject]@{

                Model = $_.Model
                Manufacturer = $_.Manufacturer
                InterfaceType = $_.InterfaceType
                MediaType = $_.MediaType
                SerialNumber = $_.SerialNumber
                FirmwareRevision = $_.FirmwareRevision
                SizeGB = if ($_.Size) {
                    [Math]::Round(
                        ([double]$_.Size / 1GB),
                        2
                    )
                }
                else {
                    $null
                }
                Status = $_.Status
                PNPDeviceID = $_.PNPDeviceID
            }
        }

    $StorageDevices = $PhysicalDisks
}
catch {

    Add-Warning "Physical storage device information could not be fully retrieved."
}


$StoragePnPProblems = @(
    $PnPDevices |
    Where-Object {

        $_.PNPClass -match "DiskDrive|HDC|SCSIAdapter|Storage" -and
        $_.ConfigManagerErrorCode -ne 0
    }
)

if ($StoragePnPProblems.Count -gt 0) {

    Add-Issue (
        "$($StoragePnPProblems.Count) storage-related device(s) " +
        "report a PnP problem."
    )
}


# ============================================================================
# SECTION 16 - CAMERA / IMAGING DEVICES
# ============================================================================

$CameraDevices = @(
    $PnPDevices |
    Where-Object {

        $_.PNPClass -match "Image" -or
        $_.Name -match `
            "Camera|Webcam|Imaging Device|Integrated Camera|HD Camera"
    }
)

$CameraProblems = @(
    $CameraDevices |
    Where-Object {
        $_.ConfigManagerErrorCode -ne 0
    }
)

if ($CameraProblems.Count -gt 0) {

    Add-Issue (
        "$($CameraProblems.Count) camera/imaging device(s) report a problem."
    )
}


# ============================================================================
# SECTION 17 - HID DEVICES
# ============================================================================

$HIDDevices = @(
    $PnPDevices |
    Where-Object {

        $_.PNPClass -match "HID"
    }
)

$HIDProblems = @(
    $HIDDevices |
    Where-Object {
        $_.ConfigManagerErrorCode -ne 0
    }
)

if ($HIDProblems.Count -gt 0) {

    Add-Warning (
        "$($HIDProblems.Count) HID device(s) report a PnP problem."
    )
}


# ============================================================================
# SECTION 18 - SYSTEM DEVICES
# ============================================================================

$SystemDevices = @(
    $PnPDevices |
    Where-Object {

        $_.PNPClass -match "System"
    }
)

$SystemDeviceProblems = @(
    $SystemDevices |
    Where-Object {
        $_.ConfigManagerErrorCode -ne 0
    }
)

if ($SystemDeviceProblems.Count -gt 0) {

    Add-Issue (
        "$($SystemDeviceProblems.Count) system device(s) " +
        "report a PnP problem."
    )
}


# ============================================================================
# SECTION 19 - DRIVER INVENTORY
# ============================================================================

Write-Host "[9/10] Building driver inventory..." -ForegroundColor White

$DriverInventory = @()

try {

    $DriverInventory = Get-CimInstance `
        -ClassName Win32_PnPSignedDriver `
        -ErrorAction Stop |
        ForEach-Object {

            [PSCustomObject]@{

                DeviceName       = $_.DeviceName
                DeviceID         = $_.DeviceID
                DeviceClass      = $_.DeviceClass
                Manufacturer     = $_.Manufacturer
                DriverProvider   = $_.DriverProviderName
                DriverVersion    = $_.DriverVersion
                DriverDate       = $_.DriverDate
                InfName          = $_.InfName
                InfSection       = $_.InfSection
                IsSigned         = $_.IsSigned
                Signer           = $_.Signer
                DriverDescription = $_.DriverDescription
            }
        }
}
catch {

    Add-Warning "Signed driver inventory could not be completely retrieved."
}


$UnsignedDrivers = @(
    $DriverInventory |
    Where-Object {
        $_.IsSigned -eq $false
    }
)

if ($UnsignedDrivers.Count -gt 0) {

    Add-Warning (
        "$($UnsignedDrivers.Count) driver record(s) are reported as unsigned."
    )
}


# ============================================================================
# SECTION 20 - DRIVER DATE ANALYSIS
# ============================================================================

$DriversWithoutDate = @(
    $DriverInventory |
    Where-Object {
        [string]::IsNullOrWhiteSpace($_.DriverDate)
    }
)

if ($DriversWithoutDate.Count -gt 0) {

    Add-Warning (
        "$($DriversWithoutDate.Count) driver record(s) do not expose " +
        "a driver date through WMI."
    )
}


# ============================================================================
# SECTION 21 - DEVICE EVENT LOG
# ============================================================================

Write-Host "[10/10] Checking recent device-related events..." -ForegroundColor White

$DeviceEvents = @()

try {

    $RawDeviceEvents = Get-WinEvent `
        -FilterHashtable @{
            LogName = "System"
            StartTime = (Get-Date).AddDays(-30)
        } `
        -ErrorAction Stop |
        Where-Object {

            $_.ProviderName -match `
                "Kernel-PnP|UserPnp|DriverFrameworks|DeviceSetupManager"
        } |
        Select-Object -First 200

    foreach ($Event in $RawDeviceEvents) {

        $DeviceEvents += [PSCustomObject]@{

            TimeCreated = $Event.TimeCreated
            Id          = $Event.Id
            Level       = $Event.LevelDisplayName
            Provider    = $Event.ProviderName
            Message     = $Event.Message
        }
    }
}
catch {

    Add-Warning "Device-related Windows event logs could not be fully retrieved."
}


$CriticalDeviceEvents = @(
    $DeviceEvents |
    Where-Object {
        $_.Level -in @(
            "Error",
            "Critical"
        )
    }
)

if ($CriticalDeviceEvents.Count -gt 0) {

    Add-Warning (
        "$($CriticalDeviceEvents.Count) Error/Critical " +
        "device-related event(s) were found within the last 30 days."
    )
}


# ============================================================================
# SECTION 22 - DRIVERSTORE / SIGNED DRIVER PACKAGE SUMMARY
# ============================================================================

$DriverPackageSummary = @()

try {

    $DriverPackages = Get-CimInstance `
        -ClassName Win32_PnPSignedDriver `
        -ErrorAction Stop

    $DriverPackageSummary = @(
        $DriverPackages |
        Group-Object DriverProviderName |
        Sort-Object Count -Descending |
        ForEach-Object {

            [PSCustomObject]@{

                Provider = $_.Name
                DriverCount = $_.Count
            }
        }
    )
}
catch {

    Add-Warning "Driver provider summary could not be generated."
}


# ============================================================================
# SECTION 23 - DEVICE CATEGORY SUMMARY
# ============================================================================

$CategoryChecks = [ordered]@{

    Display = [ordered]@{
        Total = $DisplayDevices.Count
        Problems = $DisplayProblems.Count
        Status = if ($DisplayProblems.Count -eq 0) {
            "OK"
        }
        else {
            "REVIEW"
        }
    }

    Audio = [ordered]@{
        Total = $AudioDevices.Count
        Problems = $AudioProblems.Count
        Status = if ($AudioProblems.Count -eq 0) {
            "OK"
        }
        else {
            "REVIEW"
        }
    }

    MicrophoneCapture = [ordered]@{
        Total = $CaptureDevices.Count
        Problems = $CaptureProblems.Count
        Status = if ($CaptureProblems.Count -eq 0) {
            "OK"
        }
        else {
            "REVIEW"
        }
    }

    USB = [ordered]@{
        Total = $USBDevices.Count
        Problems = $USBProblems.Count
        Status = if ($USBProblems.Count -eq 0) {
            "OK"
        }
        else {
            "REVIEW"
        }
    }

    Network = [ordered]@{
        Total = $NetworkDevices.Count
        Problems = $NetworkPnPProblems.Count
        Status = if ($NetworkPnPProblems.Count -eq 0) {
            "OK"
        }
        else {
            "REVIEW"
        }
    }

    Bluetooth = [ordered]@{
        Total = $BluetoothDevices.Count
        Problems = $BluetoothProblems.Count
        Status = if ($BluetoothProblems.Count -eq 0) {
            "OK"
        }
        else {
            "REVIEW"
        }
    }

    Storage = [ordered]@{
        Total = $StorageDevices.Count
        Problems = $StoragePnPProblems.Count
        Status = if ($StoragePnPProblems.Count -eq 0) {
            "OK"
        }
        else {
            "REVIEW"
        }
    }

    Camera = [ordered]@{
        Total = $CameraDevices.Count
        Problems = $CameraProblems.Count
        Status = if ($CameraProblems.Count -eq 0) {
            "OK"
        }
        else {
            "REVIEW"
        }
    }

    HID = [ordered]@{
        Total = $HIDDevices.Count
        Problems = $HIDProblems.Count
        Status = if ($HIDProblems.Count -eq 0) {
            "OK"
        }
        else {
            "REVIEW"
        }
    }

    SystemDevices = [ordered]@{
        Total = $SystemDevices.Count
        Problems = $SystemDeviceProblems.Count
        Status = if ($SystemDeviceProblems.Count -eq 0) {
            "OK"
        }
        else {
            "REVIEW"
        }
    }
}


# ============================================================================
# SECTION 24 - OVERALL VALIDATION
# ============================================================================

$OverallStatus = "PASS"

if ($ValidationIssues.Count -gt 0) {

    $OverallStatus = "REVIEW"
}


# ============================================================================
# SECTION 25 - REPORT OBJECT
# ============================================================================

$Report = [ordered]@{

    Project = [ordered]@{

        Name        = $ProjectName
        Module      = $ModuleName
        Version     = $Version
        GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }

    System = $SystemInfo

    DeviceSummary = [ordered]@{

        TotalPnPDevices        = $PnPDevices.Count
        HealthyDevices         = @(
            $PnPDevices |
            Where-Object {
                $_.ConfigManagerErrorCode -eq 0
            }
        ).Count

        ProblemDevices         = $ProblemDevices.Count
        DisabledDevices        = $DisabledDevices.Count
        UnknownDevices         = $UnknownDevices.Count
        MissingDriverDevices   = $MissingDriverDevices.Count
        DriverProblemDevices   = $DriverProblemDevices.Count
    }

    DeviceClassSummary = $DeviceClassSummary

    CategoryChecks = $CategoryChecks

    Devices = $PnPDevices

    DisplayDevices = $DisplayDevices

    AudioDevices = $AudioDevices

    CaptureDevices = $CaptureDevices

    USBDevices = $USBDevices

    NetworkDevices = $NetworkDevices

    BluetoothDevices = $BluetoothDevices

    StorageDevices = $StorageDevices

    CameraDevices = $CameraDevices

    HIDDevices = $HIDDevices

    SystemDevices = $SystemDevices

    DriverInventory = $DriverInventory

    UnsignedDrivers = $UnsignedDrivers

    DriverPackageSummary = $DriverPackageSummary

    DeviceEvents = $DeviceEvents

    CriticalDeviceEvents = $CriticalDeviceEvents

    Validation = [ordered]@{

        OverallStatus = $OverallStatus

        Issues = @(
            $ValidationIssues
        )

        Warnings = @(
            $Warnings
        )
    }
}


# ============================================================================
# SECTION 26 - JSON REPORT
# ============================================================================

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
# SECTION 27 - HUMAN READABLE REPORT
# ============================================================================

$ReportLines = New-Object System.Collections.Generic.List[string]

$ReportLines.Add("============================================================")
$ReportLines.Add("SYSTEM HEALTH AND QUALITY ASSESSMENT")
$ReportLines.Add("04 - HARDWARE, DEVICE AND DRIVER VALIDATION")
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
$ReportLines.Add("OS            : $($SystemInfo.OperatingSystem)")
$ReportLines.Add("Version       : $($SystemInfo.Version)")
$ReportLines.Add("Build         : $($SystemInfo.Build)")
$ReportLines.Add("Architecture  : $($SystemInfo.Architecture)")
$ReportLines.Add("")

$ReportLines.Add("DEVICE SUMMARY")
$ReportLines.Add("------------------------------------------------------------")
$ReportLines.Add("Total PnP Devices       : $($PnPDevices.Count)")
$ReportLines.Add("Healthy Devices          : $(@($PnPDevices | Where-Object {$_.ConfigManagerErrorCode -eq 0}).Count)")
$ReportLines.Add("Problem Devices          : $($ProblemDevices.Count)")
$ReportLines.Add("Disabled Devices         : $($DisabledDevices.Count)")
$ReportLines.Add("Unknown Devices          : $($UnknownDevices.Count)")
$ReportLines.Add("Missing Driver Devices   : $($MissingDriverDevices.Count)")
$ReportLines.Add("Driver Problem Devices   : $($DriverProblemDevices.Count)")
$ReportLines.Add("")

$ReportLines.Add("CATEGORY STATUS")
$ReportLines.Add("------------------------------------------------------------")

foreach ($Category in $CategoryChecks.GetEnumerator()) {

    $ReportLines.Add(
        "$($Category.Key) | Total: $($Category.Value.Total) | " +
        "Problems: $($Category.Value.Problems) | " +
        "Status: $($Category.Value.Status)"
    )
}

$ReportLines.Add("")
$ReportLines.Add("PROBLEM DEVICES")
$ReportLines.Add("------------------------------------------------------------")

if ($ProblemDevices.Count -eq 0) {

    $ReportLines.Add("No PnP device problems were detected.")

}
else {

    $Counter = 1

    foreach ($Device in $ProblemDevices) {

        $ReportLines.Add(
            "$Counter. $($Device.Name)"
        )

        $ReportLines.Add(
            "   Class       : $($Device.PNPClass)"
        )

        $ReportLines.Add(
            "   Problem Code: $($Device.ConfigManagerErrorCode)"
        )

        $ReportLines.Add(
            "   Description : $($Device.ProblemDescription)"
        )

        $ReportLines.Add(
            "   Manufacturer: $($Device.Manufacturer)"
        )

        $ReportLines.Add(
            "   Driver      : $($Device.DriverVersion)"
        )

        $ReportLines.Add("")

        $Counter++
    }
}

$ReportLines.Add("DISPLAY / GPU")
$ReportLines.Add("------------------------------------------------------------")

foreach ($GPU in $DisplayDevices) {

    $ReportLines.Add(
        "$($GPU.Name) | Driver: $($GPU.DriverVersion) | " +
        "Status: $($GPU.Status) | " +
        "Resolution: $($GPU.CurrentHorizontalResolution)x$($GPU.CurrentVerticalResolution)"
    )
}

$ReportLines.Add("")
$ReportLines.Add("AUDIO / MICROPHONE")
$ReportLines.Add("------------------------------------------------------------")

if ($CaptureDevices.Count -eq 0) {

    $ReportLines.Add(
        "No microphone/capture device was explicitly identified by name."
    )

}
else {

    foreach ($Device in $CaptureDevices) {

        $ReportLines.Add(
            "$($Device.Name) | Status: $($Device.Status) | " +
            "Driver: $($Device.DriverVersion)"
        )
    }
}

$ReportLines.Add("")
$ReportLines.Add("STORAGE")
$ReportLines.Add("------------------------------------------------------------")

foreach ($Disk in $StorageDevices) {

    $ReportLines.Add(
        "$($Disk.Model) | " +
        "$($Disk.InterfaceType) | " +
        "$($Disk.SizeGB) GB | " +
        "Status: $($Disk.Status)"
    )
}

$ReportLines.Add("")
$ReportLines.Add("DRIVER INVENTORY")
$ReportLines.Add("------------------------------------------------------------")
$ReportLines.Add(
    "Driver Records: $($DriverInventory.Count)"
)
$ReportLines.Add(
    "Unsigned Records: $($UnsignedDrivers.Count)"
)
$ReportLines.Add("")

$ReportLines.Add("RECENT DEVICE EVENTS")
$ReportLines.Add("------------------------------------------------------------")
$ReportLines.Add(
    "Total Device Events Reviewed: $($DeviceEvents.Count)"
)
$ReportLines.Add(
    "Error/Critical Events: $($CriticalDeviceEvents.Count)"
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
# SECTION 28 - CONSOLE SUMMARY
# ============================================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "FINAL HARDWARE / DEVICE / DRIVER VALIDATION" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Computer          : $($SystemInfo.ComputerName)"
Write-Host "Manufacturer      : $($SystemInfo.Manufacturer)"
Write-Host "Model             : $($SystemInfo.Model)"
Write-Host ""

Write-Host "Total PnP Devices : $($PnPDevices.Count)"
Write-Host "Healthy Devices   : $(@($PnPDevices | Where-Object {$_.ConfigManagerErrorCode -eq 0}).Count)"
Write-Host "Problem Devices   : $($ProblemDevices.Count)"
Write-Host "Disabled Devices  : $($DisabledDevices.Count)"
Write-Host "Missing Drivers   : $($MissingDriverDevices.Count)"
Write-Host ""

Write-Host "GPU Devices       : $($DisplayDevices.Count)"
Write-Host "Audio Devices     : $($AudioDevices.Count)"
Write-Host "Capture Devices   : $($CaptureDevices.Count)"
Write-Host "USB Devices       : $($USBDevices.Count)"
Write-Host "Network Devices   : $($NetworkDevices.Count)"
Write-Host "Bluetooth Devices : $($BluetoothDevices.Count)"
Write-Host "Storage Devices   : $($StorageDevices.Count)"
Write-Host "Camera Devices    : $($CameraDevices.Count)"
Write-Host ""

if ($OverallStatus -eq "PASS") {

    Write-Host "OVERALL STATUS: PASS" -ForegroundColor Green
    Write-Host "No actionable hardware/device problem was detected." -ForegroundColor Green
}
else {

    Write-Host "OVERALL STATUS: REVIEW" -ForegroundColor Yellow
    Write-Host "One or more hardware/device conditions require review." -ForegroundColor Yellow
}

Write-Host ""

if ($ProblemDevices.Count -gt 0) {

    Write-Host "Problem Devices:" -ForegroundColor Yellow

    $Counter = 1

    foreach ($Device in ($ProblemDevices | Select-Object -First 30)) {

        Write-Host ""
        Write-Host "$Counter. $($Device.Name)" -ForegroundColor Yellow
        Write-Host "   Class       : $($Device.PNPClass)"
        Write-Host "   Problem Code: $($Device.ConfigManagerErrorCode)"
        Write-Host "   Description : $($Device.ProblemDescription)"
        Write-Host "   Driver      : $($Device.DriverVersion)"

        $Counter++
    }
}

Write-Host ""
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
# SECTION 29 - FINAL PAUSE
# ============================================================================

Read-Host "Press Enter to continue"
Read-Host "Press Enter again to continue"
Read-Host "Press Enter one final time to finish"
```

