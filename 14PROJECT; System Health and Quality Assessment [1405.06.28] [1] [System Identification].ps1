# ============================================================================
# PROJECT: System Health and Quality Assessment
# MODULE : 01 - System Identification
# PURPOSE: Comprehensive Hardware and Software System Inventory
# VERSION: 1.0
# ============================================================================

# ----------------------------------------------------------------------------
# 1. SELF-ELEVATION AND EXECUTION POLICY
# ----------------------------------------------------------------------------

$ErrorActionPreference = "SilentlyContinue"

function Test-IsAdministrator {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)

    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

if (-not (Test-IsAdministrator)) {

    if ($PSCommandPath) {

        Write-Host ""
        Write-Host "Administrator privileges are required." -ForegroundColor Yellow
        Write-Host "Restarting PowerShell with Administrator privileges..." -ForegroundColor Yellow
        Write-Host ""

        try {
            Start-Process `
                -FilePath "powershell.exe" `
                -Verb RunAs `
                -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

            exit
        }
        catch {
            Write-Host "Unable to restart PowerShell as Administrator." -ForegroundColor Red
            Write-Host "Please run this script manually as Administrator." -ForegroundColor Red
            Read-Host "Press Enter to exit"
            exit 1
        }
    }
    else {
        Write-Host ""
        Write-Host "This script must be executed from a PowerShell script file." -ForegroundColor Red
        Write-Host "Save it as a .ps1 file and run it again." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
}

try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}
catch {
    # Process-level policy change is not mandatory if execution is already allowed.
}

# ----------------------------------------------------------------------------
# 2. PROJECT FOLDER
# ----------------------------------------------------------------------------

$DesktopPath = [Environment]::GetFolderPath("Desktop")

$ProjectFolderName = "System Health and Quality Assessment"
$ProjectFolder = Join-Path $DesktopPath $ProjectFolderName

if (-not (Test-Path -LiteralPath $ProjectFolder)) {
    New-Item -Path $ProjectFolder -ItemType Directory -Force | Out-Null
}

# ----------------------------------------------------------------------------
# 3. REPORT FILES
# ----------------------------------------------------------------------------

$TextReport = Join-Path $ProjectFolder "01_System_Identification.txt"
$JsonReport = Join-Path $ProjectFolder "01_System_Identification.json"

# ----------------------------------------------------------------------------
# 4. HELPER FUNCTIONS
# ----------------------------------------------------------------------------

function Get-SafeValue {
    param (
        [Parameter(Mandatory = $false)]
        $Value
    )

    if ($null -eq $Value) {
        return $null
    }

    $text = [string]$Value

    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    return $Value
}

function Get-CimSafe {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ClassName
    )

    try {
        return @(Get-CimInstance -ClassName $ClassName -ErrorAction Stop)
    }
    catch {
        return @()
    }
}

function Get-RegistryValueSafe {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    try {
        return Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop
    }
    catch {
        return $null
    }
}

function Convert-BytesToGB {
    param (
        [Parameter(Mandatory = $false)]
        [double]$Bytes
    )

    if ($Bytes -le 0) {
        return $null
    }

    return [math]::Round($Bytes / 1GB, 2)
}

function Get-ReadableSize {
    param (
        [Parameter(Mandatory = $false)]
        [double]$Bytes
    )

    if ($Bytes -le 0) {
        return "Unknown"
    }

    if ($Bytes -ge 1TB) {
        return "{0:N2} TB" -f ($Bytes / 1TB)
    }

    if ($Bytes -ge 1GB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    }

    if ($Bytes -ge 1MB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)
    }

    return "{0:N2} KB" -f ($Bytes / 1KB)
}

# ----------------------------------------------------------------------------
# 5. COLLECTION START
# ----------------------------------------------------------------------------

$CollectionStart = Get-Date

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " SYSTEM HEALTH AND QUALITY ASSESSMENT" -ForegroundColor Cyan
Write-Host " MODULE 01 - SYSTEM IDENTIFICATION" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Collecting system information..." -ForegroundColor Yellow
Write-Host "Please wait." -ForegroundColor Yellow
Write-Host ""

# ----------------------------------------------------------------------------
# 6. OPERATING SYSTEM
# ----------------------------------------------------------------------------

$OS = Get-CimSafe "Win32_OperatingSystem"
$ComputerSystem = Get-CimSafe "Win32_ComputerSystem"
$ComputerSystemProduct = Get-CimSafe "Win32_ComputerSystemProduct"
$WindowsVersion = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

$WindowsInfo = [ordered]@{
    ComputerName        = $env:COMPUTERNAME
    UserName            = $env:USERNAME
    Domain              = $env:USERDOMAIN
    OperatingSystem     = if ($OS) { $OS.Caption } else { $null }
    Version             = if ($OS) { $OS.Version } else { $null }
    BuildNumber         = if ($OS) { $OS.BuildNumber } else { $null }
    DisplayVersion      = Get-SafeValue $WindowsVersion.DisplayVersion
    ReleaseId           = Get-SafeValue $WindowsVersion.ReleaseId
    EditionId           = Get-SafeValue $WindowsVersion.EditionID
    InstallationDate    = if ($OS.InstallDate) { $OS.InstallDate } else { $null }
    LastBootTime        = if ($OS.LastBootUpTime) { $OS.LastBootUpTime } else { $null }
    SystemDirectory     = if ($OS) { $OS.SystemDirectory } else { $null }
    WindowsDirectory    = if ($OS) { $OS.WindowsDirectory } else { $null }
    SystemDrive         = $env:SystemDrive
    Architecture        = if ($OS) { $OS.OSArchitecture } else { $null }
    RegisteredUser      = if ($OS) { $OS.RegisteredUser } else { $null }
    SerialNumber        = if ($OS) { $OS.SerialNumber } else { $null }
}

# ----------------------------------------------------------------------------
# 7. COMPUTER / MANUFACTURER
# ----------------------------------------------------------------------------

$ComputerInfo = [ordered]@{
    Manufacturer            = if ($ComputerSystem) { $ComputerSystem.Manufacturer } else { $null }
    Model                   = if ($ComputerSystem) { $ComputerSystem.Model } else { $null }
    SystemType              = if ($ComputerSystem) { $ComputerSystem.SystemType } else { $null }
    TotalPhysicalMemoryGB   = if ($ComputerSystem) { Convert-BytesToGB $ComputerSystem.TotalPhysicalMemory } else { $null }
    Domain                  = if ($ComputerSystem) { $ComputerSystem.Domain } else { $null }
    PartOfDomain            = if ($ComputerSystem) { $ComputerSystem.PartOfDomain } else { $null }
    NumberOfLogicalCPU     = if ($ComputerSystem) { $ComputerSystem.NumberOfLogicalProcessors } else { $null }
    NumberOfPhysicalCPU    = if ($ComputerSystem) { $ComputerSystem.NumberOfProcessors } else { $null }
}

# ----------------------------------------------------------------------------
# 8. BIOS / FIRMWARE
# ----------------------------------------------------------------------------

$BIOS = Get-CimSafe "Win32_BIOS"

$BIOSInfo = @(
    foreach ($item in $BIOS) {
        [ordered]@{
            Manufacturer = $item.Manufacturer
            Name         = $item.Name
            Version      = $item.SMBIOSBIOSVersion
            ReleaseDate  = $item.ReleaseDate
            SerialNumber = $item.SerialNumber
            SMBIOSMajor  = $item.SMBIOSMajorVersion
            SMBIOSMinor  = $item.SMBIOSMinorVersion
        }
    }
)

# ----------------------------------------------------------------------------
# 9. MOTHERBOARD
# ----------------------------------------------------------------------------

$BaseBoard = Get-CimSafe "Win32_BaseBoard"

$MotherboardInfo = @(
    foreach ($item in $BaseBoard) {
        [ordered]@{
            Manufacturer = $item.Manufacturer
            Product      = $item.Product
            Version      = $item.Version
            SerialNumber = $item.SerialNumber
        }
    }
)

# ----------------------------------------------------------------------------
# 10. CPU
# ----------------------------------------------------------------------------

$CPU = Get-CimSafe "Win32_Processor"

$CPUInfo = @(
    foreach ($item in $CPU) {
        [ordered]@{
            Name                    = $item.Name
            Manufacturer            = $item.Manufacturer
            Description             = $item.Description
            Socket                  = $item.SocketDesignation
            NumberOfCores           = $item.NumberOfCores
            NumberOfLogicalProcessors = $item.NumberOfLogicalProcessors
            MaxClockSpeedMHz        = $item.MaxClockSpeed
            CurrentClockSpeedMHz    = $item.CurrentClockSpeed
            L2CacheKB               = $item.L2CacheSize
            L3CacheKB               = $item.L3CacheSize
            Architecture            = $item.Architecture
            AddressWidth            = $item.AddressWidth
            DataWidth               = $item.DataWidth
            VirtualizationFirmwareEnabled = $item.VirtualizationFirmwareEnabled
            VMMonitorModeExtensions = $item.VMMonitorModeExtensions
            SecondLevelAddressTranslationExtensions = $item.SecondLevelAddressTranslationExtensions
        }
    }
)

# ----------------------------------------------------------------------------
# 11. MEMORY
# ----------------------------------------------------------------------------

$MemoryModules = Get-CimSafe "Win32_PhysicalMemory"

$MemoryInfo = @(
    foreach ($item in $MemoryModules) {
        [ordered]@{
            Manufacturer   = $item.Manufacturer
            PartNumber     = $item.PartNumber
            SerialNumber   = $item.SerialNumber
            CapacityGB     = Convert-BytesToGB $item.Capacity
            SpeedMHz       = $item.Speed
            ConfiguredSpeedMHz = $item.ConfiguredClockSpeed
            MemoryType     = $item.MemoryType
            FormFactor     = $item.FormFactor
            DeviceLocator  = $item.DeviceLocator
            BankLabel      = $item.BankLabel
        }
    }
)

# ----------------------------------------------------------------------------
# 12. GRAPHICS
# ----------------------------------------------------------------------------

$GPU = Get-CimSafe "Win32_VideoController"

$GPUInfo = @(
    foreach ($item in $GPU) {
        [ordered]@{
            Name                  = $item.Name
            AdapterCompatibility  = $item.AdapterCompatibility
            DriverVersion         = $item.DriverVersion
            DriverDate            = $item.DriverDate
            VideoModeDescription   = $item.VideoModeDescription
            CurrentHorizontalResolution = $item.CurrentHorizontalResolution
            CurrentVerticalResolution   = $item.CurrentVerticalResolution
            CurrentRefreshRate     = $item.CurrentRefreshRate
            AdapterRAM             = Get-ReadableSize $item.AdapterRAM
            VideoProcessor         = $item.VideoProcessor
            Status                 = $item.Status
            PNPDeviceID            = $item.PNPDeviceID
        }
    }
)

# ----------------------------------------------------------------------------
# 13. PHYSICAL DISKS
# ----------------------------------------------------------------------------

$PhysicalDisks = Get-CimSafe "Win32_DiskDrive"

$PhysicalDiskInfo = @(
    foreach ($item in $PhysicalDisks) {
        [ordered]@{
            Model           = $item.Model
            Manufacturer    = $item.Manufacturer
            InterfaceType   = $item.InterfaceType
            MediaType       = $item.MediaType
            SerialNumber    = $item.SerialNumber
            Size            = Get-ReadableSize $item.Size
            SizeGB          = Convert-BytesToGB $item.Size
            FirmwareRevision = $item.FirmwareRevision
            Status          = $item.Status
            DeviceID        = $item.DeviceID
        }
    }
)

# ----------------------------------------------------------------------------
# 14. LOGICAL DISKS
# ----------------------------------------------------------------------------

$LogicalDisks = Get-CimSafe "Win32_LogicalDisk"

$LogicalDiskInfo = @(
    foreach ($item in $LogicalDisks) {

        if ($item.DriveType -eq 3) {

            [ordered]@{
                DriveLetter   = $item.DeviceID
                FileSystem    = $item.FileSystem
                VolumeName    = $item.VolumeName
                TotalSize     = Get-ReadableSize $item.Size
                FreeSpace     = Get-ReadableSize $item.FreeSpace
                TotalSizeGB   = Convert-BytesToGB $item.Size
                FreeSpaceGB   = Convert-BytesToGB $item.FreeSpace
                FreeSpacePercent = if ($item.Size -gt 0) {
                    [math]::Round(($item.FreeSpace / $item.Size) * 100, 2)
                }
                else {
                    $null
                }
            }
        }
    }
)

# ----------------------------------------------------------------------------
# 15. DISPLAY INFORMATION
# ----------------------------------------------------------------------------

$Displays = Get-CimSafe "Win32_DesktopMonitor"

$DisplayInfo = @(
    foreach ($item in $Displays) {
        [ordered]@{
            Name          = $item.Name
            Manufacturer  = $item.MonitorManufacturer
            Description   = $item.Description
            PNPDeviceID   = $item.PNPDeviceID
            Status        = $item.Status
        }
    }
)

# ----------------------------------------------------------------------------
# 16. AUDIO DEVICES
# ----------------------------------------------------------------------------

$AudioDevices = Get-CimSafe "Win32_SoundDevice"

$AudioInfo = @(
    foreach ($item in $AudioDevices) {
        [ordered]@{
            Name         = $item.Name
            Manufacturer = $item.Manufacturer
            Status       = $item.Status
            PNPDeviceID  = $item.PNPDeviceID
        }
    }
)

# ----------------------------------------------------------------------------
# 17. NETWORK ADAPTERS
# ----------------------------------------------------------------------------

$NetworkAdapters = Get-CimSafe "Win32_NetworkAdapter"

$NetworkInfo = @(
    foreach ($item in $NetworkAdapters) {

        if ($item.PhysicalAdapter -eq $true) {

            [ordered]@{
                Name              = $item.Name
                Manufacturer      = $item.Manufacturer
                AdapterType       = $item.AdapterType
                MACAddress        = $item.MACAddress
                Speed             = if ($item.Speed) { "$([math]::Round($item.Speed / 1MB, 2)) Mbps" } else { $null }
                NetConnectionID   = $item.NetConnectionID
                NetConnectionStatus = $item.NetConnectionStatus
                PNPDeviceID       = $item.PNPDeviceID
                DriverVersion     = $item.DriverVersion
            }
        }
    }
)

# ----------------------------------------------------------------------------
# 18. USB CONTROLLERS
# ----------------------------------------------------------------------------

$USBControllers = Get-CimSafe "Win32_USBController"

$USBInfo = @(
    foreach ($item in $USBControllers) {
        [ordered]@{
            Name         = $item.Name
            Manufacturer = $item.Manufacturer
            Status       = $item.Status
            PNPDeviceID  = $item.PNPDeviceID
        }
    }
)

# ----------------------------------------------------------------------------
# 19. PNP DEVICES
# ----------------------------------------------------------------------------

$PNPDevices = Get-CimSafe "Win32_PnPEntity"

$PNPInfo = @(
    foreach ($item in $PNPDevices) {

        [ordered]@{
            Name        = $item.Name
            Manufacturer = $item.Manufacturer
            Status      = $item.Status
            PNPClass    = $item.PNPClass
            PNPDeviceID = $item.PNPDeviceID
            ConfigManagerErrorCode = $item.ConfigManagerErrorCode
        }
    }
)

# ----------------------------------------------------------------------------
# 20. SIGNED DEVICE DRIVERS
# ----------------------------------------------------------------------------

$Drivers = Get-CimSafe "Win32_PnPSignedDriver"

$DriverInfo = @(
    foreach ($item in $Drivers) {

        [ordered]@{
            DeviceName      = $item.DeviceName
            Manufacturer    = $item.Manufacturer
            DriverProvider  = $item.DriverProviderName
            DriverVersion   = $item.DriverVersion
            DriverDate      = $item.DriverDate
            IsSigned        = $item.IsSigned
            Signer          = $item.Signer
            InfName         = $item.InfName
            DeviceClass     = $item.DeviceClass
            PNPDeviceID     = $item.DeviceID
        }
    }
)

# ----------------------------------------------------------------------------
# 21. INSTALLED SOFTWARE - REGISTRY
# ----------------------------------------------------------------------------

$SoftwareList = New-Object System.Collections.Generic.List[object]

$SoftwareRegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $SoftwareRegistryPaths) {

    try {

        $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue

        foreach ($item in $items) {

            if ($item.DisplayName) {

                $SoftwareList.Add(
                    [ordered]@{
                        Name            = $item.DisplayName
                        Version         = $item.DisplayVersion
                        Publisher       = $item.Publisher
                        InstallDate     = $item.InstallDate
                        InstallLocation = $item.InstallLocation
                        Architecture    = if ($path -like "*WOW6432Node*") { "32-bit" } else { "64-bit/System or User" }
                    }
                )
            }
        }
    }
    catch {
        # Continue collecting other information.
    }
}

# Remove duplicate software entries.
$SoftwareInfo = @(
    $SoftwareList |
        Sort-Object Name, Version, Publisher -Unique
)

# ----------------------------------------------------------------------------
# 22. WINDOWS SERVICES
# ----------------------------------------------------------------------------

$Services = Get-CimSafe "Win32_Service"

$ServiceInfo = @(
    foreach ($item in $Services) {

        [ordered]@{
            Name        = $item.Name
            DisplayName = $item.DisplayName
            State       = $item.State
            StartMode   = $item.StartMode
            StartName   = $item.StartName
            PathName    = $item.PathName
        }
    }
)

# ----------------------------------------------------------------------------
# 23. WINDOWS FEATURES
# ----------------------------------------------------------------------------

$WindowsFeatures = @()

try {

    $WindowsFeatures = @(
        Get-WindowsOptionalFeature -Online -ErrorAction Stop |
        Select-Object FeatureName, State
    )

}
catch {
    # Feature enumeration may not be available on every environment.
}

# ----------------------------------------------------------------------------
# 24. WINDOWS DEFENDER
# ----------------------------------------------------------------------------

$DefenderInfo = $null

try {

    $Defender = Get-MpComputerStatus -ErrorAction Stop

    $DefenderInfo = [ordered]@{
        AntivirusEnabled       = $Defender.AntivirusEnabled
        AntispywareEnabled     = $Defender.AntispywareEnabled
        RealTimeProtection     = $Defender.RealTimeProtectionEnabled
        BehaviorMonitor        = $Defender.BehaviorMonitorEnabled
        IoavProtection         = $Defender.IoavProtectionEnabled
        TamperProtection       = $Defender.IsTamperProtected
        AntivirusVersion       = $Defender.AntivirusVersion
        EngineVersion          = $Defender.AMEngineVersion
        SecurityIntelligenceVersion = $Defender.AntivirusSignatureVersion
        SecurityIntelligenceLastUpdated = $Defender.AntivirusSignatureLastUpdated
    }

}
catch {
    $DefenderInfo = [ordered]@{
        Status = "Windows Defender information unavailable"
    }
}

# ----------------------------------------------------------------------------
# 25. WINDOWS FIREWALL
# ----------------------------------------------------------------------------

$FirewallInfo = @()

try {

    $FirewallProfiles = Get-NetFirewallProfile -ErrorAction Stop

    $FirewallInfo = @(
        foreach ($profile in $FirewallProfiles) {

            [ordered]@{
                Name            = $profile.Name
                Enabled         = $profile.Enabled
                DefaultInbound  = $profile.DefaultInboundAction
                DefaultOutbound = $profile.DefaultOutboundAction
            }
        }
    )

}
catch {
    $FirewallInfo = @()
}

# ----------------------------------------------------------------------------
# 26. NETWORK CONFIGURATION
# ----------------------------------------------------------------------------

$IPConfiguration = @()

try {

    $IPConfiguration = @(
        Get-NetIPConfiguration -ErrorAction Stop |
        Select-Object InterfaceAlias,
                      InterfaceIndex,
                      IPv4Address,
                      IPv6Address,
                      DNSServer,
                      NetProfile
    )

}
catch {
    $IPConfiguration = @()
}

# ----------------------------------------------------------------------------
# 27. POWER / BATTERY
# ----------------------------------------------------------------------------

$Battery = Get-CimSafe "Win32_Battery"

$BatteryInfo = @(
    foreach ($item in $Battery) {

        [ordered]@{
            Name                = $item.Name
            DeviceID            = $item.DeviceID
            BatteryStatus       = $item.BatteryStatus
            EstimatedCharge     = $item.EstimatedChargeRemaining
            EstimatedRunTimeMin = $item.EstimatedRunTime
            Chemistry           = $item.Chemistry
            DesignVoltage       = $item.DesignVoltage
        }
    }
)

# ----------------------------------------------------------------------------
# 28. BIOS / UEFI BOOT MODE
# ----------------------------------------------------------------------------

$FirmwareInfo = [ordered]@{
    FirmwareType = $null
    SecureBootAvailable = $null
    SecureBootEnabled = $null
}

try {
    $FirmwareInfo.FirmwareType = (Get-ComputerInfo -Property BiosFirmwareType).BiosFirmwareType
}
catch {}

try {
    $FirmwareInfo.SecureBootEnabled = Confirm-SecureBootUEFI
}
catch {
    $FirmwareInfo.SecureBootEnabled = $null
}

try {
    $FirmwareInfo.SecureBootAvailable = $true
}
catch {
    $FirmwareInfo.SecureBootAvailable = $false
}

# ----------------------------------------------------------------------------
# 29. WINDOWS PRODUCT INFORMATION
# ----------------------------------------------------------------------------

$WindowsProductInfo = @()

try {

    $Products = Get-CimInstance `
        -ClassName SoftwareLicensingProduct `
        -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f'" `
        -ErrorAction Stop

    $WindowsProductInfo = @(
        foreach ($product in $Products) {

            if ($product.Name) {

                [ordered]@{
                    Name            = $product.Name
                    Description     = $product.Description
                    PartialProductKey = $product.PartialProductKey
                    LicenseStatus   = $product.LicenseStatus
                    LicenseFamily   = $product.LicenseFamily
                }
            }
        }
    )
}
catch {
    $WindowsProductInfo = @()
}

# ----------------------------------------------------------------------------
# 30. ENVIRONMENT
# ----------------------------------------------------------------------------

$EnvironmentInfo = [ordered]@{
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    PowerShellEdition = $PSVersionTable.PSEdition
    CLRVersion        = $PSVersionTable.CLRVersion.ToString()
    ProcessArchitecture = $env:PROCESSOR_ARCHITECTURE
    Is64BitOperatingSystem = [Environment]::Is64BitOperatingSystem
    Is64BitProcess = [Environment]::Is64BitProcess
    CurrentUser = [Environment]::UserName
    CurrentDirectory = (Get-Location).Path
}

# ----------------------------------------------------------------------------
# 31. SYSTEM TIME
# ----------------------------------------------------------------------------

$TimeInfo = [ordered]@{
    CollectionStarted = $CollectionStart
    CollectionFinished = Get-Date
    TimeZone = (Get-TimeZone).Id
}

# ----------------------------------------------------------------------------
# 32. FINAL STRUCTURED REPORT
# ----------------------------------------------------------------------------

$Report = [ordered]@{

    Project = [ordered]@{
        Name    = "System Health and Quality Assessment"
        Module  = "01 - System Identification"
        Version = "1.0"
        Purpose = "Comprehensive hardware and software inventory"
    }

    Collection = $TimeInfo

    Windows = $WindowsInfo

    Computer = $ComputerInfo

    BIOS = $BIOSInfo

    Motherboard = $MotherboardInfo

    CPU = $CPUInfo

    Memory = $MemoryInfo

    GPU = $GPUInfo

    PhysicalDisks = $PhysicalDiskInfo

    LogicalDisks = $LogicalDiskInfo

    Displays = $DisplayInfo

    Audio = $AudioInfo

    NetworkAdapters = $NetworkInfo

    USBControllers = $USBInfo

    PnPDevices = $PNPInfo

    Drivers = $DriverInfo

    InstalledSoftware = $SoftwareInfo

    Services = $ServiceInfo

    WindowsFeatures = $WindowsFeatures

    WindowsDefender = $DefenderInfo

    WindowsFirewall = $FirewallInfo

    NetworkConfiguration = $IPConfiguration

    Battery = $BatteryInfo

    Firmware = $FirmwareInfo

    WindowsLicensing = $WindowsProductInfo

    Environment = $EnvironmentInfo
}

# ----------------------------------------------------------------------------
# 33. SAVE JSON REPORT
# ----------------------------------------------------------------------------

try {

    $Report |
        ConvertTo-Json -Depth 8 |
        Set-Content -Path $JsonReport -Encoding UTF8

}
catch {
    Write-Host "Unable to create JSON report." -ForegroundColor Red
}

# ----------------------------------------------------------------------------
# 34. CREATE HUMAN-READABLE TEXT REPORT
# ----------------------------------------------------------------------------

$Text = New-Object System.Text.StringBuilder

[void]$Text.AppendLine("============================================================")
[void]$Text.AppendLine("SYSTEM HEALTH AND QUALITY ASSESSMENT")
[void]$Text.AppendLine("MODULE 01 - SYSTEM IDENTIFICATION")
[void]$Text.AppendLine("============================================================")
[void]$Text.AppendLine("")

[void]$Text.AppendLine("COLLECTION INFORMATION")
[void]$Text.AppendLine("----------------------")
[void]$Text.AppendLine("Collection Started : $($TimeInfo.CollectionStarted)")
[void]$Text.AppendLine("Collection Finished: $($TimeInfo.CollectionFinished)")
[void]$Text.AppendLine("Time Zone          : $($TimeInfo.TimeZone)")
[void]$Text.AppendLine("")

[void]$Text.AppendLine("WINDOWS")
[void]$Text.AppendLine("-------")

foreach ($property in $WindowsInfo.GetEnumerator()) {
    [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
}

[void]$Text.AppendLine("")
[void]$Text.AppendLine("COMPUTER")
[void]$Text.AppendLine("--------")

foreach ($property in $ComputerInfo.GetEnumerator()) {
    [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
}

[void]$Text.AppendLine("")
[void]$Text.AppendLine("BIOS")
[void]$Text.AppendLine("----")

foreach ($item in $BIOSInfo) {
    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
    }
    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("MOTHERBOARD")
[void]$Text.AppendLine("-----------")

foreach ($item in $MotherboardInfo) {
    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
    }
    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("CPU")
[void]$Text.AppendLine("---")

foreach ($item in $CPUInfo) {
    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-45}: {1}" -f $property.Key, $property.Value)
    }
    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("MEMORY")
[void]$Text.AppendLine("------")

foreach ($item in $MemoryInfo) {
    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
    }
    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("GPU")
[void]$Text.AppendLine("---")

foreach ($item in $GPUInfo) {
    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-45}: {1}" -f $property.Key, $property.Value)
    }
    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("PHYSICAL DISKS")
[void]$Text.AppendLine("--------------")

foreach ($item in $PhysicalDiskInfo) {
    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
    }
    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("LOGICAL DISKS")
[void]$Text.AppendLine("-------------")

foreach ($item in $LogicalDiskInfo) {
    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
    }
    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("DISPLAYS")
[void]$Text.AppendLine("--------")

foreach ($item in $DisplayInfo) {
    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
    }
    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("AUDIO DEVICES")
[void]$Text.AppendLine("-------------")

foreach ($item in $AudioInfo) {
    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
    }
    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("NETWORK ADAPTERS")
[void]$Text.AppendLine("----------------")

foreach ($item in $NetworkInfo) {
    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
    }
    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("USB CONTROLLERS")
[void]$Text.AppendLine("---------------")

foreach ($item in $USBInfo) {
    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
    }
    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("PNP DEVICES")
[void]$Text.AppendLine("-----------")

foreach ($item in $PNPInfo) {

    if ($item.Status -ne "OK" -or
        ($item.ConfigManagerErrorCode -ne 0 -and
         $null -ne $item.ConfigManagerErrorCode)) {

        [void]$Text.AppendLine("Name                  : $($item.Name)")
        [void]$Text.AppendLine("Manufacturer          : $($item.Manufacturer)")
        [void]$Text.AppendLine("Status                : $($item.Status)")
        [void]$Text.AppendLine("PNP Class             : $($item.PNPClass)")
        [void]$Text.AppendLine("Error Code            : $($item.ConfigManagerErrorCode)")
        [void]$Text.AppendLine("PNP Device ID         : $($item.PNPDeviceID)")
        [void]$Text.AppendLine("")
    }
}

[void]$Text.AppendLine("SIGNED DRIVERS")
[void]$Text.AppendLine("--------------")

foreach ($item in $DriverInfo) {
    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
    }
    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("INSTALLED SOFTWARE")
[void]$Text.AppendLine("------------------")

foreach ($item in $SoftwareInfo) {

    [void]$Text.AppendLine(
        "{0} | Version: {1} | Publisher: {2}" -f `
        $item.Name,
        $item.Version,
        $item.Publisher
    )
}

[void]$Text.AppendLine("")
[void]$Text.AppendLine("WINDOWS DEFENDER")
[void]$Text.AppendLine("----------------")

if ($DefenderInfo) {

    foreach ($property in $DefenderInfo.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-40}: {1}" -f $property.Key, $property.Value)
    }
}

[void]$Text.AppendLine("")
[void]$Text.AppendLine("WINDOWS FIREWALL")
[void]$Text.AppendLine("----------------")

foreach ($item in $FirewallInfo) {

    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
    }

    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("BATTERY")
[void]$Text.AppendLine("-------")

foreach ($item in $BatteryInfo) {

    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
    }

    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("FIRMWARE")
[void]$Text.AppendLine("--------")

foreach ($property in $FirmwareInfo.GetEnumerator()) {
    [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
}

[void]$Text.AppendLine("")
[void]$Text.AppendLine("WINDOWS LICENSING INFORMATION")
[void]$Text.AppendLine("-----------------------------")

foreach ($item in $WindowsProductInfo) {

    foreach ($property in $item.GetEnumerator()) {
        [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
    }

    [void]$Text.AppendLine("")
}

[void]$Text.AppendLine("ENVIRONMENT")
[void]$Text.AppendLine("-----------")

foreach ($property in $EnvironmentInfo.GetEnumerator()) {
    [void]$Text.AppendLine("{0,-35}: {1}" -f $property.Key, $property.Value)
}

[void]$Text.AppendLine("")
[void]$Text.AppendLine("============================================================")
[void]$Text.AppendLine("END OF SYSTEM IDENTIFICATION REPORT")
[void]$Text.AppendLine("============================================================")

try {
    $Text.ToString() | Set-Content -Path $TextReport -Encoding UTF8
}
catch {
    Write-Host "Unable to create text report." -ForegroundColor Red
}

# ----------------------------------------------------------------------------
# 35. CONSOLE SUMMARY
# ----------------------------------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "SYSTEM IDENTIFICATION COMPLETED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Computer : $($WindowsInfo.ComputerName)"
Write-Host "Windows  : $($WindowsInfo.OperatingSystem)"
Write-Host "Version  : $($WindowsInfo.DisplayVersion)"
Write-Host "Build    : $($WindowsInfo.BuildNumber)"
Write-Host "CPU      : $($CPUInfo[0].Name)"
Write-Host "RAM      : $($ComputerInfo.TotalPhysicalMemoryGB) GB"
Write-Host "GPU Count: $($GPUInfo.Count)"
Write-Host "Disk Count: $($PhysicalDiskInfo.Count)"
Write-Host "Driver Count: $($DriverInfo.Count)"
Write-Host "Software Count: $($SoftwareInfo.Count)"
Write-Host ""

Write-Host "Reports saved to:" -ForegroundColor Cyan
Write-Host $ProjectFolder -ForegroundColor White
Write-Host ""
Write-Host "Text Report : $TextReport"
Write-Host "JSON Report : $JsonReport"
Write-Host ""

# ----------------------------------------------------------------------------
# 36. THREE SEPARATE ENTER CONFIRMATIONS
# ----------------------------------------------------------------------------

Read-Host "Press Enter to continue"
Read-Host "Press Enter to continue"
Read-Host "Press Enter to finish"