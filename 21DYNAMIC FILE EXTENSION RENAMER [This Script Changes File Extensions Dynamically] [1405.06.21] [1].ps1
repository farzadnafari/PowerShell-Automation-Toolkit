# ============================================================
# DYNAMIC FILE EXTENSION RENAMER
#
# This script changes file extensions dynamically.
#
# IMPORTANT:
# This script DOES NOT convert file formats.
# It ONLY renames the file extension.
#
# Example:
#   .fon -> .ttf
#
# This does NOT convert a FON font into a real TTF font.
# It only changes:
#
#   Example.fon
#
# to:
#
#   Example.ttf
#
# ============================================================


Clear-Host

Write-Host "============================================================"
Write-Host "DYNAMIC FILE EXTENSION RENAMER"
Write-Host "============================================================"
Write-Host ""

# ------------------------------------------------------------
# ASK FOR FOLDER PATH
# ------------------------------------------------------------

$FolderPath = Read-Host "Enter the full folder path"

$FolderPath = $FolderPath.Trim().Trim('"')


# ------------------------------------------------------------
# CHECK FOLDER
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $FolderPath -PathType Container)) {

    Write-Host ""
    Write-Host "ERROR: The specified folder does not exist." -ForegroundColor Red
    Write-Host ""

    Read-Host "Press Enter to exit"

    exit
}


# ------------------------------------------------------------
# ASK FOR SOURCE EXTENSION
# ------------------------------------------------------------

$SourceExtension = Read-Host "Enter the SOURCE extension (example: fon)"

$SourceExtension = $SourceExtension.Trim().TrimStart('.').ToLower()


if ([string]::IsNullOrWhiteSpace($SourceExtension)) {

    Write-Host ""
    Write-Host "ERROR: Source extension cannot be empty." -ForegroundColor Red

    Read-Host "Press Enter to exit"

    exit
}


# ------------------------------------------------------------
# ASK FOR DESTINATION EXTENSION
# ------------------------------------------------------------

$DestinationExtension = Read-Host "Enter the DESTINATION extension (example: ttf)"

$DestinationExtension = $DestinationExtension.Trim().TrimStart('.').ToLower()


if ([string]::IsNullOrWhiteSpace($DestinationExtension)) {

    Write-Host ""
    Write-Host "ERROR: Destination extension cannot be empty." -ForegroundColor Red

    Read-Host "Press Enter to exit"

    exit
}


# ------------------------------------------------------------
# FIND FILES
# ------------------------------------------------------------

$Files = Get-ChildItem `
    -LiteralPath $FolderPath `
    -File |
    Where-Object {
        $_.Extension.TrimStart('.').ToLower() -eq $SourceExtension
    }


if ($Files.Count -eq 0) {

    Write-Host ""
    Write-Host "No .$SourceExtension files were found." -ForegroundColor Yellow
    Write-Host ""

    Read-Host "Press Enter to exit"

    exit
}


# ------------------------------------------------------------
# DISPLAY SUMMARY
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================"
Write-Host "OPERATION SUMMARY"
Write-Host "============================================================"
Write-Host ""

Write-Host "Folder:"
Write-Host $FolderPath

Write-Host ""

Write-Host "Source extension:"
Write-Host ".$SourceExtension"

Write-Host ""

Write-Host "Destination extension:"
Write-Host ".$DestinationExtension"

Write-Host ""

Write-Host "Files found:"
Write-Host $Files.Count

Write-Host ""

Write-Host "WARNING:"
Write-Host "This operation only changes file extensions." -ForegroundColor Yellow
Write-Host "It does NOT convert the actual file format." -ForegroundColor Yellow

Write-Host ""


# ------------------------------------------------------------
# CONFIRM
# ------------------------------------------------------------

$Confirmation = Read-Host "Continue? (Y/N)"


if ($Confirmation.Trim().ToUpper() -ne "Y") {

    Write-Host ""
    Write-Host "Operation cancelled."

    Read-Host "Press Enter to exit"

    exit
}


# ------------------------------------------------------------
# PROCESS FILES
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================"
Write-Host "PROCESSING FILES"
Write-Host "============================================================"
Write-Host ""


$SuccessCount = 0
$FailedCount  = 0
$SkippedCount = 0


foreach ($File in $Files) {

    $NewFileName = (
        $File.BaseName +
        "." +
        $DestinationExtension
    )


    $DestinationPath = Join-Path `
        -Path $File.DirectoryName `
        -ChildPath $NewFileName


    # --------------------------------------------------------
    # CHECK FOR NAME CONFLICT
    # --------------------------------------------------------

    if (Test-Path -LiteralPath $DestinationPath) {

        Write-Host "[SKIPPED] $($File.Name)" -ForegroundColor Yellow
        Write-Host "          Destination already exists:"
        Write-Host "          $NewFileName"

        $SkippedCount++

        continue
    }


    try {

        Rename-Item `
            -LiteralPath $File.FullName `
            -NewName $NewFileName `
            -ErrorAction Stop


        Write-Host "[OK] $($File.Name) -> $NewFileName" -ForegroundColor Green


        $SuccessCount++
    }

    catch {

        Write-Host "[FAILED] $($File.Name)" -ForegroundColor Red
        Write-Host "         $($_.Exception.Message)"


        $FailedCount++
    }
}


# ------------------------------------------------------------
# FINAL REPORT
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================"
Write-Host "COMPLETED"
Write-Host "============================================================"
Write-Host ""

Write-Host "Total found : $($Files.Count)"
Write-Host "Successful : $SuccessCount"
Write-Host "Skipped    : $SkippedCount"
Write-Host "Failed     : $FailedCount"

Write-Host ""

Read-Host "Press Enter to exit"