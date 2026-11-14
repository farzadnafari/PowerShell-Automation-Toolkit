# ============================================================
#                  PORTABLE SOFTWARE BUILDER
# ============================================================
#
# DESCRIPTION:
# This script provides a simple PowerShell-based utility for
# copying installed software folders into a separate output
# directory while preserving their original folder structure.
#
# FEATURES:
# - Single Software Processing Mode.
# - Batch Software Processing Mode.
# - Custom Source and Destination Folder Selection.
# - Automatic Folder Structure Preservation.
# - Recursive File and Directory Copying.
# - Robocopy-Based File Transfer.
# - Basic Error Handling and Copy Status Reporting.
#
# SINGLE MODE:
# - Select one installed software folder.
# - Specify the destination parent directory.
# - Copy the selected software into the destination.
#
# BATCH MODE:
# - Select a parent directory containing multiple software
#   folders.
# - Specify an output parent directory.
# - Automatically process each immediate subdirectory.
#
# IMPORTANT NOTES:
# - This script performs file copying, not true portable
#   application conversion.
# - Registry entries, Windows services, external dependencies,
#   and user-specific settings are not migrated.
# - Copied applications may still depend on the original
#   Windows installation environment.
#
# REQUIREMENTS:
# - Windows operating system.
# - Windows PowerShell 5.1 or later.
# - Robocopy utility.
#
# ============================================================
# VERSION: 1.0
# PLATFORM: Windows
# LANGUAGE: PowerShell
# ============================================================

$ErrorActionPreference = "Stop"

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "PORTABLE SOFTWARE BUILDER" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Read-ValidPath {
    param(
        [string]$Message,
        [bool]$MustExist = $true
    )

    while ($true) {
        $path = Read-Host $Message

        if ([string]::IsNullOrWhiteSpace($path)) {
            Write-Host "Path cannot be empty." -ForegroundColor Red
            continue
        }

        $path = [Environment]::ExpandEnvironmentVariables(
            $path.Trim().Trim('"')
        )

        if ($MustExist -and !(Test-Path -LiteralPath $path -PathType Container)) {
            Write-Host "Directory does not exist." -ForegroundColor Red
            continue
        }

        return [System.IO.Path]::GetFullPath($path)
    }
}

function Copy-Software {
    param(
        [string]$Source,
        [string]$Destination
    )

    try {
        $softwareName = Split-Path $Source -Leaf

        if (!(Test-Path -LiteralPath $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force |
                Out-Null
        }

        Write-Host ""
        Write-Host "[+] Processing: $softwareName" -ForegroundColor Yellow

        $robocopyArgs = @(
            $Source
            $Destination
            "/E"
            "/COPY:DAT"
            "/DCOPY:DAT"
            "/R:2"
            "/W:2"
            "/XJ"
            "/NFL"
            "/NDL"
            "/NP"
            "/NJH"
            "/NJS"
        )

        & robocopy.exe @robocopyArgs | Out-Null

        $result = $LASTEXITCODE

        if ($result -le 7) {
            Write-Host "[SUCCESS] $softwareName" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "[FAILED] $softwareName (Robocopy code: $result)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Start-SingleMode {

    Write-Host ""
    Write-Host "========== SINGLE SOFTWARE MODE ==========" -ForegroundColor Cyan

    $source = Read-ValidPath "Enter software folder path"
    $output = Read-ValidPath "Enter output folder path" $false

    $name = Split-Path $source -Leaf
    $destination = Join-Path $output $name

    $null = Copy-Software -Source $source -Destination $destination
}

function Start-BatchMode {

    Write-Host ""
    Write-Host "========== BATCH SOFTWARE MODE ==========" -ForegroundColor Cyan

    $sourceRoot = Read-ValidPath "Enter parent software folder path"
    $outputRoot = Read-ValidPath "Enter output parent folder path" $false

    if ([System.IO.Path]::GetFullPath($sourceRoot).TrimEnd('\') -eq
        [System.IO.Path]::GetFullPath($outputRoot).TrimEnd('\')) {

        Write-Host "Source and output folders cannot be identical." -ForegroundColor Red
        return
    }

    $softwareFolders = @(
        Get-ChildItem -LiteralPath $sourceRoot -Directory -Force |
        Where-Object {
            $_.FullName -ne $outputRoot
        }
    )

    if ($softwareFolders.Count -eq 0) {
        Write-Host "No software folders found." -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "Found $($softwareFolders.Count) software folders." -ForegroundColor Green

    $successCount = 0
    $failedCount = 0

    foreach ($folder in $softwareFolders) {

        $destination = Join-Path $outputRoot $folder.Name

        $result = Copy-Software `
            -Source $folder.FullName `
            -Destination $destination

        if ($result) {
            $successCount++
        }
        else {
            $failedCount++
        }
    }

    Write-Host ""
    Write-Host "=============== SUMMARY ===============" -ForegroundColor Cyan
    Write-Host "Total:   $($softwareFolders.Count)"
    Write-Host "Success: $successCount" -ForegroundColor Green
    Write-Host "Failed:  $failedCount" -ForegroundColor Red
}

# ============================================================
# MAIN MENU
# ============================================================

while ($true) {

    Show-Header

    Write-Host "1. Portable One Software" -ForegroundColor White
    Write-Host "2. Portable Multiple Software (Batch)" -ForegroundColor White
    Write-Host "0. Exit" -ForegroundColor Red

    Write-Host ""
    $choice = Read-Host "Select an option"

    switch ($choice) {

        "1" {
            Start-SingleMode
        }

        "2" {
            Start-BatchMode
        }

        "0" {
            Write-Host "Goodbye!" -ForegroundColor Green
            break
        }

        default {
            Write-Host "Invalid option." -ForegroundColor Red
        }
    }

    if ($choice -eq "0") {
        break
    }

    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}