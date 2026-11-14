
> [!INFO] تبدیل اطلاعات اکسل به مخاطبین VCF
> مسیر فایل Excel و محدوده داده‌های موردنظر را از کاربر دریافت می‌کند.
> ستون یا ستون‌های مربوط به نام را دریافت کرده و مقادیر آن‌ها را با یک فاصله ترکیب می‌کند.
> اطلاعات هر ردیف را به‌عنوان یک مخاطب مستقل در قالب استاندارد vCard پردازش می‌کند.
> نام ترکیب‌شده را در فیلد Given Name و همچنین FN به‌عنوان نام نمایشی مخاطب قرار می‌دهد.
> شماره تلفن را از ستون تعیین‌شده استخراج کرده و با نوع CELL ذخیره می‌کند.
> ردیف‌های فاقد نام را نادیده می‌گیرد و شماره تلفن‌های خالی را بدون ایجاد خطا می‌پذیرد.
> اطلاعات مخاطبین را به قالب VCF تبدیل کرده و خطوط طولانی را بدون شکستن حفظ می‌کند.
> فایل خروجی VCF را در کنار فایل Excel اصلی ایجاد می‌کند.
> این ابزار برای انتقال گروهی اطلاعات مخاطبین از Excel به تلفن همراه و نرم‌افزارهای مدیریت مخاطبین طراحی شده است.


> [!INFO] Excel To VCF Contact Generator
> Retrieves The Excel File Path And The Desired Data Range From The User.
> Accepts One Or Multiple First Name Columns And Combines Their Values Using A Single Space.
> Processes Each Data Row As An Independent Contact In The Standard vCard Format.
> Writes The Combined Name Into The Given Name Field And Also Uses It As The FN Display Name.
> Extracts The Phone Number From The Specified Column And Stores It With The CELL Type.
> Skips Rows Without First Names And Allows Empty Phone Numbers Without Generating Errors.
> Converts Contact Information Into VCF Format While Preserving Long Lines Without Folding.
> Creates The Output VCF File In The Same Directory As The Original Excel File.
> This Tool Is Designed For Bulk Transfer Of Excel Contact Data To Mobile Phones And Contact Management Applications.


```
# ==========================================================================================
# EXCEL TO VCF CONTACT GENERATOR
# ==========================================================================================
#
# Purpose:
#   Convert selected Excel rows into VCF contacts.
#
# Features:
#   - User-defined Excel file path
#   - User-defined data range
#   - User-defined First Name column range
#   - User-defined phone number column
#   - Multiple First Name columns are joined with one SPACE
#   - First Name is written to the vCard Given Name field
#   - First Name is also used as the FN display name
#   - Phone number is written as CELL
#   - Empty phone numbers are allowed and skipped
#   - Empty First Name cells are skipped
#   - Long vCard lines are NOT folded
#   - Output VCF is created next to the Excel file
#
# ==========================================================================================


Clear-Host

Write-Host "=========================================================================================="
Write-Host "EXCEL TO VCF CONTACT GENERATOR"
Write-Host "=========================================================================================="
Write-Host ""


# ------------------------------------------------------------------------------------------
# Excel File Path
# ------------------------------------------------------------------------------------------

$ExcelPath = Read-Host "Enter Excel file path"

if (-not (Test-Path -LiteralPath $ExcelPath)) {

    Write-Host ""
    Write-Host "ERROR: Excel file was not found." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}


# ------------------------------------------------------------------------------------------
# Excel Data Range
# ------------------------------------------------------------------------------------------

$ColumnFrom = Read-Host "Enter data start column number"
$ColumnTo   = Read-Host "Enter data end column number"

$RowFrom = Read-Host "Enter data start row number"
$RowTo   = Read-Host "Enter data end row number"


# ------------------------------------------------------------------------------------------
# First Name Column Range
# ------------------------------------------------------------------------------------------

$FirstNameColumnFrom = Read-Host "Enter First Name start column number"
$FirstNameColumnTo   = Read-Host "Enter First Name end column number"


# ------------------------------------------------------------------------------------------
# Phone Column
# ------------------------------------------------------------------------------------------

$PhoneColumn = Read-Host "Enter phone number column number"


# ------------------------------------------------------------------------------------------
# Validate Numeric Inputs
# ------------------------------------------------------------------------------------------

try {

    $ColumnFrom          = [int]$ColumnFrom
    $ColumnTo            = [int]$ColumnTo

    $RowFrom             = [int]$RowFrom
    $RowTo               = [int]$RowTo

    $FirstNameColumnFrom = [int]$FirstNameColumnFrom
    $FirstNameColumnTo   = [int]$FirstNameColumnTo

    $PhoneColumn         = [int]$PhoneColumn

}
catch {

    Write-Host ""
    Write-Host "ERROR: All column and row values must be numeric." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}


# ------------------------------------------------------------------------------------------
# Validate Range
# ------------------------------------------------------------------------------------------

if ($ColumnFrom -lt 1 -or
    $ColumnTo -lt $ColumnFrom -or
    $RowFrom -lt 1 -or
    $RowTo -lt $RowFrom -or
    $FirstNameColumnFrom -lt $ColumnFrom -or
    $FirstNameColumnTo -gt $ColumnTo -or
    $FirstNameColumnTo -lt $FirstNameColumnFrom -or
    $PhoneColumn -lt $ColumnFrom -or
    $PhoneColumn -gt $ColumnTo) {

    Write-Host ""
    Write-Host "ERROR: Invalid column or row range." -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}


# ------------------------------------------------------------------------------------------
# Output VCF Path
# ------------------------------------------------------------------------------------------

$ExcelDirectory = Split-Path -Parent $ExcelPath
$ExcelFileName  = [System.IO.Path]::GetFileNameWithoutExtension($ExcelPath)

$VcfPath = Join-Path $ExcelDirectory ($ExcelFileName + ".vcf")


# ------------------------------------------------------------------------------------------
# Display Settings
# ------------------------------------------------------------------------------------------

Write-Host ""
Write-Host "=========================================================================================="
Write-Host "SETTINGS"
Write-Host "=========================================================================================="
Write-Host ""

Write-Host "Excel File             : $ExcelPath"
Write-Host "Data Columns           : $ColumnFrom - $ColumnTo"
Write-Host "Data Rows              : $RowFrom - $RowTo"
Write-Host "First Name Columns     : $FirstNameColumnFrom - $FirstNameColumnTo"
Write-Host "Phone Column           : $PhoneColumn"
Write-Host "Output VCF             : $VcfPath"

Write-Host ""
Write-Host "=========================================================================================="
Write-Host ""


# ------------------------------------------------------------------------------------------
# Start Excel COM
# ------------------------------------------------------------------------------------------

$Excel     = $null
$Workbook  = $null
$Worksheet = $null

try {

    $Excel = New-Object -ComObject Excel.Application

    $Excel.Visible = $false
    $Excel.DisplayAlerts = $false

    $Workbook = $Excel.Workbooks.Open($ExcelPath)

    $Worksheet = $Workbook.Worksheets.Item(1)


    # --------------------------------------------------------------------------------------
    # Get Excel Cell Value
    # --------------------------------------------------------------------------------------

    function Get-CellText {

        param (
            $Worksheet,
            [int]$Row,
            [int]$Column
        )

        $Value = $Worksheet.Cells.Item($Row, $Column).Value2

        if ($null -eq $Value) {
            return ""
        }

        return ([string]$Value).Trim()
    }


    # --------------------------------------------------------------------------------------
    # Create VCF Content
    # --------------------------------------------------------------------------------------

    $VcfLines = New-Object System.Collections.Generic.List[string]

    $ContactCount = 0


    # --------------------------------------------------------------------------------------
    # Process Excel Rows
    # --------------------------------------------------------------------------------------

    for ($Row = $RowFrom; $Row -le $RowTo; $Row++) {


        # ----------------------------------------------------------------------
        # Build First Name
        # ----------------------------------------------------------------------

        $FirstNameParts = New-Object System.Collections.Generic.List[string]

        for (
            $Column = $FirstNameColumnFrom;
            $Column -le $FirstNameColumnTo;
            $Column++
        ) {

            $Value = Get-CellText `
                -Worksheet $Worksheet `
                -Row $Row `
                -Column $Column

            if (-not [string]::IsNullOrWhiteSpace($Value)) {

                $FirstNameParts.Add($Value)
            }
        }


        # ----------------------------------------------------------------------
        # Combine First Name Columns
        # ----------------------------------------------------------------------

        $FirstName = ($FirstNameParts -join " ").Trim()


        # ----------------------------------------------------------------------
        # Get Phone Number
        # ----------------------------------------------------------------------

        $PhoneNumber = Get-CellText `
            -Worksheet $Worksheet `
            -Row $Row `
            -Column $PhoneColumn


        # ----------------------------------------------------------------------
        # Skip Completely Empty Contact
        # ----------------------------------------------------------------------

        if (
            [string]::IsNullOrWhiteSpace($FirstName) -and
            [string]::IsNullOrWhiteSpace($PhoneNumber)
        ) {

            continue
        }


        # ----------------------------------------------------------------------
        # Create vCard
        # ----------------------------------------------------------------------

        $VcfLines.Add("BEGIN:VCARD")
        $VcfLines.Add("VERSION:3.0")


        # ----------------------------------------------------------------------
        # N Field
        #
        # vCard structure:
        #
        # N:Family Name;Given Name;Additional;Prefix;Suffix
        #
        # The complete selected First Name value is placed
        # inside the Given Name field.
        #
        # No line folding is applied.
        # ----------------------------------------------------------------------

        $NLine = "N:;$FirstName;;;"

        $VcfLines.Add($NLine)


        # ----------------------------------------------------------------------
        # FN Field
        #
        # The complete First Name value is used as the
        # formatted/display name.
        #
        # No line folding is applied.
        # ----------------------------------------------------------------------

        $FNLine = "FN:$FirstName"

        $VcfLines.Add($FNLine)


        # ----------------------------------------------------------------------
        # Phone Number
        #
        # Empty phone numbers are simply skipped.
        # ----------------------------------------------------------------------

        if (-not [string]::IsNullOrWhiteSpace($PhoneNumber)) {

            $PhoneLine = "TEL;TYPE=CELL:$PhoneNumber"

            $VcfLines.Add($PhoneLine)
        }


        # ----------------------------------------------------------------------
        # End vCard
        # ----------------------------------------------------------------------

        $VcfLines.Add("END:VCARD")


        $ContactCount++
    }


    # --------------------------------------------------------------------------------------
    # Save VCF
    # --------------------------------------------------------------------------------------
    #
    # UTF-8 encoding is used so Persian/Unicode names remain intact.
    #
    # The VCF is written with CRLF line endings.
    #
    # --------------------------------------------------------------------------------------

    $VcfContent = $VcfLines -join "`r`n"

    [System.IO.File]::WriteAllText(
        $VcfPath,
        $VcfContent,
        [System.Text.UTF8Encoding]::new($false)
    )


    # ------------------------------------------------------------------------------------------
    # Close Excel
    # ------------------------------------------------------------------------------------------

    $Workbook.Close($false)

    $Excel.Quit()


    # ------------------------------------------------------------------------------------------
    # Release COM Objects
    # ------------------------------------------------------------------------------------------

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Worksheet) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Workbook)  | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Excel)     | Out-Null

    $Worksheet = $null
    $Workbook  = $null
    $Excel     = $null


    # ------------------------------------------------------------------------------------------
    # Final Result
    # ------------------------------------------------------------------------------------------

    Write-Host ""
    Write-Host "=========================================================================================="
    Write-Host "PROCESS COMPLETED"
    Write-Host "=========================================================================================="
    Write-Host ""

    Write-Host "Contacts Created : $ContactCount"
    Write-Host "VCF File         : $VcfPath"

    Write-Host ""
    Write-Host "=========================================================================================="


}
catch {

    Write-Host ""
    Write-Host "=========================================================================================="
    Write-Host "ERROR"
    Write-Host "=========================================================================================="
    Write-Host ""

    Write-Host $_.Exception.Message -ForegroundColor Red

    Write-Host ""

    if ($Workbook) {
        try {
            $Workbook.Close($false)
        }
        catch {}
    }

    if ($Excel) {
        try {
            $Excel.Quit()
        }
        catch {}
    }
}


# ------------------------------------------------------------------------------------------
# Final Pause
# ------------------------------------------------------------------------------------------

Write-Host ""
Read-Host "Press Enter to exit"
```

