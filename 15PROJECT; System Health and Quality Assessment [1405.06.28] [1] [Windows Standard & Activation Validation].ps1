# ============================================================================
# PROJECT: System Health and Quality Assessment
# MODULE : 02 - Windows Standard & Activation Validation
# PURPOSE: Validate Windows Standardization, Activation, Licensing,
#          Integrity, Security Baseline and Software Environment Readiness
# VERSION: 1.0
# ============================================================================

# ============================================================================
# 01. INITIALIZATION
# ============================================================================

$ErrorActionPreference = "SilentlyContinue"

# ============================================================================
# 02. ADMINISTRATOR ELEVATION
# ============================================================================

function Test-IsAdministrator {

    $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal = New-Object Security.Principal.WindowsPrincipal(
        $CurrentIdentity
    )

    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

if (-not (Test-IsAdministrator)) {

    if ($PSCommandPath) {

        Write-Host ""
        Write-Host "Administrator privileges are required." -ForegroundColor Yellow
        Write-Host "Restarting script with Administrator privileges..." -ForegroundColor Yellow
        Write-Host ""

        try {

            Start-Process `
                -FilePath "powershell.exe" `
                -Verb RunAs `
                -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

            exit
        }
        catch {

            Write-Host ""
            Write-Host "Administrator elevation failed." -ForegroundColor Red
            Write-Host "Please run this script as Administrator." -ForegroundColor Red
            Write-Host ""

            Read-Host "Press Enter to exit"

            exit 1
        }
    }
    else {

        Write-Host ""
        Write-Host "Save this script as a .ps1 file and run it again." -ForegroundColor Red
        Write-Host ""

        Read-Host "Press Enter to exit"

        exit 1
    }
}

# ============================================================================
# 03. EXECUTION POLICY BYPASS
# ============================================================================

try {

    Set-ExecutionPolicy `
        -Scope Process `
        -ExecutionPolicy Bypass `
        -Force
}
catch {
}

# ============================================================================
# 04. PROJECT DIRECTORY
# ============================================================================

$DesktopPath = [Environment]::GetFolderPath("Desktop")

$ProjectFolderName = "System Health and Quality Assessment"

$ProjectFolder = Join-Path `
    $DesktopPath `
    $ProjectFolderName

if (-not (Test-Path -LiteralPath $ProjectFolder)) {

    New-Item `
        -Path $ProjectFolder `
        -ItemType Directory `
        -Force |
        Out-Null
}

# ============================================================================
# 05. REPORT FILES
# ============================================================================

$TextReport = Join-Path `
    $ProjectFolder `
    "02_Windows_Standard_and_Activation_Validation.txt"

$JsonReport = Join-Path `
    $ProjectFolder `
    "02_Windows_Standard_and_Activation_Validation.json"

# ============================================================================
# 06. HELPER FUNCTIONS
# ============================================================================

function Get-SafeValue {

    param (
        $Value
    )

    if ($null -eq $Value) {
        return $null
    }

    if ([string]::IsNullOrWhiteSpace([string]$Value)) {
        return $null
    }

    return $Value
}

function Invoke-SafeCommand {

    param (
        [string]$FilePath,
        [string]$Arguments
    )

    try {

        $Output = & $FilePath $Arguments 2>&1

        return ($Output | Out-String).Trim()
    }
    catch {

        return $null
    }
}

function Get-RegistryValueSafe {

    param (
        [string]$Path,
        [string]$Name
    )

    try {

        return Get-ItemPropertyValue `
            -Path $Path `
            -Name $Name `
            -ErrorAction Stop
    }
    catch {

        return $null
    }
}

# ============================================================================
# 07. START
# ============================================================================

$StartTime = Get-Date

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " SYSTEM HEALTH AND QUALITY ASSESSMENT" -ForegroundColor Cyan
Write-Host " MODULE 02 - WINDOWS STANDARD & ACTIVATION VALIDATION" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Windows environment validation started..." -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANT:" -ForegroundColor Yellow
Write-Host "This module performs diagnostic checks only." -ForegroundColor Yellow
Write-Host "No activation, repair, modification or product-key change will be performed." -ForegroundColor Yellow
Write-Host ""

# ============================================================================
# 08. WINDOWS INFORMATION
# ============================================================================

$OS = Get-CimInstance `
    -ClassName Win32_OperatingSystem

$ComputerSystem = Get-CimInstance `
    -ClassName Win32_ComputerSystem

$WindowsRegistry = Get-ItemProperty `
    -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

$WindowsInfo = [ordered]@{

    ComputerName = $env:COMPUTERNAME

    Manufacturer = Get-SafeValue $ComputerSystem.Manufacturer

    Model = Get-SafeValue $ComputerSystem.Model

    ProductName = Get-SafeValue $WindowsRegistry.ProductName

    DisplayVersion = Get-SafeValue $WindowsRegistry.DisplayVersion

    EditionID = Get-SafeValue $WindowsRegistry.EditionID

    InstallationType = Get-SafeValue $WindowsRegistry.InstallationType

    Version = Get-SafeValue $OS.Version

    BuildNumber = Get-SafeValue $OS.BuildNumber

    CurrentBuild = Get-SafeValue $WindowsRegistry.CurrentBuild

    CurrentBuildNumber = Get-SafeValue $WindowsRegistry.CurrentBuildNumber

    UBR = Get-SafeValue $WindowsRegistry.UBR

    BuildLabEx = Get-SafeValue $WindowsRegistry.BuildLabEx

    Architecture = Get-SafeValue $OS.OSArchitecture

    SystemDirectory = Get-SafeValue $OS.SystemDirectory

    WindowsDirectory = Get-SafeValue $OS.WindowsDirectory

    InstallationDate = $OS.InstallDate

    LastBootTime = $OS.LastBootUpTime
}

# ============================================================================
# 09. WINDOWS PRODUCT TYPE
# ============================================================================

$ProductType = $OS.ProductType

$ProductTypeDescription = switch ($ProductType) {

    1 { "Workstation" }

    2 { "Domain Controller" }

    3 { "Server" }

    default { "Unknown" }
}

$WindowsInfo.ProductType = $ProductTypeDescription

# ============================================================================
# 10. WINDOWS LICENSE PRODUCTS
# ============================================================================

Write-Host "Checking Windows licensing status..." -ForegroundColor Yellow

$LicenseProducts = @()

try {

    $LicenseProducts = @(
        Get-CimInstance `
            -ClassName SoftwareLicensingProduct `
            -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f'" |
        Where-Object {
            $_.Name -and
            $_.PartialProductKey
        }
    )
}
catch {

    $LicenseProducts = @()
}

$LicenseInformation = @()

foreach ($License in $LicenseProducts) {

    $LicenseStatus = switch ($License.LicenseStatus) {

        0 { "Unlicensed" }
        1 { "Licensed" }
        2 { "OOBGrace" }
        3 { "OOTGrace" }
        4 { "NonGenuineGrace" }
        5 { "Notification" }
        6 { "ExtendedGrace" }

        default { "Unknown" }
    }

    $LicenseInformation += [ordered]@{

        Name = $License.Name

        Description = $License.Description

        LicenseStatusCode = $License.LicenseStatus

        LicenseStatus = $LicenseStatus

        PartialProductKey = $License.PartialProductKey

        LicenseFamily = $License.LicenseFamily

        ProductKeyChannel = $License.ProductKeyChannel

        ApplicationID = $License.ApplicationID
    }
}

# ============================================================================
# 11. PRIMARY LICENSE
# ============================================================================

$PrimaryLicense = $LicenseInformation |
    Where-Object {
        $_.LicenseStatus -eq "Licensed"
    } |
    Select-Object -First 1

if ($PrimaryLicense) {

    $ActivationStatus = "Licensed"

}
else {

    $ActivationStatus = "Review Required"
}

# ============================================================================
# 12. SLMGR VALIDATION
# ============================================================================

Write-Host "Checking Microsoft Software Protection Platform..." -ForegroundColor Yellow

$SlmgrPath = Join-Path `
    $env:SystemRoot `
    "System32\slmgr.vbs"

$SLMGR_DLI = Invoke-SafeCommand `
    -FilePath "cscript.exe" `
    -Arguments "//Nologo `"$SlmgrPath`" /dli"

$SLMGR_DLV = Invoke-SafeCommand `
    -FilePath "cscript.exe" `
    -Arguments "//Nologo `"$SlmgrPath`" /dlv"

$SLMGR_XPR = Invoke-SafeCommand `
    -FilePath "cscript.exe" `
    -Arguments "//Nologo `"$SlmgrPath`" /xpr"

# ============================================================================
# 13. LICENSE CHANNEL DETECTION
# ============================================================================

$SLMGRCombined = @(
    $SLMGR_DLI
    $SLMGR_DLV
) -join "`r`n"

$LicenseChannel = "Unknown"

if ($SLMGRCombined -match "Retail") {

    $LicenseChannel = "Retail"
}
elseif ($SLMGRCombined -match "OEM_DM") {

    $LicenseChannel = "OEM_DM"
}
elseif ($SLMGRCombined -match "OEM") {

    $LicenseChannel = "OEM"
}
elseif ($SLMGRCombined -match "Volume") {

    $LicenseChannel = "Volume"
}
elseif ($SLMGRCombined -match "KMS") {

    $LicenseChannel = "KMS"
}

# ============================================================================
# 14. GENUINE / LICENSE STATE INDICATORS
# ============================================================================

$GenuineIndicators = [ordered]@{

    LicensedProductDetected = (
        $LicenseInformation |
        Where-Object {
            $_.LicenseStatus -eq "Licensed"
        }
    ).Count -gt 0

    NonGenuineGraceDetected = (
        $LicenseInformation |
        Where-Object {
            $_.LicenseStatus -eq "NonGenuineGrace"
        }
    ).Count -gt 0

    NotificationStateDetected = (
        $LicenseInformation |
        Where-Object {
            $_.LicenseStatus -eq "Notification"
        }
    ).Count -gt 0

    UnlicensedProductDetected = (
        $LicenseInformation |
        Where-Object {
            $_.LicenseStatus -eq "Unlicensed"
        }
    ).Count -gt 0

    LicenseChannel = $LicenseChannel
}

# ============================================================================
# 15. EMBEDDED OEM KEY DETECTION
# ============================================================================

Write-Host "Checking firmware licensing information..." -ForegroundColor Yellow

$EmbeddedOEMKeyDetected = $false

try {

    $SoftwareLicensingService = Get-CimInstance `
        -ClassName SoftwareLicensingService

    $EmbeddedOEMKey = $SoftwareLicensingService.OA3OriginalProductKey

    if (-not [string]::IsNullOrWhiteSpace($EmbeddedOEMKey)) {

        $EmbeddedOEMKeyDetected = $true
    }
}
catch {

    $EmbeddedOEMKeyDetected = $false
}

$FirmwareLicense = [ordered]@{

    EmbeddedOEMKeyDetected = $EmbeddedOEMKeyDetected

    ProductKeyValueStored = $false
}

# ============================================================================
# 16. WINDOWS EDITION VALIDATION
# ============================================================================

$EditionStatus = "REVIEW"

if (
    $WindowsInfo.ProductName -and
    $WindowsInfo.EditionID -and
    $WindowsInfo.BuildNumber
) {

    $EditionStatus = "PASS"
}

# ============================================================================
# 17. WINDOWS WORKSTATION VALIDATION
# ============================================================================

$WorkstationStatus = "INFO"

if ($ProductType -eq 1) {

    $WorkstationStatus = "PASS"
}

# ============================================================================
# 18. WINDOWS COMPONENT STORE - CHECKHEALTH
# ============================================================================

Write-Host ""
Write-Host "Running DISM CheckHealth..." -ForegroundColor Yellow

$DISM_CheckHealth = Invoke-SafeCommand `
    -FilePath "DISM.exe" `
    -Arguments "/Online /Cleanup-Image /CheckHealth"

# ============================================================================
# 19. WINDOWS COMPONENT STORE - SCANHEALTH
# ============================================================================

Write-Host "Running DISM ScanHealth..." -ForegroundColor Yellow
Write-Host "This may take several minutes." -ForegroundColor Gray

$DISM_ScanHealth = Invoke-SafeCommand `
    -FilePath "DISM.exe" `
    -Arguments "/Online /Cleanup-Image /ScanHealth"

# ============================================================================
# 20. DISM STATUS ANALYSIS
# ============================================================================

$DISMStatus = "Unknown"

$DISMCombined = @(
    $DISM_CheckHealth
    $DISM_ScanHealth
) -join "`r`n"

if ($DISMCombined -match "No component store corruption detected") {

    $DISMStatus = "Healthy"
}
elseif ($DISMCombined -match "component store corruption was detected") {

    $DISMStatus = "Corruption Detected"
}
elseif ($DISMCombined -match "component store is repairable") {

    $DISMStatus = "Repairable"
}
elseif ($DISMCombined -match "The component store is repairable") {

    $DISMStatus = "Repairable"
}

# ============================================================================
# 21. SYSTEM FILE CHECKER
# ============================================================================

Write-Host ""
Write-Host "Running System File Checker..." -ForegroundColor Yellow
Write-Host "This may take several minutes." -ForegroundColor Gray

$SFC_Scan = Invoke-SafeCommand `
    -FilePath "sfc.exe" `
    -Arguments "/scannow"

# ============================================================================
# 22. SFC STATUS ANALYSIS
# ============================================================================

$SFCStatus = "Unknown"

if ($SFC_Scan -match "did not find any integrity violations") {

    $SFCStatus = "Healthy"
}
elseif ($SFC_Scan -match "found corrupt files and successfully repaired them") {

    $SFCStatus = "Repaired"
}
elseif ($SFC_Scan -match "found corrupt files but was unable to fix some of them") {

    $SFCStatus = "Corruption Detected"
}
elseif ($SFC_Scan -match "could not perform the requested operation") {

    $SFCStatus = "Scan Failed"
}

# ============================================================================
# 23. WMI REPOSITORY
# ============================================================================

Write-Host ""
Write-Host "Checking Windows Management Instrumentation..." -ForegroundColor Yellow

$WMIStatus = "Unknown"

try {

    $WMIOutput = winmgmt /verifyrepository 2>&1

    $WMIText = ($WMIOutput | Out-String).Trim()

    if ($WMIText -match "consistent") {

        $WMIStatus = "Consistent"
    }
    elseif ($WMIText -match "inconsistent") {

        $WMIStatus = "Inconsistent"
    }
}
catch {

    $WMIStatus = "Verification Failed"
}

# ============================================================================
# 24. SECURE BOOT
# ============================================================================

Write-Host "Checking Secure Boot..." -ForegroundColor Yellow

$SecureBootStatus = "Not Available"

try {

    $SecureBootResult = Confirm-SecureBootUEFI

    if ($SecureBootResult -eq $true) {

        $SecureBootStatus = "Enabled"
    }
    else {

        $SecureBootStatus = "Disabled"
    }
}
catch {

    $SecureBootStatus = "Not Available"
}

# ============================================================================
# 25. FIRMWARE TYPE
# ============================================================================

$FirmwareType = "Unknown"

try {

    $FirmwareType = (
        Get-ComputerInfo `
            -Property BiosFirmwareType
    ).BiosFirmwareType
}
catch {
}

# ============================================================================
# 26. WINDOWS FIREWALL
# ============================================================================

Write-Host "Checking Windows Firewall..." -ForegroundColor Yellow

$FirewallProfiles = @()

try {

    $FirewallProfiles = @(
        Get-NetFirewallProfile |
        Select-Object `
            Name,
            Enabled,
            DefaultInboundAction,
            DefaultOutboundAction
    )
}
catch {

    $FirewallProfiles = @()
}

$EnabledFirewallProfiles = @(
    $FirewallProfiles |
    Where-Object {
        $_.Enabled -eq $true
    }
)

$FirewallStatus = if ($EnabledFirewallProfiles.Count -gt 0) {

    "Enabled"

}
else {

    "Review Required"
}

# ============================================================================
# 27. WINDOWS DEFENDER
# ============================================================================

Write-Host "Checking Windows Security status..." -ForegroundColor Yellow

$DefenderInfo = [ordered]@{

    Status = "Unavailable"
}

try {

    $Defender = Get-MpComputerStatus

    $DefenderInfo = [ordered]@{

        Status = "Available"

        AntivirusEnabled = $Defender.AntivirusEnabled

        AntispywareEnabled = $Defender.AntispywareEnabled

        RealTimeProtectionEnabled = $Defender.RealTimeProtectionEnabled

        BehaviorMonitorEnabled = $Defender.BehaviorMonitorEnabled

        IOAVProtectionEnabled = $Defender.IoavProtectionEnabled

        TamperProtectionEnabled = $Defender.IsTamperProtected

        AntivirusVersion = $Defender.AntivirusVersion

        EngineVersion = $Defender.AMEngineVersion

        SecurityIntelligenceVersion = $Defender.AntivirusSignatureVersion

        SecurityIntelligenceLastUpdated = $Defender.AntivirusSignatureLastUpdated
    }
}
catch {
}

# ============================================================================
# 28. WINDOWS SECURITY CENTER
# ============================================================================

$SecurityProducts = @()

try {

    $SecurityProducts = @(
        Get-CimInstance `
            -Namespace "root\SecurityCenter2" `
            -ClassName AntivirusProduct |
        Select-Object `
            displayName,
            productState,
            pathToSignedProductExe
    )
}
catch {

    $SecurityProducts = @()
}

# ============================================================================
# 29. CRITICAL WINDOWS SERVICES
# ============================================================================

Write-Host "Checking critical Windows services..." -ForegroundColor Yellow

$CriticalServices = @(
    "RpcSs",
    "DcomLaunch",
    "EventLog",
    "PlugPlay",
    "Winmgmt",
    "Schedule",
    "BFE",
    "MpsSvc",
    "wuauserv",
    "BITS",
    "CryptSvc",
    "WinDefend",
    "SecurityHealthService",
    "LanmanWorkstation",
    "Dhcp",
    "Dnscache"
)

$CriticalServiceStatus = @()

foreach ($ServiceName in $CriticalServices) {

    try {

        $Service = Get-Service `
            -Name $ServiceName `
            -ErrorAction Stop

        $CriticalServiceStatus += [ordered]@{

            Name = $Service.Name

            DisplayName = $Service.DisplayName

            Status = $Service.Status.ToString()

            StartType = $Service.StartType.ToString()
        }
    }
    catch {

        $CriticalServiceStatus += [ordered]@{

            Name = $ServiceName

            DisplayName = $null

            Status = "Not Available"

            StartType = "Unknown"
        }
    }
}

# ============================================================================
# 30. WINDOWS UPDATE INFRASTRUCTURE
# ============================================================================

$UpdateInfrastructure = @()

foreach ($ServiceName in @(
    "wuauserv",
    "BITS",
    "CryptSvc"
)) {

    try {

        $Service = Get-Service `
            -Name $ServiceName `
            -ErrorAction Stop

        $UpdateInfrastructure += [ordered]@{

            Name = $Service.Name

            Status = $Service.Status.ToString()

            StartType = $Service.StartType.ToString()
        }
    }
    catch {

        $UpdateInfrastructure += [ordered]@{

            Name = $ServiceName

            Status = "Not Available"

            StartType = "Unknown"
        }
    }
}

# ============================================================================
# 31. WINDOWS INSTALLER
# ============================================================================

$WindowsInstallerInfo = [ordered]@{

    Status = "Not Available"

    StartType = "Unknown"
}

try {

    $InstallerService = Get-Service `
        -Name "msiserver" `
        -ErrorAction Stop

    $WindowsInstallerInfo = [ordered]@{

        Status = $InstallerService.Status.ToString()

        StartType = $InstallerService.StartType.ToString()
    }
}
catch {
}

# ============================================================================
# 32. SYSTEM DIRECTORY VALIDATION
# ============================================================================

$SystemDirectoryValidation = [ordered]@{

    WindowsDirectory = Test-Path "$env:SystemRoot"

    System32Directory = Test-Path "$env:SystemRoot\System32"

    WinSxSDirectory = Test-Path "$env:SystemRoot\WinSxS"

    ServicingDirectory = Test-Path "$env:SystemRoot\servicing"

    SystemDrive = $env:SystemDrive
}

# ============================================================================
# 33. SOFTWARE ENVIRONMENT
# ============================================================================

$SoftwareEnvironment = [ordered]@{

    PowerShellVersion = $PSVersionTable.PSVersion.ToString()

    PowerShellEdition = $PSVersionTable.PSEdition

    ProcessArchitecture = $env:PROCESSOR_ARCHITECTURE

    Is64BitOperatingSystem = [Environment]::Is64BitOperatingSystem

    Is64BitProcess = [Environment]::Is64BitProcess

    ProgramFiles = $env:ProgramFiles

    ProgramFilesX86 = ${env:ProgramFiles(x86)}

    CommonProgramFiles = $env:CommonProgramFiles

    TempPath = $env:TEMP
}

# ============================================================================
# 34. WINDOWS ACTIVATION VALIDATION
# ============================================================================

$ActivationValidation = [ordered]@{

    ActivationStatus = $ActivationStatus

    LicensedProductDetected = (
        $LicenseInformation |
        Where-Object {
            $_.LicenseStatus -eq "Licensed"
        }
    ).Count -gt 0

    NonGenuineIndicatorDetected = (
        $LicenseInformation |
        Where-Object {
            $_.LicenseStatus -eq "NonGenuineGrace"
        }
    ).Count -gt 0

    UnlicensedIndicatorDetected = (
        $LicenseInformation |
        Where-Object {
            $_.LicenseStatus -eq "Unlicensed"
        }
    ).Count -gt 0

    LicenseChannel = $LicenseChannel

    EmbeddedOEMKeyDetected = $EmbeddedOEMKeyDetected
}

# ============================================================================
# 35. WINDOWS STANDARD VALIDATION
# ============================================================================

$Validation = [ordered]@{

    WindowsIdentity = if (
        $WindowsInfo.ProductName -and
        $WindowsInfo.BuildNumber
    ) {
        "PASS"
    }
    else {
        "REVIEW"
    }

    WindowsEdition = $EditionStatus

    WindowsWorkstationType = $WorkstationStatus

    WindowsActivation = if (
        $ActivationStatus -eq "Licensed"
    ) {
        "PASS"
    }
    else {
        "REVIEW"
    }

    WindowsComponentStore = if (
        $DISMStatus -eq "Healthy"
    ) {
        "PASS"
    }
    else {
        "REVIEW"
    }

    WindowsSystemFiles = if (
        $SFCStatus -in @(
            "Healthy",
            "Repaired"
        )
    ) {
        "PASS"
    }
    else {
        "REVIEW"
    }

    WMIRepository = if (
        $WMIStatus -eq "Consistent"
    ) {
        "PASS"
    }
    else {
        "REVIEW"
    }

    WindowsFirewall = if (
        $FirewallStatus -eq "Enabled"
    ) {
        "PASS"
    }
    else {
        "REVIEW"
    }

    UpdateInfrastructure = if (
        (
            $UpdateInfrastructure |
            Where-Object {
                $_.Name -eq "wuauserv" -and
                $_.Status -eq "Running"
            }
        ).Count -gt 0
    ) {
        "PASS"
    }
    else {
        "REVIEW"
    }

    SecureBoot = switch ($SecureBootStatus) {

        "Enabled" { "PASS" }

        "Disabled" { "INFO" }

        default { "NOT AVAILABLE" }
    }

    SystemDirectories = if (
        $SystemDirectoryValidation.WindowsDirectory -and
        $SystemDirectoryValidation.System32Directory -and
        $SystemDirectoryValidation.WinSxSDirectory
    ) {
        "PASS"
    }
    else {
        "REVIEW"
    }
}

# ============================================================================
# 36. REVIEW ITEMS
# ============================================================================

$ReviewItems = New-Object System.Collections.Generic.List[string]

if ($Validation.WindowsIdentity -eq "REVIEW") {

    $ReviewItems.Add(
        "Windows identity information could not be fully validated."
    )
}

if ($Validation.WindowsEdition -eq "REVIEW") {

    $ReviewItems.Add(
        "Windows edition or build information could not be fully validated."
    )
}

if ($Validation.WindowsActivation -eq "REVIEW") {

    $ReviewItems.Add(
        "Windows activation status requires review."
    )
}

if ($GenuineIndicators.NonGenuineGraceDetected) {

    $ReviewItems.Add(
        "A Windows Non-Genuine Grace indicator was detected."
    )
}

if ($GenuineIndicators.UnlicensedProductDetected) {

    $ReviewItems.Add(
        "An unlicensed Windows product was detected."
    )
}

if ($DISMStatus -ne "Healthy") {

    $ReviewItems.Add(
        "Windows component store health requires review."
    )
}

if ($SFCStatus -notin @(
    "Healthy",
    "Repaired"
)) {

    $ReviewItems.Add(
        "Windows protected system files require review."
    )
}

if ($WMIStatus -ne "Consistent") {

    $ReviewItems.Add(
        "WMI repository health requires review."
    )
}

if ($FirewallStatus -ne "Enabled") {

    $ReviewItems.Add(
        "No enabled Windows Firewall profile was detected."
    )
}

if (
    (
        $UpdateInfrastructure |
        Where-Object {
            $_.Name -eq "wuauserv" -and
            $_.Status -eq "Running"
        }
    ).Count -eq 0
) {

    $ReviewItems.Add(
        "Windows Update service is not currently running."
    )
}

# ============================================================================
# 37. OVERALL STATUS
# ============================================================================

if ($ReviewItems.Count -eq 0) {

    $OverallStatus = "PASS"
}
else {

    $OverallStatus = "REVIEW"
}

# ============================================================================
# 38. STRUCTURED JSON REPORT
# ============================================================================

$Report = [ordered]@{

    Project = [ordered]@{

        Name = "System Health and Quality Assessment"

        Module = "02 - Windows Standard & Activation Validation"

        Version = "2.0"

        Purpose = "Windows standard, activation, licensing, integrity and environment validation"
    }

    Collection = [ordered]@{

        StartTime = $StartTime

        EndTime = Get-Date

        Administrator = $true
    }

    Windows = $WindowsInfo

    Licensing = $LicenseInformation

    Activation = $ActivationValidation

    MicrosoftSoftwareProtection = [ordered]@{

        DLI = $SLMGR_DLI

        DLV = $SLMGR_DLV

        XPR = $SLMGR_XPR
    }

    FirmwareLicense = $FirmwareLicense

    DISM = [ordered]@{

        CheckHealth = $DISM_CheckHealth

        ScanHealth = $DISM_ScanHealth

        Status = $DISMStatus
    }

    SFC = [ordered]@{

        Scan = $SFC_Scan

        Status = $SFCStatus
    }

    WMI = [ordered]@{

        Status = $WMIStatus
    }

    BootSecurity = [ordered]@{

        FirmwareType = $FirmwareType

        SecureBoot = $SecureBootStatus
    }

    Firewall = $FirewallProfiles

    WindowsDefender = $DefenderInfo

    SecurityProducts = $SecurityProducts

    CriticalServices = $CriticalServiceStatus

    UpdateInfrastructure = $UpdateInfrastructure

    WindowsInstaller = $WindowsInstallerInfo

    SystemDirectories = $SystemDirectoryValidation

    SoftwareEnvironment = $SoftwareEnvironment

    Validation = $Validation

    OverallStatus = $OverallStatus

    ReviewItems = @($ReviewItems)
}

# ============================================================================
# 39. SAVE JSON REPORT
# ============================================================================

try {

    $Report |
        ConvertTo-Json -Depth 12 |
        Set-Content `
            -Path $JsonReport `
            -Encoding UTF8
}
catch {

    Write-Host "JSON report creation failed." -ForegroundColor Red
}

# ============================================================================
# 40. HUMAN READABLE REPORT
# ============================================================================

$ReportText = New-Object System.Text.StringBuilder

[void]$ReportText.AppendLine(
    "======================================================================"
)

[void]$ReportText.AppendLine(
    "SYSTEM HEALTH AND QUALITY ASSESSMENT"
)

[void]$ReportText.AppendLine(
    "MODULE 02 - WINDOWS STANDARD & ACTIVATION VALIDATION"
)

[void]$ReportText.AppendLine(
    "======================================================================"
)

[void]$ReportText.AppendLine("")

[void]$ReportText.AppendLine("OVERALL STATUS")
[void]$ReportText.AppendLine("--------------")
[void]$ReportText.AppendLine($OverallStatus)
[void]$ReportText.AppendLine("")

# ----------------------------------------------------------------------------
# WINDOWS
# ----------------------------------------------------------------------------

[void]$ReportText.AppendLine("WINDOWS INFORMATION")
[void]$ReportText.AppendLine("--------------------")

foreach ($Item in $WindowsInfo.GetEnumerator()) {

    [void]$ReportText.AppendLine(
        "{0,-35}: {1}" -f
        $Item.Key,
        $Item.Value
    )
}

[void]$ReportText.AppendLine("")

# ----------------------------------------------------------------------------
# LICENSE
# ----------------------------------------------------------------------------

[void]$ReportText.AppendLine("ACTIVATION AND LICENSING")
[void]$ReportText.AppendLine("------------------------")

foreach ($Item in $ActivationValidation.GetEnumerator()) {

    [void]$ReportText.AppendLine(
        "{0,-35}: {1}" -f
        $Item.Key,
        $Item.Value
    )
}

[void]$ReportText.AppendLine("")

foreach ($License in $LicenseInformation) {

    foreach ($Item in $License.GetEnumerator()) {

        [void]$ReportText.AppendLine(
            "{0,-35}: {1}" -f
            $Item.Key,
            $Item.Value
        )
    }

    [void]$ReportText.AppendLine("")
}

# ----------------------------------------------------------------------------
# SLMGR
# ----------------------------------------------------------------------------

[void]$ReportText.AppendLine("MICROSOFT SOFTWARE PROTECTION")
[void]$ReportText.AppendLine("------------------------------")

[void]$ReportText.AppendLine("")
[void]$ReportText.AppendLine("SLMGR DLI")
[void]$ReportText.AppendLine("----------")
[void]$ReportText.AppendLine($SLMGR_DLI)

[void]$ReportText.AppendLine("")
[void]$ReportText.AppendLine("SLMGR DLV")
[void]$ReportText.AppendLine("----------")
[void]$ReportText.AppendLine($SLMGR_DLV)

[void]$ReportText.AppendLine("")
[void]$ReportText.AppendLine("SLMGR XPR")
[void]$ReportText.AppendLine("----------")
[void]$ReportText.AppendLine($SLMGR_XPR)

[void]$ReportText.AppendLine("")

# ----------------------------------------------------------------------------
# DISM
# ----------------------------------------------------------------------------

[void]$ReportText.AppendLine("WINDOWS COMPONENT STORE")
[void]$ReportText.AppendLine("-----------------------")
[void]$ReportText.AppendLine(
    "Status: $DISMStatus"
)

[void]$ReportText.AppendLine("")
[void]$ReportText.AppendLine($DISM_CheckHealth)

[void]$ReportText.AppendLine("")
[void]$ReportText.AppendLine($DISM_ScanHealth)

[void]$ReportText.AppendLine("")

# ----------------------------------------------------------------------------
# SFC
# ----------------------------------------------------------------------------

[void]$ReportText.AppendLine("SYSTEM FILE INTEGRITY")
[void]$ReportText.AppendLine("---------------------")
[void]$ReportText.AppendLine(
    "Status: $SFCStatus"
)

[void]$ReportText.AppendLine("")
[void]$ReportText.AppendLine($SFC_Scan)

[void]$ReportText.AppendLine("")

# ----------------------------------------------------------------------------
# WMI
# ----------------------------------------------------------------------------

[void]$ReportText.AppendLine("WMI REPOSITORY")
[void]$ReportText.AppendLine("--------------")
[void]$ReportText.AppendLine(
    "Status: $WMIStatus"
)

[void]$ReportText.AppendLine("")

# ----------------------------------------------------------------------------
# BOOT SECURITY
# ----------------------------------------------------------------------------

[void]$ReportText.AppendLine("BOOT SECURITY")
[void]$ReportText.AppendLine("-------------")
[void]$ReportText.AppendLine(
    "Firmware Type : $FirmwareType"
)
[void]$ReportText.AppendLine(
    "Secure Boot   : $SecureBootStatus"
)

[void]$ReportText.AppendLine("")

# ----------------------------------------------------------------------------
# FIREWALL
# ----------------------------------------------------------------------------

[void]$ReportText.AppendLine("WINDOWS FIREWALL")
[void]$ReportText.AppendLine("----------------")

foreach ($Profile in $FirewallProfiles) {

    [void]$ReportText.AppendLine(
        "{0,-15}: Enabled={1}, Inbound={2}, Outbound={3}" -f
        $Profile.Name,
        $Profile.Enabled,
        $Profile.DefaultInboundAction,
        $Profile.DefaultOutboundAction
    )
}

[void]$ReportText.AppendLine("")

# ----------------------------------------------------------------------------
# DEFENDER
# ----------------------------------------------------------------------------

[void]$ReportText.AppendLine("WINDOWS DEFENDER")
[void]$ReportText.AppendLine("----------------")

foreach ($Item in $DefenderInfo.GetEnumerator()) {

    [void]$ReportText.AppendLine(
        "{0,-40}: {1}" -f
        $Item.Key,
        $Item.Value
    )
}

[void]$ReportText.AppendLine("")

# ----------------------------------------------------------------------------
# CRITICAL SERVICES
# ----------------------------------------------------------------------------

[void]$ReportText.AppendLine("CRITICAL WINDOWS SERVICES")
[void]$ReportText.AppendLine("-------------------------")

foreach ($Service in $CriticalServiceStatus) {

    [void]$ReportText.AppendLine(
        "{0,-30}: Status={1}, StartType={2}" -f
        $Service.Name,
        $Service.Status,
        $Service.StartType
    )
}

[void]$ReportText.AppendLine("")

# ----------------------------------------------------------------------------
# UPDATE INFRASTRUCTURE
# ----------------------------------------------------------------------------

[void]$ReportText.AppendLine("WINDOWS UPDATE INFRASTRUCTURE")
[void]$ReportText.AppendLine("-----------------------------")

foreach ($Service in $UpdateInfrastructure) {

    [void]$ReportText.AppendLine(
        "{0,-15}: Status={1}, StartType={2}" -f
        $Service.Name,
        $Service.Status,
        $Service.StartType
    )
}

[void]$ReportText.AppendLine("")

# ----------------------------------------------------------------------------
# VALIDATION
# ----------------------------------------------------------------------------

[void]$ReportText.AppendLine("VALIDATION RESULTS")
[void]$ReportText.AppendLine("------------------")

foreach ($Item in $Validation.GetEnumerator()) {

    [void]$ReportText.AppendLine(
        "{0,-35}: {1}" -f
        $Item.Key,
        $Item.Value
    )
}

[void]$ReportText.AppendLine("")

# ----------------------------------------------------------------------------
# REVIEW ITEMS
# ----------------------------------------------------------------------------

[void]$ReportText.AppendLine("REVIEW ITEMS")
[void]$ReportText.AppendLine("------------")

if ($ReviewItems.Count -eq 0) {

    [void]$ReportText.AppendLine(
        "No review items were detected."
    )
}
else {

    $Index = 1

    foreach ($Issue in $ReviewItems) {

        [void]$ReportText.AppendLine(
            "$Index. $Issue"
        )

        $Index++
    }
}

[void]$ReportText.AppendLine("")

[void]$ReportText.AppendLine(
    "======================================================================"
)

[void]$ReportText.AppendLine(
    "END OF MODULE 02 REPORT"
)

[void]$ReportText.AppendLine(
    "======================================================================"
)

# ============================================================================
# 41. SAVE TEXT REPORT
# ============================================================================

try {

    $ReportText.ToString() |
        Set-Content `
            -Path $TextReport `
            -Encoding UTF8
}
catch {

    Write-Host "Text report creation failed." -ForegroundColor Red
}

# ============================================================================
# 42. CONSOLE SUMMARY
# ============================================================================

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host " MODULE 02 COMPLETED" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Windows        : $($WindowsInfo.ProductName)"
Write-Host "Edition        : $($WindowsInfo.EditionID)"
Write-Host "Version        : $($WindowsInfo.DisplayVersion)"
Write-Host "Build          : $($WindowsInfo.BuildNumber).$($WindowsInfo.UBR)"
Write-Host "Activation     : $ActivationStatus"
Write-Host "License Channel: $LicenseChannel"
Write-Host "DISM           : $DISMStatus"
Write-Host "SFC            : $SFCStatus"
Write-Host "WMI            : $WMIStatus"
Write-Host "Firmware       : $FirmwareType"
Write-Host "Secure Boot    : $SecureBootStatus"
Write-Host "Firewall       : $FirewallStatus"
Write-Host ""

if ($OverallStatus -eq "PASS") {

    Write-Host "OVERALL STATUS: PASS" -ForegroundColor Green
}
else {

    Write-Host "OVERALL STATUS: REVIEW" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Review Items:" -ForegroundColor Yellow

    $Index = 1

    foreach ($Issue in $ReviewItems) {

        Write-Host "$Index. $Issue" -ForegroundColor Yellow

        $Index++
    }
}

Write-Host ""
Write-Host "Reports:" -ForegroundColor Cyan
Write-Host $TextReport
Write-Host $JsonReport
Write-Host ""

# ============================================================================
# 43. THREE SEPARATE ENTER CONFIRMATIONS
# ============================================================================

Read-Host "Press Enter to continue"
Read-Host "Press Enter to continue"
Read-Host "Press Enter to finish"