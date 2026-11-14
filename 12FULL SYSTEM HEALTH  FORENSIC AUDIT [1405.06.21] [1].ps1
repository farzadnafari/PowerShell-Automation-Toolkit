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
    "FULL_SYSTEM_HEALTH_AUDIT_$TimeStamp"

New-Item `
    -Path $RootFolder `
    -ItemType Directory `
    -Force `
    | Out-Null


$ReportFile = Join-Path `
    $RootFolder `
    "FULL_SYSTEM_HEALTH_REPORT.txt"

$SummaryFile = Join-Path `
    $RootFolder `
    "HEALTH_SUMMARY.txt"

$ErrorFile = Join-Path `
    $RootFolder `
    "AUDIT_ERRORS.txt"


# ============================================================
# 3. REPORT ENGINE
# ============================================================

$Report = New-Object System.Collections.Generic.List[string]

$AuditErrors = New-Object System.Collections.Generic.List[string]

$HealthScore = 100

$CriticalIssues = 0
$WarningIssues = 0
$InfoIssues = 0


function Add-Report {
    param(
        [string]$Text
    )

    $Report.Add($Text)
    $Text | Out-File `
        -FilePath $ReportFile `
        -Append `
        -Encoding UTF8
}


function Section {
    param(
        [string]$Title
    )

    Add-Report ""
    Add-Report "======================================================================"
    Add-Report " $Title"
    Add-Report "======================================================================"
}


function Add-Error {
    param(
        [string]$Text
    )

    $AuditErrors.Add($Text)
    Add-Report "[ERROR] $Text"
}


function Add-Warning {
    param(
        [string]$Text
    )

    $script:WarningIssues++
    Add-Report "[WARNING] $Text"
}


function Add-Critical {
    param(
        [string]$Text
    )

    $script:CriticalIssues++
    $script:HealthScore -= 10

    Add-Report "[CRITICAL] $Text"
}


function Add-Info {
    param(
        [string]$Text
    )

    $script:InfoIssues++
    Add-Report "[INFO] $Text"
}


function Add-OK {
    param(
        [string]$Text
    )

    Add-Report "[OK] $Text"
}


function Run-Test {
    param(
        [string]$Name,
        [scriptblock]$Script
    )

    $Start = Get-Date

    Add-Report ""
    Add-Report "---- TEST: $Name ----"

    try {

        & $Script

        $Duration = ((Get-Date) - $Start).TotalSeconds

        Add-Report "[TEST COMPLETE] $Name | Duration: $([math]::Round($Duration,2)) sec"
    }
    catch {

        $Message = $_.Exception.Message

        Add-Error "$Name failed: $Message"
    }
}


# ============================================================
# 4. HEADER
# ============================================================

Add-Report "FULL SYSTEM HEALTH / FORENSIC AUDIT"
Add-Report "======================================================================"
Add-Report "Audit Started : $(Get-Date)"
Add-Report "Computer      : $env:COMPUTERNAME"
Add-Report "User          : $env:USERNAME"
Add-Report "PowerShell    : $($PSVersionTable.PSVersion)"
Add-Report "OS            : Windows"
Add-Report "Mode          : READ-ONLY"
Add-Report "======================================================================"


# ============================================================
# 5. OS INFORMATION
# ============================================================

Run-Test "Operating System" {

    Section "OPERATING SYSTEM"

    $OS = Get-CimInstance Win32_OperatingSystem

    Add-Report "Caption              : $($OS.Caption)"
    Add-Report "Version              : $($OS.Version)"
    Add-Report "BuildNumber          : $($OS.BuildNumber)"
    Add-Report "Architecture         : $($OS.OSArchitecture)"
    Add-Report "Install Date         : $($OS.InstallDate)"
    Add-Report "Last Boot             : $($OS.LastBootUpTime)"
    Add-Report "Windows Directory    : $($OS.WindowsDirectory)"
    Add-Report "System Directory     : $($OS.SystemDirectory)"
    Add-Report "System Drive         : $($OS.SystemDrive)"
    Add-Report "Registered User      : $($OS.RegisteredUser)"

    $Uptime = (Get-Date) - $OS.LastBootUpTime

    Add-Report "Current Uptime       : $($Uptime.Days) days $($Uptime.Hours) hours $($Uptime.Minutes) minutes"

    Add-OK "Operating system information collected."
}


# ============================================================
# 6. COMPUTER / MOTHERBOARD
# ============================================================

Run-Test "Computer and Motherboard" {

    Section "COMPUTER / MOTHERBOARD"

    $CS = Get-CimInstance Win32_ComputerSystem
    $Board = Get-CimInstance Win32_BaseBoard
    $BIOS = Get-CimInstance Win32_BIOS

    Add-Report "Manufacturer         : $($CS.Manufacturer)"
    Add-Report "Model                : $($CS.Model)"
    Add-Report "System Type          : $($CS.SystemType)"
    Add-Report "Domain               : $($CS.Domain)"
    Add-Report "Total RAM            : $([math]::Round($CS.TotalPhysicalMemory / 1GB,2)) GB"

    Add-Report ""
    Add-Report "Motherboard:"
    Add-Report "Manufacturer         : $($Board.Manufacturer)"
    Add-Report "Product              : $($Board.Product)"
    Add-Report "Version              : $($Board.Version)"
    Add-Report "Serial               : $($Board.SerialNumber)"

    Add-Report ""
    Add-Report "BIOS:"
    Add-Report "Manufacturer         : $($BIOS.Manufacturer)"
    Add-Report "Version              : $($BIOS.SMBIOSBIOSVersion)"
    Add-Report "Release Date         : $($BIOS.ReleaseDate)"
    Add-Report "SMBIOS Version       : $($BIOS.SMBIOSMajorVersion).$($BIOS.SMBIOSMinorVersion)"
    Add-Report "BIOS Serial          : $($BIOS.SerialNumber)"

    Add-OK "Computer, motherboard and BIOS inventory collected."
}


# ============================================================
# 7. CPU
# ============================================================

Run-Test "CPU Health" {

    Section "CPU"

    $CPUs = Get-CimInstance Win32_Processor

    foreach ($CPU in $CPUs) {

        Add-Report "Name                 : $($CPU.Name)"
        Add-Report "Manufacturer         : $($CPU.Manufacturer)"
        Add-Report "Socket               : $($CPU.SocketDesignation)"
        Add-Report "Cores                : $($CPU.NumberOfCores)"
        Add-Report "Logical Processors   : $($CPU.NumberOfLogicalProcessors)"
        Add-Report "Max Clock MHz        : $($CPU.MaxClockSpeed)"
        Add-Report "Current Clock MHz    : $($CPU.CurrentClockSpeed)"
        Add-Report "Load Percentage      : $($CPU.LoadPercentage)"
        Add-Report "L2 Cache             : $($CPU.L2CacheSize) KB"
        Add-Report "L3 Cache             : $($CPU.L3CacheSize) KB"

        if ($CPU.LoadPercentage -ge 90) {
            Add-Warning "CPU load is currently very high: $($CPU.LoadPercentage)%"
        }
        else {
            Add-OK "CPU current load is normal."
        }
    }
}


# ============================================================
# 8. RAM
# ============================================================

Run-Test "Memory Health" {

    Section "RAM / MEMORY"

    $CS = Get-CimInstance Win32_ComputerSystem
    $OS = Get-CimInstance Win32_OperatingSystem
    $MemoryModules = Get-CimInstance Win32_PhysicalMemory

    $TotalGB = $CS.TotalPhysicalMemory / 1GB
    $FreeGB = $OS.FreePhysicalMemory / 1MB
    $UsedGB = $TotalGB - $FreeGB
    $Usage = ($UsedGB / $TotalGB) * 100

    Add-Report "Total RAM            : $([math]::Round($TotalGB,2)) GB"
    Add-Report "Used RAM             : $([math]::Round($UsedGB,2)) GB"
    Add-Report "Free RAM             : $([math]::Round($FreeGB,2)) GB"
    Add-Report "RAM Usage            : $([math]::Round($Usage,2)) %"

    Add-Report ""
    Add-Report "Physical Memory Modules:"

    foreach ($RAM in $MemoryModules) {

        Add-Report "----------------------------------------"
        Add-Report "Manufacturer         : $($RAM.Manufacturer)"
        Add-Report "Part Number          : $($RAM.PartNumber)"
        Add-Report "Capacity             : $([math]::Round($RAM.Capacity / 1GB,2)) GB"
        Add-Report "Speed                : $($RAM.Speed) MHz"
        Add-Report "Configured Clock     : $($RAM.ConfiguredClockSpeed) MHz"
        Add-Report "Memory Type          : $($RAM.MemoryType)"
        Add-Report "Device Locator       : $($RAM.DeviceLocator)"
        Add-Report "Bank Locator         : $($RAM.BankLabel)"
    }

    if ($Usage -ge 90) {
        Add-Warning "RAM usage is currently above 90%."
    }
    else {
        Add-OK "RAM usage is currently within a normal range."
    }
}


# ============================================================
# 9. DISKS
# ============================================================

Run-Test "Physical Disks" {

    Section "PHYSICAL DISKS"

    $Disks = Get-CimInstance Win32_DiskDrive

    foreach ($Disk in $Disks) {

        Add-Report "----------------------------------------"
        Add-Report "Model                : $($Disk.Model)"
        Add-Report "Manufacturer         : $($Disk.Manufacturer)"
        Add-Report "Interface            : $($Disk.InterfaceType)"
        Add-Report "Media Type           : $($Disk.MediaType)"
        Add-Report "Size                 : $([math]::Round($Disk.Size / 1GB,2)) GB"
        Add-Report "Partitions           : $($Disk.Partitions)"
        Add-Report "Status               : $($Disk.Status)"
        Add-Report "PNP Device ID        : $($Disk.PNPDeviceID)"

        if ($Disk.Status -ne "OK") {
            Add-Critical "Physical disk reports status: $($Disk.Status)"
        }
    }

    Add-OK "Physical disk inventory completed."
}


# ============================================================
# 10. SMART / STORAGE HEALTH
# ============================================================

Run-Test "SMART and Storage Health" {

    Section "SMART / STORAGE HEALTH"

    try {

        $Storage = Get-PhysicalDisk

        foreach ($Drive in $Storage) {

            Add-Report "----------------------------------------"
            Add-Report "Friendly Name        : $($Drive.FriendlyName)"
            Add-Report "Media Type           : $($Drive.MediaType)"
            Add-Report "Bus Type             : $($Drive.BusType)"
            Add-Report "Health Status        : $($Drive.HealthStatus)"
            Add-Report "Operational Status   : $($Drive.OperationalStatus)"
            Add-Report "Size                 : $([math]::Round($Drive.Size / 1GB,2)) GB"
            Add-Report "Firmware             : $($Drive.FirmwareVersion)"

            if ($Drive.HealthStatus -ne "Healthy") {
                Add-Critical "Storage device health is not Healthy: $($Drive.FriendlyName)"
            }
        }

    }
    catch {

        Add-Error "Get-PhysicalDisk could not retrieve complete storage health."
    }
}


# ============================================================
# 11. VOLUME HEALTH
# ============================================================

Run-Test "Volumes" {

    Section "VOLUMES / FILE SYSTEM"

    $Volumes = Get-Volume

    foreach ($Volume in $Volumes) {

        Add-Report "----------------------------------------"
        Add-Report "Drive Letter        : $($Volume.DriveLetter)"
        Add-Report "File System         : $($Volume.FileSystem)"
        Add-Report "File System Label   : $($Volume.FileSystemLabel)"
        Add-Report "Health Status       : $($Volume.HealthStatus)"
        Add-Report "Size                 : $([math]::Round($Volume.Size / 1GB,2)) GB"
        Add-Report "Free Space           : $([math]::Round($Volume.SizeRemaining / 1GB,2)) GB"

        if ($Volume.Size -gt 0) {

            $FreePercent = ($Volume.SizeRemaining / $Volume.Size) * 100

            Add-Report "Free Percentage      : $([math]::Round($FreePercent,2)) %"

            if ($FreePercent -lt 10) {
                Add-Warning "Volume $($Volume.DriveLetter): has less than 10% free space."
            }
        }

        if ($Volume.HealthStatus -ne "Healthy" -and
            $Volume.HealthStatus -ne $null) {

            Add-Critical "Volume $($Volume.DriveLetter): health status = $($Volume.HealthStatus)"
        }
    }
}


# ============================================================
# 12. FILE SYSTEM CHKDSK SCAN
# ============================================================

Run-Test "CHKDSK Read-Only Scan" {

    Section "CHKDSK / FILE SYSTEM INTEGRITY"

    $SystemDrive = $env:SystemDrive

    Add-Report "Running: chkdsk $SystemDrive /scan"
    Add-Report "This is a diagnostic scan. No /f repair is requested."

    $CHK = & chkdsk.exe "$SystemDrive" /scan 2>&1

    foreach ($Line in $CHK) {
        Add-Report "$Line"
    }

    Add-OK "CHKDSK diagnostic scan completed."
}


# ============================================================
# 13. WINDOWS SYSTEM FILE CHECK
# ============================================================

Run-Test "SFC Verification" {

    Section "WINDOWS SYSTEM FILE CHECKER"

    Add-Report "Running: sfc /verifyonly"
    Add-Report "This verifies protected Windows files without requesting repair."

    $SFC = & sfc.exe /verifyonly 2>&1

    foreach ($Line in $SFC) {
        Add-Report "$Line"
    }

    Add-OK "SFC verification completed."
}


# ============================================================
# 14. DISM COMPONENT STORE
# ============================================================

Run-Test "DISM Component Store Scan" {

    Section "DISM COMPONENT STORE"

    Add-Report "Running: DISM /Online /Cleanup-Image /ScanHealth"
    Add-Report "This scans the Windows component store."

    $DISM = & DISM.exe `
        /Online `
        /Cleanup-Image `
        /ScanHealth `
        2>&1

    foreach ($Line in $DISM) {
        Add-Report "$Line"
    }

    Add-OK "DISM ScanHealth completed."
}


# ============================================================
# 15. BIOS / UEFI / SECURE BOOT
# ============================================================

Run-Test "BIOS UEFI Secure Boot" {

    Section "BIOS / UEFI / SECURE BOOT"

    $BIOS = Get-CimInstance Win32_BIOS

    Add-Report "BIOS Vendor          : $($BIOS.Manufacturer)"
    Add-Report "BIOS Version         : $($BIOS.SMBIOSBIOSVersion)"
    Add-Report "BIOS Release Date    : $($BIOS.ReleaseDate)"
    Add-Report "SMBIOS Version       : $($BIOS.SMBIOSMajorVersion).$($BIOS.SMBIOSMinorVersion)"

    try {

        $FirmwareType = (Get-ItemProperty `
            "HKLM:\SYSTEM\CurrentControlSet\Control" `
            -Name "PEFirmwareType" `
            -ErrorAction Stop).PEFirmwareType

        switch ($FirmwareType) {

            1 {
                Add-Report "Firmware Type        : BIOS / Legacy"
            }

            2 {
                Add-Report "Firmware Type        : UEFI"
            }

            default {
                Add-Report "Firmware Type        : Unknown ($FirmwareType)"
            }
        }
    }
    catch {

        Add-Report "Firmware Type        : Unable to determine"
    }

    try {

        $SecureBoot = Confirm-SecureBootUEFI

        Add-Report "Secure Boot          : $SecureBoot"

        if ($SecureBoot -eq $true) {
            Add-OK "Secure Boot is enabled."
        }
        else {
            Add-Warning "Secure Boot is disabled."
        }

    }
    catch {

        Add-Report "Secure Boot          : Unsupported / Legacy BIOS / unavailable"
    }
}


# ============================================================
# 16. TPM
# ============================================================

Run-Test "TPM Health" {

    Section "TPM / TRUSTED PLATFORM MODULE"

    try {

        $TPM = Get-Tpm

        Add-Report "TPM Present          : $($TPM.TpmPresent)"
        Add-Report "TPM Ready            : $($TPM.TpmReady)"
        Add-Report "TPM Enabled          : $($TPM.TpmEnabled)"
        Add-Report "TPM Activated        : $($TPM.TpmActivated)"
        Add-Report "TPM Manufacturer     : $($TPM.ManufacturerId)"
        Add-Report "TPM Version           : $($TPM.ManufacturerVersion)"

        if ($TPM.TpmPresent -and $TPM.TpmReady) {
            Add-OK "TPM is present and ready."
        }
        elseif (-not $TPM.TpmPresent) {
            Add-Warning "TPM was not detected."
        }
        else {
            Add-Warning "TPM is present but not ready."
        }

    }
    catch {

        Add-Error "TPM information unavailable."
    }
}


# ============================================================
# 17. BOOT / BCD
# ============================================================

Run-Test "Boot Configuration" {

    Section "BOOT / BCD"

    Add-Report "BOOT CONFIGURATION DATA"
    Add-Report ""

    $BCD = & bcdedit.exe /enum all 2>&1

    foreach ($Line in $BCD) {
        Add-Report "$Line"
    }

    Add-OK "BCD configuration collected."
}


# ============================================================
# 18. BOOT EVENT LOG
# ============================================================

Run-Test "Boot Event Logs" {

    Section "BOOT EVENT LOG"

    try {

        $BootEvents = Get-WinEvent `
            -FilterHashtable @{
                LogName = "System"
                Id = 100
            } `
            -MaxEvents 20 `
            -ErrorAction SilentlyContinue

        foreach ($Event in $BootEvents) {

            Add-Report "----------------------------------------"
            Add-Report "Time       : $($Event.TimeCreated)"
            Add-Report "Provider   : $($Event.ProviderName)"
            Add-Report "ID         : $($Event.Id)"
            Add-Report "Message    : $($Event.Message)"
        }

        Add-OK "Recent boot-related event information collected."
    }
    catch {

        Add-Error "Boot event information unavailable."
    }
}


# ============================================================
# 19. DEVICE MANAGER / DRIVER ERRORS
# ============================================================

Run-Test "Device and Driver Health" {

    Section "DEVICE MANAGER / DRIVER HEALTH"

    $Devices = Get-CimInstance Win32_PnPEntity

    $ProblemDevices = $Devices |
        Where-Object {
            $_.ConfigManagerErrorCode -ne 0
        }

    Add-Report "Total PNP Devices   : $($Devices.Count)"
    Add-Report "Problem Devices     : $($ProblemDevices.Count)"
    Add-Report ""

    foreach ($Device in $ProblemDevices) {

        Add-Report "----------------------------------------"
        Add-Report "Name                 : $($Device.Name)"
        Add-Report "Device ID            : $($Device.DeviceID)"
        Add-Report "Error Code           : $($Device.ConfigManagerErrorCode)"
        Add-Report "Status               : $($Device.Status)"

        Add-Warning "Device problem detected: $($Device.Name)"
    }

    if ($ProblemDevices.Count -eq 0) {
        Add-OK "No PNP device configuration errors detected."
    }
}


# ============================================================
# 20. DRIVER INVENTORY
# ============================================================

Run-Test "Driver Inventory" {

    Section "DRIVER INVENTORY"

    $Drivers = Get-CimInstance Win32_PnPSignedDriver |
        Where-Object {
            $_.DeviceName -ne $null
        }

    foreach ($Driver in $Drivers) {

        Add-Report "----------------------------------------"
        Add-Report "Device               : $($Driver.DeviceName)"
        Add-Report "Manufacturer         : $($Driver.Manufacturer)"
        Add-Report "Driver Version       : $($Driver.DriverVersion)"
        Add-Report "Driver Date          : $($Driver.DriverDate)"
        Add-Report "Provider             : $($Driver.DriverProviderName)"
        Add-Report "Signer               : $($Driver.Signer)"
        Add-Report "Inf Name             : $($Driver.InfName)"
    }

    Add-OK "Driver inventory completed."
}


# ============================================================
# 21. GPU
# ============================================================

Run-Test "GPU Inventory" {

    Section "GRAPHICS / GPU"

    $GPUs = Get-CimInstance Win32_VideoController

    foreach ($GPU in $GPUs) {

        Add-Report "----------------------------------------"
        Add-Report "Name                 : $($GPU.Name)"
        Add-Report "Adapter RAM          : $([math]::Round($GPU.AdapterRAM / 1GB,2)) GB"
        Add-Report "Driver Version       : $($GPU.DriverVersion)"
        Add-Report "Driver Date          : $($GPU.DriverDate)"
        Add-Report "Video Processor      : $($GPU.VideoProcessor)"
        Add-Report "Current Resolution   : $($GPU.CurrentHorizontalResolution)x$($GPU.CurrentVerticalResolution)"
        Add-Report "Current Refresh      : $($GPU.CurrentRefreshRate) Hz"
        Add-Report "Status               : $($GPU.Status)"
    }

    Add-OK "GPU information collected."
}


# ============================================================
# 22. PAGE FILE / VIRTUAL MEMORY
# ============================================================

Run-Test "Virtual Memory" {

    Section "PAGE FILE / VIRTUAL MEMORY"

    $PageFiles = Get-CimInstance Win32_PageFileUsage

    foreach ($Page in $PageFiles) {

        Add-Report "----------------------------------------"
        Add-Report "Name                 : $($Page.Name)"
        Add-Report "Allocated Base       : $($Page.AllocatedBaseSize) MB"
        Add-Report "Current Usage        : $($Page.CurrentUsage) MB"
        Add-Report "Peak Usage           : $($Page.PeakUsage) MB"
    }

    $ComputerSystem = Get-CimInstance Win32_ComputerSystem

    Add-Report ""
    Add-Report "Automatic Pagefile Management: $($ComputerSystem.AutomaticManagedPagefile)"

    Add-OK "Virtual memory configuration collected."
}


# ============================================================
# 23. SERVICES
# ============================================================

Run-Test "Windows Services" {

    Section "WINDOWS SERVICES"

    $Services = Get-CimInstance Win32_Service

    Add-Report "Total Services      : $($Services.Count)"

    $Running = $Services |
        Where-Object { $_.State -eq "Running" }

    $Stopped = $Services |
        Where-Object { $_.State -eq "Stopped" }

    Add-Report "Running Services    : $($Running.Count)"
    Add-Report "Stopped Services    : $($Stopped.Count)"

    Add-Report ""
    Add-Report "Non-Microsoft / Third-Party Services:"

    $ThirdParty = $Services |
        Where-Object {
            $_.PathName -and
            $_.PathName -notmatch "Windows\\|Microsoft"
        }

    foreach ($Service in $ThirdParty) {

        Add-Report "----------------------------------------"
        Add-Report "Name                 : $($Service.Name)"
        Add-Report "Display Name         : $($Service.DisplayName)"
        Add-Report "State                : $($Service.State)"
        Add-Report "Start Mode           : $($Service.StartMode)"
        Add-Report "Path                 : $($Service.PathName)"
    }
}


# ============================================================
# 24. STARTUP ITEMS
# ============================================================

Run-Test "Startup Inventory" {

    Section "STARTUP PROGRAMS"

    try {

        $Startup = Get-CimInstance Win32_StartupCommand

        Add-Report "Startup Entries      : $($Startup.Count)"

        foreach ($Item in $Startup) {

            Add-Report "----------------------------------------"
            Add-Report "Name                 : $($Item.Name)"
            Add-Report "Command              : $($Item.Command)"
            Add-Report "Location             : $($Item.Location)"
            Add-Report "User                 : $($Item.User)"
        }

        Add-OK "Startup inventory collected."
    }
    catch {

        Add-Error "Startup inventory unavailable."
    }
}


# ============================================================
# 25. SCHEDULED TASKS
# ============================================================

Run-Test "Scheduled Tasks" {

    Section "SCHEDULED TASKS"

    try {

        $Tasks = Get-ScheduledTask

        Add-Report "Total Scheduled Tasks: $($Tasks.Count)"

        $RunningTasks = $Tasks |
            Where-Object {
                $_.State -eq "Running"
            }

        Add-Report "Currently Running    : $($RunningTasks.Count)"

        foreach ($Task in $RunningTasks) {

            Add-Report "----------------------------------------"
            Add-Report "Task Name            : $($Task.TaskName)"
            Add-Report "Task Path            : $($Task.TaskPath)"
            Add-Report "State                : $($Task.State)"
        }

    }
    catch {

        Add-Error "Scheduled task inventory unavailable."
    }
}


# ============================================================
# 26. CURRENT PROCESSES
# ============================================================

Run-Test "Process Analysis" {

    Section "CURRENT PROCESSES"

    $Processes = Get-Process |
        Sort-Object CPU -Descending

    Add-Report "Top CPU Processes:"
    Add-Report ""

    foreach ($Process in ($Processes | Select-Object -First 25)) {

        try {

            Add-Report "$($Process.ProcessName) | PID=$($Process.Id) | CPU=$([math]::Round($Process.CPU,2)) sec | RAM=$([math]::Round($Process.WorkingSet64/1MB,2)) MB"

        }
        catch {}
    }

    Add-Report ""
    Add-Report "Top Memory Processes:"
    Add-Report ""

    $MemoryProcesses = Get-Process |
        Sort-Object WorkingSet64 -Descending

    foreach ($Process in ($MemoryProcesses | Select-Object -First 25)) {

        Add-Report "$($Process.ProcessName) | PID=$($Process.Id) | RAM=$([math]::Round($Process.WorkingSet64/1MB,2)) MB"
    }

    Add-OK "Current process snapshot collected."
}


# ============================================================
# 27. NETWORK
# ============================================================

Run-Test "Network Configuration" {

    Section "NETWORK CONFIGURATION"

    $Adapters = Get-NetAdapter

    foreach ($Adapter in $Adapters) {

        Add-Report "----------------------------------------"
        Add-Report "Name                 : $($Adapter.Name)"
        Add-Report "Description          : $($Adapter.InterfaceDescription)"
        Add-Report "Status               : $($Adapter.Status)"
        Add-Report "Link Speed           : $($Adapter.LinkSpeed)"
        Add-Report "MAC                  : $($Adapter.MacAddress)"
    }

    Add-Report ""
    Add-Report "IP Configuration:"
    
    $IP = Get-NetIPConfiguration

    foreach ($Item in $IP) {

        Add-Report "----------------------------------------"
        Add-Report "Interface            : $($Item.InterfaceAlias)"
        Add-Report "IPv4                 : $($Item.IPv4Address.IPAddress -join ', ')"
        Add-Report "Gateway              : $($Item.IPv4DefaultGateway.NextHop)"
        Add-Report "DNS                  : $($Item.DNSServer.ServerAddresses -join ', ')"
    }

    Add-OK "Network configuration collected."
}


# ============================================================
# 28. FIREWALL
# ============================================================

Run-Test "Windows Firewall" {

    Section "WINDOWS FIREWALL"

    try {

        $FirewallProfiles = Get-NetFirewallProfile

        foreach ($Profile in $FirewallProfiles) {

            Add-Report "----------------------------------------"
            Add-Report "Profile              : $($Profile.Name)"
            Add-Report "Enabled              : $($Profile.Enabled)"
            Add-Report "Default Inbound      : $($Profile.DefaultInboundAction)"
            Add-Report "Default Outbound     : $($Profile.DefaultOutboundAction)"
            Add-Report "Log File             : $($Profile.LogFileName)"
        }

        Add-OK "Firewall configuration collected."
    }
    catch {

        Add-Error "Firewall information unavailable."
    }
}


# ============================================================
# 29. WINDOWS DEFENDER
# ============================================================

Run-Test "Microsoft Defender" {

    Section "MICROSOFT DEFENDER"

    try {

        $Defender = Get-MpComputerStatus

        Add-Report "Antivirus Enabled            : $($Defender.AntivirusEnabled)"
        Add-Report "Antivirus Running            : $($Defender.AntivirusActive)"
        Add-Report "Real-Time Protection         : $($Defender.RealTimeProtectionEnabled)"
        Add-Report "Behavior Monitoring           : $($Defender.BehaviorMonitorEnabled)"
        Add-Report "IOAV Protection               : $($Defender.IOAVProtectionEnabled)"
        Add-Report "AMSI Enabled                  : $($Defender.AMServiceEnabled)"
        Add-Report "Antispyware Enabled           : $($Defender.AntispywareEnabled)"
        Add-Report "NIS Protection                : $($Defender.NISEnabled)"
        Add-Report "Engine Version                : $($Defender.AMEngineVersion)"
        Add-Report "Product Version               : $($Defender.AMProductVersion)"
        Add-Report "Antivirus Signature Version   : $($Defender.AntivirusSignatureVersion)"
        Add-Report "Antivirus Signature Age       : $($Defender.AntivirusSignatureAge) days"
        Add-Report "Last Quick Scan               : $($Defender.QuickScanStartTime)"
        Add-Report "Last Full Scan                : $($Defender.FullScanStartTime)"

        if ($Defender.RealTimeProtectionEnabled) {
            Add-OK "Defender Real-Time Protection is enabled."
        }
        else {
            Add-Warning "Defender Real-Time Protection is disabled."
        }

    }
    catch {

        Add-Error "Microsoft Defender status unavailable."
    }
}


# ============================================================
# 30. WINDOWS UPDATE
# ============================================================

Run-Test "Windows Update Services" {

    Section "WINDOWS UPDATE"

    $UpdateServices = Get-Service `
        -Name `
        wuauserv, bits, UsoSvc `
        -ErrorAction SilentlyContinue

    foreach ($Service in $UpdateServices) {

        Add-Report "----------------------------------------"
        Add-Report "Service              : $($Service.Name)"
        Add-Report "Display Name         : $($Service.DisplayName)"
        Add-Report "Status               : $($Service.Status)"
        Add-Report "Start Type           : $($Service.StartType)"
    }

    Add-OK "Windows Update service state collected."
}


# ============================================================
# 31. EVENT LOG HEALTH
# ============================================================

Run-Test "Critical Event Logs" {

    Section "EVENT LOG HEALTH"

    $Logs = @(
        "System",
        "Application"
    )

    foreach ($LogName in $Logs) {

        Add-Report ""
        Add-Report "LOG: $LogName"

        try {

            $Events = Get-WinEvent `
                -FilterHashtable @{
                    LogName = $LogName
                    Level = 1,2,3
                    StartTime = (Get-Date).AddDays(-7)
                } `
                -MaxEvents 100 `
                -ErrorAction SilentlyContinue

            Add-Report "Critical/Error/Warning Events in last 7 days: $($Events.Count)"

            foreach ($Event in ($Events | Select-Object -First 30)) {

                Add-Report "----------------------------------------"
                Add-Report "Time       : $($Event.TimeCreated)"
                Add-Report "Provider   : $($Event.ProviderName)"
                Add-Report "ID         : $($Event.Id)"
                Add-Report "Level      : $($Event.LevelDisplayName)"
                Add-Report "Message    : $($Event.Message)"
            }

        }
        catch {

            Add-Error "Could not read $LogName event log."
        }
    }
}


# ============================================================
# 32. RESTORE POINTS
# ============================================================

Run-Test "System Restore" {

    Section "SYSTEM RESTORE"

    try {

        $RestorePoints = Get-CimInstance `
            -Namespace root/default `
            -ClassName SystemRestore `
            -ErrorAction Stop

        Add-Report "Restore Points Found: $($RestorePoints.Count)"

        foreach ($RP in ($RestorePoints | Sort-Object CreationTime -Descending | Select-Object -First 10)) {

            Add-Report "----------------------------------------"
            Add-Report "Sequence             : $($RP.SequenceNumber)"
            Add-Report "Description          : $($RP.Description)"
            Add-Report "Creation Time        : $($RP.CreationTime)"
        }

        if ($RestorePoints.Count -eq 0) {
            Add-Warning "No System Restore Points were found."
        }
        else {
            Add-OK "System Restore points are available."
        }
    }
    catch {

        Add-Error "System Restore information unavailable."
    }
}


# ============================================================
# 33. WINDOWS SECURITY CENTER
# ============================================================

Run-Test "Windows Security Center" {

    Section "WINDOWS SECURITY CENTER"

    try {

        $SecurityProducts = Get-CimInstance `
            -Namespace root/SecurityCenter2 `
            -ClassName AntiVirusProduct `
            -ErrorAction SilentlyContinue

        foreach ($Product in $SecurityProducts) {

            Add-Report "----------------------------------------"
            Add-Report "Product              : $($Product.displayName)"
            Add-Report "Path                 : $($Product.pathToSignedProductExe)"
            Add-Report "Reporting Status     : $($Product.productState)"
        }

        Add-OK "Security product inventory collected."
    }
    catch {

        Add-Error "Security Center information unavailable."
    }
}


# ============================================================
# 34. WINDOWS ACTIVATION
# ============================================================

Run-Test "Windows Licensing" {

    Section "WINDOWS LICENSE / ACTIVATION"

    try {

        $License = Get-CimInstance `
            -ClassName SoftwareLicensingProduct |
            Where-Object {
                $_.PartialProductKey -and
                $_.Name -like "Windows*"
            }

        foreach ($Item in $License) {

            Add-Report "----------------------------------------"
            Add-Report "Name                 : $($Item.Name)"
            Add-Report "Description          : $($Item.Description)"
            Add-Report "License Status       : $($Item.LicenseStatus)"
            Add-Report "Partial Product Key  : $($Item.PartialProductKey)"
        }

        Add-OK "Windows licensing state collected."
    }
    catch {

        Add-Error "Windows licensing information unavailable."
    }
}


# ============================================================
# 35. POWER / BATTERY
# ============================================================

Run-Test "Power and Battery" {

    Section "POWER / BATTERY"

    try {

        $Battery = Get-CimInstance Win32_Battery

        foreach ($B in $Battery) {

            Add-Report "----------------------------------------"
            Add-Report "Name                 : $($B.Name)"
            Add-Report "Status               : $($B.Status)"
            Add-Report "Battery Status       : $($B.BatteryStatus)"
            Add-Report "Estimated Charge     : $($B.EstimatedChargeRemaining)%"
            Add-Report "Estimated Runtime    : $($B.EstimatedRunTime) minutes"
        }

    }
    catch {}

    try {

        $PowerPlan = powercfg /getactivescheme 2>&1

        Add-Report ""
        Add-Report "Active Power Plan:"
        
        foreach ($Line in $PowerPlan) {
            Add-Report "$Line"
        }

    }
    catch {}

    Add-OK "Power configuration collected."
}


# ============================================================
# 36. WINDOWS MEMORY DIAGNOSTICS STATUS
# ============================================================

Run-Test "Windows Memory Diagnostic" {

    Section "WINDOWS MEMORY DIAGNOSTIC"

    try {

        $MemoryEvents = Get-WinEvent `
            -FilterHashtable @{
                LogName = "System"
                ProviderName = "Microsoft-Windows-MemoryDiagnostics-Results"
            } `
            -MaxEvents 10 `
            -ErrorAction SilentlyContinue

        if ($MemoryEvents) {

            foreach ($Event in $MemoryEvents) {

                Add-Report "----------------------------------------"
                Add-Report "Time       : $($Event.TimeCreated)"
                Add-Report "ID         : $($Event.Id)"
                Add-Report "Message    : $($Event.Message)"
            }

            Add-OK "Memory Diagnostic history found."
        }
        else {

            Add-Report "No Windows Memory Diagnostic result was found."
            Add-Info "This does NOT prove that RAM is defective."
        }

    }
    catch {

        Add-Error "Memory Diagnostic information unavailable."
    }
}


# ============================================================
# 37. WMI HEALTH
# ============================================================

Run-Test "WMI Health" {

    Section "WMI / MANAGEMENT INFRASTRUCTURE"

    try {

        $WMI = Get-CimInstance `
            -Namespace root/cimv2 `
            -ClassName Win32_OperatingSystem `
            -ErrorAction Stop

        if ($WMI) {
            Add-OK "WMI/CIM query infrastructure is responding normally."
        }

    }
    catch {

        Add-Critical "WMI/CIM query infrastructure returned an error."
    }
}


# ============================================================
# 38. WINDOWS BOOT CONFIGURATION FILES
# ============================================================

Run-Test "Boot Files" {

    Section "BOOT FILE / EFI INFORMATION"

    $EFI = "$env:SystemDrive\EFI"

    if (Test-Path $EFI) {

        Add-Report "EFI directory detected: $EFI"

        try {

            Get-ChildItem `
                -Path $EFI `
                -Recurse `
                -ErrorAction SilentlyContinue |
                Select-Object FullName,Length,LastWriteTime |
                ForEach-Object {

                    Add-Report "$($_.FullName) | $($_.Length) bytes | $($_.LastWriteTime)"
                }

            Add-OK "EFI boot file inventory collected."
        }
        catch {

            Add-Error "Could not fully inspect EFI directory."
        }

    }
    else {

        Add-Report "EFI directory not visible from system drive."
        Add-Info "This may be normal depending on firmware/storage configuration."
    }
}


# ============================================================
# 39. WINDOWS PERFORMANCE COUNTER SNAPSHOT
# ============================================================

Run-Test "Performance Snapshot" {

    Section "LIVE PERFORMANCE SNAPSHOT"

    try {

        $CPUCounter = Get-Counter `
            '\Processor(_Total)\% Processor Time' `
            -SampleInterval 1 `
            -MaxSamples 3

        Add-Report "CPU Samples:"

        foreach ($Sample in $CPUCounter.CounterSamples) {

            Add-Report "$([math]::Round($Sample.CookedValue,2)) %"
        }

    }
    catch {

        Add-Error "CPU performance counter unavailable."
    }


    try {

        $DiskCounter = Get-Counter `
            '\PhysicalDisk(_Total)\% Disk Time' `
            -SampleInterval 1 `
            -MaxSamples 3

        Add-Report ""
        Add-Report "Disk Samples:"

        foreach ($Sample in $DiskCounter.CounterSamples) {

            Add-Report "$([math]::Round($Sample.CookedValue,2)) %"
        }

    }
    catch {}

}


# ============================================================
# 40. TOP RESOURCE CONSUMERS
# ============================================================

Run-Test "Resource Consumer Analysis" {

    Section "RESOURCE CONSUMERS"

    $TopCPU = Get-Process |
        Sort-Object CPU -Descending |
        Select-Object -First 15

    Add-Report "TOP CPU PROCESSES"
    Add-Report "-----------------"

    foreach ($P in $TopCPU) {

        try {

            Add-Report "$($P.ProcessName) | PID=$($P.Id) | CPU=$([math]::Round($P.CPU,2))"

        }
        catch {}
    }


    $TopRAM = Get-Process |
        Sort-Object WorkingSet64 -Descending |
        Select-Object -First 15

    Add-Report ""
    Add-Report "TOP MEMORY PROCESSES"
    Add-Report "--------------------"

    foreach ($P in $TopRAM) {

        Add-Report "$($P.ProcessName) | PID=$($P.Id) | RAM=$([math]::Round($P.WorkingSet64 / 1MB,2)) MB"
    }

    Add-OK "Resource consumer analysis completed."
}


# ============================================================
# 41. SYSTEM HEALTH EVENTS
# ============================================================

Run-Test "Kernel and Hardware Error Events" {

    Section "KERNEL / HARDWARE ERROR EVENTS"

    try {

        $HardwareEvents = Get-WinEvent `
            -FilterHashtable @{
                LogName = "System"
                StartTime = (Get-Date).AddDays(-30)
            } `
            -MaxEvents 2000 `
            -ErrorAction SilentlyContinue |
            Where-Object {

                $_.ProviderName -match `
                "WHEA|Disk|Ntfs|storahci|stornvme|volmgr|Kernel-Power|Kernel-Boot"
            }

        Add-Report "Relevant events found: $($HardwareEvents.Count)"

        foreach ($Event in ($HardwareEvents | Select-Object -First 100)) {

            Add-Report "----------------------------------------"
            Add-Report "Time       : $($Event.TimeCreated)"
            Add-Report "Provider   : $($Event.ProviderName)"
            Add-Report "ID         : $($Event.Id)"
            Add-Report "Level      : $($Event.LevelDisplayName)"
            Add-Report "Message    : $($Event.Message)"
        }

        if ($HardwareEvents.Count -eq 0) {
            Add-OK "No matching kernel/storage/hardware events found in the inspected period."
        }
        else {
            Add-Warning "Kernel/storage/hardware-related events were found. Review the detailed section."
        }

    }
    catch {

        Add-Error "Hardware event analysis unavailable."
    }
}


# ============================================================
# 42. CRASH / BLUE SCREEN EVENTS
# ============================================================

Run-Test "Crash and BugCheck History" {

    Section "CRASH / BLUE SCREEN / BUGCHECK HISTORY"

    try {

        $CrashEvents = Get-WinEvent `
            -FilterHashtable @{
                LogName = "System"
                Id = 41,1001,6008
                StartTime = (Get-Date).AddDays(-30)
            } `
            -MaxEvents 100 `
            -ErrorAction SilentlyContinue

        Add-Report "Crash-related events in last 30 days: $($CrashEvents.Count)"

        foreach ($Event in $CrashEvents) {

            Add-Report "----------------------------------------"
            Add-Report "Time       : $($Event.TimeCreated)"
            Add-Report "Provider   : $($Event.ProviderName)"
            Add-Report "ID         : $($Event.Id)"
            Add-Report "Message    : $($Event.Message)"
        }

        if ($CrashEvents.Count -eq 0) {
            Add-OK "No recent BugCheck/Kernel-Power/Unexpected Shutdown events detected."
        }
        else {
            Add-Warning "Recent crash or unexpected shutdown events detected."
        }

    }
    catch {

        Add-Error "Crash history analysis unavailable."
    }
}


# ============================================================
# 43. SYSTEM FILE / WINDOWS DIRECTORY CHECK
# ============================================================

Run-Test "Core Windows Paths" {

    Section "CORE WINDOWS PATHS"

    $Paths = @(
        "$env:windir",
        "$env:windir\System32",
        "$env:windir\System32\drivers",
        "$env:ProgramFiles",
        "${env:ProgramFiles(x86)}"
    )

    foreach ($Path in $Paths) {

        if (Test-Path $Path) {
            Add-Report "[OK] $Path"
        }
        else {
            Add-Warning "Expected Windows path not found: $Path"
        }
    }
}


# ============================================================
# 44. ENVIRONMENT / PATH
# ============================================================

Run-Test "Environment Configuration" {

    Section "ENVIRONMENT / PATH"

    Add-Report "PATH:"
    Add-Report $env:PATH

    Add-Report ""
    Add-Report "TEMP                : $env:TEMP"
    Add-Report "TMP                 : $env:TMP"
    Add-Report "ProgramFiles        : $env:ProgramFiles"
    Add-Report "ProgramFiles(x86)   : ${env:ProgramFiles(x86)}"
    Add-Report "SystemRoot          : $env:SystemRoot"

    Add-OK "Environment information collected."
}


# ============================================================
# 45. FINAL HEALTH ANALYSIS
# ============================================================

Section "FINAL HEALTH ANALYSIS"

if ($HealthScore -lt 0) {
    $HealthScore = 0
}

$Rating = ""

if ($CriticalIssues -gt 0) {
    $Rating = "CRITICAL - Investigation Required"
}
elseif ($HealthScore -ge 90) {
    $Rating = "EXCELLENT"
}
elseif ($HealthScore -ge 80) {
    $Rating = "GOOD"
}
elseif ($HealthScore -ge 70) {
    $Rating = "FAIR"
}
elseif ($HealthScore -ge 50) {
    $Rating = "WARNING"
}
else {
    $Rating = "POOR"
}

Add-Report ""
Add-Report "HEALTH SCORE          : $HealthScore / 100"
Add-Report "RATING                : $Rating"
Add-Report "Critical Issues      : $CriticalIssues"
Add-Report "Warnings             : $WarningIssues"
Add-Report "Informational Items  : $InfoIssues"
Add-Report "Audit Errors         : $($AuditErrors.Count)"


# ============================================================
# 46. FINAL INTERPRETATION
# ============================================================

Add-Report ""
Add-Report "INTERPRETATION"
Add-Report "------------------------------------------------------------------"

if ($CriticalIssues -eq 0 -and $HealthScore -ge 90) {

    Add-Report "SYSTEM RESULT: No major diagnostic problem was detected by this audit."

}
elseif ($CriticalIssues -eq 0 -and $HealthScore -ge 80) {

    Add-Report "SYSTEM RESULT: System appears generally healthy. Review warnings if present."

}
elseif ($CriticalIssues -eq 0) {

    Add-Report "SYSTEM RESULT: System is operational but requires review of warnings."

}
else {

    Add-Report "SYSTEM RESULT: One or more potentially significant problems require investigation."
}


Add-Report ""
Add-Report "IMPORTANT:"
Add-Report "This audit is diagnostic and cannot prove physical hardware health with 100% certainty."
Add-Report "SMART, Windows logs, SFC and DISM are indicators and should be interpreted together."
Add-Report "No intentional configuration changes were performed by this script."
Add-Report ""
Add-Report "Audit Finished: $(Get-Date)"


# ============================================================
# 47. ERROR FILE
# ============================================================

if ($AuditErrors.Count -gt 0) {

    $AuditErrors |
        Out-File `
            -FilePath $ErrorFile `
            -Encoding UTF8
}
else {

    "No script-level audit errors were recorded." |
        Out-File `
            -FilePath $ErrorFile `
            -Encoding UTF8
}


# ============================================================
# 48. SUMMARY FILE
# ============================================================

@"
======================================================================
FULL SYSTEM HEALTH AUDIT - SUMMARY
======================================================================

Computer       : $env:COMPUTERNAME
Audit Time     : $(Get-Date)

HEALTH SCORE   : $HealthScore / 100
RATING         : $Rating

Critical Issues : $CriticalIssues
Warnings        : $WarningIssues
Info Items      : $InfoIssues
Audit Errors    : $($AuditErrors.Count)

----------------------------------------------------------------------
IMPORTANT RESULT
----------------------------------------------------------------------

This was a READ-ONLY diagnostic audit.

No intentional changes were made to:
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
- Network Configuration

----------------------------------------------------------------------
FILES
----------------------------------------------------------------------

Full Report:
$ReportFile

Errors:
$ErrorFile

======================================================================
"@ | Out-File `
    -FilePath $SummaryFile `
    -Encoding UTF8


# ============================================================
# 49. CONSOLE SUMMARY
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " FULL SYSTEM HEALTH AUDIT COMPLETED" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if ($HealthScore -ge 90 -and $CriticalIssues -eq 0) {

    Write-Host "[HEALTH] $HealthScore / 100 - EXCELLENT" -ForegroundColor Green

}
elseif ($HealthScore -ge 80 -and $CriticalIssues -eq 0) {

    Write-Host "[HEALTH] $HealthScore / 100 - GOOD" -ForegroundColor Green

}
elseif ($CriticalIssues -eq 0) {

    Write-Host "[HEALTH] $HealthScore / 100 - REVIEW WARNINGS" -ForegroundColor Yellow

}
else {

    Write-Host "[HEALTH] $HealthScore / 100 - CRITICAL REVIEW REQUIRED" -ForegroundColor Red
}

Write-Host ""
Write-Host "Critical Issues : $CriticalIssues" -ForegroundColor Red
Write-Host "Warnings        : $WarningIssues" -ForegroundColor Yellow
Write-Host "Audit Errors    : $($AuditErrors.Count)" -ForegroundColor Yellow
Write-Host ""

Write-Host "Full Report:" -ForegroundColor Cyan
Write-Host "$ReportFile"

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "$SummaryFile"

Write-Host ""
Write-Host "Errors:" -ForegroundColor Cyan
Write-Host "$ErrorFile"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " IMPORTANT: NO SYSTEM CONFIGURATION WAS INTENTIONALLY CHANGED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

pause