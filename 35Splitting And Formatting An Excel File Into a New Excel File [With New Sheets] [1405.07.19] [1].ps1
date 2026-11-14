# ==========================================================================================
#                         EXCEL CATEGORY SPLITTER ENGINE
# ==========================================================================================
#
# Purpose:
#   Split an Excel worksheet into separate worksheets based on unique category values.
#
# Features:
#   - Select source worksheet by numeric index.
#   - Select source data range dynamically.
#   - Select category column dynamically.
#   - Select category detection start row dynamically.
#   - Copy a configurable header range to every output worksheet.
#   - Preserve complete rows as single records.
#   - Preserve empty cells.
#   - Preserve Excel formatting from the source worksheet.
#   - Preserve:
#       * Fonts
#       * Font sizes
#       * Font styles
#       * Font colors
#       * Cell fills
#       * Borders
#       * Alignment
#       * Number formats
#       * Column widths
#       * Row heights
#       * Hidden rows/columns where applicable
#       * Merged cells inside the copied header range
#   - Create one worksheet per unique category.
#   - Sort category names alphabetically.
#   - Automatically generate valid and unique Excel worksheet names.
#   - Save the final workbook as XLSX.
#
# ==========================================================================================


# ==========================================================================================
# ADMINISTRATOR CHECK
# ==========================================================================================

$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)

if (-not $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {

    Write-Host ""
    Write-Host "Administrator privileges are required."
    Write-Host "Restarting PowerShell as Administrator..."
    Write-Host ""

    $scriptPath = $MyInvocation.MyCommand.Definition

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`""

    exit
}


# ==========================================================================================
# EXECUTION POLICY
# ==========================================================================================

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force


# ==========================================================================================
# HELPER FUNCTION - COLUMN NUMBER TO LETTER
# ==========================================================================================

function Convert-ColumnNumberToLetter {

    param(
        [int]$ColumnNumber
    )

    $result = ""

    while ($ColumnNumber -gt 0) {

        $remainder = ($ColumnNumber - 1) % 26

        $result = [char](65 + $remainder) + $result

        $ColumnNumber = [math]::Floor(
            ($ColumnNumber - 1) / 26
        )
    }

    return $result
}


# ==========================================================================================
# HELPER FUNCTION - GENERATE SAFE WORKSHEET NAME
# ==========================================================================================

function Get-SafeWorksheetName {

    param(
        [string]$Name,
        $Workbook
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {

        $Name = "EMPTY_CATEGORY"
    }

    # Remove invalid Excel worksheet-name characters.
    $SafeName = $Name -replace '[\\\/\?\*\[\]\:]', '_'

    # Remove control characters.
    $SafeName = $SafeName -replace '[\x00-\x1F]', '_'

    $SafeName = $SafeName.Trim()

    if ([string]::IsNullOrWhiteSpace($SafeName)) {

        $SafeName = "EMPTY_CATEGORY"
    }

    # Excel worksheet names cannot exceed 31 characters.
    if ($SafeName.Length -gt 31) {

        $SafeName = $SafeName.Substring(0, 31)
    }

    $BaseName = $SafeName
    $Counter = 1

    while ($true) {

        $Exists = $false

        foreach ($ExistingSheet in $Workbook.Worksheets) {

            if ($ExistingSheet.Name -eq $SafeName) {

                $Exists = $true
                break
            }
        }

        if (-not $Exists) {

            return $SafeName
        }

        $Suffix = " ($Counter)"

        $MaximumBaseLength = 31 - $Suffix.Length

        if ($BaseName.Length -gt $MaximumBaseLength) {

            $SafeName = $BaseName.Substring(
                0,
                $MaximumBaseLength
            ) + $Suffix
        }
        else {

            $SafeName = $BaseName + $Suffix
        }

        $Counter++
    }
}


# ==========================================================================================
# HEADER
# ==========================================================================================

Clear-Host

Write-Host "=========================================================================================="
Write-Host "                           EXCEL CATEGORY SPLITTER ENGINE"
Write-Host "=========================================================================================="
Write-Host ""
Write-Host "Each unique category will become a separate worksheet."
Write-Host "Complete rows will remain together."
Write-Host "The selected header range will be copied to every output worksheet."
Write-Host "Source worksheet formatting will be preserved."
Write-Host ""


# ==========================================================================================
# USER INPUT
# ==========================================================================================

$InputPath = Read-Host "Enter INPUT Excel file path"
$OutputPath = Read-Host "Enter OUTPUT Excel file path"

$WorksheetIndex = [int](
    Read-Host "Enter SOURCE WORKSHEET number"
)

$StartColumn = [int](
    Read-Host "Enter START COLUMN number"
)

$EndColumn = [int](
    Read-Host "Enter END COLUMN number"
)

$StartRow = [int](
    Read-Host "Enter START ROW number"
)

$EndRow = [int](
    Read-Host "Enter END ROW number"
)

$CategoryColumn = [int](
    Read-Host "Enter CATEGORY COLUMN number"
)

$CategoryStartRow = [int](
    Read-Host "Enter CATEGORY START ROW number"
)

$HeaderStartRow = [int](
    Read-Host "Enter HEADER START ROW number"
)

$HeaderEndRow = [int](
    Read-Host "Enter HEADER END ROW number"
)


# ==========================================================================================
# INPUT VALIDATION
# ==========================================================================================

if (-not (Test-Path $InputPath)) {

    Write-Host ""
    Write-Host "ERROR: Input Excel file was not found."
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

if ([System.IO.Path]::GetFullPath($InputPath) -eq
    [System.IO.Path]::GetFullPath($OutputPath)) {

    Write-Host ""
    Write-Host "ERROR: Input and output files must be different."
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

if ($StartColumn -lt 1) {

    Write-Host "ERROR: START COLUMN must be at least 1."
    Read-Host "Press Enter to exit"
    exit
}

if ($EndColumn -lt $StartColumn) {

    Write-Host "ERROR: END COLUMN must be greater than or equal to START COLUMN."
    Read-Host "Press Enter to exit"
    exit
}

if ($StartRow -lt 1) {

    Write-Host "ERROR: START ROW must be at least 1."
    Read-Host "Press Enter to exit"
    exit
}

if ($EndRow -lt $StartRow) {

    Write-Host "ERROR: END ROW must be greater than or equal to START ROW."
    Read-Host "Press Enter to exit"
    exit
}

if ($CategoryColumn -lt $StartColumn -or
    $CategoryColumn -gt $EndColumn) {

    Write-Host ""
    Write-Host "ERROR: CATEGORY COLUMN must be inside the selected data range."
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

if ($CategoryStartRow -lt $StartRow -or
    $CategoryStartRow -gt $EndRow) {

    Write-Host ""
    Write-Host "ERROR: CATEGORY START ROW must be inside the selected data range."
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

if ($HeaderStartRow -lt 1) {

    Write-Host ""
    Write-Host "ERROR: HEADER START ROW must be at least 1."
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

if ($HeaderEndRow -lt $HeaderStartRow) {

    Write-Host ""
    Write-Host "ERROR: HEADER END ROW must be greater than or equal to HEADER START ROW."
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

if ($HeaderEndRow -ge $StartRow) {

    Write-Host ""
    Write-Host "ERROR: Header rows must be located before the data START ROW."
    Write-Host ""
    Write-Host "Example:"
    Write-Host "HEADER START = 1"
    Write-Host "HEADER END   = 1"
    Write-Host "DATA START   = 2"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}


# ==========================================================================================
# COLUMN LETTERS
# ==========================================================================================

$StartColumnLetter =
    Convert-ColumnNumberToLetter $StartColumn

$EndColumnLetter =
    Convert-ColumnNumberToLetter $EndColumn

$CategoryColumnLetter =
    Convert-ColumnNumberToLetter $CategoryColumn


# ==========================================================================================
# CONFIGURATION DISPLAY
# ==========================================================================================

$ColumnCount =
    $EndColumn - $StartColumn + 1

$RowCount =
    $EndRow - $StartRow + 1

$HeaderRowCount =
    $HeaderEndRow - $HeaderStartRow + 1


Write-Host ""
Write-Host "=========================================================================================="
Write-Host " PROCESSING CONFIGURATION"
Write-Host "=========================================================================================="
Write-Host ""
Write-Host "Input File          : $InputPath"
Write-Host "Output File         : $OutputPath"
Write-Host "Worksheet Number    : $WorksheetIndex"
Write-Host "Data Range          : $StartColumnLetter$StartRow : $EndColumnLetter$EndRow"
Write-Host "Start Column        : $StartColumn"
Write-Host "End Column          : $EndColumn"
Write-Host "Start Row           : $StartRow"
Write-Host "End Row             : $EndRow"
Write-Host "Category Column     : $CategoryColumn ($CategoryColumnLetter)"
Write-Host "Category Start Row  : $CategoryStartRow"
Write-Host "Header Start Row    : $HeaderStartRow"
Write-Host "Header End Row      : $HeaderEndRow"
Write-Host "Header Rows         : $HeaderRowCount"
Write-Host "Selected Columns    : $ColumnCount"
Write-Host "Selected Rows       : $RowCount"
Write-Host ""


# ==========================================================================================
# CONFIRMATION
# ==========================================================================================

$Confirmation =
    Read-Host "Continue with category splitting? (Y/N)"

if ($Confirmation -notmatch '^[Yy]$') {

    Write-Host ""
    Write-Host "Operation cancelled by user."
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}


# ==========================================================================================
# START TIMER
# ==========================================================================================

$StartTime = Get-Date


# ==========================================================================================
# EXCEL CONSTANTS
# ==========================================================================================

$xlOpenXMLWorkbook = 51


# ==========================================================================================
# EXCEL OBJECTS
# ==========================================================================================

$Excel = $null
$InputWorkbook = $null
$OutputWorkbook = $null
$SourceWorksheet = $null
$DataRange = $null
$HeaderRange = $null


# ==========================================================================================
# MAIN PROCESS
# ==========================================================================================

try {

    # ======================================================================================
    # START EXCEL
    # ======================================================================================

    Write-Host ""
    Write-Host "Starting Microsoft Excel..."

    $Excel =
        New-Object -ComObject Excel.Application

    $Excel.Visible = $false
    $Excel.DisplayAlerts = $false
    $Excel.ScreenUpdating = $false
    $Excel.EnableEvents = $false


    # ======================================================================================
    # OPEN INPUT WORKBOOK
    # ======================================================================================

    Write-Host "Opening input workbook..."

    $InputWorkbook =
        $Excel.Workbooks.Open(
            $InputPath,
            0,
            $true
        )


    # ======================================================================================
    # VALIDATE WORKSHEET INDEX
    # ======================================================================================

    if ($WorksheetIndex -lt 1 -or
        $WorksheetIndex -gt $InputWorkbook.Worksheets.Count) {

        throw "Worksheet number $WorksheetIndex does not exist. Workbook contains $($InputWorkbook.Worksheets.Count) worksheets."
    }


    # ======================================================================================
    # SELECT SOURCE WORKSHEET
    # ======================================================================================

    $SourceWorksheet =
        $InputWorkbook.Worksheets.Item($WorksheetIndex)

    Write-Host ""
    Write-Host "Selected worksheet:"
    Write-Host $SourceWorksheet.Name


    # ======================================================================================
    # CREATE SOURCE DATA RANGE
    # ======================================================================================

    $DataRangeAddress =
        "${StartColumnLetter}${StartRow}:${EndColumnLetter}${EndRow}"

    $DataRange =
        $SourceWorksheet.Range($DataRangeAddress)


    # ======================================================================================
    # CREATE HEADER RANGE
    # ======================================================================================

    $HeaderStartColumnLetter =
        Convert-ColumnNumberToLetter $StartColumn

    $HeaderEndColumnLetter =
        Convert-ColumnNumberToLetter $EndColumn

    $HeaderRangeAddress =
        "${HeaderStartColumnLetter}${HeaderStartRow}:${HeaderEndColumnLetter}${HeaderEndRow}"

    $HeaderRange =
        $SourceWorksheet.Range($HeaderRangeAddress)


    # ======================================================================================
    # READ DATA
    # ======================================================================================

    Write-Host ""
    Write-Host "Reading selected data range..."

    $DataValues =
        $DataRange.Value2


    # ======================================================================================
    # DETECT UNIQUE CATEGORIES
    # ======================================================================================

    Write-Host "Detecting unique categories..."

    $CategoryMap = @{}

    $CategoryRelativeIndex =
        $CategoryColumn - $StartColumn + 1


    for (
        $SourceRow = $CategoryStartRow;
        $SourceRow -le $EndRow;
        $SourceRow++
    ) {

        $RelativeRow =
            $SourceRow - $StartRow + 1

        $CategoryValue =
            $DataValues[
                $RelativeRow,
                $CategoryRelativeIndex
            ]


        # Empty category values are grouped into EMPTY_CATEGORY.
        if (
            $null -eq $CategoryValue -or
            [string]::IsNullOrWhiteSpace(
                [string]$CategoryValue
            )
        ) {

            $CategoryKey =
                "EMPTY_CATEGORY"
        }
        else {

            $CategoryKey =
                [string]$CategoryValue
        }


        if (-not $CategoryMap.ContainsKey($CategoryKey)) {

            $CategoryMap[$CategoryKey] =
                New-Object System.Collections.Generic.List[int]
        }

        $CategoryMap[$CategoryKey].Add($SourceRow)
    }


    # ======================================================================================
    # SORT CATEGORIES
    # ======================================================================================

    $SortedCategories =
        $CategoryMap.Keys |
        Sort-Object


    Write-Host ""
    Write-Host "Unique categories found: $($SortedCategories.Count)"
    Write-Host ""


    foreach ($Category in $SortedCategories) {

        Write-Host (
            "{0,-50} {1,6} rows" -f
            $Category,
            $CategoryMap[$Category].Count
        )
    }


    # ======================================================================================
    # CREATE OUTPUT WORKBOOK
    # ======================================================================================

    Write-Host ""
    Write-Host "Creating output workbook..."

    $OutputWorkbook =
        $Excel.Workbooks.Add()


    # ======================================================================================
    # KEEP ONE DEFAULT WORKSHEET
    # ======================================================================================

    # Excel requires at least one visible worksheet.
    # The first worksheet is reused for the first category.

    while (
        $OutputWorkbook.Worksheets.Count -gt 1
    ) {

        $OutputWorkbook.Worksheets.Item(
            $OutputWorkbook.Worksheets.Count
        ).Delete()
    }


    # ======================================================================================
    # PROCESS CATEGORIES
    # ======================================================================================

    $CategoryNumber = 0


    foreach ($Category in $SortedCategories) {

        $CategoryNumber++


        # ==================================================================================
        # CREATE / REUSE OUTPUT WORKSHEET
        # ==================================================================================

        if ($CategoryNumber -eq 1) {

            $OutputWorksheet =
                $OutputWorkbook.Worksheets.Item(1)
        }
        else {

            $OutputWorksheet =
                $OutputWorkbook.Worksheets.Add(
                    [Type]::Missing,
                    $OutputWorkbook.Worksheets.Item(
                        $OutputWorkbook.Worksheets.Count
                    )
                )
        }


        # ==================================================================================
        # GENERATE SAFE WORKSHEET NAME
        # ==================================================================================

        $SafeWorksheetName =
            Get-SafeWorksheetName `
                -Name $Category `
                -Workbook $OutputWorkbook


        $OutputWorksheet.Name =
            $SafeWorksheetName


        Write-Host ""
        Write-Host "Created worksheet: $SafeWorksheetName ($($CategoryMap[$Category].Count) rows)"


        # ==================================================================================
        # COPY HEADER RANGE
        # ==================================================================================

        # Copy the selected header range from the source worksheet.
        #
        # The destination always starts at A1.
        #
        # Excel performs the actual copy operation, preserving the source
        # cell formatting and values.

        $HeaderDestination =
            $OutputWorksheet.Range("A1")

        $HeaderRange.Copy(
            $HeaderDestination
        ) | Out-Null

        [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
            $HeaderDestination
        ) | Out-Null

        $HeaderDestination = $null


        # ==================================================================================
        # COPY COLUMN WIDTHS
        # ==================================================================================

        for (
            $ColumnOffset = 0;
            $ColumnOffset -lt $ColumnCount;
            $ColumnOffset++
        ) {

            $SourceColumnNumber =
                $StartColumn + $ColumnOffset

            $DestinationColumnNumber =
                $ColumnOffset + 1


            $SourceColumn =
                $SourceWorksheet.Columns.Item(
                    $SourceColumnNumber
                )

            $DestinationColumn =
                $OutputWorksheet.Columns.Item(
                    $DestinationColumnNumber
                )


            $DestinationColumn.ColumnWidth =
                $SourceColumn.ColumnWidth


            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
                $SourceColumn
            ) | Out-Null

            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
                $DestinationColumn
            ) | Out-Null
        }


        # ==================================================================================
        # COPY HEADER ROW HEIGHTS
        # ==================================================================================

        for (
            $HeaderRow = $HeaderStartRow;
            $HeaderRow -le $HeaderEndRow;
            $HeaderRow++
        ) {

            $OutputHeaderRow =
                $HeaderRow - $HeaderStartRow + 1


            $SourceRowObject =
                $SourceWorksheet.Rows.Item(
                    $HeaderRow
                )

            $DestinationRowObject =
                $OutputWorksheet.Rows.Item(
                    $OutputHeaderRow
                )


            $DestinationRowObject.RowHeight =
                $SourceRowObject.RowHeight


            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
                $SourceRowObject
            ) | Out-Null

            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
                $DestinationRowObject
            ) | Out-Null
        }


        # ==================================================================================
        # COPY MATCHING DATA ROWS
        # ==================================================================================

        $OutputRow =
            $HeaderRowCount + 1


        foreach (
            $SourceRow in $CategoryMap[$Category]
        ) {

            $SourceRange =
                $SourceWorksheet.Range(
                    "${StartColumnLetter}${SourceRow}:${EndColumnLetter}${SourceRow}"
                )


            # Destination ends at the number of selected columns,
            # not at the original Excel column number.

            $DestinationEndColumnLetter =
                Convert-ColumnNumberToLetter $ColumnCount


            $DestinationRange =
                $OutputWorksheet.Range(
                    "A${OutputRow}:${DestinationEndColumnLetter}${OutputRow}"
                )


            # Copy complete row including values and formatting.
            $SourceRange.Copy(
                $DestinationRange
            ) | Out-Null


            # Preserve source row height.
            $SourceRowObject =
                $SourceWorksheet.Rows.Item(
                    $SourceRow
                )

            $DestinationRowObject =
                $OutputWorksheet.Rows.Item(
                    $OutputRow
                )


            $DestinationRowObject.RowHeight =
                $SourceRowObject.RowHeight


            # Release temporary COM row objects.
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
                $SourceRowObject
            ) | Out-Null

            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
                $DestinationRowObject
            ) | Out-Null


            # Release temporary range objects.
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
                $SourceRange
            ) | Out-Null

            [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
                $DestinationRange
            ) | Out-Null


            $OutputRow++
        }


        # ==================================================================================
        # COPY SHEET VIEW / GRIDLINE STATE
        # ==================================================================================

        try {

            $OutputWorksheet.Activate()

            $OutputWorksheet.Application.ActiveWindow.DisplayGridlines =
                $SourceWorksheet.Application.ActiveWindow.DisplayGridlines
        }
        catch {

            # Some Excel configurations do not expose window properties.
            # Continue without stopping the operation.
        }


        # ==================================================================================
        # RELEASE OUTPUT WORKSHEET
        # ==================================================================================

        [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
            $OutputWorksheet
        ) | Out-Null

        $OutputWorksheet = $null
    }


    # ======================================================================================
    # SAVE OUTPUT WORKBOOK
    # ======================================================================================

    Write-Host ""
    Write-Host "Saving output workbook..."


    $OutputWorkbook.SaveAs(
        $OutputPath,
        $xlOpenXMLWorkbook
    )


    Write-Host ""
    Write-Host "Output workbook saved successfully."
    Write-Host $OutputPath


    # ======================================================================================
    # COMPLETION INFORMATION
    # ======================================================================================

    $EndTime =
        Get-Date

    $ExecutionTime =
        $EndTime - $StartTime


    Write-Host ""
    Write-Host ""
    Write-Host "=========================================================================================="
    Write-Host "                                CATEGORY SPLITTING COMPLETED"
    Write-Host "=========================================================================================="
    Write-Host ""
    Write-Host "Input File        : $InputPath"
    Write-Host "Output File       : $OutputPath"
    Write-Host "Source Worksheet  : $WorksheetIndex"
    Write-Host "Source Range      : $StartColumnLetter$StartRow : $EndColumnLetter$EndRow"
    Write-Host "Category Column   : $CategoryColumnLetter"
    Write-Host "Category Start Row: $CategoryStartRow"
    Write-Host "Header Range      : $HeaderStartColumnLetter$HeaderStartRow : $HeaderEndColumnLetter$HeaderEndRow"
    Write-Host "Header Rows       : $HeaderRowCount"
    Write-Host "Rows Processed    : $RowCount"
    Write-Host "Columns Processed : $ColumnCount"
    Write-Host "Categories        : $($SortedCategories.Count)"
    Write-Host "Worksheets Made   : $($SortedCategories.Count)"
    Write-Host ""
    Write-Host "Execution Time    : $($ExecutionTime.ToString('hh\:mm\:ss'))"
    Write-Host ""
    Write-Host "Every matching row was copied as one complete record."
    Write-Host "Selected header rows were copied to every output worksheet."
    Write-Host "Source worksheet formatting was preserved."
    Write-Host "Empty cells were preserved."
    Write-Host ""


}
catch {

    Write-Host ""
    Write-Host "=========================================================================================="
    Write-Host "                                      ERROR"
    Write-Host "=========================================================================================="
    Write-Host ""
    Write-Host $_.Exception.Message
    Write-Host ""
}


# ==========================================================================================
# CLEANUP
# ==========================================================================================

try {

    if ($InputWorkbook) {

        $InputWorkbook.Close($false)

        [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
            $InputWorkbook
        ) | Out-Null

        $InputWorkbook = $null
    }

}
catch {}


try {

    if ($OutputWorkbook) {

        $OutputWorkbook.Close($true)

        [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
            $OutputWorkbook
        ) | Out-Null

        $OutputWorkbook = $null
    }

}
catch {}


try {

    if ($SourceWorksheet) {

        [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
            $SourceWorksheet
        ) | Out-Null

        $SourceWorksheet = $null
    }

}
catch {}


try {

    if ($DataRange) {

        [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
            $DataRange
        ) | Out-Null

        $DataRange = $null
    }

}
catch {}


try {

    if ($HeaderRange) {

        [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
            $HeaderRange
        ) | Out-Null

        $HeaderRange = $null
    }

}
catch {}


try {

    if ($Excel) {

        # Do not assign Boolean values to Excel.CutCopyMode.
        # Excel COM expects an XlCutCopyMode value here.
        #
        # Excel will automatically clear the copy state when the
        # application is closed.

        $Excel.Quit()

        [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
            $Excel
        ) | Out-Null

        $Excel = $null
    }

}
catch {}


# ==========================================================================================
# FINAL GARBAGE COLLECTION
# ==========================================================================================

[GC]::Collect()
[GC]::WaitForPendingFinalizers()

[GC]::Collect()
[GC]::WaitForPendingFinalizers()


# ==========================================================================================
# FINAL PAUSE
# ==========================================================================================

Write-Host ""
Read-Host "Press Enter to exit"