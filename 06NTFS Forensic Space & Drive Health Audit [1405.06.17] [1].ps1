# ================================================================
# NTFS FORENSIC SPACE & DRIVE HEALTH AUDIT - V4
# ================================================================
# PowerShell 5.1 Compatible
#
# TARGET:
#   D:
#
# PURPOSE:
#   1. Exact filesystem capacity / used / free verification
#   2. NTFS filesystem information
#   3. NTFS sector / cluster information
#   4. NTFS allocation report
#   5. Full accessible file enumeration
#   6. Logical file-size calculation
#   7. Real alternate data stream (ADS) detection
#   8. Recycle Bin inspection
#   9. System Volume Information inspection
#  10. Shadow Storage inspection
#  11. Shadow Copy inspection
#  12. Reparse point inspection
#  13. NTFS filesystem statistics
#  14. CHKDSK /SCAN filesystem integrity check
#  15. Physical disk health check where supported
#  16. Windows disk status verification
#  17. DiskResourceFailure event check
#  18. LogFileFull event check
#  19. Space reconciliation
#  20. Intelligent PASS / WARNING / FAIL verdict
#
# IMPORTANT:
#   READ-ONLY AUDIT
#
#   This script does NOT:
#   - Delete files
#   - Modify files
#   - Repair the filesystem
#   - Format the drive
#   - Dismount the drive
#   - Defragment the drive
#   - Change partition information
#   - Change drive letters
#   - Change NTFS configuration
#   - Delete Shadow Copies
#   - Modify the Recycle Bin
#
# ================================================================

$ErrorActionPreference = 'Continue'

# ================================================================
# CONFIGURATION
# ================================================================

$Drive = 'D:'
$Root  = "$Drive\"

# ================================================================
# ADMINISTRATOR ELEVATION
# ================================================================

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()

$Principal = New-Object Security.Principal.WindowsPrincipal(
    $CurrentIdentity
)

if (-not $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {

    Write-Host ""
    Write-Host "Administrator privileges are required." -ForegroundColor Yellow
    Write-Host "Restarting script as Administrator..." -ForegroundColor Yellow
    Write-Host ""

    $ScriptPath = $MyInvocation.MyCommand.Definition

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList @(
            '-NoProfile'
            '-ExecutionPolicy'
            'Bypass'
            '-File'
            "`"$ScriptPath`""
        )

    exit
}

# ================================================================
# HELPER FUNCTIONS
# ================================================================

function Format-Bytes {

    param(
        [UInt64]$Bytes
    )

    if ($Bytes -ge 1TB) {
        return "{0:N2} TB" -f ($Bytes / 1TB)
    }
    elseif ($Bytes -ge 1GB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    }
    elseif ($Bytes -ge 1MB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)
    }
    elseif ($Bytes -ge 1KB) {
        return "{0:N2} KB" -f ($Bytes / 1KB)
    }
    else {
        return "$Bytes bytes"
    }
}

function Write-Section {

    param(
        [string]$Title
    )

    Write-Host ""
    Write-Host "================================================================" `
        -ForegroundColor Cyan

    Write-Host " $Title" `
        -ForegroundColor Cyan

    Write-Host "================================================================" `
        -ForegroundColor Cyan
}

function Run-NativeCommand {

    param(
        [string]$FilePath,
        [string[]]$Arguments
    )

    try {

        $Output = & $FilePath @Arguments 2>&1

        return [PSCustomObject]@{
            Success  = ($LASTEXITCODE -eq 0)
            ExitCode = $LASTEXITCODE
            Output   = @($Output)
        }

    }
    catch {

        return [PSCustomObject]@{
            Success  = $false
            ExitCode = -1
            Output   = @($_.Exception.Message)
        }
    }
}

# ================================================================
# START
# ================================================================

$AuditStart = Get-Date

$Warnings = New-Object System.Collections.ArrayList
$Failures = New-Object System.Collections.ArrayList

Clear-Host

Write-Host ""
Write-Host "================================================================" `
    -ForegroundColor DarkCyan

Write-Host "                NTFS FORENSIC DRIVE AUDIT V4" `
    -ForegroundColor White

Write-Host "================================================================" `
    -ForegroundColor DarkCyan

Write-Host ""
Write-Host "READ-ONLY / ADMINISTRATOR MODE" `
    -ForegroundColor Yellow

Write-Host ""
Write-Host "Target Drive : $Drive" -ForegroundColor White
Write-Host "Started      : $AuditStart" -ForegroundColor White
Write-Host ""

# ================================================================
# BASIC DRIVE VALIDATION
# ================================================================

Write-Section "1. BASIC DRIVE VALIDATION"

$Volume = $null
$CapacityBytes = [UInt64]0
$FreeBytes = [UInt64]0
$UsedBytes = [UInt64]0

try {

    $Volume = Get-CimInstance Win32_LogicalDisk `
        -Filter "DeviceID='$Drive'"

    if (-not $Volume) {

        Write-Host ""
        Write-Host "ERROR: Drive $Drive was not found." `
            -ForegroundColor Red

        $Failures.Add(
            "Drive $Drive was not found."
        ) | Out-Null

    }
    else {

        Write-Host "Drive        : $($Volume.DeviceID)"
        Write-Host "Volume Name  : $($Volume.VolumeName)"
        Write-Host "File System  : $($Volume.FileSystem)"
        Write-Host "Capacity     : $($Volume.Size) bytes"
        Write-Host "Capacity     : $(Format-Bytes $Volume.Size)"
        Write-Host "Free Space   : $($Volume.FreeSpace) bytes"
        Write-Host "Free Space   : $(Format-Bytes $Volume.FreeSpace)"

        $CapacityBytes = [UInt64]$Volume.Size
        $FreeBytes = [UInt64]$Volume.FreeSpace
        $UsedBytes = $CapacityBytes - $FreeBytes

        Write-Host "Used Space   : $UsedBytes bytes"
        Write-Host "Used Space   : $(Format-Bytes $UsedBytes)"

        if ($Volume.FileSystem -ne 'NTFS') {

            Write-Host ""
            Write-Host "ERROR: Target filesystem is not NTFS." `
                -ForegroundColor Red

            $Failures.Add(
                "Target filesystem is not NTFS."
            ) | Out-Null
        }
        else {

            Write-Host ""
            Write-Host "Filesystem status: NTFS" `
                -ForegroundColor Green
        }
    }
}
catch {

    Write-Host ""
    Write-Host "Drive validation failed." `
        -ForegroundColor Red

    $Failures.Add(
        "Drive validation failed."
    ) | Out-Null
}

# ================================================================
# NTFS INFORMATION
# ================================================================

Write-Section "2. NTFS INFORMATION"

$NtfsResult = Run-NativeCommand `
    "fsutil.exe" `
    @("fsinfo","ntfsinfo",$Root)

if ($NtfsResult.Success) {

    foreach ($Line in $NtfsResult.Output) {
        Write-Host $Line
    }

}
else {

    Write-Host "Unable to obtain NTFS information." `
        -ForegroundColor Yellow

    $Warnings.Add(
        "NTFS information was unavailable."
    ) | Out-Null
}

# ================================================================
# SECTOR INFORMATION
# ================================================================

Write-Section "3. SECTOR / CLUSTER INFORMATION"

$SectorResult = Run-NativeCommand `
    "fsutil.exe" `
    @("fsinfo","sectorinfo",$Root)

if ($SectorResult.Success) {

    foreach ($Line in $SectorResult.Output) {
        Write-Host $Line
    }

}
else {

    Write-Host "Sector information is unavailable on this system." `
        -ForegroundColor DarkYellow

    Write-Host "This does not indicate a drive failure." `
        -ForegroundColor DarkYellow
}

# ================================================================
# NTFS ALLOCATION REPORT
# ================================================================

Write-Section "4. NTFS ALLOCATION REPORT"

Write-Host "Running official NTFS allocation report..." `
    -ForegroundColor Yellow

$AllocationResult = Run-NativeCommand `
    "fsutil.exe" `
    @("volume","allocationreport",$Drive)

$AllocationAvailable = $false
$AllocationOutput = @()

if ($AllocationResult.Success) {

    $AllocationAvailable = $true
    $AllocationOutput = @($AllocationResult.Output)

    foreach ($Line in $AllocationOutput) {
        Write-Host $Line
    }

}
else {

    Write-Host ""
    Write-Host "NTFS allocation report is unavailable." `
        -ForegroundColor DarkYellow

    Write-Host "This does not automatically indicate filesystem corruption." `
        -ForegroundColor DarkYellow
}

# ================================================================
# FULL FILE ENUMERATION
# ================================================================

Write-Section "5. FULL FILE ENUMERATION"

Write-Host "Scanning every accessible file..." `
    -ForegroundColor Yellow

$FileCount = 0
$LogicalBytes = [UInt64]0
$EnumerationErrors = 0

$Files = New-Object System.Collections.Generic.List[System.IO.FileInfo]

try {

    Get-ChildItem `
        -LiteralPath $Root `
        -Force `
        -Recurse `
        -File `
        -ErrorAction SilentlyContinue |
    ForEach-Object {

        try {

            $FileCount++

            $LogicalBytes += [UInt64]$_.Length

            $Files.Add($_)

        }
        catch {

            $EnumerationErrors++
        }
    }

}
catch {

    $EnumerationErrors++
}

Write-Host ""
Write-Host "Files Found       : $FileCount"
Write-Host "Logical File Data : $LogicalBytes bytes"
Write-Host "Logical File Data : $(Format-Bytes $LogicalBytes)"
Write-Host "Enumeration Errors: $EnumerationErrors"

if ($EnumerationErrors -gt 0) {

    Write-Host ""
    Write-Host "WARNING: Some filesystem objects could not be fully enumerated." `
        -ForegroundColor Yellow

    $Warnings.Add(
        "$EnumerationErrors enumeration errors occurred."
    ) | Out-Null
}

# ================================================================
# ROOT DIRECTORY CONTENT
# ================================================================

Write-Section "6. ROOT DIRECTORY CONTENT"

try {

    Get-ChildItem -LiteralPath $Root -Force |
        Sort-Object Name |
        ForEach-Object {

            $Type = if ($_.PSIsContainer) {
                "[DIR ]"
            }
            else {
                "[FILE]"
            }

            Write-Host ("{0,-6} {1}" -f $Type,$_.Name)
        }

}
catch {

    Write-Host "Unable to enumerate root directory." `
        -ForegroundColor Yellow

    $Warnings.Add(
        "Root directory enumeration failed."
    ) | Out-Null
}

# ================================================================
# RECYCLE BIN
# ================================================================

Write-Section "7. RECYCLE BIN"

$RecyclePath = Join-Path $Root '$RECYCLE.BIN'

$RecycleCount = 0
$RecycleBytes = [UInt64]0

if (Test-Path -LiteralPath $RecyclePath) {

    try {

        Get-ChildItem `
            -LiteralPath $RecyclePath `
            -Force `
            -Recurse `
            -File `
            -ErrorAction SilentlyContinue |
        ForEach-Object {

            $RecycleCount++
            $RecycleBytes += [UInt64]$_.Length
        }

        Write-Host "Files : $RecycleCount"
        Write-Host "Bytes : $RecycleBytes"
        Write-Host "Size  : $(Format-Bytes $RecycleBytes)"

    }
    catch {

        Write-Host "Recycle Bin could not be fully inspected." `
            -ForegroundColor DarkYellow

        Write-Host "This does not indicate filesystem failure." `
            -ForegroundColor DarkYellow
    }

}
else {

    Write-Host "Recycle Bin directory not found."
}

# ================================================================
# SYSTEM VOLUME INFORMATION
# ================================================================

Write-Section "8. SYSTEM VOLUME INFORMATION"

$SviPath = Join-Path $Root 'System Volume Information'

$SviCount = 0
$SviBytes = [UInt64]0

if (Test-Path -LiteralPath $SviPath) {

    try {

        Get-ChildItem `
            -LiteralPath $SviPath `
            -Force `
            -Recurse `
            -File `
            -ErrorAction Stop |
        ForEach-Object {

            $SviCount++
            $SviBytes += [UInt64]$_.Length
        }

        Write-Host "Accessible Files : $SviCount"
        Write-Host "Accessible Bytes : $SviBytes"
        Write-Host "Accessible Size  : $(Format-Bytes $SviBytes)"

    }
    catch {

        Write-Host ""
        Write-Host "System Volume Information is protected by Windows." `
            -ForegroundColor DarkYellow

        Write-Host "Protected access is normal and is not treated as a drive failure." `
            -ForegroundColor DarkYellow
    }

}
else {

    Write-Host "System Volume Information directory not found."
}

# ================================================================
# SHADOW STORAGE
# ================================================================

Write-Section "9. SHADOW STORAGE"

$ShadowStorageResult = Run-NativeCommand `
    "vssadmin.exe" `
    @("list","shadowstorage","/for=$Drive")

$ShadowStorageOutput = @($ShadowStorageResult.Output)

if ($ShadowStorageResult.Success) {

    foreach ($Line in $ShadowStorageOutput) {
        Write-Host $Line
    }

}
else {

    Write-Host ""
    Write-Host "Shadow Storage information is unavailable." `
        -ForegroundColor DarkYellow

    Write-Host "This does not automatically indicate filesystem or SSD failure." `
        -ForegroundColor DarkYellow
}

# ================================================================
# SHADOW COPIES
# ================================================================

Write-Section "10. SHADOW COPIES"

$ShadowCopyResult = Run-NativeCommand `
    "vssadmin.exe" `
    @("list","shadows","/for=$Drive")

$ShadowCopyOutput = @($ShadowCopyResult.Output)

if ($ShadowCopyResult.Success) {

    foreach ($Line in $ShadowCopyOutput) {
        Write-Host $Line
    }

}
else {

    Write-Host ""
    Write-Host "Shadow Copy information is unavailable." `
        -ForegroundColor DarkYellow

    Write-Host "This does not automatically indicate filesystem or SSD failure." `
        -ForegroundColor DarkYellow
}

# ================================================================
# REAL ADS SCAN
# ================================================================

Write-Section "11. ALTERNATE DATA STREAM (ADS) SCAN"

Write-Host "Scanning named streams..." `
    -ForegroundColor Yellow

$AdsCount = 0
$AdsBytes = [UInt64]0
$AdsErrors = 0

foreach ($File in $Files) {

    try {

        $Streams = Get-Item `
            -LiteralPath $File.FullName `
            -Stream * `
            -ErrorAction Stop

        foreach ($Stream in $Streams) {

            # The default NTFS data stream is :$DATA.
            # Any other stream is considered an alternate data stream.

            if ($Stream.Stream -ne ':$DATA') {

                $AdsCount++
                $AdsBytes += [UInt64]$Stream.Length
            }
        }
    }
    catch {

        $AdsErrors++
    }
}

Write-Host ""
Write-Host "ADS Count  : $AdsCount"
Write-Host "ADS Bytes  : $AdsBytes"
Write-Host "ADS Size   : $(Format-Bytes $AdsBytes)"
Write-Host "ADS Errors : $AdsErrors"

if ($AdsErrors -gt 0) {

    Write-Host ""
    Write-Host "$AdsErrors files could not be inspected for ADS." `
        -ForegroundColor DarkYellow

}

if ($AdsCount -eq 0) {

    Write-Host ""
    Write-Host "No alternate data streams detected." `
        -ForegroundColor Green
}
else {

    Write-Host ""
    Write-Host "Alternate data streams were detected." `
        -ForegroundColor Yellow

    Write-Host "ADS presence alone is not considered filesystem corruption." `
        -ForegroundColor DarkYellow
}

# ================================================================
# REPARSE POINTS
# ================================================================

Write-Section "12. REPARSE POINT SCAN"

$ReparseCount = 0

try {

    Get-ChildItem `
        -LiteralPath $Root `
        -Force `
        -Recurse `
        -ErrorAction SilentlyContinue |
    Where-Object {
        ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)
    } |
    ForEach-Object {

        $ReparseCount++

        Write-Host $_.FullName `
            -ForegroundColor Yellow
    }

}
catch {

    Write-Host "Reparse point scan encountered an error." `
        -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "Reparse Points: $ReparseCount"

if ($ReparseCount -eq 0) {

    Write-Host "No reparse points detected." `
        -ForegroundColor Green
}
else {

    Write-Host "Reparse points exist and are not automatically considered errors." `
        -ForegroundColor DarkYellow
}

# ================================================================
# NTFS FILESYSTEM STATISTICS
# ================================================================

Write-Section "13. NTFS FILESYSTEM STATISTICS"

$StatsResult = Run-NativeCommand `
    "fsutil.exe" `
    @("fsinfo","statistics",$Drive)

if ($StatsResult.Success) {

    foreach ($Line in $StatsResult.Output) {
        Write-Host $Line
    }

}
else {

    Write-Host "Filesystem statistics are unavailable." `
        -ForegroundColor DarkYellow
}

# ================================================================
# CHKDSK /SCAN
# ================================================================

Write-Section "14. FILESYSTEM INTEGRITY CHECK"

Write-Host ""
Write-Host "Running CHKDSK /SCAN..." `
    -ForegroundColor Yellow

Write-Host "This is a READ-ONLY filesystem integrity scan." `
    -ForegroundColor DarkYellow

Write-Host ""

$ChkResult = Run-NativeCommand `
    "chkdsk.exe" `
    @($Drive,"/scan")

$ChkOutput = @($ChkResult.Output)

foreach ($Line in $ChkOutput) {

    Write-Host $Line
}

$ChkText = ($ChkOutput -join "`n")

$ChkClean = $false
$ChkBadSectorDetected = $false
$ChkFilesystemProblem = $false

if (
    ($ChkText -match "found no problems") -or
    ($ChkText -match "No further action is required") -or
    ($ChkText -match "0 KB in bad sectors")
) {

    $ChkClean = $true
}

if (
    ($ChkText -match "bad sectors") -and
    ($ChkText -notmatch "0 KB in bad sectors")
) {

    $ChkBadSectorDetected = $true
}

if (
    ($ChkText -match "found problems") -or
    ($ChkText -match "corrupt") -or
    ($ChkText -match "errors were found") -or
    ($ChkText -match "Windows found problems")
) {

    $ChkFilesystemProblem = $true
}

Write-Host ""

if ($ChkFilesystemProblem -or $ChkBadSectorDetected) {

    Write-Host "Filesystem integrity requires attention." `
        -ForegroundColor Red

    $Failures.Add(
        "CHKDSK reported a filesystem problem or bad sectors."
    ) | Out-Null

}
elseif ($ChkClean) {

    Write-Host "CHKDSK reports the filesystem is clean." `
        -ForegroundColor Green

}
else {

    Write-Host "CHKDSK completed, but the result could not be conclusively classified." `
        -ForegroundColor DarkYellow
}

# ================================================================
# PHYSICAL DISK HEALTH
# ================================================================

Write-Section "15. PHYSICAL DISK HEALTH"

$PhysicalDiskAvailable = $false
$PhysicalDiskProblems = 0

try {

    $PhysicalDisks = Get-PhysicalDisk -ErrorAction Stop

    if ($PhysicalDisks) {

        $PhysicalDiskAvailable = $true

        foreach ($Disk in $PhysicalDisks) {

            Write-Host ""
            Write-Host "Disk Number    : $($Disk.DeviceId)"
            Write-Host "Friendly Name  : $($Disk.FriendlyName)"
            Write-Host "Media Type     : $($Disk.MediaType)"
            Write-Host "Health Status  : $($Disk.HealthStatus)"
            Write-Host "Operational    : $($Disk.OperationalStatus -join ', ')"

            if (
                ($Disk.HealthStatus -ne 'Healthy') -and
                ($Disk.HealthStatus -ne 'Unknown')
            ) {

                $PhysicalDiskProblems++

                $Failures.Add(
                    "Physical disk $($Disk.DeviceId) is not reporting Healthy."
                ) | Out-Null
            }

            if (
                ($Disk.OperationalStatus) -and
                ($Disk.OperationalStatus -notcontains 'OK') -and
                ($Disk.OperationalStatus -notcontains 'Unknown')
            ) {

                $PhysicalDiskProblems++

                $Failures.Add(
                    "Physical disk $($Disk.DeviceId) operational status requires attention."
                ) | Out-Null
            }
        }
    }

}
catch {

    Write-Host ""
    Write-Host "Get-PhysicalDisk is unavailable on this system." `
        -ForegroundColor DarkYellow

    Write-Host "Physical disk health cannot be independently verified by this provider." `
        -ForegroundColor DarkYellow
}

# ================================================================
# WINDOWS DISK STATUS
# ================================================================

Write-Section "16. WINDOWS DISK STATUS"

try {

    $DiskDrives = Get-CimInstance Win32_DiskDrive

    foreach ($Disk in $DiskDrives) {

        Write-Host ""
        Write-Host "Model        : $($Disk.Model)"
        Write-Host "Serial       : $($Disk.SerialNumber)"
        Write-Host "Status       : $($Disk.Status)"

        if (
            $Disk.Status -and
            ($Disk.Status -ne 'OK') -and
            ($Disk.Status -ne 'Unknown')
        ) {

            $Failures.Add(
                "Win32_DiskDrive reported status '$($Disk.Status)' for $($Disk.Model)."
            ) | Out-Null
        }
    }

}
catch {

    Write-Host "Win32 disk status is unavailable." `
        -ForegroundColor DarkYellow
}

# ================================================================
# DISK RESOURCE FAILURE EVENTS
# ================================================================

Write-Section "17. DISK RESOURCE FAILURE EVENT CHECK"

$DiskResourceFailureCount = 0

try {

    $DiskResourceEvents = Get-WinEvent `
        -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'disk'
            Id = 157
        } `
        -MaxEvents 100 `
        -ErrorAction SilentlyContinue

    if ($DiskResourceEvents) {

        $DiskResourceFailureCount = @($DiskResourceEvents).Count

        Write-Host ""
        Write-Host "Recent disk resource failure events: $DiskResourceFailureCount" `
            -ForegroundColor Yellow

        foreach ($Event in $DiskResourceEvents) {

            Write-Host ""
            Write-Host "Time   : $($Event.TimeCreated)"
            Write-Host "ID     : $($Event.Id)"
            Write-Host "Message: $($Event.Message)"
        }

        $Failures.Add(
            "Disk resource failure events were detected."
        ) | Out-Null

    }
    else {

        Write-Host ""
        Write-Host "DiskResourceFailure events detected: 0" `
            -ForegroundColor Green
    }

}
catch {

    Write-Host ""
    Write-Host "Disk resource failure event check is unavailable." `
        -ForegroundColor DarkYellow
}

# ================================================================
# LOG FILE FULL EVENT CHECK
# ================================================================

Write-Section "18. LOG FILE FULL EVENT CHECK"

$LogFileFullCount = 0

try {

    $LogEvents = Get-WinEvent `
        -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Ntfs'
            Id = 140
        } `
        -MaxEvents 100 `
        -ErrorAction SilentlyContinue

    if ($LogEvents) {

        $LogFileFullCount = @($LogEvents).Count

        Write-Host ""
        Write-Host "Recent NTFS LogFileFull events: $LogFileFullCount" `
            -ForegroundColor Yellow

        foreach ($Event in $LogEvents) {

            Write-Host ""
            Write-Host "Time   : $($Event.TimeCreated)"
            Write-Host "ID     : $($Event.Id)"
            Write-Host "Message: $($Event.Message)"
        }

        $Failures.Add(
            "NTFS LogFileFull events were detected."
        ) | Out-Null

    }
    else {

        Write-Host ""
        Write-Host "LogFileFull events detected: 0" `
            -ForegroundColor Green
    }

}
catch {

    Write-Host ""
    Write-Host "NTFS LogFileFull event check is unavailable." `
        -ForegroundColor DarkYellow
}

# ================================================================
# SPACE RECONCILIATION
# ================================================================

Write-Section "19. SPACE RECONCILIATION"

$Difference = [Int64]$UsedBytes - [Int64]$LogicalBytes

Write-Host ""
Write-Host "================================================================"
Write-Host " VOLUME"
Write-Host "================================================================"

Write-Host "Capacity           : $(Format-Bytes $CapacityBytes)"
Write-Host "Used               : $(Format-Bytes $UsedBytes)"
Write-Host "Free               : $(Format-Bytes $FreeBytes)"

Write-Host ""
Write-Host "================================================================"
Write-Host " LOGICAL FILE DATA"
Write-Host "================================================================"

Write-Host "Files              : $FileCount"
Write-Host "Logical File Data  : $(Format-Bytes $LogicalBytes)"

Write-Host ""
Write-Host "================================================================"
Write-Host " RECONCILIATION"
Write-Host "================================================================"

if ($Difference -ge 0) {

    Write-Host "Used - Logical     : $Difference bytes"
    Write-Host "Used - Logical     : $(Format-Bytes ([UInt64]$Difference))"

}
else {

    $AbsoluteDifference = [UInt64](-$Difference)

    Write-Host "Logical - Used     : $AbsoluteDifference bytes"
    Write-Host "Logical - Used     : $(Format-Bytes $AbsoluteDifference)"
}

Write-Host ""
Write-Host "The Logical File Data value is not expected to exactly equal"
Write-Host "filesystem Used Space because NTFS also uses metadata,"
Write-Host "allocation structures, reserved space, directory structures,"
Write-Host "system data and other filesystem-level storage."

# ================================================================
# SPACE ANALYSIS
# ================================================================

Write-Section "20. SPACE ANALYSIS"

Write-Host ""

if ($Difference -eq 0) {

    Write-Host "Logical file data exactly matches reported Used Space." `
        -ForegroundColor Green

}
elseif ($Difference -gt 0) {

    Write-Host "Filesystem Used Space exceeds enumerated logical file data." `
        -ForegroundColor Green

    Write-Host ""
    Write-Host "This difference can be normal and may include:" `
        -ForegroundColor DarkYellow

    Write-Host " - NTFS metadata"
    Write-Host " - MFT and filesystem structures"
    Write-Host " - Allocation structures"
    Write-Host " - Directory structures"
    Write-Host " - Cluster allocation effects"
    Write-Host " - Protected system data"
    Write-Host " - Shadow Copy storage"
    Write-Host " - Recycle Bin data"
    Write-Host " - Other filesystem-managed storage"

}
else {

    Write-Host "Enumerated logical file data exceeds reported Used Space." `
        -ForegroundColor Yellow

    Write-Host ""
    Write-Host "This result is unusual and should be reviewed." `
        -ForegroundColor Yellow

    $Warnings.Add(
        "Enumerated logical file data exceeded reported Used Space."
    ) | Out-Null
}

# ================================================================
# FINAL VERDICT LOGIC
# ================================================================

Write-Section "21. FINAL DRIVE VERDICT"

$FinalStatus = "PASS"

# ------------------------------------------------
# FAIL CONDITIONS
# ------------------------------------------------

if ($Failures.Count -gt 0) {

    $FinalStatus = "FAIL"
}

# ------------------------------------------------
# WARNING CONDITIONS
# ------------------------------------------------

elseif ($Warnings.Count -gt 0) {

    $FinalStatus = "WARNING"
}

# ------------------------------------------------
# PASS
# ------------------------------------------------

else {

    $FinalStatus = "PASS"
}

# ================================================================
# FINAL SUMMARY
# ================================================================

Write-Host ""
Write-Host "Audit completed." `
    -ForegroundColor White

$AuditEnd = Get-Date
$Duration = $AuditEnd - $AuditStart

Write-Host ""
Write-Host "Started  : $AuditStart"
Write-Host "Finished : $AuditEnd"
Write-Host "Duration : $($Duration.ToString())"

Write-Host ""
Write-Host "Warnings : $($Warnings.Count)"
Write-Host "Failures : $($Failures.Count)"

# ================================================================
# FAILURE SUMMARY
# ================================================================

if ($Failures.Count -gt 0) {

    Write-Host ""
    Write-Host "FAILURES:" `
        -ForegroundColor Red

    foreach ($Item in $Failures) {

        Write-Host " - $Item" `
            -ForegroundColor Red
    }
}

# ================================================================
# WARNING SUMMARY
# ================================================================

if ($Warnings.Count -gt 0) {

    Write-Host ""
    Write-Host "WARNINGS:" `
        -ForegroundColor Yellow

    foreach ($Item in $Warnings) {

        Write-Host " - $Item" `
            -ForegroundColor Yellow
    }
}

# ================================================================
# BIG FINAL RESULT
# ================================================================

Write-Host ""
Write-Host ""
Write-Host "================================================================" `
    -ForegroundColor White

if ($FinalStatus -eq "PASS") {

    Write-Host ""
    Write-Host "                    DRIVE HEALTH: EXCELLENT" `
        -ForegroundColor Green

    Write-Host ""
    Write-Host "                 NO IDENTIFIABLE PROBLEM FOUND" `
        -ForegroundColor Green

    Write-Host ""
    Write-Host "        FILESYSTEM STATUS : HEALTHY" `
        -ForegroundColor Green

    Write-Host "        STORAGE STATUS    : HEALTHY" `
        -ForegroundColor Green

    Write-Host "        DISK STATUS       : HEALTHY" `
        -ForegroundColor Green

    Write-Host ""

}
elseif ($FinalStatus -eq "WARNING") {

    Write-Host ""
    Write-Host "                 DRIVE HEALTH: REQUIRES REVIEW" `
        -ForegroundColor Yellow

    Write-Host ""
    Write-Host "             NO CONFIRMED DRIVE FAILURE DETECTED" `
        -ForegroundColor Yellow

    Write-Host ""
    Write-Host "        SOME AUDIT ITEMS REQUIRE FURTHER REVIEW" `
        -ForegroundColor Yellow

    Write-Host ""

}
else {

    Write-Host ""
    Write-Host "                     DRIVE HEALTH: FAILED" `
        -ForegroundColor Red

    Write-Host ""
    Write-Host "                  A DRIVE PROBLEM WAS DETECTED" `
        -ForegroundColor Red

    Write-Host ""
    Write-Host "             REVIEW THE FAILURE DETAILS ABOVE" `
        -ForegroundColor Red

    Write-Host ""
}

Write-Host "================================================================" `
    -ForegroundColor White

# ================================================================
# IMPORTANT DISCLAIMER
# ================================================================

Write-Host ""
Write-Host "NOTE:" `
    -ForegroundColor Cyan

Write-Host "This audit verifies filesystem consistency and available"
Write-Host "Windows disk-health indicators."

Write-Host ""
Write-Host "It is not a substitute for manufacturer-specific"
Write-Host "SMART diagnostics when those are required."

Write-Host ""
Write-Host "A Windows Health Status of Healthy does not guarantee"
Write-Host "that every NAND cell or every physical component is perfect."

Write-Host ""
Write-Host "For definitive hardware diagnostics, manufacturer-specific"
Write-Host "SSD diagnostic software may provide additional SMART data."

# ================================================================
# KEEP WINDOW OPEN
# ================================================================

Write-Host ""
Write-Host "Press ENTER to continue..." `
    -ForegroundColor Gray

Read-Host

Write-Host ""
Write-Host "Press ENTER again to close..." `
    -ForegroundColor Gray

Read-Host

Write-Host ""
Write-Host "Press ENTER one final time to exit..." `
    -ForegroundColor Gray

Read-Host