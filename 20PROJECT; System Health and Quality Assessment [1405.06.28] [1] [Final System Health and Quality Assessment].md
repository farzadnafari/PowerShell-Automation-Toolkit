
> [!INFO] ارزیابی نهایی سلامت و کیفیت سیستم ویندوز
> گزارش‌های نهایی ماژول‌های 01 تا 06 را برای تهیه یک ارزیابی جامع از وضعیت سلامت سیستم تجمیع می‌کند.
> فایل‌های JSON را به‌عنوان منبع اصلی اطلاعات ساختاریافته بررسی کرده و در صورت عدم دسترسی، از گزارش‌های TXT استفاده می‌کند.
> مشکلات و هشدارهای صریح ثبت‌شده در ماژول‌های قبلی را استخراج و دسته‌بندی می‌کند.
> از تشخیص اشتباه مشکلات بر اساس کلمات عمومی مانند ERROR، FAILED، REVIEW و WHEA جلوگیری می‌کند.
> رویدادهای صفر WHEA یا عناوین بخش‌های خطا را بدون وجود شواهد واقعی، مشکل سخت‌افزاری تلقی نمی‌کند.
> نتایج بررسی‌های ویندوز، سخت‌افزار، درایورها، پردازنده، کارت گرافیک و به‌روزرسانی‌ها را یکپارچه می‌کند.
> هیچ‌گونه بررسی سخت‌افزاری یا نرم‌افزاری جدیدی انجام نمی‌دهد و صرفاً گزارش‌های تولیدشده قبلی را می‌خواند.
> هیچ تنظیمی را تغییر نمی‌دهد، فایلی را حذف نمی‌کند و هیچ عملیات نصب، تعمیر یا به‌روزرسانی انجام نمی‌دهد.
> در نهایت گزارش جامع سلامت و کیفیت سیستم را در قالب فایل‌های TXT و JSON تولید می‌کند.


> [!INFO] Final Windows System Health And Quality Assessment
> Consolidates The Final Reports From Modules 01 Through 06 To Produce A Comprehensive Assessment Of System Health.
> Reads JSON Files As The Primary Source Of Structured Information And Uses TXT Reports As A Fallback When Necessary.
> Extracts And Categorizes Explicit Problems And Warnings Reported By Previous Modules.
> Prevents False Problem Detection Based On Generic Terms Such As ERROR, FAILED, REVIEW, And WHEA.
> Does Not Interpret Zero WHEA Events Or Error Section Headings As Actual Hardware Problems Without Supporting Evidence.
> Integrates Results From Windows, Hardware, Drivers, CPU, GPU, And Windows Update Assessments.
> Performs No New Hardware Or Software Diagnostics And Only Reads Previously Generated Reports.
> Does Not Modify Settings, Delete Files, Or Perform Installation, Repair, Or Update Operations.
> Finally Generates Comprehensive System Health And Quality Assessment Reports In TXT And JSON Formats.


```
# ==================================================================================================
# SYSTEM HEALTH AND QUALITY ASSESSMENT
# MODULE: 07 - FINAL SYSTEM HEALTH AND QUALITY ASSESSMENT
# VERSION: 3.0
#
# PURPOSE:
# Consolidates the final results of Modules 01 through 06.
#
# ARCHITECTURE:
# - Modules 01 through 06 are completely independent.
# - Module 07 does not perform hardware or Windows diagnostics.
# - Module 07 only reads the final TXT/JSON reports produced by Modules 01 through 06.
# - JSON is preferred as the primary structured source.
# - TXT is used only as a conservative fallback when JSON is unavailable or unreadable.
#
# IMPORTANT:
# - This module does not install, remove, modify, update, or repair anything.
# - Generic words such as ERROR, FAILED, REVIEW, or WHEA are NOT treated as problems by themselves.
# - Zero WHEA events are NOT a CPU problem.
# - A section title such as GRAPHICS DEVICE ERRORS is NOT a GPU problem by itself.
# - Only explicit Problems and Warnings reported by the previous modules are consolidated.
#
# OUTPUT:
# 07_Final_System_Health_and_Quality_Assessment.txt
# 07_Final_System_Health_and_Quality_Assessment.json
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# PROJECT IDENTITY
# --------------------------------------------------------------------------------------------------

$ProjectName = "System Health and Quality Assessment"
$ModuleName  = "07 - Final System Health and Quality Assessment"
$Version     = "3.0"

# --------------------------------------------------------------------------------------------------
# AUTO-ELEVATION
# --------------------------------------------------------------------------------------------------

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

if (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

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

$OutputTXT  = Join-Path $ProjectFolder "07_Final_System_Health_and_Quality_Assessment.txt"
$OutputJSON = Join-Path $ProjectFolder "07_Final_System_Health_and_Quality_Assessment.json"

# --------------------------------------------------------------------------------------------------
# SYSTEM IDENTIFICATION
# --------------------------------------------------------------------------------------------------

$OS = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$ComputerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue

$ComputerName = $env:COMPUTERNAME
$Manufacturer = if ($ComputerSystem) { $ComputerSystem.Manufacturer } else { "Unknown" }
$Model        = if ($ComputerSystem) { $ComputerSystem.Model } else { "Unknown" }
$OperatingSys = if ($OS) { $OS.Caption } else { "Unknown" }
$OSVersion    = if ($OS) { $OS.Version } else { "Unknown" }
$OSBuild      = if ($OS) { $OS.BuildNumber } else { "Unknown" }

$Generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# --------------------------------------------------------------------------------------------------
# MODULE DEFINITIONS
#
# IMPORTANT:
# These filenames match the actual filenames produced by the independent modules.
# --------------------------------------------------------------------------------------------------

$Modules = @(
    [PSCustomObject]@{
        Number = 1
        Name = "System Identification"
        TXT  = "01_System_Identification.txt"
        JSON = "01_System_Identification.json"
    }

    [PSCustomObject]@{
        Number = 2
        Name = "Windows Standard and Activation Validation"
        TXT  = "02_Windows_Standard_and_Activation_Validation.txt"
        JSON = "02_Windows_Standard_and_Activation_Validation.json"
    }

    [PSCustomObject]@{
        Number = 3
        Name = "Windows Update and KB Validation"
        TXT  = "03_Windows_Update_and_KB_Validation.txt"
        JSON = "03_Windows_Update_and_KB_Validation.json"
    }

    [PSCustomObject]@{
        Number = 4
        Name = "Hardware Device and Driver Validation"
        TXT  = "04_Hardware_Device_and_Driver_Validation.txt"
        JSON = "04_Hardware_Device_and_Driver_Validation.json"
    }

    [PSCustomObject]@{
        Number = 5
        Name = "CPU Status, Power, Capability and Health Validation"
        TXT  = "05_CPU_Status_Power_Capability_and_Health_Validation.txt"
        JSON = "05_CPU_Status_Power_Capability_and_Health_Validation.json"
    }

    [PSCustomObject]@{
        Number = 6
        Name = "GPU Status, Power, Capability and Health Validation"
        TXT  = "06_GPU_Status_Power_Capability_and_Health_Validation.txt"
        JSON = "06_GPU_Status_Power_Capability_and_Health_Validation.json"
    }
)

# --------------------------------------------------------------------------------------------------
# STORAGE
# --------------------------------------------------------------------------------------------------

$ModuleResults = @()
$AllProblems = @()
$AllWarnings = @()
$MissingModules = @()

# --------------------------------------------------------------------------------------------------
# HELPER FUNCTION
# --------------------------------------------------------------------------------------------------

function Add-AssessmentItem {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $true)]
        [string]$Severity,

        [Parameter(Mandatory = $true)]
        [string]$Issue,

        [Parameter(Mandatory = $true)]
        [string]$Evidence
    )

    [PSCustomObject]@{
        Module   = $ModuleName
        Severity = $Severity
        Issue    = $Issue
        Evidence = $Evidence
    }
}

# --------------------------------------------------------------------------------------------------
# READ MODULE REPORTS
# --------------------------------------------------------------------------------------------------

foreach ($Module in $Modules) {

    $TXTPath  = Join-Path $ProjectFolder $Module.TXT
    $JSONPath = Join-Path $ProjectFolder $Module.JSON

    $TXTFound  = Test-Path -LiteralPath $TXTPath
    $JSONFound = Test-Path -LiteralPath $JSONPath

    $Status = "MISSING"

    $Problems = @()
    $Warnings = @()

    $JSONReadable = $false

    # ----------------------------------------------------------------------------------------------
    # JSON PRIMARY SOURCE
    # ----------------------------------------------------------------------------------------------

    if ($JSONFound) {

        try {

            $RawJSON = Get-Content -LiteralPath $JSONPath -Raw -ErrorAction Stop
            $ReportJSON = $RawJSON | ConvertFrom-Json -ErrorAction Stop

            $JSONReadable = $true

            # --------------------------------------------------------------------------------------
            # Explicit Problems
            # --------------------------------------------------------------------------------------

            if ($null -ne $ReportJSON.Problems) {

                foreach ($Problem in @($ReportJSON.Problems)) {

                    if ($Problem -is [string]) {
                        if (-not [string]::IsNullOrWhiteSpace($Problem)) {
                            $Problems += $Problem
                        }
                    }
                    else {
                        $Problems += ($Problem | Out-String).Trim()
                    }
                }
            }

            # --------------------------------------------------------------------------------------
            # Explicit Warnings
            # --------------------------------------------------------------------------------------

            if ($null -ne $ReportJSON.Warnings) {

                foreach ($Warning in @($ReportJSON.Warnings)) {

                    if ($Warning -is [string]) {
                        if (-not [string]::IsNullOrWhiteSpace($Warning)) {
                            $Warnings += $Warning
                        }
                    }
                    else {
                        $Warnings += ($Warning | Out-String).Trim()
                    }
                }
            }

            # --------------------------------------------------------------------------------------
            # Determine module status
            # --------------------------------------------------------------------------------------

            if ($Problems.Count -gt 0) {
                $Status = "PROBLEM"
            }
            elseif ($Warnings.Count -gt 0) {
                $Status = "REVIEW REQUIRED"
            }
            elseif ($ReportJSON.OverallStatus) {
                $Status = [string]$ReportJSON.OverallStatus
            }
            else {
                $Status = "COMPLETED"
            }
        }
        catch {

            $JSONReadable = $false
        }
    }

    # ----------------------------------------------------------------------------------------------
    # TXT FALLBACK
    #
    # Only used when JSON is unavailable or unreadable.
    # Only explicit PROBLEMS and WARNINGS sections are parsed.
    # Generic words elsewhere in the TXT are ignored.
    # ----------------------------------------------------------------------------------------------

    if (-not $JSONReadable -and $TXTFound) {

        try {

            $Lines = Get-Content -LiteralPath $TXTPath -ErrorAction Stop

            $CurrentSection = ""

            foreach ($Line in $Lines) {

                $Trimmed = $Line.Trim()

                if ($Trimmed -match "^PROBLEMS$") {
                    $CurrentSection = "PROBLEMS"
                    continue
                }

                if ($Trimmed -match "^WARNINGS$") {
                    $CurrentSection = "WARNINGS"
                    continue
                }

                if ($Trimmed -match "^[A-Z0-9 _-]{3,}$") {

                    if (
                        $Trimmed -ne "PROBLEMS" -and
                        $Trimmed -ne "WARNINGS"
                    ) {
                        $CurrentSection = ""
                    }
                }

                if ($CurrentSection -eq "PROBLEMS") {

                    if ($Trimmed -match "^\d+\.\s+(.+)$") {
                        $Problems += $Matches[1].Trim()
                    }
                }

                if ($CurrentSection -eq "WARNINGS") {

                    if ($Trimmed -match "^\d+\.\s+(.+)$") {
                        $Warnings += $Matches[1].Trim()
                    }
                }
            }

            if ($Problems.Count -gt 0) {
                $Status = "PROBLEM"
            }
            elseif ($Warnings.Count -gt 0) {
                $Status = "REVIEW REQUIRED"
            }
            else {
                $Status = "COMPLETED"
            }
        }
        catch {

            $Status = "UNREADABLE"
        }
    }

    # ----------------------------------------------------------------------------------------------
    # MISSING MODULE
    # ----------------------------------------------------------------------------------------------

    if (-not $TXTFound -and -not $JSONFound) {

        $Status = "MISSING"

        $MissingModules += $Module
    }

    # ----------------------------------------------------------------------------------------------
    # CONSOLIDATE EXPLICIT PROBLEMS
    # ----------------------------------------------------------------------------------------------

    foreach ($Problem in $Problems) {

        if (-not [string]::IsNullOrWhiteSpace($Problem)) {

            $AllProblems += Add-AssessmentItem `
                -ModuleName $Module.Name `
                -Severity "PROBLEM" `
                -Issue $Problem `
                -Evidence "Explicitly reported by Module $($Module.Number) report."
        }
    }

    # ----------------------------------------------------------------------------------------------
    # CONSOLIDATE EXPLICIT WARNINGS
    # ----------------------------------------------------------------------------------------------

    foreach ($Warning in $Warnings) {

        if (-not [string]::IsNullOrWhiteSpace($Warning)) {

            $AllWarnings += Add-AssessmentItem `
                -ModuleName $Module.Name `
                -Severity "REVIEW" `
                -Issue $Warning `
                -Evidence "Explicitly reported by Module $($Module.Number) report."
        }
    }

    # ----------------------------------------------------------------------------------------------
    # MODULE RESULT
    # ----------------------------------------------------------------------------------------------

    $ModuleResults += [PSCustomObject]@{
        Number     = $Module.Number
        Name       = $Module.Name
        TXTFound   = $TXTFound
        JSONFound  = $JSONFound
        Status     = $Status
        Problems   = $Problems.Count
        Warnings   = $Warnings.Count
    }
}

# --------------------------------------------------------------------------------------------------
# FINAL ASSESSMENT LOGIC
# --------------------------------------------------------------------------------------------------

if ($MissingModules.Count -gt 0) {

    $FinalStatus = "INCOMPLETE"

}
elseif ($AllProblems.Count -gt 0) {

    $FinalStatus = "REVIEW REQUIRED"

}
elseif ($AllWarnings.Count -gt 0) {

    $FinalStatus = "PASS WITH WARNINGS"

}
else {

    $FinalStatus = "EXCELLENT"
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
$Report.Add("Operating Sys : $OperatingSys")
$Report.Add("OS Version    : $OSVersion")
$Report.Add("OS Build      : $OSBuild")
$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("MODULE REPORT STATUS")
$Report.Add("==================================================================================")

foreach ($Result in $ModuleResults) {

    $TXTStatus  = if ($Result.TXTFound) { "FOUND" } else { "MISSING" }
    $JSONStatus = if ($Result.JSONFound) { "FOUND" } else { "MISSING" }

    $Report.Add(
        "Module $($Result.Number) | $($Result.Name) | TXT: $TXTStatus | JSON: $JSONStatus | STATUS: $($Result.Status)"
    )
}

$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("FINAL ASSESSMENT")
$Report.Add("==================================================================================")
$Report.Add("FINAL STATUS: $FinalStatus")
$Report.Add("")

if ($FinalStatus -eq "INCOMPLETE") {

    $Report.Add("The final assessment cannot be considered complete.")
    $Report.Add("One or more required assessment modules are missing.")
    $Report.Add("Run the missing module(s) before treating the final assessment as complete.")

}
elseif ($FinalStatus -eq "REVIEW REQUIRED") {

    $Report.Add("All required modules are present.")
    $Report.Add("One or more explicit problems were reported by the assessment modules.")
    $Report.Add("Review the actionable problems listed below.")

}
elseif ($FinalStatus -eq "PASS WITH WARNINGS") {

    $Report.Add("All required modules are present.")
    $Report.Add("No explicit problems were reported.")
    $Report.Add("One or more warnings or review items were reported.")

}
else {

    $Report.Add("All required modules are present.")
    $Report.Add("No explicit problems or warnings were reported.")
    $Report.Add("Overall assessment: EXCELLENT.")
}

$Report.Add("")

# --------------------------------------------------------------------------------------------------
# MISSING MODULES
# --------------------------------------------------------------------------------------------------

if ($MissingModules.Count -gt 0) {

    $Report.Add("==================================================================================")
    $Report.Add("MISSING MODULES")
    $Report.Add("==================================================================================")

    $Index = 1

    foreach ($Module in $MissingModules) {

        $TXTPath  = Join-Path $ProjectFolder $Module.TXT
        $JSONPath = Join-Path $ProjectFolder $Module.JSON

        $Report.Add("$Index. Module $($Module.Number) - $($Module.Name)")
        $Report.Add("   Expected TXT : $TXTPath")
        $Report.Add("   Expected JSON: $JSONPath")

        $Index++
    }

    $Report.Add("")
}

# --------------------------------------------------------------------------------------------------
# ACTIONABLE PROBLEMS
# --------------------------------------------------------------------------------------------------

$Report.Add("==================================================================================")
$Report.Add("ACTIONABLE PROBLEMS")
$Report.Add("==================================================================================")

if ($AllProblems.Count -eq 0) {

    $Report.Add("No explicit problems were reported by Modules 01 through 06.")

}
else {

    $Index = 1

    foreach ($Problem in $AllProblems) {

        $Report.Add("$Index. MODULE - $($Problem.Module)")
        $Report.Add("   Severity : $($Problem.Severity)")
        $Report.Add("   Issue    : $($Problem.Issue)")
        $Report.Add("   Evidence : $($Problem.Evidence)")
        $Report.Add("")

        $Index++
    }
}

$Report.Add("")

# --------------------------------------------------------------------------------------------------
# REVIEW WARNINGS
# --------------------------------------------------------------------------------------------------

$Report.Add("==================================================================================")
$Report.Add("REVIEW WARNINGS")
$Report.Add("==================================================================================")

if ($AllWarnings.Count -eq 0) {

    $Report.Add("No explicit warnings were reported by Modules 01 through 06.")

}
else {

    $Index = 1

    foreach ($Warning in $AllWarnings) {

        $Report.Add("$Index. MODULE - $($Warning.Module)")
        $Report.Add("   Severity : $($Warning.Severity)")
        $Report.Add("   Issue    : $($Warning.Issue)")
        $Report.Add("   Evidence : $($Warning.Evidence)")
        $Report.Add("")

        $Index++
    }
}

$Report.Add("")

# --------------------------------------------------------------------------------------------------
# STAGE-BY-STAGE SUMMARY
# --------------------------------------------------------------------------------------------------

$Report.Add("==================================================================================")
$Report.Add("STAGE-BY-STAGE SUMMARY")
$Report.Add("==================================================================================")

foreach ($Result in $ModuleResults) {

    $Report.Add(
        "Module $($Result.Number) - $($Result.Name) : $($Result.Status)"
    )
}

$Report.Add("")

# --------------------------------------------------------------------------------------------------
# NEXT ACTION
# --------------------------------------------------------------------------------------------------

$Report.Add("==================================================================================")
$Report.Add("NEXT ACTION")
$Report.Add("==================================================================================")

if ($MissingModules.Count -gt 0) {

    $Index = 1

    foreach ($Module in $MissingModules) {

        $Report.Add(
            "$Index. Run Module $($Module.Number) - $($Module.Name)."
        )

        $Index++
    }

    $Report.Add(
        "$Index. After all missing modules are completed, run Module 07 again."
    )
}
elseif ($AllProblems.Count -gt 0) {

    $Index = 1

    foreach ($Problem in $AllProblems) {

        $Report.Add(
            "$Index. Review Module - $($Problem.Module): $($Problem.Issue)"
        )

        $Index++
    }

}
elseif ($AllWarnings.Count -gt 0) {

    $Report.Add("No explicit problems were reported.")
    $Report.Add("Review the warning items if necessary.")

}
else {

    $Report.Add("No corrective action is currently indicated by Modules 01 through 06.")
    $Report.Add("The assessment result is EXCELLENT.")
}

$Report.Add("")

# --------------------------------------------------------------------------------------------------
# IMPORTANT INTERPRETATION
# --------------------------------------------------------------------------------------------------

$Report.Add("==================================================================================")
$Report.Add("IMPORTANT INTERPRETATION")
$Report.Add("==================================================================================")
$Report.Add("Module 07 is a consolidated assessment of Modules 01 through 06.")
$Report.Add("Modules 01 through 06 remain independent diagnostic modules.")
$Report.Add("Module 07 does not repeat their diagnostic work.")
$Report.Add("JSON Problems and Warnings fields are preferred as structured evidence.")
$Report.Add("TXT is used only as a conservative fallback when JSON is unavailable or unreadable.")
$Report.Add("Zero-valued telemetry is not automatically considered a problem.")
$Report.Add("For example, zero WHEA events does not represent a CPU hardware error.")
$Report.Add("Generic words such as ERROR, REVIEW, FAILED, or WHEA are not independently treated as problems.")
$Report.Add("A section title alone is not considered evidence of a hardware or software failure.")
$Report.Add("An EXCELLENT result does not mathematically prove that every physical component is perfect.")
$Report.Add("CPU and GPU physical health cannot be completely proven by Windows software telemetry alone.")
$Report.Add("")

# --------------------------------------------------------------------------------------------------
# REPORT FILES
# --------------------------------------------------------------------------------------------------

$Report.Add("==================================================================================")
$Report.Add("REPORT FILES")
$Report.Add("==================================================================================")
$Report.Add("TXT Report : $OutputTXT")
$Report.Add("JSON Report: $OutputJSON")
$Report.Add("")

$Report.Add("==================================================================================")
$Report.Add("END OF MODULE 07")
$Report.Add("==================================================================================")

# --------------------------------------------------------------------------------------------------
# SAVE TXT REPORT
# --------------------------------------------------------------------------------------------------

try {

    $Report | Set-Content -LiteralPath $OutputTXT -Encoding UTF8 -Force

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
        ComputerName = $ComputerName
        Manufacturer = $Manufacturer
        Model        = $Model
        OperatingSystem = $OperatingSys
        OSVersion    = $OSVersion
        OSBuild      = $OSBuild
    }

    FinalStatus = $FinalStatus

    Modules = $ModuleResults

    MissingModules = $MissingModules | ForEach-Object {
        [PSCustomObject]@{
            Number = $_.Number
            Name   = $_.Name
            TXT    = $_.TXT
            JSON   = $_.JSON
        }
    }

    Problems = $AllProblems

    Warnings = $AllWarnings

    Interpretation = @(
        "Module 07 consolidates Modules 01 through 06.",
        "Modules 01 through 06 remain independent.",
        "JSON Problems and Warnings are preferred as structured evidence.",
        "TXT is used only as a conservative fallback.",
        "Generic diagnostic words are not independently treated as problems.",
        "Zero WHEA events are not treated as a CPU hardware error.",
        "Section titles alone are not treated as evidence of failure.",
        "An EXCELLENT result does not mathematically prove perfect physical hardware health."
    )

    ReportFiles = [PSCustomObject]@{
        TXT  = $OutputTXT
        JSON = $OutputJSON
    }
}

try {

    $JSONReport |
        ConvertTo-Json -Depth 10 |
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
Write-Host "MODULE: 07 - FINAL SYSTEM HEALTH AND QUALITY ASSESSMENT" -ForegroundColor Cyan
Write-Host "VERSION: $Version" -ForegroundColor Cyan
Write-Host "==================================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Final Status: $FinalStatus" -ForegroundColor Yellow
Write-Host ""

Write-Host "Module Status:" -ForegroundColor White

foreach ($Result in $ModuleResults) {

    Write-Host (
        "Module {0} - {1} : {2}" -f
        $Result.Number,
        $Result.Name,
        $Result.Status
    )
}

Write-Host ""

Write-Host "Explicit Problems : $($AllProblems.Count)" -ForegroundColor White
Write-Host "Explicit Warnings : $($AllWarnings.Count)" -ForegroundColor White
Write-Host "Missing Modules   : $($MissingModules.Count)" -ForegroundColor White

Write-Host ""
Write-Host "TXT Report :" -ForegroundColor White
Write-Host $OutputTXT -ForegroundColor Gray

Write-Host ""
Write-Host "JSON Report:" -ForegroundColor White
Write-Host $OutputJSON -ForegroundColor Gray

Write-Host ""
Write-Host "Module 07 completed." -ForegroundColor Green
Write-Host ""

# --------------------------------------------------------------------------------------------------
# THREE SEPARATE ENTER PRESSES
# --------------------------------------------------------------------------------------------------

Read-Host "Press Enter (1/3)"
Read-Host "Press Enter (2/3)"
Read-Host "Press Enter (3/3)"

# ==================================================================================================
# END
# ==================================================================================================
```

