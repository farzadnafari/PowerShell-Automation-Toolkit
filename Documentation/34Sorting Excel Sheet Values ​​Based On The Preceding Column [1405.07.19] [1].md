
> [!INFO] موتور مرتب‌سازی چندستونی و پویا در Excel
> محدوده فایل Excel ورودی و مسیر ذخیره فایل خروجی را به‌صورت پویا از کاربر دریافت می‌کند.
> ستون‌های ابتدا و انتهای محدوده مرتب‌سازی را از کاربر دریافت می‌کند.
> محدوده ردیف‌های موردنظر را مشخص کرده و داده‌ها را بر اساس تمام ستون‌های انتخاب‌شده مرتب می‌کند.
> مرتب‌سازی به‌صورت چندسطحی و با اولویت متوالی ستون اول تا آخرین ستون انتخاب‌شده انجام می‌شود.
> هنگام مرتب‌سازی، تمام سلول‌های هر ردیف به‌عنوان یک واحد یکپارچه جابه‌جا می‌شوند.
> ارتباط میان نام‌ها، شماره تلفن‌ها، مقادیر فارسی و انگلیسی، اعداد و سایر اطلاعات هر ردیف حفظ می‌شود.
> از محتوای متنی و عددی با قابلیت پردازش داده‌های فارسی و انگلیسی پشتیبانی می‌کند.
> برای اجرای عملیات مرتب‌سازی از Microsoft Excel و قابلیت‌های داخلی آن استفاده می‌کند.
> فایل مرتب‌شده را به‌صورت یک فایل Excel جدید ذخیره کرده و فایل اصلی را بدون تغییر حفظ می‌کند.


> [!INFO] Excel Dynamic Multi-Column Sort Engine
> Dynamically Retrieves The Input Excel File Path And The Output File Destination.
> Retrieves The Starting And Ending Columns Of The Selected Sorting Range.
> Defines The Target Row Range And Sorts Data Using All Selected Columns.
> Performs Multi-Level Sorting With Sequential Priority From The First Selected Column To The Last.
> Moves All Cells Within Each Row Together As A Single Integrated Unit During Sorting.
> Preserves Relationships Between Names, Phone Numbers, Persian And English Values, Numbers, And Other Row Data.
> Supports Textual And Numeric Content, Including Persian And English Data Processing.
> Uses Microsoft Excel And Its Built-In Capabilities To Perform The Sorting Operation.
> Saves The Sorted Results As A New Excel Workbook Without Modifying The Original Input File.


```
# ================================================================
# EXCEL DYNAMIC MULTI-COLUMN SORT ENGINE
# ================================================================
#
# Purpose:
#   Sort a selected Excel range using multi-level sorting.
#
# Sort logic:
#
#   Column 1
#       -> Column 2
#           -> Column 3
#               -> Column 4
#                   -> ...
#                       -> Last Selected Column
#
# Important:
#   The complete row is always moved as one unit.
#
#   Therefore:
#       Names
#       Phone numbers
#       Persian values
#       English values
#       Numbers
#       Categories
#       Descriptions
#       Any other cell values
#
#   remain attached to their original row.
#
# Features:
#   - Automatically requests Administrator privileges
#   - Automatically launches with ExecutionPolicy Bypass
#   - Dynamic input/output Excel paths
#   - Dynamic start/end columns
#   - Dynamic start/end rows
#   - Supports Persian and English cell contents
#   - Supports numeric and text values
#   - Creates a new output Excel file
#   - Does NOT modify the original input file
#
# Requirement:
#   Microsoft Excel must be installed on the computer.
#
# ================================================================


# ------------------------------------------------
# AUTO-ELEVATION TO ADMINISTRATOR
# ------------------------------------------------

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()

$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

$IsAdministrator = $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)


if (-not $IsAdministrator) {

    Write-Host ""
    Write-Host "Administrator privileges are required." -ForegroundColor Yellow
    Write-Host "Restarting PowerShell as Administrator..." -ForegroundColor Yellow
    Write-Host ""

    $ScriptPath = $MyInvocation.MyCommand.Path

    if ([string]::IsNullOrWhiteSpace($ScriptPath)) {

        Write-Host "ERROR: The script must be saved as a .ps1 file." -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }

    Start-Process `
        -FilePath "powershell.exe" `
        -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

    exit
}


# ------------------------------------------------
# FORCE EXECUTION POLICY BYPASS FOR CURRENT PROCESS
# ------------------------------------------------

Set-ExecutionPolicy `
    -Scope Process `
    -ExecutionPolicy Bypass `
    -Force


# ------------------------------------------------
# BASIC SETTINGS
# ------------------------------------------------

$ErrorActionPreference = "Stop"

$Excel = $null
$InputWorkbook = $null
$OutputWorkbook = $null


# ------------------------------------------------
# HELPER FUNCTION
# ------------------------------------------------

function Read-RequiredInput {

    param(
        [string]$Prompt
    )

    while ($true) {

        $Value = Read-Host $Prompt

        if (-not [string]::IsNullOrWhiteSpace($Value)) {

            return $Value.Trim()
        }

        Write-Host "Value cannot be empty." -ForegroundColor Red
    }
}


# ------------------------------------------------
# INTEGER INPUT FUNCTION
# ------------------------------------------------

function Read-PositiveInteger {

    param(
        [string]$Prompt
    )

    while ($true) {

        $Value = Read-Host $Prompt

        $Number = 0

        if ([int]::TryParse($Value, [ref]$Number)) {

            if ($Number -gt 0) {

                return $Number
            }
        }

        Write-Host "Please enter a valid positive integer." -ForegroundColor Red
    }
}


# ------------------------------------------------
# HEADER
# ------------------------------------------------

Clear-Host

Write-Host ""
Write-Host ("=" * 90)
Write-Host " EXCEL DYNAMIC MULTI-COLUMN SORT ENGINE ".PadLeft(61)
Write-Host ("=" * 90)
Write-Host ""

Write-Host "All selected columns will be sorted in hierarchical order."
Write-Host "The complete row will always remain together."
Write-Host ""


# ------------------------------------------------
# INPUT EXCEL PATH
# ------------------------------------------------

$InputPath = Read-RequiredInput "Enter INPUT Excel file path"


# ------------------------------------------------
# OUTPUT EXCEL PATH
# ------------------------------------------------

$OutputPath = Read-RequiredInput "Enter OUTPUT Excel file path"


# ------------------------------------------------
# START COLUMN
# ------------------------------------------------

$StartColumn = Read-PositiveInteger "Enter START COLUMN number"


# ------------------------------------------------
# END COLUMN
# ------------------------------------------------

$EndColumn = Read-PositiveInteger "Enter END COLUMN number"


# ------------------------------------------------
# START ROW
# ------------------------------------------------

$StartRow = Read-PositiveInteger "Enter START ROW number"


# ------------------------------------------------
# END ROW
# ------------------------------------------------

$EndRow = Read-PositiveInteger "Enter END ROW number"


# ------------------------------------------------
# VALIDATE COLUMN RANGE
# ------------------------------------------------

if ($EndColumn -lt $StartColumn) {

    Write-Host ""
    Write-Host "ERROR: END COLUMN cannot be smaller than START COLUMN." -ForegroundColor Red
    Write-Host ""

    Read-Host "Press Enter to exit"

    exit 1
}


# ------------------------------------------------
# VALIDATE ROW RANGE
# ------------------------------------------------

if ($EndRow -lt $StartRow) {

    Write-Host ""
    Write-Host "ERROR: END ROW cannot be smaller than START ROW." -ForegroundColor Red
    Write-Host ""

    Read-Host "Press Enter to exit"

    exit 1
}


# ------------------------------------------------
# VALIDATE EXCEL FILE EXTENSIONS
# ------------------------------------------------

$InputExtension = [System.IO.Path]::GetExtension($InputPath).ToLower()

$OutputExtension = [System.IO.Path]::GetExtension($OutputPath).ToLower()


if ($InputExtension -notin @(".xlsx", ".xlsm", ".xls")) {

    Write-Host ""
    Write-Host "ERROR: Input file must be an Excel file." -ForegroundColor Red
    Write-Host "Supported formats: .xlsx, .xlsm, .xls"
    Write-Host ""

    Read-Host "Press Enter to exit"

    exit 1
}


if ($OutputExtension -notin @(".xlsx", ".xlsm", ".xls")) {

    Write-Host ""
    Write-Host "ERROR: Output file must be an Excel file." -ForegroundColor Red
    Write-Host "Supported formats: .xlsx, .xlsm, .xls"
    Write-Host ""

    Read-Host "Press Enter to exit"

    exit 1
}


# ------------------------------------------------
# VALIDATE INPUT FILE
# ------------------------------------------------

if (-not (Test-Path -LiteralPath $InputPath)) {

    Write-Host ""
    Write-Host "ERROR: Input Excel file was not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Path:"
    Write-Host $InputPath
    Write-Host ""

    Read-Host "Press Enter to exit"

    exit 1
}


# ------------------------------------------------
# NORMALIZE PATHS
# ------------------------------------------------

$InputPath = [System.IO.Path]::GetFullPath($InputPath)

$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)


# ------------------------------------------------
# PREVENT OVERWRITING INPUT FILE
# ------------------------------------------------

if (
    [System.IO.Path]::GetFullPath($InputPath) -eq
    [System.IO.Path]::GetFullPath($OutputPath)
) {

    Write-Host ""
    Write-Host "ERROR: Input and output files cannot be the same." -ForegroundColor Red
    Write-Host ""

    Read-Host "Press Enter to exit"

    exit 1
}


# ------------------------------------------------
# CREATE OUTPUT DIRECTORY IF NECESSARY
# ------------------------------------------------

$OutputDirectory = Split-Path -Parent $OutputPath

if (-not (Test-Path -LiteralPath $OutputDirectory)) {

    New-Item `
        -ItemType Directory `
        -Path $OutputDirectory `
        -Force |
        Out-Null
}


# ------------------------------------------------
# DISPLAY CONFIGURATION
# ------------------------------------------------

Write-Host ""
Write-Host ("=" * 90)
Write-Host " SORT CONFIGURATION "
Write-Host ("=" * 90)
Write-Host ""

Write-Host "Input File       : $InputPath"
Write-Host "Output File      : $OutputPath"
Write-Host "Start Column     : $StartColumn"
Write-Host "End Column       : $EndColumn"
Write-Host "Start Row        : $StartRow"
Write-Host "End Row          : $EndRow"

$SelectedColumnCount = $EndColumn - $StartColumn + 1
$SelectedRowCount = $EndRow - $StartRow + 1

Write-Host "Selected Columns : $SelectedColumnCount"
Write-Host "Selected Rows    : $SelectedRowCount"

Write-Host ""
Write-Host ("=" * 90)
Write-Host ""


# ------------------------------------------------
# CONFIRM OPERATION
# ------------------------------------------------

$Confirmation = Read-Host "Continue with sorting? (Y/N)"

if ($Confirmation -notmatch "^[Yy]$") {

    Write-Host ""
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    Write-Host ""

    exit
}


# ------------------------------------------------
# START TIMER
# ------------------------------------------------

$StartTime = Get-Date


try {

    # ------------------------------------------------
    # START EXCEL
    # ------------------------------------------------

    Write-Host ""
    Write-Host "Starting Microsoft Excel..." -ForegroundColor Cyan

    $Excel = New-Object -ComObject Excel.Application

    $Excel.Visible = $false

    $Excel.DisplayAlerts = $false

    $Excel.ScreenUpdating = $false

    $Excel.EnableEvents = $false

    $Excel.AskToUpdateLinks = $false


    # ------------------------------------------------
    # OPEN INPUT WORKBOOK
    # ------------------------------------------------

    Write-Host "Opening input workbook..." -ForegroundColor Cyan

    $InputWorkbook = $Excel.Workbooks.Open(
        $InputPath,
        0,
        $true
    )


    # ------------------------------------------------
    # USE FIRST WORKSHEET
    # ------------------------------------------------
    #
    # If the data is located on another worksheet,
    # change this section to select that worksheet.
    #
    # ------------------------------------------------

    $InputWorksheet = $InputWorkbook.Worksheets.Item(1)


    Write-Host ""
    Write-Host "Worksheet selected:"
    Write-Host $InputWorksheet.Name
    Write-Host ""


    # ------------------------------------------------
    # CREATE OUTPUT WORKBOOK
    # ------------------------------------------------

    Write-Host "Creating output workbook..." -ForegroundColor Cyan

    $OutputWorkbook = $Excel.Workbooks.Add()

    $OutputWorksheet = $OutputWorkbook.Worksheets.Item(1)


    # ------------------------------------------------
    # COPY COMPLETE WORKSHEET
    # ------------------------------------------------
    #
    # This preserves the original row relationships.
    #
    # ------------------------------------------------

    Write-Host "Copying source worksheet..." -ForegroundColor Cyan

    $InputWorksheet.Cells.Copy(
        $OutputWorksheet.Cells
    )


    # ------------------------------------------------
    # DETERMINE SORT RANGE
    # ------------------------------------------------
    #
    # Example:
    #
    # Start Column = 1
    # End Column   = 13
    # Start Row    = 2
    # End Row      = 1000000
    #
    # Result:
    #
    # A2:M1000000
    #
    # ------------------------------------------------

    $StartCell = $OutputWorksheet.Cells.Item(
        $StartRow,
        $StartColumn
    )

    $EndCell = $OutputWorksheet.Cells.Item(
        $EndRow,
        $EndColumn
    )

    $SortRange = $OutputWorksheet.Range(
        $StartCell,
        $EndCell
    )


    # ------------------------------------------------
    # CREATE EXCEL SORT OBJECT
    # ------------------------------------------------

    Write-Host "Preparing multi-level sort..." -ForegroundColor Cyan

    $SortObject = $OutputWorksheet.Sort

    $SortObject.SortFields.Clear()


    # ------------------------------------------------
    # ADD EVERY SELECTED COLUMN AS A SORT LEVEL
    # ------------------------------------------------
    #
    # The first selected column has the highest priority.
    #
    # The second selected column is used only when
    # the first column contains equal values.
    #
    # This continues until the last selected column.
    #
    # ------------------------------------------------

    for ($Column = $StartColumn; $Column -le $EndColumn; $Column++) {

        $KeyCell = $OutputWorksheet.Cells.Item(
            $StartRow,
            $Column
        )

        $KeyRange = $OutputWorksheet.Range(
            $KeyCell,
            $OutputWorksheet.Cells.Item(
                $EndRow,
                $Column
            )
        )

        $SortObject.SortFields.Add(
            $KeyRange,
            0,
            1,
            $null,
            0
        ) | Out-Null


        Write-Host (
            "Added sort level: Column {0}" -f $Column
        )
    }


    # ------------------------------------------------
    # CONFIGURE SORT RANGE
    # ------------------------------------------------

    $SortObject.SetRange($SortRange)

    $SortObject.Header = 0

    $SortObject.MatchCase = $false

    $SortObject.Orientation = 1

    $SortObject.SortMethod = 1


    # ------------------------------------------------
    # EXECUTE SORT
    # ------------------------------------------------

    Write-Host ""
    Write-Host "Executing multi-level sort..." -ForegroundColor Cyan
    Write-Host ""

    $SortObject.Apply()


    Write-Host "Sort completed successfully." -ForegroundColor Green
    Write-Host ""


    # ------------------------------------------------
    # SAVE OUTPUT FILE
    # ------------------------------------------------

    Write-Host "Saving output workbook..." -ForegroundColor Cyan


    # ------------------------------------------------
    # XLSX FORMAT
    # ------------------------------------------------

    if ($OutputExtension -eq ".xlsx") {

        $OutputWorkbook.SaveAs(
            $OutputPath,
            51
        )
    }


    # ------------------------------------------------
    # XLSM FORMAT
    # ------------------------------------------------

    elseif ($OutputExtension -eq ".xlsm") {

        $OutputWorkbook.SaveAs(
            $OutputPath,
            52
        )
    }


    # ------------------------------------------------
    # XLS FORMAT
    # ------------------------------------------------

    elseif ($OutputExtension -eq ".xls") {

        $OutputWorkbook.SaveAs(
            $OutputPath,
            56
        )
    }


    Write-Host ""
    Write-Host "Output file saved successfully." -ForegroundColor Green
    Write-Host $OutputPath
    Write-Host ""


    # ------------------------------------------------
    # CLOSE WORKBOOKS
    # ------------------------------------------------

    $OutputWorkbook.Close($true)

    $InputWorkbook.Close($false)


    # ------------------------------------------------
    # RELEASE COM OBJECTS
    # ------------------------------------------------

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
        $SortObject
    ) | Out-Null

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
        $SortRange
    ) | Out-Null

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
        $OutputWorksheet
    ) | Out-Null

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
        $InputWorksheet
    ) | Out-Null

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
        $OutputWorkbook
    ) | Out-Null

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
        $InputWorkbook
    ) | Out-Null

    $OutputWorkbook = $null
    $InputWorkbook = $null


    # ------------------------------------------------
    # QUIT EXCEL
    # ------------------------------------------------

    $Excel.Quit()

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
        $Excel
    ) | Out-Null

    $Excel = $null


    # ------------------------------------------------
    # FORCE GARBAGE COLLECTION
    # ------------------------------------------------

    [GC]::Collect()

    [GC]::WaitForPendingFinalizers()


    # ------------------------------------------------
    # CALCULATE EXECUTION TIME
    # ------------------------------------------------

    $EndTime = Get-Date

    $ElapsedTime = $EndTime - $StartTime


    # ------------------------------------------------
    # FINAL REPORT
    # ------------------------------------------------

    Write-Host ""
    Write-Host ("=" * 90)
    Write-Host " SORT OPERATION COMPLETED ".PadLeft(60)
    Write-Host ("=" * 90)
    Write-Host ""

    Write-Host "Input File       : $InputPath"
    Write-Host "Output File      : $OutputPath"
    Write-Host "Start Column     : $StartColumn"
    Write-Host "End Column       : $EndColumn"
    Write-Host "Start Row        : $StartRow"
    Write-Host "End Row          : $EndRow"
    Write-Host "Columns Sorted   : $SelectedColumnCount"
    Write-Host "Rows Processed   : $SelectedRowCount"

    Write-Host ""

    Write-Host (
        "Execution Time   : {0:hh\:mm\:ss}" -f $ElapsedTime
    )

    Write-Host ""

    Write-Host "Important:" -ForegroundColor Green
    Write-Host "Each complete row was treated as one record." -ForegroundColor Green
    Write-Host "Values such as phone numbers remain attached to their original records." -ForegroundColor Green

    Write-Host ""
    Write-Host ("=" * 90)
    Write-Host ""

}
catch {

    # ------------------------------------------------
    # ERROR HANDLING
    # ------------------------------------------------

    Write-Host ""
    Write-Host ("=" * 90)
    Write-Host " ERROR ".PadLeft(48)
    Write-Host ("=" * 90)
    Write-Host ""

    Write-Host $_.Exception.Message -ForegroundColor Red

    Write-Host ""

    # ------------------------------------------------
    # CLEANUP AFTER ERROR
    # ------------------------------------------------

    try {

        if ($OutputWorkbook -ne $null) {

            $OutputWorkbook.Close($false)
        }

    }
    catch {}


    try {

        if ($InputWorkbook -ne $null) {

            $InputWorkbook.Close($false)
        }

    }
    catch {}


    try {

        if ($Excel -ne $null) {

            $Excel.Quit()
        }

    }
    catch {}


    # ------------------------------------------------
    # RELEASE OBJECTS
    # ------------------------------------------------

    try {

        if ($OutputWorkbook -ne $null) {

            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
                $OutputWorkbook
            ) | Out-Null
        }

    }
    catch {}


    try {

        if ($InputWorkbook -ne $null) {

            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
                $InputWorkbook
            ) | Out-Null
        }

    }
    catch {}


    try {

        if ($Excel -ne $null) {

            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
                $Excel
            ) | Out-Null
        }

    }
    catch {}


    [GC]::Collect()

    [GC]::WaitForPendingFinalizers()


    Write-Host ""
    Write-Host "The operation was not completed." -ForegroundColor Red
    Write-Host ""

}


# ------------------------------------------------
# FINAL PAUSE
# ------------------------------------------------

Write-Host ""
Read-Host "Press Enter to exit"
```

