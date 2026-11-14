
> [!INFO] ابزار مسیردهی و سازمان‌دهی فایل‌ها بر اساس ساختار پوشه مرجع
> این اسکریپت با استفاده از ساختار پوشه مرجع، فایل‌های موجود در یک پوشه ورودی را شناسایی و سازمان‌دهی می‌کند.
> مسیر پوشه مرجع، پوشه ورودی و پوشه مقصد را از کاربر دریافت می‌کند.
> مسیرهای واردشده را اعتبارسنجی کرده و از هم‌پوشانی ناامن میان پوشه‌ها جلوگیری می‌کند.
> پوشه مرجع و تمام زیرپوشه‌های آن را به‌صورت بازگشتی بررسی می‌کند.
> با استفاده از نام فایل‌های مرجع و مسیر نسبی آن‌ها، یک نقشه ساختاری ایجاد می‌کند.
> فایل‌های ورودی را بر اساس نام فایل و بدون درنظرگرفتن پسوند با نقشه مرجع مقایسه می‌کند.
> برای هر فایل دارای تطبیق یکتا، مسیر پوشه مقصد متناظر را تعیین می‌کند.
> در صورت وجود نداشتن پوشه مقصد موردنیاز، آن را ایجاد می‌کند.
> فایل‌های دارای تطبیق یکتا را به پوشه مقصد منتقل می‌کند و فایل‌های بدون تطبیق یا دارای نام‌های تکراری و مبهم را نادیده می‌گیرد.


> [!INFO] Blueprint-Based File Routing and Organization Utility
> This script organizes files in an input directory using the directory structure of a reference folder as a blueprint.
> It prompts the user to provide the reference root, input directory, and destination root paths.
> It validates the specified paths and prevents unsafe directory overlaps.
> It recursively scans the reference directory and all its subdirectories.
> It builds a directory mapping based on reference filenames and their relative directory paths.
> It compares input filenames against the reference mapping without considering file extensions.
> It determines the corresponding destination directory for each uniquely matched input file.
> It creates the required destination directory if it does not already exist.
> It moves uniquely matched files into their mapped destination directories while skipping unmatched files and ambiguous matches involving duplicate reference filenames.


```
# =============================================================================
# SCRIPT NAME      : BlueprintRouter.ps1
# SCRIPT VERSION   : 1.0.0
# SCRIPT TYPE      : File Organization and Directory Mapping Utility
# PLATFORM         : Microsoft Windows 10
# SHELL            : Windows PowerShell 5.1
# ENCODING         : UTF-8
# =============================================================================
#
# PURPOSE
# -------
# This script organizes files by using the directory structure of a reference
# folder as a blueprint. It searches the reference folder and all its
# subdirectories, builds a filename mapping, and uses that mapping to identify
# the correct destination directory for files found in a separate input folder.
#
# GENERAL WORKFLOW
# ----------------
# 1. Request the path of the reference root directory.
# 2. Request the path of the input directory containing files to organize.
# 3. Request the path of the destination root directory.
# 4. Validate the specified paths and prevent unsafe directory overlaps.
# 5. Scan the reference directory recursively, including its subdirectories.
# 6. Build a blueprint using each reference filename and its relative directory.
# 7. Compare input filenames against the blueprint without considering extensions.
# 8. Identify a unique reference directory for each matching input file.
# 9. Create the corresponding destination directory when it does not exist.
# 10. Move each uniquely matched file into its mapped destination directory.
# 11. Skip files that have no matching reference filename.
# 12. Skip ambiguous matches when multiple reference files share the same name.
# 13. Skip operations that would overwrite an existing destination file.
# 14. Record operation details, warnings, and errors in a log file.
# 15. Display a summary of the operation when processing is complete.
#
# FILENAME MATCHING RULES
# -----------------------
# File extensions are ignored during filename matching.
#
# Examples:
#   Reference:  Customer.docx
#   Input:      Customer.pdf
#   Result:     MATCH
#
#   Reference:  AnnualReport.xlsx
#   Input:      AnnualReport.pdf
#   Result:     MATCH
#
#   Reference:  MeetingNotes.md
#   Input:      MeetingNotes.txt
#   Result:     MATCH
#
# Matching is case-insensitive. For example, "Report.PDF" and "report.docx"
# are treated as having the same base filename.
#
# A match is considered valid only when exactly one reference file has the
# corresponding base filename. If multiple reference files share that base
# filename, the match is considered ambiguous and is skipped.
#
# DIRECTORY MAPPING
# -----------------
# The relative directory of a matching reference file determines the target
# directory under the destination root.
#
# Example reference structure:
#
#   Reference\
#       DepartmentA\
#           ProjectB\
#               EmployeeC\
#                   EmployeeC.docx
#
# Example input:
#
#   Input\
#       EmployeeC.pdf
#
# Expected destination:
#
#   Destination\
#       DepartmentA\
#           ProjectB\
#               EmployeeC\
#                   EmployeeC.pdf
#
# The original filename and extension of the input file are preserved.
# The reference folder and its contents are not modified.
#
# FILE OPERATION POLICY
# ---------------------
# Matched files are MOVED from the input directory to the destination directory.
# They are not copied. A successful move removes the original input file from
# its previous location.
#
# Files without a reference match remain in the input directory.
# Files with ambiguous reference matches remain in the input directory.
# Files whose destination path already contains a file with the same name are
# skipped to prevent accidental data loss.
#
# Existing destination files are never overwritten by this script.
# The script does not intentionally delete reference files.
#
# PATH VALIDATION AND SAFETY
# --------------------------
# All required directory paths must be provided and valid.
# The reference directory must exist before processing can begin.
# The input directory must exist before processing can begin.
# The destination directory may be created automatically when necessary.
#
# Overlapping reference, input, and destination directory paths are rejected
# to reduce the risk of recursive scanning, duplicate processing, or accidental
# movement of files into their own source directories.
#
# Administrator privileges are requested automatically when required.
# ExecutionPolicy Bypass applies only to the PowerShell process launched for
# this script. It does not permanently change the system execution policy.
#
# LOGGING AND REPORTING
# ---------------------
# A timestamped log file is created in the current user's Windows TEMP folder.
# The log records relevant paths, successful moves, unmatched files,
# ambiguous matches, errors, and final processing statistics.
#
# The final summary includes:
#   - Total number of input files discovered.
#   - Number of files successfully moved.
#   - Number of files without a reference match.
#   - Number of ambiguous filename matches.
#   - Number of failed operations.
#   - Location of the log file.
#
# REQUIREMENTS
# ------------
# Operating System : Microsoft Windows 10
# PowerShell       : Windows PowerShell 5.1
# Required Utility : Standard Windows PowerShell cmdlets
# Permissions      : Read access to reference and input directories
#                    Write access to destination directories
#                    Appropriate permissions to move input files
#
# IMPORTANT NOTES
# ---------------
# 1. Test the script with a small sample before processing important files.
# 2. Back up important data before running a large file-movement operation.
# 3. Review the log file to identify skipped files and processing errors.
# 4. Filename matching alone does not verify file contents or file identity.
# 5. Different files may share the same base filename in different directories.
# 6. Ambiguous matches are intentionally skipped rather than guessed.
# 7. Filesystem permissions, locked files, network failures, or antivirus
#    software may prevent individual operations from completing successfully.
# 8. Administrator privileges do not guarantee access to every protected file.
#
# =============================================================================
# END OF SCRIPT DOCUMENTATION
# =============================================================================

$ErrorActionPreference = 'Stop'

# Automatically restart this script as Administrator.
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {
    if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
        Write-Host 'Save this script as a .ps1 file before running it.' -ForegroundColor Red
        Read-Host 'Press Enter to exit'
        exit 1
    }

    try {
        $powershellExe = Join-Path $env:SystemRoot `
            'System32\WindowsPowerShell\v1.0\powershell.exe'

        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $PSCommandPath

        Start-Process -FilePath $powershellExe `
            -ArgumentList $arguments `
            -Verb RunAs

        exit
    }
    catch {
        Write-Host ("Administrator launch failed: {0}" -f $_.Exception.Message) `
            -ForegroundColor Red
        Read-Host 'Press Enter to exit'
        exit 1
    }
}

# Configure the console.
$Host.UI.RawUI.WindowTitle = 'BLUEPRINT FILE ROUTER'
try {
    $Host.UI.RawUI.BackgroundColor = 'Black'
    $Host.UI.RawUI.ForegroundColor = 'Gray'
    Clear-Host
}
catch {
    # Continue if console appearance cannot be changed.
}

# Display the application banner.
Write-Host ''
Write-Host '====================================================' -ForegroundColor DarkCyan
Write-Host '               BLUEPRINT FILE ROUTER' -ForegroundColor Cyan
Write-Host '          Recursive Filename Matching Tool' -ForegroundColor White
Write-Host '====================================================' -ForegroundColor DarkCyan
Write-Host ''

# Create a timestamped log file.
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$script:LogPath = Join-Path $env:TEMP "BlueprintRouter_$stamp.log"

# Normalize a filesystem path.
function Get-NormalizedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $rootPath = [System.IO.Path]::GetPathRoot($fullPath)

    if ($fullPath.Length -gt $rootPath.Length) {
        $fullPath = $fullPath.TrimEnd([char[]]@('\', '/'))
    }

    return $fullPath
}

# Check whether two paths are equal or one is inside the other.
function Test-PathsOverlap {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathA,

        [Parameter(Mandatory = $true)]
        [string]$PathB
    )

    $a = Get-NormalizedPath -Path $PathA
    $b = Get-NormalizedPath -Path $PathB

    if ($a.Equals($b, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    $prefixA = $a.TrimEnd('\') + '\'
    $prefixB = $b.TrimEnd('\') + '\'

    return (
        $b.StartsWith($prefixA, [System.StringComparison]::OrdinalIgnoreCase) -or
        $a.StartsWith($prefixB, [System.StringComparison]::OrdinalIgnoreCase)
    )
}

# Write a message to the log and the console.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $line = '{0} [{1}] {2}' -f (
        Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    ), $Level, $Message

    Add-Content -LiteralPath $script:LogPath -Value $line -Encoding UTF8

    switch ($Level) {
        'SUCCESS' { Write-Host $Message -ForegroundColor Green }
        'WARNING' { Write-Host $Message -ForegroundColor Yellow }
        'ERROR'   { Write-Host $Message -ForegroundColor Red }
        default   { Write-Host $Message -ForegroundColor Gray }
    }
}

try {
    # Collect the three required paths.
    $referenceInput = (Read-Host 'Reference folder').Trim().Trim('"')
    $inputInput = (Read-Host 'Folder containing files to move').Trim().Trim('"')
    $destinationInput = (Read-Host 'Destination root folder').Trim().Trim('"')

    if ([string]::IsNullOrWhiteSpace($referenceInput) -or
        [string]::IsNullOrWhiteSpace($inputInput) -or
        [string]::IsNullOrWhiteSpace($destinationInput)) {
        throw 'All three folder paths are required.'
    }

    $reference = Get-NormalizedPath -Path $referenceInput
    $inputRoot = Get-NormalizedPath -Path $inputInput
    $destination = Get-NormalizedPath -Path $destinationInput

    # Validate all input paths.
    if (-not (Test-Path -LiteralPath $reference -PathType Container)) {
        throw "Reference folder does not exist: $reference"
    }

    if (-not (Test-Path -LiteralPath $inputRoot -PathType Container)) {
        throw "Input folder does not exist: $inputRoot"
    }

    # Prevent recursive scans and accidental movement into source trees.
    if (Test-PathsOverlap -PathA $reference -PathB $inputRoot) {
        throw 'Reference and input folders must not overlap.'
    }

    if (Test-PathsOverlap -PathA $reference -PathB $destination) {
        throw 'Reference and destination folders must not overlap.'
    }

    if (Test-PathsOverlap -PathA $inputRoot -PathB $destination) {
        throw 'Input and destination folders must not overlap.'
    }

    # Ask for explicit confirmation before moving files.
    Write-Host ''
    Write-Host 'REFERENCE   : ' -NoNewline -ForegroundColor DarkCyan
    Write-Host $reference -ForegroundColor White
    Write-Host 'INPUT       : ' -NoNewline -ForegroundColor DarkCyan
    Write-Host $inputRoot -ForegroundColor White
    Write-Host 'DESTINATION : ' -NoNewline -ForegroundColor DarkCyan
    Write-Host $destination -ForegroundColor White
    Write-Host 'LOG         : ' -NoNewline -ForegroundColor DarkCyan
    Write-Host $script:LogPath -ForegroundColor White
    Write-Host ''
    Write-Host 'Matching ignores file extensions.' -ForegroundColor Cyan
    Write-Host 'Matched files will be MOVED, not copied.' -ForegroundColor Yellow
    Write-Host 'Existing destination files will never be overwritten.' `
        -ForegroundColor Yellow
    Write-Host ''

    $confirmation = Read-Host 'Type MOVE to continue'

    if ($confirmation -cne 'MOVE') {
        Write-Host 'Operation cancelled.' -ForegroundColor Yellow
        exit
    }

    # Build the reference blueprint.
    Write-Host ''
    Write-Host 'Building filename blueprint...' -ForegroundColor Cyan

    $blueprint = @{}
    $referenceFiles = @(
        Get-ChildItem -LiteralPath $reference -File -Recurse -Force
    )

    foreach ($file in $referenceFiles) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

        if ([string]::IsNullOrWhiteSpace($baseName)) {
            continue
        }

        $key = $baseName.ToLowerInvariant()
        $relativeDirectory = $file.DirectoryName.Substring(
            $reference.Length
        ).TrimStart([char[]]@('\', '/'))

        if (-not $blueprint.ContainsKey($key)) {
            $blueprint[$key] = New-Object 'System.Collections.Generic.List[object]'
        }

        $blueprint[$key].Add([PSCustomObject]@{
            Name = $file.Name
            RelativeDirectory = $relativeDirectory
            ReferencePath = $file.FullName
        })
    }

    Write-Host ("Reference files indexed: {0}" -f $referenceFiles.Count) `
        -ForegroundColor Gray

    # Collect input files before moving any of them.
    $inputFiles = @(
        Get-ChildItem -LiteralPath $inputRoot -File -Recurse -Force
    )

    # Initialize counters.
    $matched = 0
    $notFound = 0
    $ambiguous = 0
    $failed = 0

    Write-Host ''
    Write-Host 'Matching and moving files...' -ForegroundColor Cyan
    Write-Log 'Operation started.'
    Write-Log "Reference root: $reference"
    Write-Log "Input root: $inputRoot"
    Write-Log "Destination root: $destination"

    # Process each input file.
    $total = $inputFiles.Count
    $index = 0

    foreach ($file in $inputFiles) {
        $index++

        if ($total -gt 0) {
            $percent = [int](100 * $index / $total)
            Write-Progress -Activity 'Matching files' `
                -Status ("File {0} of {1}: {2}" -f $index, $total, $file.Name) `
                -PercentComplete $percent
        }

        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

        if ([string]::IsNullOrWhiteSpace($baseName)) {
            $notFound++
            Write-Log "Skipped empty basename: $($file.FullName)" 'WARNING'
            continue
        }

        $key = $baseName.ToLowerInvariant()

        if (-not $blueprint.ContainsKey($key)) {
            $notFound++
            Write-Log "No reference match: $($file.FullName)" 'WARNING'
            continue
        }

        $candidates = $blueprint[$key]

        # Never guess if the same basename appears in multiple reference folders.
        if ($candidates.Count -ne 1) {
            $ambiguous++
            Write-Log (
                "Ambiguous basename: {0}; reference matches: {1}" -f
                $baseName, $candidates.Count
            ) 'WARNING'
            continue
        }

        $relativeDirectory = $candidates[0].RelativeDirectory

        if ([string]::IsNullOrWhiteSpace($relativeDirectory)) {
            $targetDirectory = $destination
        }
        else {
            $targetDirectory = Join-Path $destination $relativeDirectory
        }

        try {
            # Create the destination directory when necessary.
            if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
                New-Item -ItemType Directory -Path $targetDirectory -Force |
                    Out-Null
            }

            $targetFile = Join-Path $targetDirectory $file.Name

            # Do not overwrite an existing file.
            if (Test-Path -LiteralPath $targetFile) {
                $failed++
                Write-Log "Destination file already exists: $targetFile" 'ERROR'
                continue
            }

            # Move the matched file and preserve its original filename.
            Move-Item -LiteralPath $file.FullName -Destination $targetFile

            $matched++
            Write-Log (
                "Moved: {0} -> {1}" -f $file.FullName, $targetFile
            ) 'SUCCESS'
        }
        catch {
            $failed++
            Write-Log (
                "Move failed: {0} | {1}" -f
                $file.FullName, $_.Exception.Message
            ) 'ERROR'
        }
    }

    Write-Progress -Activity 'Matching files' -Completed

    # Display final results.
    Write-Host ''
    Write-Host '====================================================' -ForegroundColor DarkCyan
    Write-Host '                    SUMMARY' -ForegroundColor Cyan
    Write-Host '====================================================' -ForegroundColor DarkCyan
    Write-Host ("Input files : {0}" -f $total)
    Write-Host ("Moved       : {0}" -f $matched) -ForegroundColor Green
    Write-Host ("Not matched : {0}" -f $notFound) -ForegroundColor Yellow
    Write-Host ("Ambiguous   : {0}" -f $ambiguous) -ForegroundColor Yellow
    Write-Host ("Failed      : {0}" -f $failed) -ForegroundColor Red
    Write-Host ("Log file    : {0}" -f $script:LogPath) -ForegroundColor Gray

    Write-Log (
        "Completed. Total={0}; Moved={1}; NotMatched={2}; Ambiguous={3}; Failed={4}" -f
        $total, $matched, $notFound, $ambiguous, $failed
    )
}
catch {
    Write-Host ''
    Write-Host 'OPERATION ERROR' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    try {
        Write-Log $_.Exception.Message 'ERROR'
        Write-Host ("Log file: {0}" -f $script:LogPath) -ForegroundColor Gray
    }
    catch {
        # Keep the original error visible if logging also fails.
    }
}
finally {
    Write-Host ''
    Read-Host 'Press Enter to exit'
}
```

