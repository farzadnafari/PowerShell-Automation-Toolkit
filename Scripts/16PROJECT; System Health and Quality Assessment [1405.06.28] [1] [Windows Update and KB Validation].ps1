# ==================================================================================================
# SYSTEM HEALTH AND QUALITY ASSESSMENT
# MODULE: 03 - Windows Update and KB Validation
# VERSION: 3.0
#
# PURPOSE:
# Independently validates Windows Update, applicable updates, installed KBs,
# update services, update configuration, reboot requirements, update history,
# recent Windows Update events, and unresolved update problems.
#
# ARCHITECTURE:
# - This module is completely independent.
# - It does not depend on Modules 01, 02, 04, 05, 06, or 07.
# - It does not modify Windows Update.
# - It does not install or remove updates.
# - Module 07 may later read this module's JSON/TXT reports.
#
# IMPORTANT INTERPRETATION:
# - Historical failed/aborted update operations are NOT automatically Problems.
# - A historical failure becomes actionable only when there is evidence that
#   the current update state remains unresolved.
# - Currently applicable pending updates are evaluated separately.
# - Security updates currently applicable and pending are reported as Problems.
# - Historical failures that were later followed by successful installation
#   are treated as historical information.
# - Recent Windows Update error events are treated as Warnings unless there
#   is additional evidence of a current unresolved update problem.
#
# OUTPUT:
# 03_Windows_Update_and_KB_Validation.txt
# 03_Windows_Update_and_KB_Validation.json
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# PROJECT IDENTITY
# --------------------------------------------------------------------------------------------------

$ProjectName = "System Health and Quality Assessment"
$ModuleName  = "03 - Windows Update and KB Validation"
$Version     = "3.0"

# --------------------------------------------------------------------------------------------------
# AUTO-ELEVATION
# --------------------------------------------------------------------------------------------------

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

if (-not $CurrentPrincipal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {

    Write-Host ""
    Write-Host "Administrator privileges are required." -ForegroundColor Yellow
    Write-Host "Restarting PowerShell with Administrator privileges..." -ForegroundColor Yellow
    Write-Host ""

    try {

        Start-Process powershell.exe `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
            -Verb RunAs

        exit
    }
    catch {

        Write-Host "Failed to restart PowerShell as Administrator." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit
    }
}

# --------------------------------------------------------------------------------------------------
# EXECUTION POLICY
# --------------------------------------------------------------------------------------------------

try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}
catch {
    Write-Host "Execution policy could not be changed for this process." -ForegroundColor Yellow
}

# --------------------------------------------------------------------------------------------------
# PROJECT FOLDER
# --------------------------------------------------------------------------------------------------

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ProjectFolder = Join-Path $DesktopPath $ProjectName

if (-not (Test-Path -LiteralPath $ProjectFolder)) {

    New-Item -ItemType Directory -Path $ProjectFolder -Force | Out-Null
}

# --------------------------------------------------------------------------------------------------
# OUTPUT FILES
# --------------------------------------------------------------------------------------------------

$OutputTXT  = Join-Path $ProjectFolder "03_Windows_Update_and_KB_Validation.txt"
$OutputJSON = Join-Path $ProjectFolder "03_Windows_Update_and_KB_Validation.json"

$Generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# --------------------------------------------------------------------------------------------------
# STORAGE
# --------------------------------------------------------------------------------------------------

$Problems = New-Object System.Collections.Generic.List[string]
$Warnings = New-Object System.Collections.Generic.List[string]
$Information = New-Object System.Collections.Generic.List[string]

$AvailableUpdates = @()
$InstalledHotFixes = @()
$UpdateHistory = @()
$FailedHistory = @()
$RecentUpdateEvents = @()
$UpdateServices = @()
$RegisteredUpdateServices = @()

$PendingReboot = $false
$WUAAvailable = $false
$OnlineSearchSuccessful = $false
$SecurityUpdatesPending = 0
$NonSecurityUpdatesPending = 0
$TotalApplicableUpdates = 0

# --------------------------------------------------------------------------------------------------
# SYSTEM IDENTIFICATION
# --------------------------------------------------------------------------------------------------

$OS = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$ComputerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue

$ComputerName = $env:COMPUTERNAME

$Manufacturer = if ($ComputerSystem) {
    $ComputerSystem.Manufacturer
}
else {
    "Unknown"
}

$Model = if ($ComputerSystem) {
    $ComputerSystem.Model
}
else {
    "Unknown"
}

$OperatingSystem = if ($OS) {
    $OS.Caption
}
else {
    "Unknown"
}

$OSVersion = if ($OS) {
    $OS.Version
}
else {
    "Unknown"
}

$OSBuild = if ($OS) {
    $OS.BuildNumber
}
else {
    "Unknown"
}

$OSArchitecture = if ($OS) {
    $OS.OSArchitecture
}
else {
    "Unknown"
}

# --------------------------------------------------------------------------------------------------
# WINDOWS UPDATE SERVICES
# --------------------------------------------------------------------------------------------------

$ServiceNames = @(
    "wuauserv",
    "bits",
    "cryptsvc",
    "UsoSvc"
)

foreach ($ServiceName in $ServiceNames) {

    try {

        $Service = Get-Service -Name $ServiceName -ErrorAction Stop

        $UpdateServices += [PSCustomObject]@{
            Name        = $Service.Name
            DisplayName = $Service.DisplayName
            Status      = [string]$Service.Status
            StartType   = [string]$Service.StartType
        }

    }
    catch {

        $UpdateServices += [PSCustomObject]@{
            Name        = $ServiceName
            DisplayName = "Unavailable"
            Status      = "NOT FOUND"
            StartType   = "Unknown"
        }
    }
}

$WUAService = $UpdateServices | Where-Object {
    $_.Name -eq "wuauserv"
}

$BITSService = $UpdateServices | Where-Object {
    $_.Name -eq "bits"
}

if ($WUAService.Status -ne "Running") {

    $Warnings.Add(
        "Windows Update service (wuauserv) is not currently running."
    )
}

if ($BITSService.Status -ne "Running") {

    $Warnings.Add(
        "Background Intelligent Transfer Service (BITS) is not currently running."
    )
}

# --------------------------------------------------------------------------------------------------
# WINDOWS UPDATE REGISTRY CONFIGURATION
# --------------------------------------------------------------------------------------------------

$AURegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"

$AUConfig = [PSCustomObject]@{
    RegistryPath = $AURegistryPath
    AUOptions = $null
    NoAutoUpdate = $null
    UseWUServer = $null
}

try {

    if (Test-Path -LiteralPath $AURegistryPath) {

        $AUValues = Get-ItemProperty -LiteralPath $AURegistryPath -ErrorAction SilentlyContinue

        $AUConfig.AUOptions = $AUValues.AUOptions
        $AUConfig.NoAutoUpdate = $AUValues.NoAutoUpdate
        $AUConfig.UseWUServer = $AUValues.UseWUServer
    }
}
catch {

    $Warnings.Add(
        "Windows Update automatic update registry configuration could not be fully read."
    )
}

if ($AUConfig.NoAutoUpdate -eq 1) {

    $Warnings.Add(
        "Automatic Windows Update is disabled by the current system configuration."
    )
}

# --------------------------------------------------------------------------------------------------
# REGISTERED WINDOWS UPDATE SERVICES
# --------------------------------------------------------------------------------------------------

try {

    $ServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager

    foreach ($Service in $ServiceManager.Services) {

        $RegisteredUpdateServices += [PSCustomObject]@{
            Name        = [string]$Service.Name
            ServiceID   = [string]$Service.ServiceID
            IsManaged   = [bool]$Service.IsManaged
            OffersWindowsUpdates = [bool]$Service.OffersWindowsUpdates
        }
    }

}
catch {

    $Warnings.Add(
        "Registered Windows Update service information could not be fully read."
    )
}

# --------------------------------------------------------------------------------------------------
# WINDOWS UPDATE AGENT
# --------------------------------------------------------------------------------------------------

$UpdateSession = $null
$UpdateSearcher = $null

try {

    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

    $WUAAvailable = $true

    $Information.Add(
        "Windows Update Agent is available."
    )
}
catch {

    $Problems.Add(
        "Windows Update Agent could not be initialized."
    )
}

# --------------------------------------------------------------------------------------------------
# ONLINE WINDOWS UPDATE SEARCH
# --------------------------------------------------------------------------------------------------

if ($WUAAvailable) {

    try {

        $SearchResult = $UpdateSearcher.Search(
            "IsInstalled=0 and IsHidden=0"
        )

        $OnlineSearchSuccessful = $true

        $TotalApplicableUpdates = $SearchResult.Updates.Count

        foreach ($Update in $SearchResult.Updates) {

            $Categories = @()

            try {

                foreach ($Category in $Update.Categories) {
                    $Categories += $Category.Name
                }
            }
            catch {
            }

            $IsSecurity = $false

            foreach ($CategoryName in $Categories) {

                if ($CategoryName -match "Security") {
                    $IsSecurity = $true
                }
            }

            $UpdateObject = [PSCustomObject]@{
                Title             = [string]$Update.Title
                KBArticleIDs      = @($Update.KBArticleIDs)
                Categories        = $Categories
                IsSecurity        = $IsSecurity
                IsDownloaded      = [bool]$Update.IsDownloaded
                IsInstalled       = [bool]$Update.IsInstalled
                IsHidden          = [bool]$Update.IsHidden
                RebootRequired    = [bool]$Update.RebootRequired
                EulaAccepted      = [bool]$Update.EulaAccepted
            }

            $AvailableUpdates += $UpdateObject

            if ($IsSecurity) {
                $SecurityUpdatesPending++
            }
            else {
                $NonSecurityUpdatesPending++
            }
        }

    }
    catch {

        $Warnings.Add(
            "Windows Update Agent could not complete the online update search."
        )
    }
}

# --------------------------------------------------------------------------------------------------
# CURRENT APPLICABLE UPDATE ASSESSMENT
# --------------------------------------------------------------------------------------------------

if ($OnlineSearchSuccessful) {

    if ($SecurityUpdatesPending -gt 0) {

        $Problems.Add(
            "Currently applicable security updates are pending: $SecurityUpdatesPending"
        )
    }

    if ($NonSecurityUpdatesPending -gt 0) {

        $Warnings.Add(
            "Currently applicable non-security updates are pending: $NonSecurityUpdatesPending"
        )
    }

    if ($TotalApplicableUpdates -eq 0) {

        $Information.Add(
            "Windows Update reported no currently applicable non-hidden updates."
        )
    }
    else {

        $Information.Add(
            "Windows Update reported $TotalApplicableUpdates currently applicable non-hidden update(s)."
        )
    }
}

# --------------------------------------------------------------------------------------------------
# INSTALLED HOTFIX INVENTORY
# --------------------------------------------------------------------------------------------------

try {

    $InstalledHotFixes = @(
        Get-HotFix -ErrorAction Stop |
        Sort-Object InstalledOn -Descending |
        Select-Object HotFixID,
                      Description,
                      InstalledOn,
                      InstalledBy,
                      Caption,
                      ServicePackInEffect
    )

}
catch {

    $Warnings.Add(
        "Installed Windows hotfix inventory could not be fully retrieved."
    )
}

# --------------------------------------------------------------------------------------------------
# UPDATE HISTORY
# --------------------------------------------------------------------------------------------------

if ($WUAAvailable) {

    try {

        $HistoryCount = $UpdateSearcher.GetTotalHistoryCount()

        $ReadCount = [Math]::Min([int]$HistoryCount, 300)

        if ($ReadCount -gt 0) {

            $HistoryResults = $UpdateSearcher.QueryHistory(0, $ReadCount)

            foreach ($Entry in $HistoryResults) {

                $ResultCode = switch ([int]$Entry.ResultCode) {

                    0 { "NotStarted" }
                    1 { "InProgress" }
                    2 { "Succeeded" }
                    3 { "SucceededWithErrors" }
                    4 { "Failed" }
                    5 { "Aborted" }
                    default { "Unknown" }
                }

                $UpdateHistory += [PSCustomObject]@{
                    Date        = [string]$Entry.Date
                    Title       = [string]$Entry.Title
                    Description = [string]$Entry.Description
                    Operation   = [string]$Entry.Operation
                    ResultCode  = [int]$Entry.ResultCode
                    Result      = $ResultCode
                    HResult     = [int64]$Entry.HResult
                    UpdateID    = [string]$Entry.UpdateIdentity.UpdateID
                }
            }
        }

    }
    catch {

        $Warnings.Add(
            "Windows Update history could not be fully retrieved."
        )
    }
}

# --------------------------------------------------------------------------------------------------
# HISTORICAL FAILURE ANALYSIS
#
# IMPORTANT:
# Historical failed or aborted operations are NOT automatically Problems.
# We examine them to determine whether there is evidence of an unresolved
# current update issue.
# --------------------------------------------------------------------------------------------------

$FailedHistory = @(
    $UpdateHistory |
    Where-Object {
        $_.Result -eq "Failed" -or
        $_.Result -eq "Aborted"
    }
)

$RecentFailedHistory = @(
    $FailedHistory |
    Where-Object {
        try {
            ([datetime]$_.Date) -ge (Get-Date).AddDays(-30)
        }
        catch {
            $false
        }
    }
)

if ($FailedHistory.Count -gt 0) {

    $Information.Add(
        "Windows Update history contains $($FailedHistory.Count) failed or aborted operation(s). Historical failures are not automatically treated as current problems."
    )
}

if ($RecentFailedHistory.Count -gt 0) {

    $Warnings.Add(
        "Windows Update history contains $($RecentFailedHistory.Count) failed or aborted operation(s) within the last 30 days. These require review only when they remain unresolved."
    )
}

# --------------------------------------------------------------------------------------------------
# DETERMINE WHETHER HISTORICAL FAILURES ARE CURRENTLY UNRESOLVED
# --------------------------------------------------------------------------------------------------

$CurrentPendingTitles = @(
    $AvailableUpdates |
    ForEach-Object {
        $_.Title
    }
)

$PotentiallyUnresolvedFailures = @()

foreach ($Failure in $RecentFailedHistory) {

    $FailureTitle = $Failure.Title

    if ([string]::IsNullOrWhiteSpace($FailureTitle)) {
        continue
    }

    $MatchingPendingUpdate = $AvailableUpdates |
        Where-Object {
            $_.Title -eq $FailureTitle
        } |
        Select-Object -First 1

    if ($null -ne $MatchingPendingUpdate) {

        $PotentiallyUnresolvedFailures += $Failure
    }
}

if ($PotentiallyUnresolvedFailures.Count -gt 0) {

    $Warnings.Add(
        "Recent failed update operations correspond to updates that are still reported as applicable and pending: $($PotentiallyUnresolvedFailures.Count)"
    )
}

# --------------------------------------------------------------------------------------------------
# REBOOT REQUIRED DETECTION
# --------------------------------------------------------------------------------------------------

$RebootIndicators = @()

try {

    $CBSRebootPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"

    if (Test-Path -LiteralPath $CBSRebootPath) {

        $RebootIndicators += "Component Based Servicing RebootPending"
    }

}
catch {
}

try {

    $WURebootPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"

    if (Test-Path -LiteralPath $WURebootPath) {

        $RebootIndicators += "Windows Update RebootRequired"
    }

}
catch {
}

try {

    $PendingRenamePath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"

    $PendingRename = Get-ItemProperty `
        -LiteralPath $PendingRenamePath `
        -Name "PendingFileRenameOperations" `
        -ErrorAction SilentlyContinue

    if ($null -ne $PendingRename.PendingFileRenameOperations) {

        $RebootIndicators += "PendingFileRenameOperations"
    }

}
catch {
}

if ($RebootIndicators.Count -gt 0) {

    $PendingReboot = $true

    $Warnings.Add(
        "Windows reports that a system restart may be required to complete one or more operations."
    )
}
else {

    $Information.Add(
        "No standard Windows Update reboot-required indicator was detected."
    )
}

# --------------------------------------------------------------------------------------------------
# RECENT WINDOWS UPDATE EVENTS
# --------------------------------------------------------------------------------------------------

$UpdateEventLogs = @(
    "System",
    "Application"
)

$RecentUpdateEvents = @()

$EventStart = (Get-Date).AddDays(-30)

foreach ($LogName in $UpdateEventLogs) {

    try {

        $Events = Get-WinEvent -FilterHashtable @{
            LogName   = $LogName
            StartTime = $EventStart
        } -ErrorAction SilentlyContinue

        foreach ($Event in $Events) {

            $Provider = [string]$Event.ProviderName
            $Message = [string]$Event.Message

            if (
                $Provider -match "WindowsUpdate|Windows Update|UpdateOrchestrator|USO|Servicing|CBS|TrustedInstaller" -or
                $Message -match "Windows Update|update failed|update error|KB\d+|servicing stack|cumulative update"
            ) {

                if (
                    $Event.LevelDisplayName -eq "Error" -or
                    $Event.LevelDisplayName -eq "Critical"
                ) {

                    $RecentUpdateEvents += [PSCustomObject]@{
                        TimeCreated = $Event.TimeCreated
                        LogName     = $LogName
                        Provider    = $Provider
                        EventID     = $Event.Id
                        Level       = $Event.LevelDisplayName
                        Message     = $Message
                    }
                }
            }
        }

    }
    catch {
    }
}

if ($RecentUpdateEvents.Count -gt 0) {

    $Warnings.Add(
        "Recent Windows Update-related error or critical events detected: $($RecentUpdateEvents.Count)"
    )
}
else {

    $Information.Add(
        "No matching Windows Update-related Error or Critical events were detected in the last 30 days."
    )
}

# --------------------------------------------------------------------------------------------------
# UPDATE SOURCE ASSESSMENT
# --------------------------------------------------------------------------------------------------

$UpdateSourceAssessment = "Unknown"

try {

    if ($AUConfig.UseWUServer -eq 1) {

        $UpdateSourceAssessment = "Managed Windows Update service configuration detected."

        $Information.Add(
            "Windows Update is configured to use a managed update service."
        )
    }
    else {

        $UpdateSourceAssessment = "Standard Windows Update configuration detected."

        $Information.Add(
            "Windows Update is configured without the UseWUServer registry flag."
        )
    }

}
catch {

    $Warnings.Add(
        "Windows Update source configuration could not be fully assessed."
    )
}

# --------------------------------------------------------------------------------------------------
# LATEST SUCCESSFUL UPDATE
# --------------------------------------------------------------------------------------------------

$LatestSuccessfulUpdate = $null

$LatestSuccessfulUpdate = $UpdateHistory |
    Where-Object {
        $_.Result -eq "Succeeded" -or
        $_.Result -eq "SucceededWithErrors"
    } |
    Sort-Object Date -Descending |
    Select-Object -First 1

if ($null -ne $LatestSuccessfulUpdate) {

    $Information.Add(
        "Latest successful Windows Update history entry: $($LatestSuccessfulUpdate.Title) on $($LatestSuccessfulUpdate.Date)."
    )
}
else {

    $Warnings.Add(
        "No successful Windows Update history entry was identified in the retrieved history."
    )
}

# --------------------------------------------------------------------------------------------------
# FINAL STATUS
# --------------------------------------------------------------------------------------------------

if ($Problems.Count -gt 0) {

    $OverallStatus = "PROBLEM"

}
elseif ($Warnings.Count -gt 0) {

    $OverallStatus = "REVIEW"

}
else {

    $OverallStatus = "PASS"
}

# --------------------------------------------------------------------------------------------------
# HUMAN-READABLE REPORT
# --------------------------------------------------------------------------------------------------

$Report = New-Object System.Collections.Generic.List[string]

$Report.Add("SYSTEM HEALTH AND QUALITY ASSESSMENT")
$Report.Add("MODULE: $ModuleName")
$Report.Add("VERSION: $Version")
$Report.Add("GENERATED: $Generated")
$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("SYSTEM IDENTIFICATION")
$Report.Add("==================================================================================")
$Report.Add("Computer Name : $ComputerName")
$Report.Add("Manufacturer  : $Manufacturer")
$Report.Add("Model         : $Model")
$Report.Add("Operating Sys : $OperatingSystem")
$Report.Add("OS Version    : $OSVersion")
$Report.Add("OS Build      : $OSBuild")
$Report.Add("Architecture  : $OSArchitecture")
$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("WINDOWS UPDATE AGENT")
$Report.Add("==================================================================================")
$Report.Add("WUA Available           : $WUAAvailable")
$Report.Add("Online Search Successful: $OnlineSearchSuccessful")
$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("WINDOWS UPDATE SERVICES")
$Report.Add("==================================================================================")

foreach ($Service in $UpdateServices) {

    $Report.Add(
        "$($Service.Name) | Status: $($Service.Status) | StartType: $($Service.StartType)"
    )
}

$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("AUTOMATIC UPDATE CONFIGURATION")
$Report.Add("==================================================================================")
$Report.Add("AUOptions     : $($AUConfig.AUOptions)")
$Report.Add("NoAutoUpdate  : $($AUConfig.NoAutoUpdate)")
$Report.Add("UseWUServer   : $($AUConfig.UseWUServer)")
$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("UPDATE SOURCE")
$Report.Add("==================================================================================")
$Report.Add("Assessment: $UpdateSourceAssessment")
$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("CURRENT APPLICABLE UPDATES")
$Report.Add("==================================================================================")
$Report.Add("Total Applicable Updates : $TotalApplicableUpdates")
$Report.Add("Security Updates Pending : $SecurityUpdatesPending")
$Report.Add("Non-Security Updates     : $NonSecurityUpdatesPending")
$Report.Add("")

if ($AvailableUpdates.Count -gt 0) {

    $Index = 1

    foreach ($Update in $AvailableUpdates) {

        $KBs = if ($Update.KBArticleIDs.Count -gt 0) {
            ($Update.KBArticleIDs -join ", ")
        }
        else {
            "None reported"
        }

        $CategoryText = if ($Update.Categories.Count -gt 0) {
            ($Update.Categories -join ", ")
        }
        else {
            "None reported"
        }

        $Report.Add(
            "$Index. $($Update.Title)"
        )

        $Report.Add(
            "   KB          : $KBs"
        )

        $Report.Add(
            "   Security    : $($Update.IsSecurity)"
        )

        $Report.Add(
            "   Categories  : $CategoryText"
        )

        $Report.Add(
            "   Reboot Req. : $($Update.RebootRequired)"
        )

        $Report.Add("")

        $Index++
    }
}
else {

    $Report.Add("No currently applicable updates were returned by Windows Update.")
    $Report.Add("")
}

$Report.Add("==================================================================================")
$Report.Add("INSTALLED HOTFIX SUMMARY")
$Report.Add("==================================================================================")
$Report.Add("Installed Hotfix Count: $($InstalledHotFixes.Count)")
$Report.Add("")

if ($InstalledHotFixes.Count -gt 0) {

    $RecentHotFixes = $InstalledHotFixes |
        Select-Object -First 30

    foreach ($HotFix in $RecentHotFixes) {

        $Report.Add(
            "$($HotFix.HotFixID) | Installed: $($HotFix.InstalledOn) | Description: $($HotFix.Description)"
        )
    }
}

$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("UPDATE HISTORY SUMMARY")
$Report.Add("==================================================================================")
$Report.Add("Retrieved History Entries : $($UpdateHistory.Count)")
$Report.Add("Failed / Aborted History  : $($FailedHistory.Count)")
$Report.Add("Recent Failed / Aborted   : $($RecentFailedHistory.Count)")
$Report.Add("Potentially Unresolved    : $($PotentiallyUnresolvedFailures.Count)")
$Report.Add("")

$Report.Add("Historical failed or aborted operations are not automatically classified as current problems.")
$Report.Add("A historical failure is actionable only when there is evidence that the current update state remains unresolved.")
$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("REBOOT STATUS")
$Report.Add("==================================================================================")
$Report.Add("Pending Reboot: $PendingReboot")

if ($RebootIndicators.Count -gt 0) {

    foreach ($Indicator in $RebootIndicators) {

        $Report.Add("Indicator: $Indicator")
    }
}
else {

    $Report.Add("No standard reboot-required indicators detected.")
}

$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("RECENT WINDOWS UPDATE EVENTS")
$Report.Add("==================================================================================")
$Report.Add("Matching Error/Critical Events in Last 30 Days: $($RecentUpdateEvents.Count)")
$Report.Add("")

if ($RecentUpdateEvents.Count -gt 0) {

    $RecentEventsToDisplay = $RecentUpdateEvents |
        Sort-Object TimeCreated -Descending |
        Select-Object -First 50

    $Index = 1

    foreach ($Event in $RecentEventsToDisplay) {

        $ShortMessage = ($Event.Message -replace "\r?\n", " ").Trim()

        if ($ShortMessage.Length -gt 500) {
            $ShortMessage = $ShortMessage.Substring(0,500) + "..."
        }

        $Report.Add(
            "$Index. $($Event.TimeCreated) | $($Event.Provider) | Event ID: $($Event.EventID)"
        )

        $Report.Add(
            "   $ShortMessage"
        )

        $Report.Add("")

        $Index++
    }
}
else {

    $Report.Add("No matching Error or Critical events were detected.")
    $Report.Add("")
}

$Report.Add("==================================================================================")
$Report.Add("LATEST SUCCESSFUL UPDATE")
$Report.Add("==================================================================================")

if ($null -ne $LatestSuccessfulUpdate) {

    $Report.Add("Title : $($LatestSuccessfulUpdate.Title)")
    $Report.Add("Date  : $($LatestSuccessfulUpdate.Date)")
    $Report.Add("Result: $($LatestSuccessfulUpdate.Result)")
}
else {

    $Report.Add("No successful update entry identified.")
}

$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("PROBLEMS")
$Report.Add("==================================================================================")

if ($Problems.Count -eq 0) {

    $Report.Add("No current Windows Update problems were detected.")

}
else {

    $Index = 1

    foreach ($Problem in $Problems) {

        $Report.Add("$Index. $Problem")
        $Index++
    }
}

$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("WARNINGS")
$Report.Add("==================================================================================")

if ($Warnings.Count -eq 0) {

    $Report.Add("No Windows Update warnings require review.")

}
else {

    $Index = 1

    foreach ($Warning in $Warnings) {

        $Report.Add("$Index. $Warning")
        $Index++
    }
}

$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("INFORMATION")
$Report.Add("==================================================================================")

if ($Information.Count -eq 0) {

    $Report.Add("No additional information was recorded.")

}
else {

    $Index = 1

    foreach ($Info in $Information) {

        $Report.Add("$Index. $Info")
        $Index++
    }
}

$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("OVERALL ASSESSMENT")
$Report.Add("==================================================================================")
$Report.Add("OVERALL STATUS: $OverallStatus")
$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("IMPORTANT INTERPRETATION")
$Report.Add("==================================================================================")
$Report.Add("This module is independent of all other assessment modules.")
$Report.Add("Historical failed or aborted update operations are not automatically current problems.")
$Report.Add("Current applicable pending updates are evaluated separately from historical update failures.")
$Report.Add("Security updates that are currently applicable and pending are classified as Problems.")
$Report.Add("Non-security pending updates are classified as Warnings.")
$Report.Add("Recent Windows Update error events are classified as Warnings unless current unresolved evidence exists.")
$Report.Add("A successful Windows Update search does not mean that every update ever released by Microsoft is installed.")
$Report.Add("Windows Update applicability is evaluated according to the update service response at scan time.")
$Report.Add("This module does not install, remove, or modify updates.")
$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("REPORT FILES")
$Report.Add("==================================================================================")
$Report.Add("TXT Report : $OutputTXT")
$Report.Add("JSON Report: $OutputJSON")
$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("END OF MODULE 03")
$Report.Add("==================================================================================")

# --------------------------------------------------------------------------------------------------
# SAVE TXT
# --------------------------------------------------------------------------------------------------

try {

    $Report |
        Set-Content -LiteralPath $OutputTXT -Encoding UTF8 -Force

}
catch {

    Write-Host ""
    Write-Host "Failed to save TXT report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# --------------------------------------------------------------------------------------------------
# JSON REPORT
# --------------------------------------------------------------------------------------------------

$JSONReport = [PSCustomObject]@{

    ProjectName = $ProjectName
    ModuleName  = $ModuleName
    Version     = $Version
    Generated   = $Generated

    SystemIdentification = [PSCustomObject]@{
        ComputerName    = $ComputerName
        Manufacturer    = $Manufacturer
        Model           = $Model
        OperatingSystem = $OperatingSystem
        OSVersion       = $OSVersion
        OSBuild         = $OSBuild
        Architecture    = $OSArchitecture
    }

    WindowsUpdateAgent = [PSCustomObject]@{
        Available            = $WUAAvailable
        OnlineSearchSuccessful = $OnlineSearchSuccessful
        TotalApplicableUpdates = $TotalApplicableUpdates
        SecurityUpdatesPending = $SecurityUpdatesPending
        NonSecurityUpdatesPending = $NonSecurityUpdatesPending
    }

    Services = $UpdateServices

    AutomaticUpdateConfiguration = $AUConfig

    RegisteredUpdateServices = $RegisteredUpdateServices

    UpdateSourceAssessment = $UpdateSourceAssessment

    AvailableUpdates = $AvailableUpdates

    InstalledHotFixes = $InstalledHotFixes

    UpdateHistory = $UpdateHistory

    FailedHistory = $FailedHistory

    RecentFailedHistory = $RecentFailedHistory

    PotentiallyUnresolvedFailures = $PotentiallyUnresolvedFailures

    RebootStatus = [PSCustomObject]@{
        PendingReboot = $PendingReboot
        Indicators    = $RebootIndicators
    }

    RecentUpdateEvents = $RecentUpdateEvents

    LatestSuccessfulUpdate = $LatestSuccessfulUpdate

    Problems = @($Problems)

    Warnings = @($Warnings)

    Information = @($Information)

    OverallStatus = $OverallStatus

    ReportFiles = [PSCustomObject]@{
        TXT  = $OutputTXT
        JSON = $OutputJSON
    }

    Interpretation = @(
        "Historical failed or aborted update operations are not automatically current problems.",
        "Current applicable pending updates are evaluated separately.",
        "Currently applicable security updates pending installation are Problems.",
        "Currently applicable non-security updates pending installation are Warnings.",
        "Recent update error events are Warnings unless current unresolved evidence exists.",
        "A successful WUA search does not mean every Microsoft update ever released is installed.",
        "This module does not install, remove, or modify Windows Updates."
    )
}

try {

    $JSONReport |
        ConvertTo-Json -Depth 15 |
        Set-Content -LiteralPath $OutputJSON -Encoding UTF8 -Force

}
catch {

    Write-Host ""
    Write-Host "Failed to save JSON report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# --------------------------------------------------------------------------------------------------
# CONSOLE SUMMARY
# --------------------------------------------------------------------------------------------------

Clear-Host

Write-Host ""
Write-Host "==================================================================================" -ForegroundColor Cyan
Write-Host "SYSTEM HEALTH AND QUALITY ASSESSMENT" -ForegroundColor Cyan
Write-Host "MODULE: 03 - WINDOWS UPDATE AND KB VALIDATION" -ForegroundColor Cyan
Write-Host "VERSION: $Version" -ForegroundColor Cyan
Write-Host "==================================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Windows Update Agent Available : $WUAAvailable"
Write-Host "Online Search Successful       : $OnlineSearchSuccessful"
Write-Host "Applicable Updates             : $TotalApplicableUpdates"
Write-Host "Security Updates Pending       : $SecurityUpdatesPending"
Write-Host "Non-Security Updates Pending   : $NonSecurityUpdatesPending"
Write-Host "Historical Failed/Aborted      : $($FailedHistory.Count)"
Write-Host "Recent Failed/Aborted          : $($RecentFailedHistory.Count)"
Write-Host "Potentially Unresolved         : $($PotentiallyUnresolvedFailures.Count)"
Write-Host "Pending Reboot                 : $PendingReboot"
Write-Host ""

Write-Host "Problems : $($Problems.Count)" -ForegroundColor $(if ($Problems.Count -gt 0) { "Red" } else { "Green" })
Write-Host "Warnings : $($Warnings.Count)" -ForegroundColor $(if ($Warnings.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

Write-Host "Overall Status: $OverallStatus" -ForegroundColor $(
    if ($OverallStatus -eq "PASS") {
        "Green"
    }
    elseif ($OverallStatus -eq "REVIEW") {
        "Yellow"
    }
    else {
        "Red"
    }
)

Write-Host ""

if ($Problems.Count -gt 0) {

    Write-Host "CURRENT PROBLEMS:" -ForegroundColor Red

    foreach ($Problem in $Problems) {

        Write-Host " - $Problem" -ForegroundColor Red
    }

    Write-Host ""
}

if ($Warnings.Count -gt 0) {

    Write-Host "WARNINGS:" -ForegroundColor Yellow

    foreach ($Warning in $Warnings) {

        Write-Host " - $Warning" -ForegroundColor Yellow
    }

    Write-Host ""
}

Write-Host "TXT Report :" -ForegroundColor White
Write-Host $OutputTXT -ForegroundColor Gray

Write-Host ""
Write-Host "JSON Report:" -ForegroundColor White
Write-Host $OutputJSON -ForegroundColor Gray

Write-Host ""
Write-Host "Module 03 completed." -ForegroundColor Green
Write-Host ""

# --------------------------------------------------------------------------------------------------
# THREE SEPARATE ENTER PRESSES
# --------------------------------------------------------------------------------------------------

Read-Host "Press Enter (1/3)"
Read-Host "Press Enter (2/3)"
Read-Host "Press Enter (3/3)"

# ==================================================================================================
# END OF MODULE 03
# ==================================================================================================