
> [!INFO] بنچمارک استرس سنگین و ارزیابی عملکرد واقعی CPU، GPU، RAM و برنامه‌های کاربردی
> اطلاعات سخت‌افزاری و مشخصات سیستم ویندوز را برای ارزیابی عملکرد جمع‌آوری می‌کند.
> پوشه اختصاصی بنچمارک را روی Desktop ایجاد کرده و فایل‌های گزارش و اطلاعات تست را در آن ذخیره می‌کند.
> دسترسی Administrator را بررسی کرده و در صورت نداشتن دسترسی، اجرای عملیات را متوقف می‌کند.
> پارامترهای تست شامل مدت فشار پردازنده، زمان حفظ بار سیستم، فاصله پایش و تعداد برنامه‌های هم‌زمان را تنظیم می‌کند.
> قابلیت تست چندوظیفگی با اجرای هم‌زمان Chrome، Excel، Word و PowerPoint را در ساختار پروژه پیش‌بینی می‌کند.
> حجم محاسبات Excel را با ۷۵۰۰۰ ردیف و چهار مرحله محاسباتی سنگین تنظیم می‌کند.
> ابعاد تصاویر آزمایشی GIMP را روی ۵۰۰۰ در ۳۵۰۰ پیکسل تعیین می‌کند.
> مسیرهای مجزایی برای ثبت گزارش‌ها، تست‌های Office، آزمایش‌های GIMP و اطلاعات GPU آماده می‌کند.
> توابع اختصاصی برای ثبت رویدادها، نمایش بخش‌های مختلف تست، بررسی فضای آزاد درایو و شناسایی مسیر برنامه‌ها تعریف می‌کند.
> این کد فعلاً فقط بخش ابتدایی پروژه است و با وجود معرفی تست‌های سنگین، در قسمت ارسال‌شده هنوز عملیات واقعی تست CPU، GPU، GIMP و برنامه‌های Office اجرا نشده‌اند.


> [!INFO] Extreme Stress Benchmark And Real-World Performance Assessment Of CPU, GPU, RAM, And Applications
> Collects Hardware Information And Windows System Specifications For Performance Assessment.
> Creates A Dedicated Benchmark Folder On The Desktop And Stores Test Reports And Information Within It.
> Checks Administrator Privileges And Stops Execution If The Required Access Is Not Available.
> Configures Benchmark Parameters Including CPU Stress Duration, System Load Duration, Monitoring Interval, And Concurrent Application Counts.
> Prepares A Multitasking Test Structure For Running Chrome, Excel, Word, And PowerPoint Simultaneously.
> Configures Excel Workloads With 75,000 Rows And Four Intensive Calculation Rounds.
> Sets The GIMP Test Image Dimensions To 5,000 By 3,500 Pixels.
> Prepares Separate Directories For Logs, Office Tests, GIMP Experiments, And GPU Information.
> Defines Dedicated Functions For Event Logging, Section Display, Free Disk Space Checks, And Application Path Detection.
> This Is Only The Initial Project Section; Despite Defining Heavy Benchmark Parameters, The Submitted Code Does Not Yet Execute Actual CPU, GPU, GIMP, Or Office Stress Tests.


```
<#
============================================================
 EXTREME PC + GPU + GIMP REAL-WORLD STRESS BENCHMARK
============================================================

هدف:
    بررسی سخت گیرانه CPU / RAM / DISK / GPU / GIMP /
    Office / Chrome / Multitasking و Stability سیستم.

PowerShell:
    5.1+

نکات:
    - فایل های شخصی تغییر داده نمی شوند.
    - برنامه های از قبل باز شده بسته نمی شوند.
    - فایل های تست در Desktop ساخته می شوند.
    - تست CPU عمداً سنگین است.
    - تست GPU بر اساس قابلیت های قابل دسترس Windows انجام می شود.
    - GIMP در صورت پیدا شدن به صورت واقعی اجرا می شود.
    - امتیاز نهایی یک Benchmark داخلی است و استاندارد صنعتی نیست.

============================================================
#>

$ErrorActionPreference = "Continue"

# ============================================================
# CONFIGURATION
# ============================================================

$TestRoot = Join-Path $env:USERPROFILE "Desktop\EXTREME_PC_BENCHMARK"

$LogDir       = Join-Path $TestRoot "Logs"
$OfficeDir    = Join-Path $TestRoot "Office"
$GimpDir      = Join-Path $TestRoot "GIMP"
$GpuDir       = Join-Path $TestRoot "GPU"

$CpuStressSeconds = 60
$HeavyHoldSeconds = 60
$MonitorInterval  = 1

# تعداد برنامه ها
$ChromeTabs = 12
$ExcelFiles = 5
$WordFiles  = 3
$PptFiles   = 2

# Excel workload
$ExcelRows = 75000
$ExcelRounds = 4

# GIMP image size
$GimpWidth  = 5000
$GimpHeight = 3500

# ============================================================
# PREPARE DIRECTORIES
# ============================================================

New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
New-Item -ItemType Directory -Force -Path $OfficeDir | Out-Null
New-Item -ItemType Directory -Force -Path $GimpDir | Out-Null
New-Item -ItemType Directory -Force -Path $GpuDir | Out-Null

$StartTime = Get-Date

$ReportFile  = Join-Path $TestRoot "FINAL-REPORT.txt"
$MonitorFile = Join-Path $LogDir "SYSTEM-MONITOR.csv"
$HardwareLog = Join-Path $LogDir "HARDWARE.txt"
$EventLog    = Join-Path $LogDir "EVENTS.txt"

"" | Set-Content $EventLog

# ============================================================
# FUNCTIONS
# ============================================================

function Write-Log {
    param(
        [string]$Message
    )

    $time = Get-Date -Format "HH:mm:ss"

    Write-Host "[$time] $Message"

    Add-Content -Path $EventLog -Value "[$time] $Message"
}

function Write-Section {
    param(
        [string]$Title
    )

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Get-FreeGB {
    param(
        [string]$Drive = "C"
    )

    try {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$Drive`:'"

        if ($disk) {
            return [math]::Round($disk.FreeSpace / 1GB, 2)
        }
    }
    catch {}

    return 0
}

function Find-Program {
    param(
        [string[]]$Paths
    )

    foreach ($p in $Paths) {
        if (Test-Path $p) {
            return $p
        }
    }

    return $null
}

# ============================================================
# ADMIN CHECK
# ============================================================

Write-Section "ADMINISTRATOR CHECK"

$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {

    Write-Host ""
    Write-Host "[ERROR] PowerShell must be Run as Administrator." -ForegroundColor Red
    Write-Host ""
    Pause
    exit
}

Write-Host "[OK] Administrator privileges confirmed." -ForegroundColor Green

# ============================================================
# SYSTEM INFORMATION
# ============================================================

Write-Section "SYSTEM INFORMATION"

$Computer = Get-CimInstance Win32_ComputerSystem
$CPU      = Get-CimInstance Win32_Processor | Select-Object -First 1
$OS       = Get-CimInstance Win32_OperatingSystem
$GPUList  = Get-CimInstance Win32_VideoController

$TotalRAMGB = [math]::Round(
    $Computer.TotalPhysicalMemory / 1GB,
    2
)

$LogicalCPU = $CPU.NumberOfLogicalProcessors
$PhysicalCPU = $CPU.NumberOfCores

Write-Host "Computer      : $($Computer.Manufacturer) $($Computer.Model)"
Write-Host "CPU           : $($CPU.Name)"
Write-Host "Physical Core : $PhysicalCPU"
Write-Host "Logical CPU   : $LogicalCPU"
Write-Host "RAM           : $TotalRAMGB GB"
Write-Host "Windows       : $($OS.Caption)"
Write-Host "Build         : $($OS.BuildNumber)"

Write-Host ""
Write-Host "GPU(s):"

foreach ($gpu in $GPUList) {

    Write-Host "  Name        : $($gpu.Name)"
    Write-Host "  Driver      : $($gpu.DriverVersion)"
    Write-Host "  Driver Date : $($gpu.DriverDate)"
    Write-Host "  RAM         : $([math]::Round($gpu.AdapterRAM / 1GB,2)) GB"
    Write-Host ""
}

# ============================================================
# HARDWARE LOG
# ============================================================

@"
============================================================
HARDWARE INFORMATION
============================================================

Computer:
$($Computer.Manufacturer) $($Computer.Model)

CPU:
$($CPU.Name)

Physical Cores:
$PhysicalCPU

Logical Processors:
$LogicalCPU

RAM:
$TotalRAMGB GB

Windows:
$($OS.Caption)

Build:
$($OS.BuildNumber)

GPU:
$($GPUList | Out-String)

"@ | Set-Content $HardwareLog

# ============================================================
# POWER PLAN
# ============================================================

Write-Section "POWER PLAN"

try {

    $power = powercfg /getactivescheme 2>&1

    Write-Host $power

}
catch {

    Write-Host "[WARNING] Could not read power plan."
}

# ============================================================
# DIRECTX
# ============================================================

Write-Section "DIRECTX / GRAPHICS ENVIRONMENT"

$DxDiagFile = Join-Path $GpuDir "DxDiag.txt"

try {

    Start-Process `
        -FilePath "$env:WINDIR\System32\dxdiag.exe" `
        -ArgumentList "/t `"$DxDiagFile`"" `
        -Wait `
        -WindowStyle Hidden

    if (Test-Path $DxDiagFile) {

        Write-Host "[OK] DirectX diagnostic information collected."

    }
}
catch {

    Write-Host "[WARNING] DxDiag could not be executed."
}

# ============================================================
# FIND APPLICATIONS
# ============================================================

Write-Section "APPLICATION DETECTION"

$ChromePath = Find-Program @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)

$ExcelPath = Find-Program @(
    "$env:ProgramFiles\Microsoft Office\root\Office16\EXCEL.EXE",
    "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\EXCEL.EXE"
)

$WordPath = Find-Program @(
    "$env:ProgramFiles\Microsoft Office\root\Office16\WINWORD.EXE",
    "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\WINWORD.EXE"
)

$PptPath = Find-Program @(
    "$env:ProgramFiles\Microsoft Office\root\Office16\POWERPNT.EXE",
    "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\POWERPNT.EXE"
)

$GimpPath = Find-Program @(
    "$env:ProgramFiles\GIMP 3\bin\gimp-3.0.exe",
    "$env:ProgramFiles\GIMP 3\bin\gimp.exe",
    "$env:ProgramFiles\GIMP 2\bin\gimp-2.10.exe",
    "$env:ProgramFiles\GIMP 2\bin\gimp.exe",
    "${env:ProgramFiles(x86)}\GIMP 3\bin\gimp-3.0.exe",
    "${env:ProgramFiles(x86)}\GIMP 3\bin\gimp.exe",
    "${env:ProgramFiles(x86)}\GIMP 2\bin\gimp-2.10.exe",
    "${env:ProgramFiles(x86)}\GIMP 2\bin\gimp.exe"
)

if ($ChromePath) {
    Write-Host "[OK] Chrome found: $ChromePath" -ForegroundColor Green
}
else {
    Write-Host "[WARNING] Chrome not found." -ForegroundColor Yellow
}

if ($ExcelPath) {
    Write-Host "[OK] Excel found." -ForegroundColor Green
}
else {
    Write-Host "[WARNING] Excel not found." -ForegroundColor Yellow
}

if ($WordPath) {
    Write-Host "[OK] Word found." -ForegroundColor Green
}
else {
    Write-Host "[WARNING] Word not found." -ForegroundColor Yellow
}

if ($PptPath) {
    Write-Host "[OK] PowerPoint found." -ForegroundColor Green
}
else {
    Write-Host "[WARNING] PowerPoint not found." -ForegroundColor Yellow
}

if ($GimpPath) {
    Write-Host "[OK] GIMP found: $GimpPath" -ForegroundColor Green
}
else {
    Write-Host "[WARNING] GIMP not found." -ForegroundColor Yellow
}

# ============================================================
# GPU PERFORMANCE COUNTERS
# ============================================================

Write-Section "GPU PERFORMANCE COUNTERS"

$GpuCounterPaths = @(
    "\GPU Engine(*)\Utilization Percentage",
    "\GPU Process Memory(*)\Dedicated Usage",
    "\GPU Process Memory(*)\Shared Usage"
)

$AvailableGpuCounters = @()

foreach ($counter in $GpuCounterPaths) {

    try {

        $test = Get-Counter -Counter $counter -ErrorAction Stop

        $AvailableGpuCounters += $counter

        Write-Host "[OK] $counter"

    }
    catch {

        Write-Host "[NOT AVAILABLE] $counter"
    }
}

# ============================================================
# MONITORING INITIALIZATION
# ============================================================

"Timestamp,CPU_Total_Percent,Available_RAM_GB,Used_RAM_Percent,Disk_Total_Percent,Process_Count,GPU_Utilization_Percent,GPU_Dedicated_MB" |
    Set-Content $MonitorFile

$CpuSamples = New-Object System.Collections.Generic.List[double]
$RamSamples = New-Object System.Collections.Generic.List[double]
$DiskSamples = New-Object System.Collections.Generic.List[double]
$GpuSamples = New-Object System.Collections.Generic.List[double]

$MinAvailableRAM = $TotalRAMGB
$PeakCPU = 0
$PeakDisk = 0
$PeakGPU = 0

function Get-GpuUsage {

    $gpuTotal = 0

    try {

        $counter = Get-Counter "\GPU Engine(*)\Utilization Percentage" -ErrorAction Stop

        foreach ($sample in $counter.CounterSamples) {

            $value = $sample.CookedValue

            if ($value -gt 0) {
                $gpuTotal += $value
            }
        }

        if ($gpuTotal -gt 100) {
            $gpuTotal = 100
        }

        return [math]::Round($gpuTotal, 2)

    }
    catch {

        return 0
    }
}

function Get-GpuDedicatedMemoryMB {

    $total = 0

    try {

        $counter = Get-Counter "\GPU Process Memory(*)\Dedicated Usage" -ErrorAction Stop

        foreach ($sample in $counter.CounterSamples) {

            if ($sample.CookedValue -gt 0) {
                $total += $sample.CookedValue
            }
        }

        return [math]::Round($total / 1MB, 2)

    }
    catch {

        return 0
    }
}

function Take-MonitorSample {

    try {

        $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue

        $osNow = Get-CimInstance Win32_OperatingSystem

        $availableGB = [math]::Round(
            $osNow.FreePhysicalMemory / 1MB,
            2
        )

        $usedRAMPercent = [math]::Round(
            (($TotalRAMGB - $availableGB) / $TotalRAMGB) * 100,
            2
        )

        $disk = (Get-Counter '\PhysicalDisk(_Total)\% Disk Time').CounterSamples[0].CookedValue

        if ($disk -gt 100) {
            $disk = 100
        }

        $gpu = Get-GpuUsage
        $gpuMem = Get-GpuDedicatedMemoryMB

        $processCount = @(Get-Process).Count

        $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        "$time,$([math]::Round($cpu,2)),$availableGB,$usedRAMPercent,$([math]::Round($disk,2)),$processCount,$gpu,$gpuMem" |
            Add-Content $MonitorFile

        [void]$CpuSamples.Add([double]$cpu)
        [void]$RamSamples.Add([double]$availableGB)
        [void]$DiskSamples.Add([double]$disk)
        [void]$GpuSamples.Add([double]$gpu)

        if ($cpu -gt $script:PeakCPU) {
            $script:PeakCPU = $cpu
        }

        if ($disk -gt $script:PeakDisk) {
            $script:PeakDisk = $disk
        }

        if ($gpu -gt $script:PeakGPU) {
            $script:PeakGPU = $gpu
        }

        if ($availableGB -lt $script:MinAvailableRAM) {
            $script:MinAvailableRAM = $availableGB
        }

    }
    catch {

        Add-Content $EventLog "[MONITOR ERROR] $($_.Exception.Message)"
    }
}

# ============================================================
# PRE-TEST BASELINE
# ============================================================

Write-Section "BASELINE MONITORING"

Write-Log "Collecting idle baseline for 10 seconds."

for ($i = 1; $i -le 10; $i++) {

    Take-MonitorSample

    Start-Sleep -Seconds $MonitorInterval
}

# ============================================================
# CPU STRESS TEST
# ============================================================

Write-Section "EXTREME CPU STRESS TEST"

Write-Log "Starting CPU stress for $CpuStressSeconds seconds."

$CpuJobs = @()

for ($i = 1; $i -le $LogicalCPU; $i++) {

    $CpuJobs += Start-Job -ScriptBlock {

        param($Seconds)

        $stop = [DateTime]::UtcNow.AddSeconds($Seconds)

        $x = 1.23456789

        while ([DateTime]::UtcNow -lt $stop) {

            $x = [math]::Sin($x) *
                 [math]::Cos($x) *
                 [math]::Sqrt([math]::Abs($x) + 1)

            $x += 0.000001

            if ($x -gt 1000000) {
                $x = 1.1
            }
        }

        return $x

    } -ArgumentList $CpuStressSeconds
}

$cpuStressStart = Get-Date

while ((Get-Date) -lt $cpuStressStart.AddSeconds($CpuStressSeconds)) {

    Take-MonitorSample

    Start-Sleep -Seconds $MonitorInterval
}

$CpuJobs | Wait-Job | Out-Null
$CpuJobs | Remove-Job -Force

Write-Log "CPU stress completed."

# ============================================================
# CREATE EXCEL TEST FILES
# ============================================================

Write-Section "EXCEL HEAVY WORKLOAD"

$ExcelObjects = @()
$ExcelTimes = @()

if ($ExcelPath) {

    try {

        $Excel = New-Object -ComObject Excel.Application
        $Excel.Visible = $true
        $Excel.DisplayAlerts = $false

        for ($f = 1; $f -le $ExcelFiles; $f++) {

            Write-Log "Creating Excel workload $f / $ExcelFiles"

            $wb = $Excel.Workbooks.Add()
            $ws = $wb.Worksheets.Item(1)

            $data = New-Object 'object[,]' ($ExcelRows + 1), 6

            $data[0,0] = "ID"
            $data[0,1] = "ValueA"
            $data[0,2] = "ValueB"
            $data[0,3] = "ValueC"
            $data[0,4] = "Result"
            $data[0,5] = "Category"

            for ($r = 1; $r -le $ExcelRows; $r++) {

                $data[$r,0] = $r
                $data[$r,1] = ($r * 3) % 997
                $data[$r,2] = ($r * 7) % 541
                $data[$r,3] = ($r * 11) % 431
            }

            $ws.Range(
                "A1:F$($ExcelRows + 1)"
            ).Value2 = $data

            $ws.Range("E2").FormulaR1C1 =
                "=SUM(RC[-3]:RC[-1])+AVERAGE(RC[-3]:RC[-1])*2"

            $ws.Range("E2:E$($ExcelRows + 1)").FillDown()

            $ws.Range("F2").FormulaR1C1 =
                '=IF(RC[-1]>2000,"HIGH",IF(RC[-1]>1000,"MEDIUM","LOW"))'

            $ws.Range("F2:F$($ExcelRows + 1)").FillDown()

            $excelFile = Join-Path $OfficeDir "HeavyExcel_$f.xlsx"

            $calcStart = Get-Date

            for ($round = 1; $round -le $ExcelRounds; $round++) {

                Write-Log "Excel $f - calculation round $round / $ExcelRounds"

                $Excel.CalculateFullRebuild()

                Take-MonitorSample
            }

            $calcTime = ((Get-Date) - $calcStart).TotalSeconds

            $ExcelTimes += $calcTime

            $wb.SaveAs($excelFile)

            $ExcelObjects += $wb
        }

        Write-Log "Excel workload completed."

    }
    catch {

        Write-Log "Excel ERROR: $($_.Exception.Message)"
    }
}

# ============================================================
# WORD WORKLOAD
# ============================================================

Write-Section "WORD WORKLOAD"

$WordObjects = @()

if ($WordPath) {

    try {

        $Word = New-Object -ComObject Word.Application
        $Word.Visible = $true

        for ($i = 1; $i -le $WordFiles; $i++) {

            Write-Log "Creating Word document $i / $WordFiles"

            $doc = $Word.Documents.Add()

            for ($p = 1; $p -le 150; $p++) {

                $range = $doc.Content
                $range.InsertAfter(
                    "Performance benchmark paragraph $p. " +
                    "This text is intentionally repeated to create " +
                    "a realistic document processing workload. " +
                    "CPU RAM and storage resources are monitored during the operation.`r`n"
                )
            }

            for ($t = 1; $t -le 5; $t++) {

                $table = $doc.Tables.Add(
                    $doc.Range($doc.Content.End - 1),
                    20,
                    8
                )

                for ($r = 1; $r -le 20; $r++) {

                    for ($c = 1; $c -le 8; $c++) {

                        $table.Cell($r,$c).Range.Text =
                            "R${r}C${c}"
                    }
                }
            }

            $wordFile = Join-Path $OfficeDir "HeavyWord_$i.docx"

            $doc.SaveAs([ref]$wordFile)

            $WordObjects += $doc

            Take-MonitorSample
        }

        Write-Log "Word workload completed."

    }
    catch {

        Write-Log "Word ERROR: $($_.Exception.Message)"
    }
}

# ============================================================
# POWERPOINT WORKLOAD
# ============================================================

Write-Section "POWERPOINT WORKLOAD"

$PptObjects = @()

if ($PptPath) {

    try {

        $Ppt = New-Object -ComObject PowerPoint.Application

        for ($i = 1; $i -le $PptFiles; $i++) {

            Write-Log "Creating PowerPoint $i / $PptFiles"

            $presentation = $Ppt.Presentations.Add()

            for ($s = 1; $s -le 40; $s++) {

                $slide = $presentation.Slides.Add(
                    $s,
                    12
                )

                $textbox = $slide.Shapes.AddTextbox(
                    1,
                    50,
                    50,
                    600,
                    100
                )

                $textbox.TextFrame.TextRange.Text =
                    "Extreme Benchmark Slide $s"

                for ($shape = 1; $shape -le 12; $shape++) {

                    $slide.Shapes.AddShape(
                        1,
                        ($shape * 30),
                        200,
                        100,
                        50
                    ) | Out-Null
                }
            }

            $pptFile = Join-Path $OfficeDir "HeavyPowerPoint_$i.pptx"

            $presentation.SaveAs($pptFile)

            $PptObjects += $presentation

            Take-MonitorSample
        }

        Write-Log "PowerPoint workload completed."

    }
    catch {

        Write-Log "PowerPoint ERROR: $($_.Exception.Message)"
    }
}

# ============================================================
# CREATE GIMP TEST IMAGE
# ============================================================

Write-Section "GIMP GRAPHICS TEST PREPARATION"

$GimpImage = Join-Path $GimpDir "GIMP_5000x3500_Test.ppm"

try {

    Write-Log "Generating large graphics test image."

    # PPM binary image
    $fs = [System.IO.File]::Open(
        $GimpImage,
        [System.IO.FileMode]::Create
    )

    $header = "P6`n$GimpWidth $GimpHeight`n255`n"

    $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)

    $fs.Write(
        $headerBytes,
        0,
        $headerBytes.Length
    )

    # Generate rows without keeping entire image in RAM
    $row = New-Object byte[] ($GimpWidth * 3)

    for ($y = 0; $y -lt $GimpHeight; $y++) {

        for ($x = 0; $x -lt $GimpWidth; $x++) {

            $index = $x * 3

            $row[$index]     = [byte](($x + $y) % 256)
            $row[$index + 1] = [byte](($x * 2) % 256)
            $row[$index + 2] = [byte](($y * 2) % 256)
        }

        $fs.Write(
            $row,
            0,
            $row.Length
        )
    }

    $fs.Close()

    Write-Log "GIMP test image created."

}
catch {

    Write-Log "GIMP image creation ERROR: $($_.Exception.Message)"

    try {
        if ($fs) {
            $fs.Close()
        }
    }
    catch {}
}

# ============================================================
# GIMP TEST
# ============================================================

Write-Section "GIMP REAL-WORLD GRAPHICS TEST"

$GimpProcess = $null
$GimpLaunchSeconds = 0

if ($GimpPath -and (Test-Path $GimpImage)) {

    try {

        Write-Log "Launching GIMP with large test image."

        $gimpStart = Get-Date

        $GimpProcess = Start-Process `
            -FilePath $GimpPath `
            -ArgumentList "`"$GimpImage`"" `
            -PassThru

        # Wait for process initialization
        Start-Sleep -Seconds 5

        $GimpLaunchSeconds =
            ((Get-Date) - $gimpStart).TotalSeconds

        Write-Log "GIMP launch elapsed time: $([math]::Round($GimpLaunchSeconds,2)) seconds."

        # Monitor GIMP for 30 seconds
        for ($i = 1; $i -le 30; $i++) {

            Take-MonitorSample

            Start-Sleep -Seconds 1
        }

        Write-Log "GIMP graphics loading phase completed."

    }
    catch {

        Write-Log "GIMP ERROR: $($_.Exception.Message)"
    }

}
else {

    Write-Log "GIMP test skipped because executable or test image was unavailable."
}

# ============================================================
# CHROME WORKLOAD
# ============================================================

Write-Section "CHROME REAL-WORLD WORKLOAD"

$Urls = @(
    "https://www.google.com",
    "https://www.wikipedia.org",
    "https://www.microsoft.com",
    "https://github.com",
    "https://www.youtube.com",
    "https://www.reddit.com",
    "https://www.bing.com",
    "https://www.office.com",
    "https://www.mozilla.org",
    "https://www.python.org",
    "https://www.w3.org",
    "https://learn.microsoft.com"
)

if ($ChromePath) {

    try {

        $chromeStart = Get-Date

        foreach ($url in $Urls) {

            Start-Process `
                -FilePath $ChromePath `
                -ArgumentList "--new-tab `"$url`""
        }

        $ChromeLaunchSeconds =
            ((Get-Date) - $chromeStart).TotalSeconds

        Write-Log "Chrome workload launched."

    }
    catch {

        Write-Log "Chrome ERROR: $($_.Exception.Message)"
    }
}
else {

    $ChromeLaunchSeconds = 0
}

# ============================================================
# HEAVY MULTITASKING HOLD PHASE
# ============================================================

Write-Section "EXTREME MULTITASKING HOLD"

Write-Log "All workloads are now running simultaneously."

$holdStart = Get-Date

$CpuAbove80Seconds  = 0
$CpuAbove90Seconds  = 0
$CpuAbove95Seconds  = 0
$RamPressureSeconds = 0
$DiskPressureSeconds = 0
$GpuActiveSeconds = 0

while ((Get-Date) -lt $holdStart.AddSeconds($HeavyHoldSeconds)) {

    Take-MonitorSample

    $lastCpu = $CpuSamples[$CpuSamples.Count - 1]
    $lastRam = $RamSamples[$RamSamples.Count - 1]
    $lastDisk = $DiskSamples[$DiskSamples.Count - 1]
    $lastGpu = $GpuSamples[$GpuSamples.Count - 1]

    if ($lastCpu -ge 80) {
        $CpuAbove80Seconds++
    }

    if ($lastCpu -ge 90) {
        $CpuAbove90Seconds++
    }

    if ($lastCpu -ge 95) {
        $CpuAbove95Seconds++
    }

    if ($lastRam -lt 2) {
        $RamPressureSeconds++
    }

    if ($lastDisk -ge 90) {
        $DiskPressureSeconds++
    }

    if ($lastGpu -ge 50) {
        $GpuActiveSeconds++
    }

    Start-Sleep -Seconds $MonitorInterval
}

Write-Log "Extreme multitasking hold completed."

# ============================================================
# APPLICATION HEALTH CHECK
# ============================================================

Write-Section "APPLICATION HEALTH CHECK"

$ApplicationResults = @()

$checkProcesses = @(
    "chrome",
    "excel",
    "winword",
    "powerpnt",
    "gimp",
    "gimp-2.10",
    "gimp-3.0"
)

foreach ($procName in $checkProcesses) {

    $running = @(Get-Process -Name $procName -ErrorAction SilentlyContinue)

    if ($running.Count -gt 0) {

        $ApplicationResults += "$procName = RUNNING"

    }
}

$ApplicationResults | ForEach-Object {
    Write-Host "[OK] $_"
}

# ============================================================
# CALCULATE METRICS
# ============================================================

Write-Section "CALCULATING RESULTS"

$AvgCPU = 0
$AvgRAM = 0
$AvgDisk = 0
$AvgGPU = 0

if ($CpuSamples.Count -gt 0) {
    $AvgCPU = [math]::Round(
        ($CpuSamples | Measure-Object -Average).Average,
        2
    )
}

if ($RamSamples.Count -gt 0) {
    $AvgRAM = [math]::Round(
        ($RamSamples | Measure-Object -Average).Average,
        2
    )
}

if ($DiskSamples.Count -gt 0) {
    $AvgDisk = [math]::Round(
        ($DiskSamples | Measure-Object -Average).Average,
        2
    )
}

if ($GpuSamples.Count -gt 0) {
    $AvgGPU = [math]::Round(
        ($GpuSamples | Measure-Object -Average).Average,
        2
    )
}

# ============================================================
# CPU SCORE
# ============================================================

$CPUScore = 100

if ($PeakCPU -ge 95) {
    $CPUScore -= 35
}
elseif ($PeakCPU -ge 90) {
    $CPUScore -= 25
}
elseif ($PeakCPU -ge 80) {
    $CPUScore -= 15
}
elseif ($PeakCPU -ge 70) {
    $CPUScore -= 5
}

if ($CpuAbove90Seconds -ge 45) {
    $CPUScore -= 10
}

if ($CPUScore -lt 0) {
    $CPUScore = 0
}

# ============================================================
# RAM SCORE
# ============================================================

$RAMScore = 100

if ($MinAvailableRAM -lt 1) {
    $RAMScore -= 50
}
elseif ($MinAvailableRAM -lt 2) {
    $RAMScore -= 35
}
elseif ($MinAvailableRAM -lt 3) {
    $RAMScore -= 20
}
elseif ($MinAvailableRAM -lt 4) {
    $RAMScore -= 10
}

if ($RAMScore -lt 0) {
    $RAMScore = 0
}

# ============================================================
# DISK SCORE
# ============================================================

$DiskScore = 100

if ($PeakDisk -ge 95) {
    $DiskScore -= 35
}
elseif ($PeakDisk -ge 90) {
    $DiskScore -= 25
}
elseif ($PeakDisk -ge 75) {
    $DiskScore -= 10
}

if ($DiskScore -lt 0) {
    $DiskScore = 0
}

# ============================================================
# GPU SCORE
# ============================================================

$GPUScore = 50

if ($GPUList.Count -gt 0) {

    $GPUScore = 70

    if ($PeakGPU -ge 80) {
        $GPUScore += 15
    }
    elseif ($PeakGPU -ge 50) {
        $GPUScore += 10
    }
    elseif ($PeakGPU -ge 25) {
        $GPUScore += 5
    }

    if ($GPUScore -gt 100) {
        $GPUScore = 100
    }
}

# ============================================================
# GIMP SCORE
# ============================================================

$GimpScore = 0

if ($GimpPath) {

    $GimpScore = 50

    if ($GimpLaunchSeconds -gt 0 -and $GimpLaunchSeconds -lt 5) {
        $GimpScore += 25
    }
    elseif ($GimpLaunchSeconds -lt 10) {
        $GimpScore += 15
    }
    elseif ($GimpLaunchSeconds -lt 20) {
        $GimpScore += 5
    }

    if ($PeakCPU -lt 85) {
        $GimpScore += 10
    }

    if ($MinAvailableRAM -gt 3) {
        $GimpScore += 10
    }

    if ($GimpScore -gt 100) {
        $GimpScore = 100
    }
}

# ============================================================
# MULTITASKING SCORE
# ============================================================

$MultitaskingScore = 100

if ($CpuAbove95Seconds -gt 30) {
    $MultitaskingScore -= 25
}
elseif ($CpuAbove90Seconds -gt 30) {
    $MultitaskingScore -= 15
}

if ($RamPressureSeconds -gt 10) {
    $MultitaskingScore -= 30
}
elseif ($RamPressureSeconds -gt 0) {
    $MultitaskingScore -= 15
}

if ($DiskPressureSeconds -gt 20) {
    $MultitaskingScore -= 20
}

if ($MultitaskingScore -lt 0) {
    $MultitaskingScore = 0
}

# ============================================================
# STABILITY SCORE
# ============================================================

$StabilityScore = 100

if ($ApplicationResults.Count -lt 3) {
    $StabilityScore -= 15
}

if ($CpuAbove95Seconds -gt 45) {
    $StabilityScore -= 20
}

if ($RamPressureSeconds -gt 20) {
    $StabilityScore -= 25
}

if ($DiskPressureSeconds -gt 30) {
    $StabilityScore -= 15
}

if ($StabilityScore -lt 0) {
    $StabilityScore = 0
}

# ============================================================
# OVERALL SCORE
# ============================================================

$OverallScore = [math]::Round(
    (
        ($CPUScore * 0.20) +
        ($RAMScore * 0.15) +
        ($GPUScore * 0.20) +
        ($GimpScore * 0.15) +
        ($MultitaskingScore * 0.20) +
        ($StabilityScore * 0.10)
    ),
    0
)

# ============================================================
# RATING
# ============================================================

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

    $Rating = "MODERATE"

}
elseif ($OverallScore -ge 45) {

    $Rating = "WEAK"

}
else {

    $Rating = "VERY WEAK"
}

# ============================================================
# BOTTLENECK DETECTION
# ============================================================

$Bottleneck = "None clearly detected"

$Scores = @{
    CPU = $CPUScore
    RAM = $RAMScore
    GPU = $GPUScore
    GIMP = $GimpScore
    Multitasking = $MultitaskingScore
    Stability = $StabilityScore
}

$Lowest = $Scores.GetEnumerator() |
    Sort-Object Value |
    Select-Object -First 1

if ($Lowest.Value -lt 70) {

    $Bottleneck = $Lowest.Key
}

# ============================================================
# PRACTICAL ASSESSMENT
# ============================================================

$PhotoshopAssessment = "UNKNOWN"

if ($GimpScore -ge 85 -and $RAMScore -ge 80 -and $GPUScore -ge 80) {

    $PhotoshopAssessment =
        "Suitable for serious image editing and moderate Photoshop workloads."

}
elseif ($GimpScore -ge 70 -and $RAMScore -ge 70) {

    $PhotoshopAssessment =
        "Usable for normal image editing, but heavy Photoshop projects may be slow."

}
elseif ($GimpScore -ge 50) {

    $PhotoshopAssessment =
        "Basic image editing is possible; large PSD files and heavy filters may be slow."

}
else {

    $PhotoshopAssessment =
        "Not recommended for heavy Photoshop workloads."
}

# ============================================================
# CPU PRACTICAL ASSESSMENT
# ============================================================

if ($CPUScore -ge 85) {

    $CPUAssessment = "Strong CPU headroom."

}
elseif ($CPUScore -ge 70) {

    $CPUAssessment = "Acceptable CPU performance with some limitation under sustained heavy load."

}
elseif ($CPUScore -ge 50) {

    $CPUAssessment = "CPU is a significant performance limitation."

}
else {

    $CPUAssessment = "CPU is a major bottleneck."

}

# ============================================================
# RAM PRACTICAL ASSESSMENT
# ============================================================

if ($RAMScore -ge 85) {

    $RAMAssessment = "Good RAM headroom."

}
elseif ($RAMScore -ge 70) {

    $RAMAssessment = "RAM is adequate but limited for very heavy multitasking."

}
elseif ($RAMScore -ge 50) {

    $RAMAssessment = "RAM pressure is significant."

}
else {

    $RAMAssessment = "RAM is a major bottleneck."

}

# ============================================================
# GPU PRACTICAL ASSESSMENT
# ============================================================

if ($GPUScore -ge 85) {

    $GPUAssessment = "Good graphics capability for general accelerated workloads."

}
elseif ($GPUScore -ge 70) {

    $GPUAssessment = "Usable graphics capability with limitations for demanding workloads."

}
elseif ($GPUScore -ge 50) {

    $GPUAssessment = "Basic graphics capability; demanding GPU workloads will be limited."

}
else {

    $GPUAssessment = "Very limited graphics capability."

}

# ============================================================
# FINAL REPORT
# ============================================================

$EndTime = Get-Date
$TotalSeconds = ($EndTime - $StartTime).TotalSeconds

$ExcelAverageTime = 0

if ($ExcelTimes.Count -gt 0) {

    $ExcelAverageTime =
        [math]::Round(
            ($ExcelTimes | Measure-Object -Average).Average,
            2
        )
}

$Report = @"
============================================================
       EXTREME PC + GPU + GIMP BENCHMARK
============================================================

TEST START:
$StartTime

TEST END:
$EndTime

TOTAL TEST TIME:
$([math]::Round($TotalSeconds,2)) seconds


============================================================
SYSTEM
============================================================

Computer:
$($Computer.Manufacturer) $($Computer.Model)

CPU:
$($CPU.Name)

Physical Cores:
$PhysicalCPU

Logical Processors:
$LogicalCPU

RAM:
$TotalRAMGB GB

GPU:
$($GPUList.Name -join ", ")

Windows:
$($OS.Caption)

Build:
$($OS.BuildNumber)


============================================================
STRESS CONFIGURATION
============================================================

CPU Stress:
$CpuStressSeconds seconds

Extreme Multitasking Hold:
$HeavyHoldSeconds seconds

Chrome Tabs:
$ChromeTabs

Excel Files:
$ExcelFiles

Excel Rows:
$ExcelRows

Excel Calculation Rounds:
$ExcelRounds

Word Files:
$WordFiles

PowerPoint Files:
$PptFiles

GIMP Image:
$GimpWidth x $GimpHeight


============================================================
RESOURCE RESULTS
============================================================

CPU Average:
$AvgCPU %

CPU Peak:
$([math]::Round($PeakCPU,2)) %

CPU >= 80%:
$CpuAbove80Seconds seconds

CPU >= 90%:
$CpuAbove90Seconds seconds

CPU >= 95%:
$CpuAbove95Seconds seconds


Average Available RAM:
$AvgRAM GB

Minimum Available RAM:
$([math]::Round($MinAvailableRAM,2)) GB


Average Disk Activity:
$AvgDisk %

Peak Disk Activity:
$([math]::Round($PeakDisk,2)) %


Average GPU Activity:
$AvgGPU %

Peak GPU Activity:
$([math]::Round($PeakGPU,2)) %

GPU Active >= 50%:
$GpuActiveSeconds seconds


============================================================
APPLICATION PERFORMANCE
============================================================

GIMP:
$(if ($GimpPath) {"DETECTED"} else {"NOT DETECTED"})

GIMP Launch/Image Load Time:
$([math]::Round($GimpLaunchSeconds,2)) seconds

Chrome Launch Time:
$([math]::Round($ChromeLaunchSeconds,2)) seconds

Excel Average Calculation Time:
$ExcelAverageTime seconds


============================================================
SCORES
============================================================

CPU Performance:
$CPUScore / 100

RAM Performance:
$RAMScore / 100

GPU Performance:
$GPUScore / 100

GIMP Graphics:
$GimpScore / 100

Multitasking:
$MultitaskingScore / 100

Stability:
$StabilityScore / 100


============================================================
OVERALL
============================================================

Overall Score:
$OverallScore / 100

Rating:
$Rating

Primary Bottleneck:
$Bottleneck


============================================================
PRACTICAL ASSESSMENT
============================================================

CPU:
$CPUAssessment

RAM:
$RAMAssessment

GPU:
$GPUAssessment

GIMP:
$(if ($GimpScore -ge 80) {
"Good for GIMP workloads."
}
elseif ($GimpScore -ge 60) {
"Usable for GIMP, but large images and advanced operations may be slow."
}
else {
"GIMP heavy workloads are likely to be slow."
})


PHOTOSHOP:
$PhotoshopAssessment


============================================================
MULTITASKING ASSESSMENT
============================================================

$(if ($MultitaskingScore -ge 85) {
"System has good sustained multitasking capability."
}
elseif ($MultitaskingScore -ge 70) {
"System can multitask reasonably well, but sustained heavy workloads expose limitations."
}
elseif ($MultitaskingScore -ge 50) {
"Heavy multitasking causes noticeable resource pressure."
}
else {
"System is not well suited to sustained heavy multitasking."
})


============================================================
STRESS INTERPRETATION
============================================================

CPU pressure:
$(if ($CpuAbove95Seconds -gt 30) {
"SEVERE - CPU spent significant time at >=95%."
}
elseif ($CpuAbove90Seconds -gt 30) {
"HIGH - CPU spent significant time at >=90%."
}
elseif ($CpuAbove80Seconds -gt 30) {
"MODERATE - CPU spent significant time above 80%."
}
else {
"LOW - CPU retained reasonable headroom."
})


RAM pressure:
$(if ($RamPressureSeconds -gt 20) {
"SEVERE - available RAM dropped below 2 GB for extended time."
}
elseif ($RamPressureSeconds -gt 0) {
"DETECTED - available RAM dropped below 2 GB."
}
else {
"LOW - no critical RAM pressure detected."
})


Disk pressure:
$(if ($DiskPressureSeconds -gt 20) {
"HIGH - disk was heavily saturated."
}
elseif ($PeakDisk -gt 75) {
"MODERATE - substantial disk activity detected."
}
else {
"LOW - disk was not a major bottleneck."
})


GPU:
$(if ($PeakGPU -ge 80) {
"GPU reached high utilization during the test."
}
elseif ($PeakGPU -ge 50) {
"GPU showed meaningful workload activity."
}
else {
"GPU utilization remained relatively low or Windows GPU counters were limited."
})


============================================================
FILES
============================================================

Test Root:
$TestRoot

Hardware Log:
$HardwareLog

Monitor CSV:
$MonitorFile

DirectX Log:
$DxDiagFile

Event Log:
$EventLog


============================================================
IMPORTANT
============================================================

This benchmark is a custom real-world stress benchmark.

The score is NOT an official industry benchmark such as
Cinebench, 3DMark, PCMark or PugetBench.

GPU utilization may vary depending on Windows Performance
Counter availability and driver implementation.

Photoshop capability is estimated from the measured CPU,
RAM, GPU and GIMP behavior; Photoshop itself was not tested.

============================================================
END OF REPORT
============================================================
"@

$Report | Set-Content $ReportFile -Encoding UTF8

# ============================================================
# CLEANUP OFFICE DOCUMENTS
# ============================================================

Write-Section "CLEANUP"

# بستن فقط فایل هایی که همین اسکریپت ساخته است.
# برنامه های قبلی کاربر دست نخورده باقی می مانند.

foreach ($wb in $ExcelObjects) {

    try {
        $wb.Close($true)
    }
    catch {}
}

try {
    if ($Excel) {
        $Excel.Quit()
    }
}
catch {}

foreach ($doc in $WordObjects) {

    try {
        $doc.Close($true)
    }
    catch {}
}

try {
    if ($Word) {
        $Word.Quit()
    }
}
catch {}

foreach ($presentation in $PptObjects) {

    try {
        $presentation.Close()
    }
    catch {}
}

try {
    if ($Ppt) {
        $Ppt.Quit()
    }
}
catch {}

# GIMP که توسط تست اجرا شده بود
if ($GimpProcess) {

    try {

        if (-not $GimpProcess.HasExited) {

            Stop-Process `
                -Id $GimpProcess.Id `
                -Force `
                -ErrorAction SilentlyContinue
        }

    }
    catch {}
}

# ============================================================
# FINAL SCREEN
# ============================================================

Write-Section "FINAL RESULT"

Write-Host ""
Write-Host "CPU SCORE          : $CPUScore / 100"
Write-Host "RAM SCORE          : $RAMScore / 100"
Write-Host "GPU SCORE          : $GPUScore / 100"
Write-Host "GIMP SCORE         : $GimpScore / 100"
Write-Host "MULTITASKING SCORE : $MultitaskingScore / 100"
Write-Host "STABILITY SCORE    : $StabilityScore / 100"

Write-Host ""
Write-Host "============================================================"
Write-Host "OVERALL SCORE : $OverallScore / 100"
Write-Host "RATING        : $Rating"
Write-Host "BOTTLENECK    : $Bottleneck"
Write-Host "============================================================"

Write-Host ""
Write-Host "GIMP / Photoshop Assessment:"
Write-Host $PhotoshopAssessment

Write-Host ""
Write-Host "Report:"
Write-Host $ReportFile

Write-Host ""
Write-Host "Monitor CSV:"
Write-Host $MonitorFile

Write-Host ""

# ============================================================
# OPEN REPORT
# ============================================================

try {

    Start-Process notepad.exe $ReportFile

}
catch {}

Write-Host ""
Write-Host "[DONE] Extreme benchmark completed." -ForegroundColor Green
Write-Host ""
Pause
```

