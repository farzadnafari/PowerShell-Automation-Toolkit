
> [!INFO] بنچمارک تشخیصی اختصاصی GPU و GIMP
> دسترسی Administrator را بررسی کرده و در صورت نداشتن مجوز لازم، اجرای اسکریپت را متوقف می‌کند.
> نسخه‌های مختلف GIMP شامل سری 2.x و 3.x را برای شناسایی و بررسی سازگاری در نظر می‌گیرد.
> تمام پردازنده‌های گرافیکی (GPU) نصب‌شده روی سیستم را شناسایی و اطلاعات سخت‌افزاری آن‌ها را جمع‌آوری می‌کند.
> مشخصات حافظه گرافیکی (VRAM) و اطلاعات درایورهای GPU را برای ارزیابی وضعیت سخت‌افزاری بررسی می‌کند.
> موتورهای پردازش گرافیکی ویندوز (GPU Engines) را برای مشاهده فعالیت پردازنده‌های گرافیکی بررسی می‌کند.
> تصاویر آزمایشی سنگین ایجاد می‌کند تا عملکرد GIMP هنگام پردازش تصاویر حجیم ارزیابی شود.
> نرم‌افزار GIMP را اجرا کرده و بارگذاری تصاویر آزمایشی را برای بررسی عملکرد واقعی آن انجام می‌دهد.
> میزان مصرف CPU، RAM، Disk و GPU را هنگام اجرای تست به‌صورت مستمر پایش و اطلاعات را در فایل CSV ذخیره می‌کند.
> پردازنده گرافیکی مورد استفاده GIMP را بررسی کرده و گزارش‌های سخت‌افزاری، اطلاعات رویدادها و نتایج نهایی را تولید می‌کند.
> عملکرد احتمالی Photoshop را به‌صورت تخمینی ارزیابی می‌کند؛ زیرا این اسکریپت Photoshop را مستقیماً اجرا و آزمایش نمی‌کند.


> [!INFO] Dedicated GPU And GIMP Diagnostic Benchmark
> Checks Administrator Privileges And Stops Execution If The Required Permissions Are Not Available.
> Accounts For Different GIMP Versions, Including The 2.x And 3.x Series, For Identification And Compatibility Assessment.
> Detects All Installed Graphics Processing Units (GPUs) And Collects Their Hardware Information.
> Examines Video Memory (VRAM) Specifications And GPU Driver Information To Assess Hardware Status.
> Inspects Windows GPU Engines To Monitor Graphics Processor Activity.
> Creates Heavy Test Images To Evaluate GIMP Performance When Processing Large Images.
> Launches GIMP And Loads Test Images To Assess Its Real-World Performance.
> Continuously Monitors CPU, RAM, Disk, And GPU Usage During Testing And Stores The Data In A CSV File.
> Examines Which Graphics Processor Is Used By GIMP And Generates Hardware, Event, And Final Performance Reports.
> Provides An Estimated Assessment Of Potential Photoshop Performance Because This Script Does Not Directly Launch Or Benchmark Photoshop.


```
<#
============================================================
 GPU + GIMP DIAGNOSTIC BENCHMARK
 PowerShell 5.1
============================================================

هدف:
    تست اختصاصی GPU و GIMP روی سیستم

موارد بررسی:
    1. شناسایی GIMP 2.x / 3.x
    2. شناسایی تمام GPU ها
    3. بررسی VRAM و Driver
    4. تست GPU Engine های Windows
    5. ساخت تصاویر سنگین
    6. اجرای GIMP
    7. Load کردن تصاویر سنگین
    8. مانیتور CPU / RAM / Disk / GPU
    9. بررسی GPU مصرفی توسط GIMP
    10. تولید گزارش نهایی

نکته:
    این تست Photoshop را مستقیماً اجرا نمی‌کند.
    نتیجه Photoshop به صورت تخمینی ارائه می‌شود.
============================================================
#>

$ErrorActionPreference = "SilentlyContinue"

# ----------------------------------------------------------
# ADMIN CHECK
# ----------------------------------------------------------

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

if (-not $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Write-Host ""
    Write-Host "[ERROR] Please run PowerShell as Administrator." -ForegroundColor Red
    Write-Host ""
    pause
    exit
}

# ----------------------------------------------------------
# PATHS
# ----------------------------------------------------------

$Desktop = [Environment]::GetFolderPath("Desktop")

$Root = Join-Path $Desktop "GPU_GIMP_DIAGNOSTIC_BENCHMARK"

$Logs    = Join-Path $Root "Logs"
$Images  = Join-Path $Root "Images"
$GPU     = Join-Path $Root "GPU"
$GIMPDir = Join-Path $Root "GIMP"

New-Item -ItemType Directory -Force -Path $Root    | Out-Null
New-Item -ItemType Directory -Force -Path $Logs    | Out-Null
New-Item -ItemType Directory -Force -Path $Images  | Out-Null
New-Item -ItemType Directory -Force -Path $GPU     | Out-Null
New-Item -ItemType Directory -Force -Path $GIMPDir | Out-Null

$ReportFile = Join-Path $Root "FINAL-REPORT.txt"
$MonitorCSV = Join-Path $Logs "GPU-GIMP-MONITOR.csv"
$Hardware   = Join-Path $Logs "HARDWARE.txt"
$DxDiagFile = Join-Path $GPU "DxDiag.txt"
$EventsFile = Join-Path $Logs "EVENTS.txt"

# ----------------------------------------------------------
# HEADER
# ----------------------------------------------------------

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "        GPU + GIMP DIAGNOSTIC BENCHMARK" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$StartTime = Get-Date

Write-Host "TEST START: $StartTime"
Write-Host ""

# ----------------------------------------------------------
# SYSTEM INFORMATION
# ----------------------------------------------------------

Write-Host "[1/10] Collecting system information..." -ForegroundColor Yellow

$Computer = Get-CimInstance Win32_ComputerSystem
$CPUInfo  = Get-CimInstance Win32_Processor
$OSInfo   = Get-CimInstance Win32_OperatingSystem

$TotalRAMGB = [math]::Round(
    $Computer.TotalPhysicalMemory / 1GB,
    2
)

$CPUName = $CPUInfo[0].Name
$PhysicalCores = $CPUInfo[0].NumberOfCores
$LogicalCPU = $CPUInfo[0].NumberOfLogicalProcessors

$OSName = $OSInfo.Caption
$Build  = $OSInfo.BuildNumber

# ----------------------------------------------------------
# GPU INFORMATION
# ----------------------------------------------------------

Write-Host "[2/10] Detecting GPU devices..." -ForegroundColor Yellow

$GPUs = Get-CimInstance Win32_VideoController |
    Where-Object {
        $_.Name -and
        $_.Name -notmatch "Basic Display"
    }

$GPUList = @()

foreach ($G in $GPUs) {

    $VRAMGB = 0

    if ($G.AdapterRAM) {
        $VRAMGB = [math]::Round(
            [double]$G.AdapterRAM / 1GB,
            2
        )
    }

    $GPUObject = [PSCustomObject]@{
        Name         = $G.Name
        VRAM_GB      = $VRAMGB
        Driver       = $G.DriverVersion
        VideoMode    = $G.VideoModeDescription
        PNPDeviceID  = $G.PNPDeviceID
        Status       = $G.Status
    }

    $GPUList += $GPUObject
}

$GPUList | Format-Table -AutoSize

# ----------------------------------------------------------
# GIMP DETECTION
# ----------------------------------------------------------

Write-Host ""
Write-Host "[3/10] Searching for GIMP..." -ForegroundColor Yellow

$GimpCandidates = @()

# PATH
$GimpCommand = Get-Command "gimp.exe" -ErrorAction SilentlyContinue

if ($GimpCommand) {
    $GimpCandidates += $GimpCommand.Source
}

# Common locations
$CommonGimpPaths = @(
    "$env:ProgramFiles\GIMP 3\bin\gimp-3.0.exe",
    "$env:ProgramFiles\GIMP 3\bin\gimp.exe",
    "$env:ProgramFiles\GIMP 2\bin\gimp-2.10.exe",
    "$env:ProgramFiles\GIMP 2\bin\gimp.exe",
    "$env:ProgramFiles(x86)\GIMP 3\bin\gimp-3.0.exe",
    "$env:ProgramFiles(x86)\GIMP 3\bin\gimp.exe",
    "$env:ProgramFiles(x86)\GIMP 2\bin\gimp-2.10.exe",
    "$env:ProgramFiles(x86)\GIMP 2\bin\gimp.exe",
    "$env:LOCALAPPDATA\Programs\GIMP\bin\gimp-3.0.exe",
    "$env:LOCALAPPDATA\Programs\GIMP\bin\gimp-2.10.exe",
    "$env:LOCALAPPDATA\Programs\GIMP\bin\gimp.exe"
)

foreach ($Path in $CommonGimpPaths) {

    if ($Path -and (Test-Path $Path)) {
        $GimpCandidates += $Path
    }
}

# Registry uninstall entries
$RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($RegPath in $RegistryPaths) {

    $Apps = Get-ItemProperty $RegPath

    foreach ($App in $Apps) {

        if ($App.DisplayName -match "GIMP") {

            if ($App.InstallLocation) {

                $Possible = @(
                    (Join-Path $App.InstallLocation "bin\gimp.exe"),
                    (Join-Path $App.InstallLocation "bin\gimp-2.10.exe"),
                    (Join-Path $App.InstallLocation "bin\gimp-3.0.exe"),
                    (Join-Path $App.InstallLocation "gimp.exe"),
                    (Join-Path $App.InstallLocation "gimp-2.10.exe"),
                    (Join-Path $App.InstallLocation "gimp-3.0.exe")
                )

                foreach ($P in $Possible) {
                    if (Test-Path $P) {
                        $GimpCandidates += $P
                    }
                }
            }

            if ($App.DisplayIcon) {

                $IconPath = $App.DisplayIcon -replace '"',''

                if (Test-Path $IconPath) {
                    $GimpCandidates += $IconPath
                }
            }
        }
    }
}

$GimpCandidates = $GimpCandidates |
    Where-Object { $_ } |
    Select-Object -Unique

$GimpPath = $null

if ($GimpCandidates.Count -gt 0) {

    $GimpPath = $GimpCandidates[0]

    Write-Host ""
    Write-Host "[OK] GIMP FOUND" -ForegroundColor Green
    Write-Host "Path: $GimpPath"
}
else {

    Write-Host ""
    Write-Host "[ERROR] GIMP NOT FOUND" -ForegroundColor Red
    Write-Host ""
    Write-Host "The test will continue without GIMP."
}

# ----------------------------------------------------------
# HARDWARE LOG
# ----------------------------------------------------------

@"
============================================================
SYSTEM
============================================================

Computer:
$($Computer.Name)

CPU:
$CPUName

Physical Cores:
$PhysicalCores

Logical Processors:
$LogicalCPU

RAM:
$TotalRAMGB GB

Windows:
$OSName

Build:
$Build


============================================================
GPU DEVICES
============================================================

$($GPUList | Out-String)


============================================================
GIMP
============================================================

Path:
$GimpPath

"@ | Out-File $Hardware -Encoding UTF8

# ----------------------------------------------------------
# DXDIAG
# ----------------------------------------------------------

Write-Host ""
Write-Host "[4/10] Collecting DirectX information..." -ForegroundColor Yellow

Start-Process "dxdiag.exe" `
    -ArgumentList "/t `"$DxDiagFile`"" `
    -Wait `
    -WindowStyle Hidden

Write-Host "[OK] DxDiag collected." -ForegroundColor Green

# ----------------------------------------------------------
# CREATE TEST IMAGE
# ----------------------------------------------------------

Write-Host ""
Write-Host "[5/10] Creating large graphics test images..." -ForegroundColor Yellow

$Width  = 5000
$Height = 3500

$ImageFiles = @()

for ($i = 1; $i -le 3; $i++) {

    $ImagePath = Join-Path $Images "GIMP_TEST_$i.ppm"

    Write-Host "Creating image $i : $Width x $Height"

    $Header = "P6`n$Width $Height`n255`n"

    $Stream = [System.IO.File]::Open(
        $ImagePath,
        [System.IO.FileMode]::Create
    )

    $Writer = New-Object System.IO.StreamWriter(
        $Stream,
        [System.Text.Encoding]::ASCII
    )

    $Writer.Write($Header)
    $Writer.Flush()

    $ChunkSize = 1024 * 1024
    $RGB = New-Object byte[] $ChunkSize

    # Generate varying RGB data
    for ($j = 0; $j -lt $RGB.Length; $j += 3) {

        if ($j + 2 -lt $RGB.Length) {

            $RGB[$j]     = [byte](($j + $i * 17) % 256)
            $RGB[$j + 1] = [byte](($j * 3 + $i * 41) % 256)
            $RGB[$j + 2] = [byte](($j * 7 + $i * 73) % 256)
        }
    }

    $PixelBytes =
        [int64]$Width *
        [int64]$Height *
        3

    while ($PixelBytes -gt 0) {

        $WriteSize = [math]::Min(
            $RGB.Length,
            $PixelBytes
        )

        $Stream.Write(
            $RGB,
            0,
            [int]$WriteSize
        )

        $PixelBytes -= $WriteSize
    }

    $Writer.Close()
    $Stream.Close()

    $ImageFiles += $ImagePath
}

Write-Host "[OK] Test images created." -ForegroundColor Green

# ----------------------------------------------------------
# BASELINE
# ----------------------------------------------------------

Write-Host ""
Write-Host "[6/10] Recording baseline..." -ForegroundColor Yellow

$BaselineCPU = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue

$BaselineRAM = (
    Get-Counter '\Memory\Available MBytes'
).CounterSamples[0].CookedValue

Write-Host ("Baseline CPU: {0:N1}%" -f $BaselineCPU)
Write-Host ("Available RAM: {0:N0} MB" -f $BaselineRAM)

# ----------------------------------------------------------
# MONITOR DATA
# ----------------------------------------------------------

$MonitorData = New-Object System.Collections.Generic.List[object]

function Get-GPUUtilization {

    $Total = 0

    $Counters = Get-Counter `
        '\GPU Engine(*)\Utilization Percentage' `
        -ErrorAction SilentlyContinue

    if ($Counters) {

        foreach ($Sample in $Counters.CounterSamples) {

            $Value = $Sample.CookedValue

            if ($Value -gt $Total) {
                $Total = $Value
            }
        }
    }

    return [math]::Round($Total,2)
}

function Get-GIMP-GPU {

    param(
        [int]$PID
    )

    if (-not $PID) {
        return 0
    }

    $Total = 0

    $Counters = Get-Counter `
        '\GPU Engine(*)\Utilization Percentage' `
        -ErrorAction SilentlyContinue

    if ($Counters) {

        foreach ($Sample in $Counters.CounterSamples) {

            $Instance = $Sample.InstanceName

            if ($Instance -match "pid_$PID") {

                $Total += $Sample.CookedValue
            }
        }
    }

    return [math]::Round($Total,2)
}

function Add-MonitorSample {

    param(
        [string]$Stage,
        [int]$GimpPID
    )

    $CPU = 0
    $RAM = 0
    $Disk = 0
    $GPUUtil = 0
    $GimpGPU = 0

    try {
        $CPU = (
            Get-Counter '\Processor(_Total)\% Processor Time'
        ).CounterSamples[0].CookedValue
    }
    catch {}

    try {
        $RAM = (
            Get-Counter '\Memory\Available MBytes'
        ).CounterSamples[0].CookedValue
    }
    catch {}

    try {
        $Disk = (
            Get-Counter '\PhysicalDisk(_Total)\% Disk Time'
        ).CounterSamples[0].CookedValue
    }
    catch {}

    try {
        $GPUUtil = Get-GPUUtilization
    }
    catch {}

    try {
        $GimpGPU = Get-GIMP-GPU -PID $GimpPID
    }
    catch {}

    $Obj = [PSCustomObject]@{
        Time          = Get-Date
        Stage         = $Stage
        CPU_Percent   = [math]::Round($CPU,2)
        RAM_Free_MB   = [math]::Round($RAM,0)
        Disk_Percent  = [math]::Round($Disk,2)
        GPU_Percent   = [math]::Round($GPUUtil,2)
        GIMP_GPU      = [math]::Round($GimpGPU,2)
    }

    $MonitorData.Add($Obj)

    return $Obj
}

# ----------------------------------------------------------
# GIMP TEST
# ----------------------------------------------------------

$GimpProcess = $null
$GimpPID = 0
$GimpLoadTimes = @()

if ($GimpPath) {

    Write-Host ""
    Write-Host "[7/10] Starting GIMP..." -ForegroundColor Yellow

    $GimpStart = Get-Date

    $GimpProcess = Start-Process `
        -FilePath $GimpPath `
        -PassThru

    $GimpPID = $GimpProcess.Id

    Write-Host "[OK] GIMP PID: $GimpPID" -ForegroundColor Green

    # Give GIMP time to initialize
    Start-Sleep -Seconds 8

    Add-MonitorSample `
        -Stage "GIMP_STARTED" `
        -GimpPID $GimpPID | Out-Null

    # ------------------------------------------------------
    # LOAD THREE LARGE IMAGES
    # ------------------------------------------------------

    foreach ($Image in $ImageFiles) {

        if (-not (Get-Process -Id $GimpPID -ErrorAction SilentlyContinue)) {
            break
        }

        Write-Host ""
        Write-Host "Loading: $(Split-Path $Image -Leaf)"

        $LoadStart = Get-Date

        # Send image path to GIMP through Windows shell
        Start-Process `
            -FilePath $GimpPath `
            -ArgumentList "`"$Image`"" `
            -WindowStyle Normal

        Start-Sleep -Seconds 8

        $LoadEnd = Get-Date

        $LoadSeconds = (
            $LoadEnd - $LoadStart
        ).TotalSeconds

        $GimpLoadTimes += $LoadSeconds

        Add-MonitorSample `
            -Stage "GIMP_IMAGE_LOAD" `
            -GimpPID $GimpPID | Out-Null

        Write-Host ("Load observation: {0:N2} sec" -f $LoadSeconds)
    }

    # ------------------------------------------------------
    # GIMP OBSERVATION
    # ------------------------------------------------------

    Write-Host ""
    Write-Host "Monitoring GIMP workload for 45 seconds..."

    $ObservationStart = Get-Date

    while (
        ((Get-Date) - $ObservationStart).TotalSeconds -lt 45
    ) {

        if (-not (Get-Process -Id $GimpPID -ErrorAction SilentlyContinue)) {
            break
        }

        Add-MonitorSample `
            -Stage "GIMP_HEAVY_WORKLOAD" `
            -GimpPID $GimpPID | Out-Null

        Start-Sleep -Seconds 2
    }

    Write-Host "[OK] GIMP observation completed." -ForegroundColor Green

}
else {

    Write-Host ""
    Write-Host "[WARNING] GIMP test skipped." -ForegroundColor Yellow
}

# ----------------------------------------------------------
# GPU STRESS OBSERVATION
# ----------------------------------------------------------

Write-Host ""
Write-Host "[8/10] GPU activity observation..." -ForegroundColor Yellow

$GPUStart = Get-Date

while (
    ((Get-Date) - $GPUStart).TotalSeconds -lt 30
) {

    Add-MonitorSample `
        -Stage "GPU_OBSERVATION" `
        -GimpPID $GimpPID | Out-Null

    Start-Sleep -Seconds 2
}

Write-Host "[OK] GPU observation completed." -ForegroundColor Green

# ----------------------------------------------------------
# SAVE MONITOR CSV
# ----------------------------------------------------------

$MonitorData |
    Export-Csv `
        -Path $MonitorCSV `
        -NoTypeInformation `
        -Encoding UTF8

# ----------------------------------------------------------
# ANALYSIS
# ----------------------------------------------------------

Write-Host ""
Write-Host "[9/10] Analyzing results..." -ForegroundColor Yellow

$CPUValues = @(
    $MonitorData |
    Where-Object { $_.CPU_Percent -ne $null } |
    Select-Object -ExpandProperty CPU_Percent
)

$GPUValues = @(
    $MonitorData |
    Where-Object { $_.GPU_Percent -ne $null } |
    Select-Object -ExpandProperty GPU_Percent
)

$GimpGPUValues = @(
    $MonitorData |
    Where-Object { $_.GIMP_GPU -ne $null } |
    Select-Object -ExpandProperty GIMP_GPU
)

$RAMValues = @(
    $MonitorData |
    Select-Object -ExpandProperty RAM_Free_MB
)

$DiskValues = @(
    $MonitorData |
    Select-Object -ExpandProperty Disk_Percent
)

function Safe-Average {
    param($Array)

    if (-not $Array -or $Array.Count -eq 0) {
        return 0
    }

    return [math]::Round(
        (($Array | Measure-Object -Average).Average),
        2
    )
}

function Safe-Max {
    param($Array)

    if (-not $Array -or $Array.Count -eq 0) {
        return 0
    }

    return [math]::Round(
        (($Array | Measure-Object -Maximum).Maximum),
        2
    )
}

function Safe-Min {
    param($Array)

    if (-not $Array -or $Array.Count -eq 0) {
        return 0
    }

    return [math]::Round(
        (($Array | Measure-Object -Minimum).Minimum),
        2
    )
}

$CPUAvg = Safe-Average $CPUValues
$CPUPeak = Safe-Max $CPUValues

$GPUAvg = Safe-Average $GPUValues
$GPUPeak = Safe-Max $GPUValues

$GimpGPUAvg = Safe-Average $GimpGPUValues
$GimpGPUPeak = Safe-Max $GimpGPUValues

$RAMMin = Safe-Min $RAMValues

$DiskAvg = Safe-Average $DiskValues
$DiskPeak = Safe-Max $DiskValues

$AverageGimpLoad = Safe-Average $GimpLoadTimes

# ----------------------------------------------------------
# GPU SCORE
# ----------------------------------------------------------

if (-not $GimpPath) {

    $GPUScore = 0
    $GimpScore = 0

}
else {

    if ($GPUPeak -ge 80) {
        $GPUScore = 100
    }
    elseif ($GPUPeak -ge 60) {
        $GPUScore = 90
    }
    elseif ($GPUPeak -ge 40) {
        $GPUScore = 75
    }
    elseif ($GPUPeak -ge 20) {
        $GPUScore = 60
    }
    else {
        $GPUScore = 40
    }

    if ($AverageGimpLoad -le 5) {
        $GimpScore = 100
    }
    elseif ($AverageGimpLoad -le 10) {
        $GimpScore = 85
    }
    elseif ($AverageGimpLoad -le 20) {
        $GimpScore = 70
    }
    elseif ($AverageGimpLoad -le 30) {
        $GimpScore = 55
    }
    else {
        $GimpScore = 40
    }
}

# ----------------------------------------------------------
# GIMP GPU INTERPRETATION
# ----------------------------------------------------------

if ($GimpGPUAvg -ge 50) {

    $GimpGPUStatus = "GIMP is actively using GPU resources."

}
elseif ($GimpGPUPeak -ge 20) {

    $GimpGPUStatus = "GIMP shows measurable GPU activity."

}
else {

    $GimpGPUStatus = "GIMP GPU activity remained low or Windows GPU counters were limited."
}

# ----------------------------------------------------------
# PHOTOSHOP ESTIMATE
# ----------------------------------------------------------

if (
    $TotalRAMGB -ge 16 -and
    $GPUScore -ge 80 -and
    $GimpScore -ge 80
) {

    $PhotoshopRating = "GOOD"

}
elseif (
    $TotalRAMGB -ge 8 -and
    $GPUScore -ge 60 -and
    $GimpScore -ge 60
) {

    $PhotoshopRating = "BASIC / MODERATE WORKLOADS"

}
else {

    $PhotoshopRating = "LIMITED"

}

# ----------------------------------------------------------
# BOTTLENECK
# ----------------------------------------------------------

$Bottlenecks = @()

if ($CPUPeak -ge 95) {
    $Bottlenecks += "CPU"
}

if ($RAMMin -lt 2048) {
    $Bottlenecks += "RAM"
}

if ($DiskPeak -ge 90) {
    $Bottlenecks += "DISK"
}

if ($GPUPeak -ge 90) {
    $Bottlenecks += "GPU"
}

if ($GimpScore -lt 60) {
    $Bottlenecks += "GIMP"
}

if ($Bottlenecks.Count -eq 0) {
    $PrimaryBottleneck = "No severe bottleneck detected"
}
else {
    $PrimaryBottleneck = $Bottlenecks -join ", "
}

# ----------------------------------------------------------
# OVERALL SCORE
# ----------------------------------------------------------

if ($GimpPath) {

    $OverallScore = [math]::Round(
        (
            ($GPUScore * 0.40) +
            ($GimpScore * 0.40) +
            (
                [math]::Min(
                    100,
                    ($TotalRAMGB / 16) * 100
                ) * 0.20
            )
        ),
        0
    )

}
else {

    $OverallScore = 0
}

if ($OverallScore -ge 90) {
    $Rating = "EXCELLENT"
}
elseif ($OverallScore -ge 80) {
    $Rating = "VERY GOOD"
}
elseif ($OverallScore -ge 70) {
    $Rating = "GOOD"
}
elseif ($OverallScore -ge 60) {
    $Rating = "ACCEPTABLE"
}
elseif ($OverallScore -gt 0) {
    $Rating = "LIMITED"
}
else {
    $Rating = "INCOMPLETE"
}

# ----------------------------------------------------------
# STOP GIMP
# ----------------------------------------------------------

Write-Host ""
Write-Host "[10/10] Cleaning up..." -ForegroundColor Yellow

if ($GimpPID) {

    $GimpProc = Get-Process -Id $GimpPID -ErrorAction SilentlyContinue

    if ($GimpProc) {

        Stop-Process `
            -Id $GimpPID `
            -Force `
            -ErrorAction SilentlyContinue
    }
}

# ----------------------------------------------------------
# EVENT LOG
# ----------------------------------------------------------

try {

    Get-WinEvent `
        -FilterHashtable @{
            LogName='System'
            StartTime=$StartTime
        } `
        -MaxEvents 100 |
        Format-List TimeCreated,ProviderName,Id,LevelDisplayName,Message |
        Out-File $EventsFile -Encoding UTF8

}
catch {}

# ----------------------------------------------------------
# FINAL REPORT
# ----------------------------------------------------------

$EndTime = Get-Date

$GPUText = $GPUList | Out-String

$LoadText = $GimpLoadTimes -join ", "

@"
============================================================
        GPU + GIMP DIAGNOSTIC BENCHMARK
============================================================

TEST START:
$StartTime

TEST END:
$EndTime

============================================================
SYSTEM
============================================================

Computer:
$($Computer.Name)

CPU:
$CPUName

Physical Cores:
$PhysicalCores

Logical Processors:
$LogicalCPU

RAM:
$TotalRAMGB GB

Windows:
$OSName

Build:
$Build


============================================================
GPU DEVICES
============================================================

$GPUText


============================================================
GIMP
============================================================

Detected:
$([bool]$GimpPath)

Path:
$GimpPath

GIMP PID:
$GimpPID

Image Size:
$Width x $Height

Average Image Load Observation:
$AverageGimpLoad seconds


============================================================
RESOURCE RESULTS
============================================================

CPU Average:
$CPUAvg %

CPU Peak:
$CPUPeak %

RAM Minimum Available:
$RAMMin MB

Disk Average:
$DiskAvg %

Disk Peak:
$DiskPeak %

GPU Average:
$GPUAvg %

GPU Peak:
$GPUPeak %


============================================================
GIMP GPU
============================================================

GIMP GPU Average:
$GimpGPUAvg %

GIMP GPU Peak:
$GimpGPUPeak %

Status:
$GimpGPUStatus


============================================================
SCORES
============================================================

GPU Score:
$GPUScore / 100

GIMP Score:
$GimpScore / 100

Overall Score:
$OverallScore / 100

Rating:
$Rating


============================================================
BOTTLENECK
============================================================

Primary Bottleneck:
$PrimaryBottleneck


============================================================
PHOTOSHOP ESTIMATE
============================================================

Estimated Photoshop Suitability:
$PhotoshopRating

IMPORTANT:
This is NOT a direct Photoshop benchmark.
The Photoshop result is an estimate based on
hardware and GIMP/GPU observations.


============================================================
INTERPRETATION
============================================================

CPU:
The test observed actual CPU behavior while
GIMP and graphics workloads were active.

RAM:
The test records minimum available RAM during
the graphics workload.

GPU:
GPU utilization is based on Windows GPU Engine counters.
Low utilization does NOT automatically mean that the GPU
is weak; the workload or driver may not expose high usage.

GIMP:
The GIMP score is based primarily on image-load behavior
and graphics workload observations.

GIMP GPU:
$GimpGPUStatus


============================================================
FILES
============================================================

Test Root:
$Root

Hardware:
$Hardware

Monitor CSV:
$MonitorCSV

DxDiag:
$DxDiagFile

Events:
$EventsFile


============================================================
END
============================================================
"@ | Out-File $ReportFile -Encoding UTF8

# ----------------------------------------------------------
# CONSOLE RESULT
# ----------------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                 TEST COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "GIMP Detected : $([bool]$GimpPath)"
Write-Host "GPU Peak      : $GPUPeak %"
Write-Host "GIMP GPU Peak : $GimpGPUPeak %"
Write-Host "CPU Peak      : $CPUPeak %"
Write-Host "RAM Minimum   : $RAMMin MB"
Write-Host "Disk Peak     : $DiskPeak %"
Write-Host ""

Write-Host "GPU Score     : $GPUScore / 100"
Write-Host "GIMP Score    : $GimpScore / 100"
Write-Host "Overall       : $OverallScore / 100"
Write-Host "Rating        : $Rating"
Write-Host ""

Write-Host "Primary Bottleneck:"
Write-Host "$PrimaryBottleneck"
Write-Host ""

Write-Host "Photoshop Estimate:"
Write-Host "$PhotoshopRating"
Write-Host ""

Write-Host "============================================================"
Write-Host "REPORT:"
Write-Host $ReportFile
Write-Host "============================================================"
Write-Host ""

pause
```

