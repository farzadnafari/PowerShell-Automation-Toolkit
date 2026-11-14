# ============================================================
# WINDOWS SYSTEM OPTIMIZATION & HEALTH CHECK
# ============================================================
#
# PURPOSE
# -------
# This script performs a read-only health and optimization
# assessment of the current Windows system.
#
# IMPORTANT
# ---------
# This script DOES NOT:
# - Change Windows settings
# - Kill processes
# - Suspend processes
# - Modify services
# - Modify startup settings
# - Change power plans
# - Delete files
# - Optimize or "clean" anything automatically
#
# It only examines the current system configuration and state.
#
# The script can be run repeatedly at any time, including while
# applications such as Chrome, Photoshop, Python, etc. are open.
#
# Compatible design for Windows 10 / Windows 11.
#
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# GLOBAL VARIABLES
# ============================================================

$TotalChecks   = 0
$PassedChecks  = 0
$WarningChecks = 0
$FailedChecks  = 0

$Score = 100

# ============================================================
# CHECK FUNCTION
# ============================================================

function Add-HealthCheck {

    param(
        [string]$Name,

        [ValidateSet(
            "PASS",
            "GOOD",
            "WARNING",
            "FAIL"
        )]
        [string]$Status,

        [string]$Details,

        [int]$Penalty = 0
    )

    $script:TotalChecks++

    switch ($Status) {

        "PASS" {
            $script:PassedChecks++
            $Color = "Green"
            $Symbol = "[PASS]"
        }

        "GOOD" {
            $script:PassedChecks++
            $Color = "Green"
            $Symbol = "[GOOD]"
        }

        "WARNING" {
            $script:WarningChecks++
            $Color = "Yellow"
            $Symbol = "[WARN]"
        }

        "FAIL" {
            $script:FailedChecks++
            $Color = "Red"
            $Symbol = "[FAIL]"
        }
    }

    if ($Penalty -gt 0) {
        $script:Score -= $Penalty
    }

    Write-Host ""
    Write-Host "$Symbol $Name" -ForegroundColor $Color
    Write-Host "      $Details"
}

# ============================================================
# HEADER
# ============================================================

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "        WINDOWS SYSTEM OPTIMIZATION & HEALTH CHECK" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Read-only diagnostic mode."
Write-Host "No system changes will be made."
Write-Host ""

# ============================================================
# WINDOWS INFORMATION
# ============================================================

Write-Host "------------------------------------------------------------"
Write-Host "1. WINDOWS INFORMATION" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$OS = Get-CimInstance Win32_OperatingSystem

if ($OS) {

    $OSName = $OS.Caption
    $OSVersion = $OS.Version
    $Build = $OS.BuildNumber

    Add-HealthCheck `
        "Windows" `
        "PASS" `
        "$OSName | Version $OSVersion | Build $Build"

}
else {

    Add-HealthCheck `
        "Windows" `
        "WARNING" `
        "Windows information could not be read."
}

# ============================================================
# SYSTEM UPTIME
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "2. SYSTEM UPTIME" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

if ($OS) {

    try {

        $BootTime = $OS.LastBootUpTime
        $Uptime = (Get-Date) - $BootTime

        $UptimeText =
            "{0} days, {1} hours, {2} minutes" -f `
            $Uptime.Days,
            $Uptime.Hours,
            $Uptime.Minutes

        if ($Uptime.TotalDays -lt 7) {

            Add-HealthCheck `
                "System Uptime" `
                "GOOD" `
                $UptimeText

        }
        elseif ($Uptime.TotalDays -lt 14) {

            Add-HealthCheck `
                "System Uptime" `
                "WARNING" `
                "$UptimeText - Consider a normal restart if performance has degraded." `
                2

        }
        else {

            Add-HealthCheck `
                "System Uptime" `
                "WARNING" `
                "$UptimeText - Long uptime can sometimes accumulate resource pressure." `
                4
        }

    }
    catch {
    }
}

# ============================================================
# CPU
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "3. CPU STATUS" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$CPU = Get-CimInstance Win32_Processor |
    Measure-Object -Property LoadPercentage -Average

$CPUUsage = [math]::Round(
    $CPU.Average,
    1
)

$CPUName =
    (Get-CimInstance Win32_Processor |
        Select-Object -First 1).Name

Write-Host ""
Write-Host "CPU : $CPUName"
Write-Host "Current Usage : $CPUUsage %"

if ($CPUUsage -lt 50) {

    Add-HealthCheck `
        "CPU Load" `
        "PASS" `
        "Current CPU load is $CPUUsage%."

}
elseif ($CPUUsage -lt 80) {

    Add-HealthCheck `
        "CPU Load" `
        "WARNING" `
        "Current CPU load is $CPUUsage%. Moderate activity detected." `
        3

}
else {

    Add-HealthCheck `
        "CPU Load" `
        "FAIL" `
        "Current CPU load is $CPUUsage%. High CPU pressure detected." `
        10
}

# ============================================================
# RAM
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "4. MEMORY STATUS" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$TotalRAMGB =
    [math]::Round(
        $OS.TotalVisibleMemorySize / 1MB,
        2
    )

$FreeRAMGB =
    [math]::Round(
        $OS.FreePhysicalMemory / 1MB,
        2
    )

$UsedRAMGB =
    [math]::Round(
        $TotalRAMGB - $FreeRAMGB,
        2
    )

$RAMPercent =
    [math]::Round(
        ($UsedRAMGB / $TotalRAMGB) * 100,
        1
    )

Write-Host ""
Write-Host "Total RAM : $TotalRAMGB GB"
Write-Host "Used RAM  : $UsedRAMGB GB"
Write-Host "Free RAM  : $FreeRAMGB GB"
Write-Host "Usage     : $RAMPercent %"

if ($RAMPercent -lt 70) {

    Add-HealthCheck `
        "RAM Usage" `
        "PASS" `
        "Memory usage is $RAMPercent%."

}
elseif ($RAMPercent -lt 85) {

    Add-HealthCheck `
        "RAM Usage" `
        "WARNING" `
        "Memory usage is $RAMPercent%." `
        5

}
else {

    Add-HealthCheck `
        "RAM Usage" `
        "FAIL" `
        "Memory usage is $RAMPercent%." `
        12
}

# ============================================================
# SYSTEM DRIVE
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "5. SYSTEM DRIVE" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$SystemDrive =
    $env:SystemDrive

$Drive =
    Get-CimInstance Win32_LogicalDisk `
        -Filter "DeviceID='$SystemDrive'"

if ($Drive) {

    $TotalDriveGB =
        [math]::Round(
            $Drive.Size / 1GB,
            2
        )

    $FreeDriveGB =
        [math]::Round(
            $Drive.FreeSpace / 1GB,
            2
        )

    $UsedDrivePercent =
        [math]::Round(
            (($Drive.Size - $Drive.FreeSpace) /
            $Drive.Size) * 100,
            1
        )

    Write-Host ""
    Write-Host "System Drive : $SystemDrive"
    Write-Host "Total        : $TotalDriveGB GB"
    Write-Host "Free         : $FreeDriveGB GB"
    Write-Host "Used         : $UsedDrivePercent %"

    if ($UsedDrivePercent -lt 80) {

        Add-HealthCheck `
            "System Drive Space" `
            "PASS" `
            "$FreeDriveGB GB free on $SystemDrive."

    }
    elseif ($UsedDrivePercent -lt 90) {

        Add-HealthCheck `
            "System Drive Space" `
            "WARNING" `
            "$FreeDriveGB GB free on $SystemDrive." `
            5

    }
    else {

        Add-HealthCheck `
            "System Drive Space" `
            "FAIL" `
            "Only $FreeDriveGB GB free on $SystemDrive." `
            12
    }
}

# ============================================================
# PHYSICAL DISK HEALTH
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "6. DISK HEALTH" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$PhysicalDisks =
    Get-PhysicalDisk

if ($PhysicalDisks) {

    foreach ($Disk in $PhysicalDisks) {

        $DiskText =
            "$($Disk.FriendlyName) | $($Disk.MediaType) | Health=$($Disk.HealthStatus) | Operational=$($Disk.OperationalStatus)"

        if ($Disk.HealthStatus -eq "Healthy") {

            Add-HealthCheck `
                "Disk: $($Disk.FriendlyName)" `
                "PASS" `
                $DiskText

        }
        else {

            Add-HealthCheck `
                "Disk: $($Disk.FriendlyName)" `
                "WARNING" `
                $DiskText `
                8
        }
    }

}
else {

    Add-HealthCheck `
        "Physical Disk Health" `
        "WARNING" `
        "Physical disk health information is unavailable on this system."
}

# ============================================================
# POWER PLAN
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "7. POWER CONFIGURATION" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$PowerOutput =
    powercfg /getactivescheme 2>$null

if ($PowerOutput) {

    Write-Host ""
    Write-Host "Active Power Plan:"
    Write-Host "  $PowerOutput"

    if ($PowerOutput -match "High performance") {

        Add-HealthCheck `
            "Power Plan" `
            "GOOD" `
            "High Performance plan is active."

    }
    elseif ($PowerOutput -match "Balanced") {

        Add-HealthCheck `
            "Power Plan" `
            "PASS" `
            "Balanced plan is active. Suitable for normal use."

    }
    elseif ($PowerOutput -match "Power saver") {

        Add-HealthCheck `
            "Power Plan" `
            "WARNING" `
            "Power Saver plan is active. Performance may be reduced." `
            3

    }
    else {

        Add-HealthCheck `
            "Power Plan" `
            "PASS" `
            "An active Windows power plan was detected."
    }

}

# ============================================================
# TOP CPU PROCESSES
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "8. TOP CPU PROCESSES" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$TopCPU =
    Get-Process |
    Sort-Object CPU -Descending |
    Select-Object -First 10 `
        ProcessName,
        Id,
        CPU

Write-Host ""

foreach ($Process in $TopCPU) {

    $CPUTime =
        if ($null -eq $Process.CPU) {
            0
        }
        else {
            [math]::Round($Process.CPU, 1)
        }

    Write-Host `
        ("  {0,-30} PID={1,-7} CPU-Time={2}" -f `
        $Process.ProcessName,
        $Process.Id,
        $CPUTime)
}

# ============================================================
# TOP MEMORY PROCESSES
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "9. TOP MEMORY PROCESSES" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$TopMemory =
    Get-Process |
    Sort-Object WorkingSet64 -Descending |
    Select-Object -First 10

Write-Host ""

foreach ($Process in $TopMemory) {

    $MemoryMB =
        [math]::Round(
            $Process.WorkingSet64 / 1MB,
            1
        )

    Write-Host `
        ("  {0,-30} PID={1,-7} RAM={2} MB" -f `
        $Process.ProcessName,
        $Process.Id,
        $MemoryMB)
}

# ============================================================
# RUNNING APPLICATIONS
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "10. CURRENTLY RUNNING APPLICATIONS" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$VisibleApplications =
    Get-Process |
    Where-Object {
        $_.MainWindowHandle -ne [IntPtr]::Zero -and
        -not [string]::IsNullOrWhiteSpace($_.MainWindowTitle)
    } |
    Sort-Object ProcessName

if ($VisibleApplications) {

    Write-Host ""

    $UniqueVisible =
        $VisibleApplications |
        Select-Object ProcessName, MainWindowTitle -Unique

    foreach ($Application in $UniqueVisible) {

        Write-Host `
            ("  {0,-30} {1}" -f `
            $Application.ProcessName,
            $Application.MainWindowTitle)
    }

}
else {

    Write-Host ""
    Write-Host "  No visible desktop applications detected."
}

# ============================================================
# IMPORTANT APPLICATIONS
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "11. IMPORTANT APPLICATION CHECK" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$ImportantApps = @(
    "chrome",
    "msedge",
    "firefox",
    "Photoshop",
    "PhotoshopElements",
    "python",
    "pythonw",
    "devenv",
    "Code",
    "WINWORD",
    "EXCEL",
    "POWERPNT",
    "Teams"
)

foreach ($AppName in $ImportantApps) {

    $Processes =
        Get-Process `
            -Name $AppName `
            -ErrorAction SilentlyContinue

    if ($Processes) {

        $Count =
            @($Processes).Count

        $Memory =
            [math]::Round(
                (
                    $Processes |
                    Measure-Object WorkingSet64 -Sum
                ).Sum / 1GB,
                2
            )

        Write-Host ""
        Write-Host "  $AppName : RUNNING | Processes=$Count | RAM=$Memory GB"

    }
}

# ============================================================
# NON-RESPONDING PROCESSES
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "12. APPLICATION RESPONSIVENESS" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$NonResponsive = @()

Get-Process |
    ForEach-Object {

        try {

            if (
                $_.MainWindowHandle -ne [IntPtr]::Zero -and
                $_.Responding -eq $false
            ) {

                $NonResponsive += $_
            }

        }
        catch {
        }
    }

if ($NonResponsive.Count -eq 0) {

    Add-HealthCheck `
        "Application Responsiveness" `
        "PASS" `
        "No visible application is currently reporting Not Responding."

}
else {

    foreach ($Process in $NonResponsive) {

        Write-Host ""
        Write-Host `
            "  NOT RESPONDING: $($Process.ProcessName) PID=$($Process.Id)" `
            -ForegroundColor Yellow
    }

    Add-HealthCheck `
        "Application Responsiveness" `
        "WARNING" `
        "$($NonResponsive.Count) visible application process(es) currently report Not Responding." `
        10
}

# ============================================================
# SUSPENDED / LOW-RESPONSIVENESS CHECK
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "13. SUSPENDED PROCESS CHECK" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$PotentiallySuspended = @()

Get-Process |
    ForEach-Object {

        try {

            if (
                $_.Responding -eq $false -and
                $_.MainWindowHandle -eq [IntPtr]::Zero
            ) {

                $PotentiallySuspended += $_
            }

        }
        catch {
        }
    }

if ($PotentiallySuspended.Count -eq 0) {

    Add-HealthCheck `
        "Suspended Process Check" `
        "PASS" `
        "No obvious suspended/non-responsive background process was detected."

}
else {

    Write-Host ""
    Write-Host "Potential candidates:" -ForegroundColor Yellow

    $PotentiallySuspended |
        Select-Object -First 20 |
        ForEach-Object {

            Write-Host `
                "  $($_.ProcessName) PID=$($_.Id)"
        }

    Add-HealthCheck `
        "Suspended Process Check" `
        "WARNING" `
        "$($PotentiallySuspended.Count) background process(es) may require investigation." `
        5
}

# ============================================================
# WINDOWS SERVICES
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "14. IMPORTANT WINDOWS SERVICES" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$ImportantServices = @(
    "EventLog",
    "RpcSs",
    "DcomLaunch",
    "PlugPlay",
    "Winmgmt",
    "Schedule",
    "ProfSvc",
    "Power",
    "LanmanWorkstation",
    "Dhcp",
    "Dnscache"
)

foreach ($ServiceName in $ImportantServices) {

    $Service =
        Get-Service `
            -Name $ServiceName `
            -ErrorAction SilentlyContinue

    if ($Service) {

        if ($Service.Status -eq "Running") {

            Write-Host `
                "  $ServiceName : Running" `
                -ForegroundColor Green

        }
        else {

            Write-Host `
                "  $ServiceName : $($Service.Status)" `
                -ForegroundColor Yellow
        }
    }
}

# ============================================================
# WINDOWS DEFENDER
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "15. SECURITY STATUS" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$DefenderCommand =
    Get-Command Get-MpComputerStatus `
        -ErrorAction SilentlyContinue

if ($DefenderCommand) {

    try {

        $Defender =
            Get-MpComputerStatus

        if ($Defender.AntivirusEnabled -and
            $Defender.RealTimeProtectionEnabled) {

            Add-HealthCheck `
                "Microsoft Defender" `
                "PASS" `
                "Antivirus and Real-Time Protection are enabled."

        }
        else {

            Add-HealthCheck `
                "Microsoft Defender" `
                "WARNING" `
                "Defender is installed but one or more protection components are not enabled." `
                5
        }

    }
    catch {

        Add-HealthCheck `
            "Microsoft Defender" `
            "WARNING" `
            "Defender status could not be fully read."
    }

}
else {

    Add-HealthCheck `
        "Microsoft Defender" `
        "WARNING" `
        "Defender status command is unavailable on this system."
}

# ============================================================
# WINDOWS UPDATE SERVICE
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "16. WINDOWS UPDATE SERVICE" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$UpdateService =
    Get-Service `
        -Name wuauserv `
        -ErrorAction SilentlyContinue

if ($UpdateService) {

    if ($UpdateService.Status -eq "Running") {

        Add-HealthCheck `
            "Windows Update Service" `
            "PASS" `
            "Windows Update service is running."

    }
    else {

        Add-HealthCheck `
            "Windows Update Service" `
            "GOOD" `
            "Windows Update service is currently $($UpdateService.Status)."
    }
}

# ============================================================
# TEMPORARY SYSTEM LOAD SNAPSHOT
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "17. FINAL RESOURCE SNAPSHOT" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

Start-Sleep -Seconds 2

$CPU2 =
    Get-CimInstance Win32_Processor |
    Measure-Object -Property LoadPercentage -Average

$CPU2Usage =
    [math]::Round(
        $CPU2.Average,
        1
    )

$OS2 =
    Get-CimInstance Win32_OperatingSystem

$FreeRAM2GB =
    [math]::Round(
        $OS2.FreePhysicalMemory / 1MB,
        2
    )

$UsedRAM2GB =
    [math]::Round(
        (
            $OS2.TotalVisibleMemorySize -
            $OS2.FreePhysicalMemory
        ) / 1MB,
        2
    )

$RAM2Percent =
    [math]::Round(
        (
            $UsedRAM2GB /
            ($OS2.TotalVisibleMemorySize / 1MB)
        ) * 100,
        1
    )

Write-Host ""
Write-Host "CPU Usage : $CPU2Usage %"
Write-Host "RAM Usage : $RAM2Percent %"
Write-Host "Free RAM  : $FreeRAM2GB GB"

# ============================================================
# FINAL SCORE
# ============================================================

if ($Score -lt 0) {
    $Score = 0
}

if ($Score -gt 100) {
    $Score = 100
}

Write-Host ""
Write-Host "============================================================"
Write-Host "                    FINAL ASSESSMENT" -ForegroundColor Cyan
Write-Host "============================================================"
Write-Host ""

Write-Host "Optimization Score : $Score / 100"
Write-Host "Total Checks       : $TotalChecks"
Write-Host "Passed / Good      : $PassedChecks"
Write-Host "Warnings           : $WarningChecks"
Write-Host "Failures           : $FailedChecks"
Write-Host ""

if (
    $FailedChecks -eq 0 -and
    $WarningChecks -eq 0 -and
    $Score -ge 90
) {

    Write-Host "SYSTEM STATUS: OPTIMAL" -ForegroundColor Green
    Write-Host ""
    Write-Host "The current system state appears healthy and well balanced."

}
elseif (
    $FailedChecks -eq 0 -and
    $Score -ge 80
) {

    Write-Host "SYSTEM STATUS: GOOD" -ForegroundColor Green
    Write-Host ""
    Write-Host "The system is operating normally with no critical issue."

}
elseif (
    $FailedChecks -eq 0 -and
    $Score -ge 65
) {

    Write-Host "SYSTEM STATUS: GOOD WITH WARNINGS" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The system is usable, but one or more conditions deserve attention."

}
else {

    Write-Host "SYSTEM STATUS: ATTENTION REQUIRED" -ForegroundColor Red
    Write-Host ""
    Write-Host "One or more conditions may be affecting system performance."

}

Write-Host ""
Write-Host "IMPORTANT:"
Write-Host "This score is a diagnostic indicator, not a benchmark."
Write-Host "High resource usage can be normal when demanding applications"
Write-Host "such as Photoshop, development tools, browsers, or games are running."
Write-Host ""
Write-Host "No system changes were made by this script."
Write-Host ""

# ============================================================
# END
# ============================================================

Read-Host "Press Enter"

Read-Host "Press Enter"

Read-Host "Press Enter"