
> [!INFO] بنچمارک واقعی عملکرد سیستم در اجرای هم‌زمان چندین برنامه
> یک محیط آزمایشی برای ارزیابی توان پردازشی، ظرفیت حافظه و عملکرد سیستم هنگام اجرای هم‌زمان چندین نرم‌افزار ایجاد می‌کند.
> تعداد تب‌های Google Chrome و فایل‌های Excel، Word و PowerPoint مورد استفاده در آزمون را از طریق متغیرهای قابل تنظیم مشخص می‌کند.
> یک پوشه اختصاصی با نام PC_Multitasking_Benchmark روی Desktop ایجاد کرده و زیرپوشه‌های مجزایی برای فایل‌های آزمایشی و گزارش‌ها می‌سازد.
> تنظیمات اولیه آزمون شامل تعداد فایل‌ها، حجم محاسبات Excel، تعداد دورهای محاسباتی و فاصله زمانی پایش منابع سیستم را تعیین می‌کند.
> فایل‌های آزمایشی Microsoft Office را برای شبیه‌سازی فعالیت‌های واقعی و سنجش توانایی سیستم در مدیریت بارهای کاری چندگانه آماده می‌کند.
> زیرساخت لازم برای اجرای هم‌زمان مرورگر Chrome و چندین سند Excel، Word و PowerPoint را فراهم می‌کند.
> مسیر ذخیره‌سازی اطلاعات پایش سیستم را در قالب فایل CSV و گزارش نهایی را در قالب TXT مشخص می‌کند.
> اطلاعات مربوط به زمان شروع آزمون و مسیر ذخیره‌سازی تنظیمات و نتایج را برای استفاده در مراحل بعدی ثبت می‌کند.
> این بخش مرحله آماده‌سازی و پیکربندی بنچمارک است و به‌تنهایی هنوز آزمون محاسباتی یا پایش مستمر منابع سیستم را اجرا نمی‌کند.
> برای اجرای کامل آزمون به ادامه اسکریپت نیاز دارد و پیش‌نیازهای آن نصب نسخه دسکتاپ Microsoft Office و Google Chrome است.


> [!INFO] Real-World PC Multitasking Performance Benchmark
> Creates A Testing Environment To Evaluate CPU Performance, Memory Capacity And System Behavior Under Multiple Simultaneous Applications.
> Defines The Number Of Google Chrome Tabs And Excel, Word And PowerPoint Files Through Configurable Variables.
> Creates A Dedicated PC_Multitasking_Benchmark Folder On The Desktop With Separate Subfolders For Test Files And Reports.
> Configures Initial Benchmark Parameters Including File Counts, Excel Calculation Volume, Calculation Rounds And System Monitoring Intervals.
> Prepares The Infrastructure For Microsoft Office Test Files To Simulate Real-World Activities And Evaluate Multitasking Performance.
> Establishes The Required Environment For Running Chrome And Multiple Excel, Word And PowerPoint Documents Simultaneously.
> Defines Storage Paths For System Monitoring Data In CSV Format And The Final Benchmark Report In TXT Format.
> Records The Benchmark Start Time And Storage Locations For Configuration Data And Test Results.
> This Section Handles Benchmark Preparation And Configuration And Does Not Yet Execute Calculations Or Continuous System Resource Monitoring.
> Requires The Remaining Script For The Complete Benchmark And Depends On Microsoft Office Desktop And Google Chrome Being Installed.


```
# ============================================================
# PC REAL-WORLD MULTITASKING BENCHMARK
# ============================================================
#
# This script:
#
# 1. Collects system configuration
# 2. Creates a dedicated benchmark folder on the Desktop
# 3. Creates Excel / Word / PowerPoint test files
# 4. Opens multiple Chrome tabs
# 5. Opens multiple Excel workbooks
# 6. Performs relatively heavy Excel calculations
# 7. Opens multiple Word documents
# 8. Opens multiple PowerPoint presentations
# 9. Continuously monitors CPU / RAM / Disk usage
# 10. Calculates a multitasking score
# 11. Generates CSV monitoring data
# 12. Generates a final TXT report
#
# IMPORTANT:
# - Microsoft Office Desktop should be installed.
# - Google Chrome should be installed.
# - Save important Office documents before running.
# - The script does NOT close your existing Office/Chrome windows.
#
# ============================================================


Clear-Host

$ErrorActionPreference = "SilentlyContinue"


# ============================================================
# USER CONFIGURATION
# ============================================================

$ChromeTabs      = 8
$ExcelFiles      = 4
$WordFiles       = 3
$PowerPointFiles = 2

# Number of Excel rows used for calculations
$ExcelRows       = 50000

# Additional calculation rounds
$ExcelRounds     = 3

# Monitoring interval in seconds
$MonitorInterval = 1

# ============================================================
# BENCHMARK FOLDER
# ============================================================

$Desktop = [Environment]::GetFolderPath("Desktop")

$BenchmarkFolder = Join-Path $Desktop "PC_Multitasking_Benchmark"

$ExcelFolder = Join-Path $BenchmarkFolder "Excel"
$WordFolder  = Join-Path $BenchmarkFolder "Word"
$PptFolder   = Join-Path $BenchmarkFolder "PowerPoint"
$LogFolder   = Join-Path $BenchmarkFolder "Logs"

New-Item -ItemType Directory -Force -Path $BenchmarkFolder | Out-Null
New-Item -ItemType Directory -Force -Path $ExcelFolder | Out-Null
New-Item -ItemType Directory -Force -Path $WordFolder | Out-Null
New-Item -ItemType Directory -Force -Path $PptFolder | Out-Null
New-Item -ItemType Directory -Force -Path $LogFolder | Out-Null


$StartTime = Get-Date

$MonitorFile = Join-Path $LogFolder "System-Monitor.csv"
$ReportFile  = Join-Path $LogFolder "Final-Report.txt"
$ConfigFile  = Join-Path $LogFolder "System-Configuration.txt"


# ============================================================
# HEADER
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "       PC REAL-WORLD MULTITASKING BENCHMARK" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Benchmark folder:" -ForegroundColor Yellow
Write-Host $BenchmarkFolder
Write-Host ""


# ============================================================
# SYSTEM CONFIGURATION
# ============================================================

Write-Host "Collecting system configuration..." -ForegroundColor Yellow

$OS = Get-CimInstance Win32_OperatingSystem

$CPU = Get-CimInstance Win32_Processor |
    Select-Object -First 1

$Computer = Get-CimInstance Win32_ComputerSystem

$GPU = Get-CimInstance Win32_VideoController |
    Where-Object { $_.Name } |
    Select-Object -First 1

$BIOS = Get-CimInstance Win32_BIOS |
    Select-Object -First 1


$TotalRAMGB = [math]::Round(
    $Computer.TotalPhysicalMemory / 1GB,
    2
)

$CPUName = $CPU.Name
$CPUCores = $CPU.NumberOfCores
$CPUThreads = $CPU.NumberOfLogicalProcessors

$GPUName = if ($GPU) {
    $GPU.Name
}
else {
    "Unknown"
}

$WindowsVersion = $OS.Caption
$WindowsBuild = $OS.BuildNumber

$PowerPlan = "Unknown"

try {
    $PowerPlan = (
        powercfg /getactivescheme 2>$null
    ) -join " "
}
catch {}


# ============================================================
# DISK INFORMATION
# ============================================================

$SystemDrive = $env:SystemDrive

$DiskInfo = Get-CimInstance Win32_LogicalDisk `
    -Filter "DeviceID='$SystemDrive'" |
    Select-Object -First 1

$DiskSizeGB = if ($DiskInfo) {
    [math]::Round($DiskInfo.Size / 1GB, 2)
}
else {
    0
}

$DiskFreeGB = if ($DiskInfo) {
    [math]::Round($DiskInfo.FreeSpace / 1GB, 2)
}
else {
    0
}


# ============================================================
# SAVE SYSTEM CONFIGURATION
# ============================================================

$Configuration = @"

============================================================
SYSTEM CONFIGURATION
============================================================

Date:
$StartTime

Computer:
$($Computer.Manufacturer) $($Computer.Model)

CPU:
$CPUName

CPU Cores:
$CPUCores

CPU Threads:
$CPUThreads

RAM:
$TotalRAMGB GB

GPU:
$GPUName

Windows:
$WindowsVersion

Windows Build:
$WindowsBuild

Power Plan:
$PowerPlan

System Drive:
$SystemDrive

System Drive Size:
$DiskSizeGB GB

System Drive Free Space:
$DiskFreeGB GB

============================================================
BENCHMARK CONFIGURATION
============================================================

Chrome Tabs:
$ChromeTabs

Excel Workbooks:
$ExcelFiles

Excel Rows:
$ExcelRows

Excel Calculation Rounds:
$ExcelRounds

Word Documents:
$WordFiles

PowerPoint Presentations:
$PowerPointFiles

============================================================

"@

$Configuration | Set-Content -LiteralPath $ConfigFile -Encoding UTF8


Write-Host ""
Write-Host "CPU       : $CPUName"
Write-Host "Cores     : $CPUCores"
Write-Host "Threads   : $CPUThreads"
Write-Host "RAM       : $TotalRAMGB GB"
Write-Host "GPU       : $GPUName"
Write-Host "Windows   : $WindowsVersion"
Write-Host "Build     : $WindowsBuild"
Write-Host ""


# ============================================================
# CHECK CHROME
# ============================================================

$ChromePath = $null

$ChromeCandidates = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)

foreach ($Path in $ChromeCandidates) {

    if ($Path -and (Test-Path $Path)) {
        $ChromePath = $Path
        break
    }
}

if (-not $ChromePath) {

    Write-Host "WARNING: Google Chrome was not found." -ForegroundColor Yellow
    Write-Host "Chrome part of the benchmark will be skipped."
    Write-Host ""
}
else {

    Write-Host "Chrome found:" -ForegroundColor Green
    Write-Host $ChromePath
    Write-Host ""
}


# ============================================================
# CHECK MICROSOFT OFFICE
# ============================================================

$ExcelInstalled = $false
$WordInstalled = $false
$PowerPointInstalled = $false

try {
    $ExcelTest = New-Object -ComObject Excel.Application
    $ExcelInstalled = $true
    $ExcelTest.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ExcelTest) | Out-Null
}
catch {}

try {
    $WordTest = New-Object -ComObject Word.Application
    $WordInstalled = $true
    $WordTest.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($WordTest) | Out-Null
}
catch {}

try {
    $PptTest = New-Object -ComObject PowerPoint.Application
    $PowerPointInstalled = $true
    $PptTest.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($PptTest) | Out-Null
}
catch {}


Write-Host "Microsoft Excel     : $ExcelInstalled"
Write-Host "Microsoft Word      : $WordInstalled"
Write-Host "Microsoft PowerPoint: $PowerPointInstalled"
Write-Host ""


# ============================================================
# PREPARE MONITORING FILE
# ============================================================

"Time,CPU_Percent,RAM_Used_Percent,RAM_Available_GB,Disk_Active_Percent,Process_Count" |
    Set-Content -LiteralPath $MonitorFile -Encoding UTF8


# ============================================================
# MONITORING VARIABLES
# ============================================================

$MonitorData = New-Object System.Collections.Generic.List[Object]

$MaxCPU = 0
$MinRAMAvailable = $TotalRAMGB
$MaxRAMUsed = 0
$MaxDisk = 0

$BenchmarkStart = Get-Date


# ============================================================
# MONITOR FUNCTION
# ============================================================

function Get-SystemSample {

    $SampleTime = Get-Date

    $CPUUsage = 0
    $RAMUsedPercent = 0
    $RAMAvailableGB = 0
    $DiskActive = 0

    try {
        $CPUUsage = (
            Get-Counter '\Processor(_Total)\% Processor Time'
        ).CounterSamples.CookedValue
    }
    catch {}

    try {
        $MemoryCounter = Get-Counter '\Memory\Available MBytes'

        $RAMAvailableGB =
            [math]::Round(
                $MemoryCounter.CounterSamples.CookedValue / 1024,
                2
            )

        $RAMUsedPercent =
            [math]::Round(
                (($TotalRAMGB - $RAMAvailableGB) /
                $TotalRAMGB) * 100,
                2
            )
    }
    catch {}

    try {
        $DiskActive = (
            Get-Counter '\PhysicalDisk(_Total)\% Disk Time'
        ).CounterSamples.CookedValue
    }
    catch {}

    $ProcessCount = (
        Get-Process
    ).Count


    [PSCustomObject]@{
        Time = $SampleTime
        CPU = [math]::Round($CPUUsage,2)
        RAMUsed = [math]::Round($RAMUsedPercent,2)
        RAMAvailable = $RAMAvailableGB
        Disk = [math]::Round($DiskActive,2)
        Processes = $ProcessCount
    }
}


# ============================================================
# MONITOR LOOP START
# ============================================================

$Monitoring = $true


# ============================================================
# INITIAL SAMPLE
# ============================================================

$Sample = Get-SystemSample

$MonitorData.Add($Sample)

"$($Sample.Time),$($Sample.CPU),$($Sample.RAMUsed),$($Sample.RAMAvailable),$($Sample.Disk),$($Sample.Processes)" |
    Add-Content -LiteralPath $MonitorFile

$MaxCPU = [math]::Max($MaxCPU,$Sample.CPU)
$MaxRAMUsed = [math]::Max($MaxRAMUsed,$Sample.RAMUsed)
$MinRAMAvailable = [math]::Min($MinRAMAvailable,$Sample.RAMAvailable)
$MaxDisk = [math]::Max($MaxDisk,$Sample.Disk)


# ============================================================
# OPEN CHROME TABS
# ============================================================

if ($ChromePath) {

    Write-Host ""
    Write-Host "Opening Chrome workload..." -ForegroundColor Cyan

    $Websites = @(
        "https://www.google.com",
        "https://www.wikipedia.org",
        "https://www.microsoft.com",
        "https://github.com",
        "https://www.youtube.com",
        "https://www.reddit.com",
        "https://www.office.com",
        "https://www.bing.com"
    )

    $TabCount = [math]::Min(
        $ChromeTabs,
        $Websites.Count
    )

    for ($i = 0; $i -lt $TabCount; $i++) {

        Start-Process `
            -FilePath $ChromePath `
            -ArgumentList $Websites[$i]

        Start-Sleep -Milliseconds 500

        $Sample = Get-SystemSample

        $MonitorData.Add($Sample)

        "$($Sample.Time),$($Sample.CPU),$($Sample.RAMUsed),$($Sample.RAMAvailable),$($Sample.Disk),$($Sample.Processes)" |
            Add-Content -LiteralPath $MonitorFile

        $MaxCPU = [math]::Max($MaxCPU,$Sample.CPU)
        $MaxRAMUsed = [math]::Max($MaxRAMUsed,$Sample.RAMUsed)
        $MinRAMAvailable = [math]::Min($MinRAMAvailable,$Sample.RAMAvailable)
        $MaxDisk = [math]::Max($MaxDisk,$Sample.Disk)
    }
}


# ============================================================
# EXCEL WORKLOAD
# ============================================================

$ExcelObjects = @()

if ($ExcelInstalled) {

    Write-Host ""
    Write-Host "Creating Excel workload..." -ForegroundColor Cyan

    $Excel = New-Object -ComObject Excel.Application

    $Excel.Visible = $true
    $Excel.DisplayAlerts = $false
    $Excel.ScreenUpdating = $false

    for ($FileIndex = 1; $FileIndex -le $ExcelFiles; $FileIndex++) {

        Write-Host "Creating Excel workbook $FileIndex / $ExcelFiles"

        $Workbook = $Excel.Workbooks.Add()

        $Sheet = $Workbook.Worksheets.Item(1)

        $Sheet.Name = "Benchmark"

        # ----------------------------------------------------
        # Headers
        # ----------------------------------------------------

        $Headers = @(
            "ID",
            "Value A",
            "Value B",
            "Value C",
            "SUM",
            "AVERAGE",
            "IF Result",
            "Lookup",
            "Complex Result"
        )

        for ($c = 0; $c -lt $Headers.Count; $c++) {

            $Sheet.Cells.Item(1,$c+1) = $Headers[$c]
        }


        # ----------------------------------------------------
        # Generate data in memory
        # ----------------------------------------------------

        $Data = New-Object 'object[,]' $ExcelRows,4

        for ($r = 0; $r -lt $ExcelRows; $r++) {

            $Data[$r,0] = $r + 1
            $Data[$r,1] = (($r * 17) % 10000) + 1
            $Data[$r,2] = (($r * 31) % 5000) + 1
            $Data[$r,3] = (($r * 43) % 2500) + 1
        }

        $Range = $Sheet.Range(
            $Sheet.Cells.Item(2,1),
            $Sheet.Cells.Item($ExcelRows + 1,4)
        )

        $Range.Value2 = $Data


        # ----------------------------------------------------
        # Heavy formulas
        # ----------------------------------------------------

        $FormulaRange = $Sheet.Range(
            "E2:I$($ExcelRows + 1)"
        )

        $FormulaRange.FormulaR1C1 = @(
            '=RC[-3]+RC[-2]+RC[-1]',
            '=AVERAGE(RC[-3]:RC[-1])',
            '=IF(RC[-2]>10000,"HIGH","NORMAL")',
            '=VLOOKUP(RC[-4],C1:C4,4,FALSE)',
            '=SUMPRODUCT(RC[-4]:RC[-1],RC[-3]:RC[-2])+AVERAGE(RC[-4]:RC[-1])'
        )


        # ----------------------------------------------------
        # Force calculation
        # ----------------------------------------------------

        $CalcStart = Get-Date

        for ($Round = 1; $Round -le $ExcelRounds; $Round++) {

            $Excel.CalculateFullRebuild()

            Start-Sleep -Milliseconds 500

            $Sample = Get-SystemSample

            $MonitorData.Add($Sample)

            "$($Sample.Time),$($Sample.CPU),$($Sample.RAMUsed),$($Sample.RAMAvailable),$($Sample.Disk),$($Sample.Processes)" |
                Add-Content -LiteralPath $MonitorFile

            $MaxCPU = [math]::Max($MaxCPU,$Sample.CPU)
            $MaxRAMUsed = [math]::Max($MaxRAMUsed,$Sample.RAMUsed)
            $MinRAMAvailable = [math]::Min($MinRAMAvailable,$Sample.RAMAvailable)
            $MaxDisk = [math]::Max($MaxDisk,$Sample.Disk)
        }

        $CalcEnd = Get-Date

        $CalcDuration = (
            $CalcEnd - $CalcStart
        ).TotalSeconds

        $Sheet.Range("K1").Value2 = "Calculation Time"
        $Sheet.Range("K2").Value2 = $CalcDuration

        $FilePath = Join-Path `
            $ExcelFolder `
            "Excel-Benchmark-$FileIndex.xlsx"

        $Workbook.SaveAs($FilePath)

        $ExcelObjects += $Workbook

        # ----------------------------------------------------
        # Restore Screen Updating
        # ----------------------------------------------------

        $Excel.ScreenUpdating = $true
    }
}
else {

    Write-Host "Excel not available - skipping Excel test." `
        -ForegroundColor Yellow
}


# ============================================================
# WORD WORKLOAD
# ============================================================

$WordObjects = @()

if ($WordInstalled) {

    Write-Host ""
    Write-Host "Creating Word workload..." -ForegroundColor Cyan

    $Word = New-Object -ComObject Word.Application

    $Word.Visible = $true

    for ($FileIndex = 1; $FileIndex -le $WordFiles; $FileIndex++) {

        Write-Host "Creating Word document $FileIndex / $WordFiles"

        $Document = $Word.Documents.Add()

        $Selection = $Word.Selection

        for ($i = 1; $i -le 100; $i++) {

            $Selection.TypeText(
                "PC Multitasking Benchmark - Document $FileIndex - Paragraph $i. "
            )

            $Selection.TypeParagraph()
        }

        # Create tables
        for ($t = 1; $t -le 5; $t++) {

            $Table = $Document.Tables.Add(
                $Selection.Range,
                20,
                8
            )

            $Table.Style = "Table Grid"

            $Selection.EndKey(6)
            $Selection.TypeParagraph()
        }

        $FilePath = Join-Path `
            $WordFolder `
            "Word-Benchmark-$FileIndex.docx"

        $Document.SaveAs([ref]$FilePath)

        $WordObjects += $Document

        $Sample = Get-SystemSample

        $MonitorData.Add($Sample)

        "$($Sample.Time),$($Sample.CPU),$($Sample.RAMUsed),$($Sample.RAMAvailable),$($Sample.Disk),$($Sample.Processes)" |
            Add-Content -LiteralPath $MonitorFile

        $MaxCPU = [math]::Max($MaxCPU,$Sample.CPU)
        $MaxRAMUsed = [math]::Max($MaxRAMUsed,$Sample.RAMUsed)
        $MinRAMAvailable = [math]::Min($MinRAMAvailable,$Sample.RAMAvailable)
        $MaxDisk = [math]::Max($MaxDisk,$Sample.Disk)
    }
}
else {

    Write-Host "Word not available - skipping Word test." `
        -ForegroundColor Yellow
}


# ============================================================
# POWERPOINT WORKLOAD
# ============================================================

$PowerPointObjects = @()

if ($PowerPointInstalled) {

    Write-Host ""
    Write-Host "Creating PowerPoint workload..." -ForegroundColor Cyan

    $PowerPoint = New-Object -ComObject PowerPoint.Application

    $PowerPoint.Visible = $true

    for ($FileIndex = 1; $FileIndex -le $PowerPointFiles; $FileIndex++) {

        Write-Host "Creating PowerPoint $FileIndex / $PowerPointFiles"

        $Presentation = $PowerPoint.Presentations.Add()

        for ($SlideIndex = 1; $SlideIndex -le 30; $SlideIndex++) {

            $Slide = $Presentation.Slides.Add(
                $SlideIndex,
                12
            )

            $TextBox = $Slide.Shapes.AddTextbox(
                1,
                50,
                50,
                600,
                300
            )

            $TextBox.TextFrame.TextRange.Text =
                "PC MULTITASKING BENCHMARK`r`n`r`n" +
                "Presentation: $FileIndex`r`n" +
                "Slide: $SlideIndex`r`n" +
                "System workload simulation."

            # Add several shapes
            for ($ShapeIndex = 1; $ShapeIndex -le 10; $ShapeIndex++) {

                $Shape = $Slide.Shapes.AddShape(
                    1,
                    50 + ($ShapeIndex * 40),
                    400,
                    30,
                    30
                )

                $Shape.TextFrame.TextRange.Text =
                    "$ShapeIndex"
            }
        }

        $FilePath = Join-Path `
            $PptFolder `
            "PowerPoint-Benchmark-$FileIndex.pptx"

        $Presentation.SaveAs($FilePath)

        $PowerPointObjects += $Presentation

        $Sample = Get-SystemSample

        $MonitorData.Add($Sample)

        "$($Sample.Time),$($Sample.CPU),$($Sample.RAMUsed),$($Sample.RAMAvailable),$($Sample.Disk),$($Sample.Processes)" |
            Add-Content -LiteralPath $MonitorFile

        $MaxCPU = [math]::Max($MaxCPU,$Sample.CPU)
        $MaxRAMUsed = [math]::Max($MaxRAMUsed,$Sample.RAMUsed)
        $MinRAMAvailable = [math]::Min($MinRAMAvailable,$Sample.RAMAvailable)
        $MaxDisk = [math]::Max($MaxDisk,$Sample.Disk)
    }
}
else {

    Write-Host "PowerPoint not available - skipping PowerPoint test." `
        -ForegroundColor Yellow
}


# ============================================================
# MULTITASKING HOLD PHASE
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " MULTITASKING STABILITY PHASE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "All benchmark applications are now open."
Write-Host "System monitoring is running..."
Write-Host ""

# 60 seconds of real simultaneous workload monitoring
$HoldSeconds = 60

for ($Second = 1; $Second -le $HoldSeconds; $Second++) {

    $Sample = Get-SystemSample

    $MonitorData.Add($Sample)

    "$($Sample.Time),$($Sample.CPU),$($Sample.RAMUsed),$($Sample.RAMAvailable),$($Sample.Disk),$($Sample.Processes)" |
        Add-Content -LiteralPath $MonitorFile

    $MaxCPU = [math]::Max($MaxCPU,$Sample.CPU)
    $MaxRAMUsed = [math]::Max($MaxRAMUsed,$Sample.RAMUsed)
    $MinRAMAvailable = [math]::Min($MinRAMAvailable,$Sample.RAMAvailable)
    $MaxDisk = [math]::Max($MaxDisk,$Sample.Disk)

    $Remaining = $HoldSeconds - $Second

    Write-Progress `
        -Activity "Multitasking Stability Test" `
        -Status "$Remaining seconds remaining" `
        -PercentComplete (($Second / $HoldSeconds) * 100)

    Start-Sleep -Seconds $MonitorInterval
}

Write-Progress `
    -Activity "Multitasking Stability Test" `
    -Completed


# ============================================================
# FINAL SAMPLE
# ============================================================

$Sample = Get-SystemSample

$MonitorData.Add($Sample)

"$($Sample.Time),$($Sample.CPU),$($Sample.RAMUsed),$($Sample.RAMAvailable),$($Sample.Disk),$($Sample.Processes)" |
    Add-Content -LiteralPath $MonitorFile

$MaxCPU = [math]::Max($MaxCPU,$Sample.CPU)
$MaxRAMUsed = [math]::Max($MaxRAMUsed,$Sample.RAMUsed)
$MinRAMAvailable = [math]::Min($MinRAMAvailable,$Sample.RAMAvailable)
$MaxDisk = [math]::Max($MaxDisk,$Sample.Disk)


# ============================================================
# CALCULATE SCORES
# ============================================================

$EndTime = Get-Date

$TotalDuration = (
    $EndTime - $StartTime
).TotalSeconds


# ------------------------------------------------------------
# CPU SCORE
# ------------------------------------------------------------

if ($MaxCPU -lt 60) {
    $CPUScore = 100
}
elseif ($MaxCPU -lt 75) {
    $CPUScore = 90
}
elseif ($MaxCPU -lt 85) {
    $CPUScore = 80
}
elseif ($MaxCPU -lt 95) {
    $CPUScore = 65
}
else {
    $CPUScore = 50
}


# ------------------------------------------------------------
# RAM SCORE
# ------------------------------------------------------------

if ($MinRAMAvailable -ge 8) {
    $RAMScore = 100
}
elseif ($MinRAMAvailable -ge 6) {
    $RAMScore = 90
}
elseif ($MinRAMAvailable -ge 4) {
    $RAMScore = 80
}
elseif ($MinRAMAvailable -ge 2) {
    $RAMScore = 65
}
else {
    $RAMScore = 45
}


# ------------------------------------------------------------
# DISK SCORE
# ------------------------------------------------------------

if ($MaxDisk -lt 50) {
    $DiskScore = 100
}
elseif ($MaxDisk -lt 75) {
    $DiskScore = 90
}
elseif ($MaxDisk -lt 90) {
    $DiskScore = 75
}
elseif ($MaxDisk -lt 100) {
    $DiskScore = 60
}
else {
    $DiskScore = 45
}


# ------------------------------------------------------------
# MULTITASKING STABILITY SCORE
# ------------------------------------------------------------

$StabilityScore = 100

if ($MaxCPU -ge 95) {
    $StabilityScore -= 15
}

if ($MinRAMAvailable -lt 2) {
    $StabilityScore -= 25
}
elseif ($MinRAMAvailable -lt 4) {
    $StabilityScore -= 10
}

if ($MaxDisk -ge 100) {
    $StabilityScore -= 10
}

$StabilityScore = [math]::Max(
    0,
    $StabilityScore
)


# ------------------------------------------------------------
# APPLICATION SCORE
# ------------------------------------------------------------

$ApplicationScore = 100

if (-not $ExcelInstalled) {
    $ApplicationScore -= 20
}

if (-not $WordInstalled) {
    $ApplicationScore -= 10
}

if (-not $PowerPointInstalled) {
    $ApplicationScore -= 10
}

if (-not $ChromePath) {
    $ApplicationScore -= 10
}

$ApplicationScore = [math]::Max(
    0,
    $ApplicationScore
)


# ------------------------------------------------------------
# OVERALL SCORE
# ------------------------------------------------------------

$OverallScore = [math]::Round(
    (
        ($CPUScore * 0.25) +
        ($RAMScore * 0.30) +
        ($DiskScore * 0.15) +
        ($StabilityScore * 0.20) +
        ($ApplicationScore * 0.10)
    ),
    0
)


# ============================================================
# RATING
# ============================================================

if ($OverallScore -ge 95) {
    $Rating = "OUTSTANDING"
    $Assessment = "Excellent system for very heavy multitasking."
}
elseif ($OverallScore -ge 90) {
    $Rating = "EXCELLENT"
    $Assessment = "Very strong system for heavy multitasking."
}
elseif ($OverallScore -ge 80) {
    $Rating = "VERY GOOD"
    $Assessment = "System should handle heavy multitasking comfortably."
}
elseif ($OverallScore -ge 70) {
    $Rating = "GOOD"
    $Assessment = "System should handle normal multitasking well."
}
elseif ($OverallScore -ge 60) {
    $Rating = "FAIR"
    $Assessment = "Heavy multitasking may cause noticeable slowdowns."
}
else {
    $Rating = "WEAK"
    $Assessment = "Heavy multitasking is likely to cause significant slowdowns."
}


# ============================================================
# BOTTLENECK ANALYSIS
# ============================================================

$Bottleneck = "None detected"

if ($MinRAMAvailable -lt 2) {

    $Bottleneck = "RAM / Memory"

}
elseif ($MaxCPU -ge 95) {

    $Bottleneck = "CPU"

}
elseif ($MaxDisk -ge 95) {

    $Bottleneck = "Storage / Disk"

}
elseif ($MaxCPU -ge 85 -and $MinRAMAvailable -lt 4) {

    $Bottleneck = "CPU + RAM"

}


# ============================================================
# CREATE FINAL REPORT
# ============================================================

$Report = @"

============================================================
          PC REAL-WORLD MULTITASKING BENCHMARK
============================================================

TEST START:
$StartTime

TEST END:
$EndTime

TOTAL TEST TIME:
$([math]::Round($TotalDuration,2)) seconds


============================================================
SYSTEM
============================================================

Computer:
$($Computer.Manufacturer) $($Computer.Model)

CPU:
$CPUName

CPU Cores:
$CPUCores

CPU Threads:
$CPUThreads

RAM:
$TotalRAMGB GB

GPU:
$GPUName

Windows:
$WindowsVersion

Windows Build:
$WindowsBuild

Power Plan:
$PowerPlan


============================================================
WORKLOAD
============================================================

Chrome Tabs:
$ChromeTabs

Excel Workbooks:
$ExcelFiles

Excel Rows:
$ExcelRows

Excel Calculation Rounds:
$ExcelRounds

Word Documents:
$WordFiles

PowerPoint Presentations:
$PowerPointFiles


============================================================
RESOURCE RESULTS
============================================================

Maximum CPU Usage:
$([math]::Round($MaxCPU,2)) %

Maximum RAM Usage:
$([math]::Round($MaxRAMUsed,2)) %

Minimum Available RAM:
$MinRAMAvailable GB

Maximum Disk Activity:
$([math]::Round($MaxDisk,2)) %


============================================================
SCORES
============================================================

CPU Performance:
$CPUScore / 100

RAM Performance:
$RAMScore / 100

Disk Performance:
$DiskScore / 100

Multitasking Stability:
$StabilityScore / 100

Application Environment:
$ApplicationScore / 100


============================================================
FINAL RESULT
============================================================

OVERALL SCORE:
$OverallScore / 100

RATING:
$Rating

PRIMARY BOTTLENECK:
$Bottleneck


============================================================
FINAL ASSESSMENT
============================================================

$Assessment


============================================================
INTERPRETATION
============================================================

This benchmark represents a simultaneous workload containing:

- Multiple Chrome browser tabs
- Multiple Excel workbooks
- Heavy Excel calculations
- Multiple Word documents
- Multiple PowerPoint presentations

The score represents the system's ability to handle this
combined workload based primarily on CPU pressure, available
memory, disk pressure and multitasking stability.

A high score means the system should remain responsive while
multiple applications are open and actively processing data.

A low score indicates that one or more hardware resources are
likely to become a bottleneck during heavy multitasking.


============================================================
FILES
============================================================

System configuration:
$ConfigFile

Monitoring data:
$MonitorFile

Benchmark folder:
$BenchmarkFolder

============================================================

"@

$Report | Set-Content -LiteralPath $ReportFile -Encoding UTF8


# ============================================================
# FINAL SCREEN
# ============================================================

Write-Host ""
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                 BENCHMARK COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "CPU Score              : $CPUScore / 100"
Write-Host "RAM Score              : $RAMScore / 100"
Write-Host "Disk Score             : $DiskScore / 100"
Write-Host "Stability Score        : $StabilityScore / 100"
Write-Host "Application Score      : $ApplicationScore / 100"

Write-Host ""
Write-Host "------------------------------------------------------------"

Write-Host "OVERALL SCORE          : $OverallScore / 100" -ForegroundColor Green
Write-Host "RATING                 : $Rating" -ForegroundColor Green

Write-Host "------------------------------------------------------------"

Write-Host ""
Write-Host "Maximum CPU            : $([math]::Round($MaxCPU,2)) %"
Write-Host "Maximum RAM Usage      : $([math]::Round($MaxRAMUsed,2)) %"
Write-Host "Minimum RAM Available  : $MinRAMAvailable GB"
Write-Host "Maximum Disk Activity  : $([math]::Round($MaxDisk,2)) %"

Write-Host ""
Write-Host "Primary Bottleneck     : $Bottleneck" -ForegroundColor Yellow

Write-Host ""
Write-Host "FINAL ASSESSMENT:" -ForegroundColor Cyan
Write-Host $Assessment

Write-Host ""
Write-Host "Report:"
Write-Host $ReportFile

Write-Host ""
Write-Host "Monitoring CSV:"
Write-Host $MonitorFile

Write-Host ""
Write-Host "============================================================"
Write-Host ""


# ============================================================
# OPEN REPORT
# ============================================================

Start-Process notepad.exe $ReportFile
```

