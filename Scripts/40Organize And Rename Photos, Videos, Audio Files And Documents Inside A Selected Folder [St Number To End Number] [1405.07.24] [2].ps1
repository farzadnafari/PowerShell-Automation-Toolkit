# ================================================================
# Memory Media Organizer
# ================================================================
# Purpose:
#   Organize and rename photos, videos, audio files and documents
#   inside a selected folder.
#
# Order:
#   Preserve the combined alphabetical order of all supported files.
#
# Naming:
#   Original Name [00001].extension
#
# Example:
#   My Photo (12).jpg
#       ->
#   My Photo [00001].jpg
#
# Requirements:
#   - Windows PowerShell 5.1+
#   - Administrator privileges
# ================================================================

# ------------------------------------------------
# 1. Self-elevate to Administrator
# ------------------------------------------------

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

$IsAdministrator = $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdministrator) {

    Write-Host ""
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow

    $ScriptPath = $MyInvocation.MyCommand.Definition

    if (-not $ScriptPath) {
        Write-Host ""
        Write-Host "ERROR: Unable to determine script path." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            "`"$ScriptPath`""
        )

    exit
}

# ------------------------------------------------
# 2. Execution Policy / Bypass
# ------------------------------------------------

try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}
catch {
    Write-Host "Could not change Process ExecutionPolicy. Continuing..." -ForegroundColor Yellow
}

# ------------------------------------------------
# 3. Header
# ------------------------------------------------

Clear-Host

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "MEMORY MEDIA ORGANIZER" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Combined alphabetical order will be preserved." -ForegroundColor White
Write-Host ""
Write-Host "The script will rename files inside the selected folder." -ForegroundColor Gray
Write-Host ""

# ------------------------------------------------
# 4. Get folder path from user
# ------------------------------------------------

do {

    $FolderPath = Read-Host "Enter the folder path"

    if ([string]::IsNullOrWhiteSpace($FolderPath)) {
        Write-Host "Path cannot be empty." -ForegroundColor Red
        continue
    }

    $FolderPath = $FolderPath.Trim('"').Trim()

    if (-not (Test-Path -LiteralPath $FolderPath -PathType Container)) {
        Write-Host ""
        Write-Host "Folder not found:" -ForegroundColor Red
        Write-Host $FolderPath -ForegroundColor Yellow
        Write-Host ""
    }
    else {
        break
    }

} while ($true)

# ------------------------------------------------
# 5. Supported file extensions
# ------------------------------------------------

$PhotoExtensions = @(
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".bmp",
    ".tif",
    ".tiff",
    ".webp",
    ".heic",
    ".heif",
    ".raw",
    ".cr2",
    ".cr3",
    ".nef",
    ".arw",
    ".dng",
    ".orf",
    ".rw2",
    ".raf",
    ".srw",
    ".pef",
    ".psd"
)

$VideoExtensions = @(
    ".mp4",
    ".mkv",
    ".avi",
    ".mov",
    ".wmv",
    ".flv",
    ".webm",
    ".m4v",
    ".3gp",
    ".mpeg",
    ".mpg",
    ".mts",
    ".m2ts",
    ".ts",
    ".vob"
)

$AudioExtensions = @(
    ".mp3",
    ".wav",
    ".flac",
    ".aac",
    ".m4a",
    ".ogg",
    ".oga",
    ".wma",
    ".opus",
    ".aiff",
    ".aif",
    ".amr",
    ".mid",
    ".midi"
)

$DocumentExtensions = @(
    ".pdf",
    ".doc",
    ".docx",
    ".docm",
    ".dot",
    ".dotx",
    ".xls",
    ".xlsx",
    ".xlsm",
    ".xlsb",
    ".csv",
    ".ods",
    ".ppt",
    ".pptx",
    ".pptm",
    ".pps",
    ".ppsx",
    ".txt",
    ".rtf",
    ".odt",
    ".odp",
    ".md",
    ".markdown",
    ".epub"
)

# ------------------------------------------------
# 6. Read files
# ------------------------------------------------

Write-Host ""
Write-Host "Scanning folder..." -ForegroundColor Cyan
Write-Host ""

$AllFiles = @(
    Get-ChildItem `
        -LiteralPath $FolderPath `
        -File `
        -ErrorAction SilentlyContinue
)

if (-not $AllFiles -or $AllFiles.Count -eq 0) {

    Write-Host "No files found in this folder." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

# ------------------------------------------------
# 7. Categorize files
# ------------------------------------------------

$Photos = @(
    $AllFiles |
    Where-Object {
        $PhotoExtensions -contains $_.Extension.ToLowerInvariant()
    }
)

$Videos = @(
    $AllFiles |
    Where-Object {
        $VideoExtensions -contains $_.Extension.ToLowerInvariant()
    }
)

$Audio = @(
    $AllFiles |
    Where-Object {
        $AudioExtensions -contains $_.Extension.ToLowerInvariant()
    }
)

$Documents = @(
    $AllFiles |
    Where-Object {
        $DocumentExtensions -contains $_.Extension.ToLowerInvariant()
    }
)

# ------------------------------------------------
# 8. Preserve combined file order
# ------------------------------------------------
# IMPORTANT:
# All supported files are sorted together by their current names.
# Files are NOT separated by photos, videos, audio or documents.
# This preserves their combined alphabetical sequence.

$OrderedFiles = @(
    $AllFiles |
    Where-Object {
        $Extension = $_.Extension.ToLowerInvariant()

        ($PhotoExtensions -contains $Extension) -or
        ($VideoExtensions -contains $Extension) -or
        ($AudioExtensions -contains $Extension) -or
        ($DocumentExtensions -contains $Extension)
    } |
    Sort-Object Name
)

# ------------------------------------------------
# 9. Display summary
# ------------------------------------------------

Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "Photos     : $($Photos.Count)" -ForegroundColor Green
Write-Host "Videos     : $($Videos.Count)" -ForegroundColor Green
Write-Host "Audio      : $($Audio.Count)" -ForegroundColor Green
Write-Host "Documents  : $($Documents.Count)" -ForegroundColor Green
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "Total      : $($OrderedFiles.Count)" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Combined alphabetical order will be used." -ForegroundColor Cyan
Write-Host ""

if ($OrderedFiles.Count -eq 0) {

    Write-Host "No supported files were found." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

# ------------------------------------------------
# 10. Safety check — maximum 99999 files
# ------------------------------------------------

if ($OrderedFiles.Count -gt 99999) {

    Write-Host ""
    Write-Host "ERROR: More than 99,999 supported files were found." -ForegroundColor Red
    Write-Host "The script stopped to prevent numbering overflow." -ForegroundColor Red
    Write-Host ""

    Read-Host "Press Enter to exit"
    exit 1
}

# ------------------------------------------------
# 11. Get numbering range
# ------------------------------------------------

do {

    $StartNumberInput = Read-Host "Enter the starting number (1-99999)"

    $StartNumber = 0

    $StartNumberValid = [int]::TryParse(
        $StartNumberInput,
        [ref]$StartNumber
    )

    if (
        -not $StartNumberValid -or
        $StartNumber -lt 1 -or
        $StartNumber -gt 99999
    ) {
        Write-Host "Invalid starting number. Enter a number from 1 to 99999." -ForegroundColor Red
        continue
    }

    break

} while ($true)

do {

    $EndNumberInput = Read-Host "Enter the ending number (up to 99999)"

    $EndNumber = 0

    $EndNumberValid = [int]::TryParse(
        $EndNumberInput,
        [ref]$EndNumber
    )

    if (
        -not $EndNumberValid -or
        $EndNumber -lt $StartNumber -or
        $EndNumber -gt 99999
    ) {
        Write-Host "Invalid ending number. It must be between the starting number and 99999." -ForegroundColor Red
        continue
    }

    break

} while ($true)

$AvailableNumbers = $EndNumber - $StartNumber + 1

if ($OrderedFiles.Count -gt $AvailableNumbers) {

    Write-Host ""
    Write-Host "ERROR: The selected numbering range is too small." -ForegroundColor Red
    Write-Host "Files found       : $($OrderedFiles.Count)" -ForegroundColor Yellow
    Write-Host "Available numbers : $AvailableNumbers" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "No files have been renamed." -ForegroundColor Red
    Write-Host ""

    Read-Host "Press Enter to exit"
    exit 1
}

# ------------------------------------------------
# 12. Confirmation
# ------------------------------------------------

Write-Host ""
Write-Host "Target folder:" -ForegroundColor White
Write-Host $FolderPath -ForegroundColor Yellow
Write-Host ""

Write-Host "Naming format:" -ForegroundColor White
Write-Host "Original Name [00001].extension" -ForegroundColor Cyan
Write-Host ""

Write-Host "Starting number : $($StartNumber.ToString('D5'))" -ForegroundColor Cyan
Write-Host "Ending number   : $($EndNumber.ToString('D5'))" -ForegroundColor Cyan
Write-Host "Files to rename : $($OrderedFiles.Count)" -ForegroundColor Cyan
Write-Host ""

$Confirmation = Read-Host "Continue? Type YES to continue"

if ($Confirmation -cne "YES") {

    Write-Host ""
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    Write-Host ""

    Read-Host "Press Enter to exit"
    exit
}

# ------------------------------------------------
# 13. Temporary rename phase
# ------------------------------------------------
# This prevents filename collisions while renaming.

Write-Host ""
Write-Host "Preparing files..." -ForegroundColor Cyan
Write-Host ""

$TemporaryFiles = @()

foreach ($File in $OrderedFiles) {

    $Extension = $File.Extension

    $TempName = "__MEMORY_ORGANIZER_TEMP__" +
                ([Guid]::NewGuid().ToString("N")) +
                $Extension

    $TempPath = Join-Path $FolderPath $TempName

    try {

        Rename-Item `
            -LiteralPath $File.FullName `
            -NewName $TempName `
            -ErrorAction Stop

        $TemporaryFiles += [PSCustomObject]@{
            TempPath      = $TempPath
            OriginalName  = $File.Name
            Extension     = $Extension
        }

    }
    catch {

        Write-Host ""
        Write-Host "ERROR while preparing:" -ForegroundColor Red
        Write-Host $File.FullName -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""

        Write-Host "Files successfully moved to temporary names:" -ForegroundColor Yellow
        Write-Host $TemporaryFiles.Count -ForegroundColor Yellow
        Write-Host "Restore these files from their temporary names if necessary." -ForegroundColor Yellow
        Write-Host ""

        Read-Host "Press Enter to exit"
        exit 1
    }
}

# ------------------------------------------------
# 14. Final rename phase
# ------------------------------------------------

Write-Host ""
Write-Host "Renaming files..." -ForegroundColor Cyan
Write-Host ""

$Counter = $StartNumber

foreach ($Item in $TemporaryFiles) {

    # Remove trailing "(number)" from the original filename.
    #
    # Examples:
    #   Photo (1)     -> Photo
    #   Photo (25)    -> Photo
    #   Photo (12345) -> Photo
    #
    # Spaces immediately before the "(number)" are removed as well.

    $BaseName = [System.IO.Path]::GetFileNameWithoutExtension(
        $Item.OriginalName
    )

    $BaseName = $BaseName -replace '\s*\(\d+\)\s*$', ''

    # Clean excessive trailing spaces
    $BaseName = $BaseName.Trim()

    # If somehow the name becomes empty
    if ([string]::IsNullOrWhiteSpace($BaseName)) {
        $BaseName = "Memory"
    }

    # Five-digit sequential number
    $Number = $Counter.ToString("D5")

    $FinalName = "$BaseName [$Number]$($Item.Extension)"

    try {

        Rename-Item `
            -LiteralPath $Item.TempPath `
            -NewName $FinalName `
            -ErrorAction Stop

        Write-Host "[$Number] $FinalName" -ForegroundColor Gray

    }
    catch {

        Write-Host ""
        Write-Host "ERROR while renaming:" -ForegroundColor Red
        Write-Host $Item.OriginalName -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""

        $Counter++
        continue
    }

    $Counter++
}

# ------------------------------------------------
# 15. Finished
# ------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "OPERATION COMPLETED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Folder:" -ForegroundColor White
Write-Host $FolderPath -ForegroundColor Cyan
Write-Host ""
Write-Host "Processed files: $($OrderedFiles.Count)" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit"