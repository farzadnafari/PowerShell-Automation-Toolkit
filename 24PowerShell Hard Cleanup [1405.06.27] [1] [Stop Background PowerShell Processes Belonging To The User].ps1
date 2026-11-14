# ============================================================
# PowerShell Hard Cleanup
#
# Purpose:
# - Run with Administrator privileges.
# - Disable/remove non-system PowerShell persistence mechanisms.
# - Clean suspicious user Startup and Run entries.
# - Disable custom Scheduled Tasks that launch PowerShell.
# - Stop background PowerShell processes belonging to the user.
# - Preserve Windows system PowerShell components and Microsoft tasks.
# - Backup user PowerShell scripts instead of deleting them.
# - Keep this PowerShell session alive until three ENTER presses.
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

# ------------------------------------------------------------
# Self-elevation
# ------------------------------------------------------------

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

if (-not $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

    exit
}

Write-Host ""
Write-Host "==============================================="
Write-Host "       POWERSHELL HARD CLEANUP"
Write-Host "==============================================="
Write-Host ""

# ------------------------------------------------------------
# Variables
# ------------------------------------------------------------

$UserStartup = Join-Path $env:APPDATA `
    "Microsoft\Windows\Start Menu\Programs\Startup"

$UserRunPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

$Desktop = [Environment]::GetFolderPath("Desktop")

$BackupDir = Join-Path $Desktop "PowerShell_Backup"

$RegistryBackup = Join-Path $Desktop "PowerShell_Startup_Backup.reg"

New-Item -ItemType Directory `
    -Path $BackupDir `
    -Force | Out-Null

# ------------------------------------------------------------
# 1. Backup user Run registry
# ------------------------------------------------------------

Write-Host "[1/8] Backing up user startup registry..."

reg.exe export `
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" `
    "$RegistryBackup" `
    /y | Out-Null

# ------------------------------------------------------------
# 2. Remove PowerShell-related user Run entries
# ------------------------------------------------------------

Write-Host "[2/8] Cleaning user Run entries..."

$RunProperties = Get-ItemProperty `
    -Path $UserRunPath

foreach ($Property in $RunProperties.PSObject.Properties) {

    $Name = $Property.Name
    $Value = [string]$Property.Value

    if ($Name -in @(
        "PSPath",
        "PSParentPath",
        "PSChildName",
        "PSDrive",
        "PSProvider"
    )) {
        continue
    }

    if ($Value -match `
        '(?i)powershell|pwsh|\.ps1|\.psm1|ExecutionPolicy|EncodedCommand') {

        Write-Host "Removing Run entry: $Name"

        Remove-ItemProperty `
            -Path $UserRunPath `
            -Name $Name `
            -Force
    }
}

# ------------------------------------------------------------
# 3. Clean user Startup folder
# ------------------------------------------------------------

Write-Host "[3/8] Cleaning user Startup folder..."

if (Test-Path $UserStartup) {

    $StartupItems = Get-ChildItem `
        -Path $UserStartup `
        -Force

    foreach ($Item in $StartupItems) {

        $RemoveItem = $false

        if ($Item.Extension -match `
            '(?i)\.ps1|\.psm1|\.psd1|\.bat|\.cmd') {

            $RemoveItem = $true
        }

        if ($Item.Extension -eq ".lnk") {

            try {

                $Shell = New-Object -ComObject WScript.Shell

                $Shortcut = $Shell.CreateShortcut(
                    $Item.FullName
                )

                $Target = [string]$Shortcut.TargetPath
                $Arguments = [string]$Shortcut.Arguments

                $Combined = "$Target $Arguments"

                if ($Combined -match `
                    '(?i)powershell|pwsh|\.ps1|ExecutionPolicy|EncodedCommand') {

                    $RemoveItem = $true
                }

                if ($Combined -match `
                    '(?i)ProgramData\\Microsoft\\Windows\\Caches') {

                    $RemoveItem = $true
                }

            }
            catch {}
        }

        if ($RemoveItem) {

            Write-Host "Removing Startup item: $($Item.Name)"

            Remove-Item `
                -Path $Item.FullName `
                -Force `
                -Recurse
        }
    }
}

# ------------------------------------------------------------
# 4. Disable custom Scheduled Tasks
# ------------------------------------------------------------

Write-Host "[4/8] Inspecting Scheduled Tasks..."

$Tasks = Get-ScheduledTask

foreach ($Task in $Tasks) {

    $TaskPath = [string]$Task.TaskPath
    $TaskName = [string]$Task.TaskName

    # Never touch Microsoft Windows system task paths.
    if ($TaskPath -like "\Microsoft\Windows\*") {
        continue
    }

    $Actions = $Task.Actions

    foreach ($Action in $Actions) {

        $Execute = [string]$Action.Execute
        $Arguments = [string]$Action.Arguments

        $CommandLine = "$Execute $Arguments"

        if ($CommandLine -match `
            '(?i)powershell|pwsh|\.ps1|EncodedCommand|ExecutionPolicy') {

            Write-Host "Disabling custom task: $TaskPath$TaskName"

            Disable-ScheduledTask `
                -TaskName $TaskName `
                -TaskPath $TaskPath | Out-Null

            break
        }
    }
}

# ------------------------------------------------------------
# 5. Disable PowerShell-based WMI event subscriptions
# ------------------------------------------------------------

Write-Host "[5/8] Inspecting WMI event subscriptions..."

$WmiNamespaces = @(
    "root\subscription"
)

foreach ($Namespace in $WmiNamespaces) {

    try {

        $Filters = Get-CimInstance `
            -Namespace $Namespace `
            -ClassName __EventFilter

        foreach ($Filter in $Filters) {

            $Query = [string]$Filter.Query

            if ($Query -match `
                '(?i)powershell|pwsh|\.ps1|EncodedCommand') {

                Write-Host "Removing suspicious WMI event filter: $($Filter.Name)"

                $Filter | Remove-CimInstance
            }
        }

    }
    catch {}
}

# ------------------------------------------------------------
# 6. Move PowerShell scripts from Desktop
# ------------------------------------------------------------

Write-Host "[6/8] Securing Desktop PowerShell scripts..."

$DesktopScripts = Get-ChildItem `
    -Path $Desktop `
    -File `
    -Force `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Extension -match '(?i)\.ps1|\.psm1|\.psd1'
    }

foreach ($Script in $DesktopScripts) {

    $Destination = Join-Path `
        $BackupDir `
        $Script.Name

    Write-Host "Moving script: $($Script.Name)"

    Move-Item `
        -Path $Script.FullName `
        -Destination $Destination `
        -Force
}

# ------------------------------------------------------------
# 7. Stop background PowerShell processes
# ------------------------------------------------------------

Write-Host "[7/8] Stopping non-system PowerShell processes..."

$CurrentPID = $PID

$Processes = Get-CimInstance Win32_Process `
    -Filter "Name='powershell.exe' OR Name='pwsh.exe'"

foreach ($Process in $Processes) {

    if ($Process.ProcessId -eq $CurrentPID) {
        continue
    }

    $ProcessCommand = [string]$Process.CommandLine

    $IsSystemPath = $false

    if ($Process.ExecutablePath -match `
        '(?i)^C:\\Windows\\System32\\|^C:\\Windows\\SysWOW64\\') {

        $IsSystemPath = $true
    }

    $IsPowerShell = $false

    if ($Process.Name -match '(?i)^powershell\.exe$|^pwsh\.exe$') {
        $IsPowerShell = $true
    }

    if ($IsPowerShell -and -not $IsSystemPath) {

        Write-Host "Stopping PID $($Process.ProcessId)"

        try {
            Stop-Process `
                -Id $Process.ProcessId `
                -Force
        }
        catch {}
    }
}

# ------------------------------------------------------------
# 8. Final verification
# ------------------------------------------------------------

Write-Host "[8/8] Final verification..."

Start-Sleep -Seconds 2

$Remaining = Get-CimInstance Win32_Process `
    -Filter "Name='powershell.exe' OR Name='pwsh.exe'" |
    Where-Object {
        $_.ProcessId -ne $CurrentPID
    }

if ($Remaining) {

    Write-Host ""
    Write-Host "Remaining PowerShell processes:"
    
    foreach ($Process in $Remaining) {
        Write-Host "PID: $($Process.ProcessId)"
        Write-Host "Path: $($Process.ExecutablePath)"
        Write-Host "Command: $($Process.CommandLine)"
        Write-Host ""
    }

}
else {

    Write-Host ""
    Write-Host "No additional PowerShell processes detected."
}

Write-Host ""
Write-Host "==============================================="
Write-Host " CLEANUP COMPLETED"
Write-Host "==============================================="
Write-Host ""

# ------------------------------------------------------------
# IMPORTANT:
# Do NOT terminate this PowerShell session.
# The three Read-Host commands intentionally keep
# this console alive until the user presses ENTER three times.
# ------------------------------------------------------------

Read-Host "Press ENTER 1/3 to exit"
Read-Host "Press ENTER 2/3 to exit"
Read-Host "Press ENTER 3/3 to exit"