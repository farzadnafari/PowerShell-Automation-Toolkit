# ============================================================
# SOFTWARE FOLDER RENAMER
# Rename software folders by removing version numbers
# and adding: [1] [2024]
#
# Example:
# Kaspersky Security Cloud 21.14.5
# -> Kaspersky Security Cloud [1] [2024]
#
# Qihoo 360 Total Security 11
# -> Qihoo 360 Total Security [1] [2024]
#
# Windows Firewall Control 6.9
# -> Windows Firewall Control [1] [2024]
#
# Alcohol 120% 2.1.1.611
# -> Alcohol 120% [1] [2024]
#
# Nero Burning ROM-Express 23.0.1.14
# -> Nero Burning ROM-Express [1] [2024]
#
# AVS Audio Software 10.5.1.23
# -> AVS Audio Software [1] [2024]
#
# HandBrake 1.8.2 x64
# -> HandBrake x64 [1] [2024]
# ============================================================


# ============================================================
# >>> SET THE PARENT FOLDER PATH HERE <<<
# ============================================================

$ParentFolder = "D:\Program"


# ============================================================
# DO NOT CHANGE BELOW THIS LINE
# ============================================================

Clear-Host

Write-Host ""
Write-Host "============================================================"
Write-Host " SOFTWARE FOLDER RENAMER"
Write-Host "============================================================"
Write-Host ""

if (-not (Test-Path -LiteralPath $ParentFolder -PathType Container)) {
    Write-Host "ERROR: Parent folder does not exist:" -ForegroundColor Red
    Write-Host $ParentFolder -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press ENTER to exit"
    exit
}

Write-Host "Parent folder:"
Write-Host $ParentFolder -ForegroundColor Cyan
Write-Host ""

Write-Host "Scanning folders..." -ForegroundColor Yellow
Write-Host ""

$Folders = Get-ChildItem -LiteralPath $ParentFolder -Directory -Recurse -ErrorAction SilentlyContinue

$RenameList = @()


foreach ($Folder in $Folders) {

    $OldName = $Folder.Name
    $NewName = $OldName

    # --------------------------------------------------------
    # Remove version numbers from the END of folder name
    # Examples:
    # 21.14.5
    # 6.9
    # 2.1.1.611
    # 1.8.2
    # --------------------------------------------------------

    $NewName = $NewName -replace '\s+\d+(?:\.\d+)+$', ''


    # --------------------------------------------------------
    # Remove simple numeric version from the END
    # Examples:
    # "Qihoo 360 Total Security 11"
    # "Adobe Photoshop 2025"
    # --------------------------------------------------------

    $NewName = $NewName -replace '\s+\d+$', ''


    # --------------------------------------------------------
    # Handle names such as:
    # "HandBrake 1.8.2 x64"
    # "Program 5.2 x86"
    #
    # Keep x64 / x86 but remove the version.
    # --------------------------------------------------------

    $NewName = $NewName -replace '\s+\d+(?:\.\d+)+\s+(x64|x86)$', ' $1'


    # --------------------------------------------------------
    # Remove a trailing year such as:
    # 2022
    # 2023
    # 2024
    # 2025
    # 2026
    #
    # Only if it is at the END of the name.
    # --------------------------------------------------------

    $NewName = $NewName -replace '\s+(19|20)\d{2}$', ''


    # --------------------------------------------------------
    # Remove extra spaces
    # --------------------------------------------------------

    $NewName = $NewName.Trim()


    # --------------------------------------------------------
    # Add required suffix
    # --------------------------------------------------------

    if ($NewName -ne $OldName) {

        $NewName = "$NewName [1] [2024]"

        $NewPath = Join-Path -Path $Folder.Parent.FullName -ChildPath $NewName

        $RenameList += [PSCustomObject]@{
            OldName = $OldName
            NewName = $NewName
            OldPath = $Folder.FullName
            NewPath = $NewPath
        }
    }
}


# ============================================================
# SHOW PREVIEW
# ============================================================

if ($RenameList.Count -eq 0) {

    Write-Host "No folders were found that require renaming." -ForegroundColor Yellow
    Write-Host ""

    Read-Host "Press ENTER to exit"
    exit
}


Write-Host ""
Write-Host "============================================================"
Write-Host " PREVIEW"
Write-Host "============================================================"
Write-Host ""

foreach ($Item in $RenameList) {

    Write-Host "OLD:" -ForegroundColor DarkGray
    Write-Host "  $($Item.OldName)"

    Write-Host "NEW:" -ForegroundColor Green
    Write-Host "  $($Item.NewName)"

    Write-Host ""
}


Write-Host "============================================================"
Write-Host " Total folders to rename: $($RenameList.Count)"
Write-Host "============================================================"
Write-Host ""


# ============================================================
# ASK FOR CONFIRMATION
# ============================================================

$Answer = Read-Host "Do you want to perform these renames? (Y/N)"

if ($Answer -notmatch '^(Y|y|Yes|yes)$') {

    Write-Host ""
    Write-Host "Operation cancelled. No folders were changed." -ForegroundColor Yellow
    Write-Host ""

    Read-Host "Press ENTER to exit"
    exit
}


# ============================================================
# PERFORM RENAMES
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host " RENAMING"
Write-Host "============================================================"
Write-Host ""


$SuccessCount = 0
$ErrorCount = 0


foreach ($Item in $RenameList) {

    try {

        # ----------------------------------------------------
        # Do not overwrite an existing folder
        # ----------------------------------------------------

        if (Test-Path -LiteralPath $Item.NewPath) {

            Write-Host "[SKIPPED]" -ForegroundColor Yellow
            Write-Host "Destination already exists:"
            Write-Host "  $($Item.NewPath)"
            Write-Host ""

            $ErrorCount++
            continue
        }


        # ----------------------------------------------------
        # Rename folder
        # ----------------------------------------------------

        Rename-Item -LiteralPath $Item.OldPath -NewName $Item.NewName -ErrorAction Stop

        Write-Host "[OK]" -ForegroundColor Green
        Write-Host "$($Item.OldName)"
        Write-Host "  -> $($Item.NewName)"
        Write-Host ""

        $SuccessCount++

    }
    catch {

        Write-Host "[ERROR]" -ForegroundColor Red
        Write-Host "$($Item.OldName)"
        Write-Host "  -> $($_.Exception.Message)"
        Write-Host ""

        $ErrorCount++
    }
}


# ============================================================
# FINAL RESULT
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host " FINISHED"
Write-Host "============================================================"
Write-Host ""

Write-Host "Successfully renamed : $SuccessCount" -ForegroundColor Green
Write-Host "Skipped / Failed     : $ErrorCount" -ForegroundColor Yellow

Write-Host ""
Read-Host "Press ENTER to exit"