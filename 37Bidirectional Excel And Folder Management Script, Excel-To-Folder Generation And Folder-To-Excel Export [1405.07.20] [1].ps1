# Excel <-> Folder Structure Automation Manager
# Project Description
# Windows 10 / Windows PowerShell 5.1+
# --------------------------------------------------------
# PROJECT OVERVIEW
# This project combines two PowerShell scripts into a
# bidirectional Excel and folder management solution.
# 
# 1. AUTOMATIC NUGET + IMPORTEXCEL INSTALLER
#    Prepares the environment by checking the PowerShell
#    version, enabling TLS 1.2, installing or verifying
#    the NuGet provider, configuring PowerShell Gallery,
#    and installing or loading the ImportExcel module.
#    It also verifies that the module can be loaded and
#    displays installation status and diagnostic errors.
# 
# 2. EXCEL -> FOLDERS
#    Reads data from an Excel (.xlsx) worksheet and creates
#    folders based on selected columns in each data row.
#    Selected cell values are trimmed and combined into
#    folder names. Invalid Windows filename characters
#    are sanitized, empty rows are skipped, and existing
#    folders are preserved rather than recreated.
# 
# 3. FOLDERS -> EXCEL
#    Reads the names of subfolders inside a selected
#    directory and exports them to an Excel (.xlsx) file.
#    Each folder name can be divided into three columns
#    using configurable prefix and suffix lengths.
#    The middle section is stored in the second column.
#    Short names are skipped when they cannot be split
#    using the requested lengths.
# 
# 4. MAIN MENU AND ERROR HANDLING
#    Provides an interactive console menu to select
#    either conversion operation or exit the application.
#    Validates user input and file paths, creates missing
#    output directories, prompts before overwriting an
#    existing Excel file, and displays operation results
#    and error messages.
# 
# KEY FEATURES
# - Bidirectional Excel and folder conversion.
# - Automatic dependency setup.
# - Folder-name sanitization and basic validation.
# - Duplicate-folder protection.
# - Configurable Excel-to-folder column selection.
# - Configurable folder-name splitting.
# - Interactive menu and error handling.
# 
# REQUIREMENTS
# - Windows 10
# - Windows PowerShell 5.1+
# - Internet access for downloading dependencies,
#   when they are not already installed.
# - ImportExcel PowerShell module.
# 
# NOTE
# The installer and the manager are separate scripts.
# Run the installer first when necessary, then launch
# the Folder-Excel-Manager.ps1 script.
# The current implementation processes direct subfolders
# only and creates one folder per eligible Excel row.

# ========================================================
# GENERATED MENU APPLICATION
# ========================================================
# Menu functions are defined below.
# Insert your own PowerShell code inside each function.

function MenuOption01 {
# ========================================================
# AUTOMATIC NUGET + IMPORTEXCEL INSTALLER
# --------------------------------------------------------
# Platform       : Windows 10
# Shell          : Windows PowerShell 5.1
# Purpose        : Automated dependency setup and verification
# Main Module    : ImportExcel
# Package Provider: NuGet
# Repository     : PowerShell Gallery (PSGallery)
# --------------------------------------------------------
# DESCRIPTION:
# This script prepares the PowerShell environment required
# by the Excel <-> Folder Structure Automation Manager.
#
# It checks the PowerShell environment, enables TLS 1.2,
# verifies and installs the NuGet package provider when
# necessary, checks PowerShell Gallery availability, and
# installs or verifies the ImportExcel module.
#
# The script then imports ImportExcel, verifies that the
# module is loaded, and displays its version and installation
# status. If an error occurs, diagnostic information and
# troubleshooting guidance are provided.
#
# INSTALLATION SCOPE:
# Dependencies are installed for the current user whenever
# supported, minimizing the need for system-wide changes.
#
# REQUIREMENTS:
# - Windows 10
# - Windows PowerShell 5.1
# - Internet access when downloading dependencies
# - Appropriate permissions and repository access
#
# USAGE:
# Run this installer before launching Folder-Excel-Manager.ps1
# if the required ImportExcel module is not yet available.
# ========================================================

$ErrorActionPreference = "Stop"

function Write-Status {
        param(
            [string]$Message,
            [string]$Color = "Cyan"
        )
        Write-Host "`n[$Message]" -ForegroundColor $Color
    }

    try {
        Write-Status "Checking PowerShell version"

        $PSVersionTable.PSVersion.ToString() | Write-Host

        # 1. Enable TLS 1.2 for PowerShell Gallery
        Write-Status "Enabling TLS 1.2"

        [Net.ServicePointManager]::SecurityProtocol =
            [Net.ServicePointManager]::SecurityProtocol -bor
            [Net.SecurityProtocolType]::Tls12

        # 2. Ensure NuGet provider is installed
        Write-Status "Checking NuGet provider"

        $NuGet = Get-PackageProvider -ListAvailable -Name NuGet `
            -ErrorAction SilentlyContinue |
            Where-Object { $_.Version -ge [version]"2.8.5.201" } |
            Select-Object -First 1

        if (-not $NuGet) {
            Write-Status "Installing NuGet provider"

            Install-PackageProvider `
                -Name NuGet `
                -MinimumVersion 2.8.5.201 `
                -Scope CurrentUser `
                -Force `
                -ErrorAction Stop | Out-Null
        }

        Import-PackageProvider -Name NuGet -Force | Out-Null

        # 3. Ensure PowerShell Gallery is available
        Write-Status "Checking PowerShell Gallery"

        $Repository = Get-PSRepository -Name PSGallery `
            -ErrorAction SilentlyContinue

        if (-not $Repository) {
            Register-PSRepository -Default -ErrorAction Stop
        }

        Set-PSRepository `
            -Name PSGallery `
            -InstallationPolicy Trusted

        # 4. Check whether ImportExcel is already installed
        Write-Status "Checking ImportExcel module"

        $Module = Get-Module -ListAvailable -Name ImportExcel |
            Sort-Object Version -Descending |
            Select-Object -First 1

        if (-not $Module) {
            Write-Status "Installing ImportExcel"

            Install-Module `
                -Name ImportExcel `
                -Repository PSGallery `
                -Scope CurrentUser `
                -Force `
                -AllowClobber `
                -ErrorAction Stop
        }
        else {
            Write-Host "ImportExcel is already installed: $($Module.Version)" `
                -ForegroundColor Green
        }

        # 5. Import and test the module
        Write-Status "Testing ImportExcel"

        Import-Module ImportExcel -ErrorAction Stop

        $LoadedModule = Get-Module ImportExcel

        if (-not $LoadedModule) {
            throw "ImportExcel could not be loaded."
        }

        Write-Host "`n========================================================" -ForegroundColor Green
        Write-Host " INSTALLATION SUCCESSFUL" -ForegroundColor Green
        Write-Host " ImportExcel: $($LoadedModule.Version)" -ForegroundColor Green
        Write-Host "========================================================" -ForegroundColor Green

        Write-Host "`nYou can now run Folder-Excel-Manager.ps1." `
            -ForegroundColor Cyan
    }
    catch {
        Write-Host "`nINSTALLATION FAILED" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

        Write-Host "`nDiagnostic details:" -ForegroundColor Yellow
        Write-Host "PowerShell: $($PSVersionTable.PSVersion)"
        Write-Host "User: $env:USERNAME"

        Write-Host "`nIf the error mentions TLS, proxy, DNS, or network access,"
        Write-Host "check your internet connection and try again."
        Write-Host "If access is denied, try running PowerShell as Administrator."
    }

    Read-Host "`nPress Enter to exit"
}

function MenuOption02 {
    $ErrorActionPreference = "Stop"

    # Install and load ImportExcel if necessary
    function Initialize-ExcelModule {
        if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
            Write-Host "`nImportExcel module is required." -ForegroundColor Yellow
            $answer = Read-Host "Install it now? (Y/N)"

            if ($answer -notin @("Y", "y")) {
                throw "ImportExcel module is not installed."
            }

            Install-Module ImportExcel -Scope CurrentUser -Force
        }

        Import-Module ImportExcel -ErrorAction Stop
    }

    function Read-NonNegativeInteger {
        param([string]$Prompt)

        while ($true) {
            $value = Read-Host $Prompt
            $number = 0

            if ([int]::TryParse($value, [ref]$number) -and $number -ge 0) {
                return $number
            }

            Write-Host "Enter a non-negative integer." -ForegroundColor Yellow
        }
    }

    function Get-ValidFolderName {
        param([string]$Name)

        # Replace Windows-invalid characters with #
        $result = $Name -replace '[\\/:*?"<>|\x00-\x1F]', '#'

        # Windows does not allow trailing spaces or dots
        $result = $result -replace '[ .]+$', '#'

        if ([string]::IsNullOrWhiteSpace($result)) {
            $result = "#"
        }

        # Avoid reserved Windows device names
        if ($result -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\..*)?$') {
            $result = "#$result"
        }

        # Keep the name within a practical length
        if ($result.Length -gt 200) {
            $result = $result.Substring(0, 200)
        }

        return $result
    }

    # --------------------------------------------------------
    # OPTION 1: Excel rows -> folders
    # --------------------------------------------------------

    function Convert-ExcelToFolders {
        Initialize-ExcelModule

        $ExcelPath = Read-Host "Enter Excel file path (.xlsx)"
        $ExcelPath = $ExcelPath.Trim().Trim('"')

        if (-not (Test-Path -LiteralPath $ExcelPath -PathType Leaf)) {
            throw "Excel file not found."
        }

        $OutputPath = Read-Host "Enter output folder path"
        $OutputPath = $OutputPath.Trim().Trim('"')

        if ([string]::IsNullOrWhiteSpace($OutputPath)) {
            throw "Output path cannot be empty."
        }

        $ColumnCount = Read-NonNegativeInteger `
            "How many columns should be used?"

        if ($ColumnCount -lt 1) {
            throw "Column count must be at least 1."
        }

        # Use the first worksheet; first row is the header
        $Rows = @(Import-Excel -Path $ExcelPath)

        if ($Rows.Count -eq 0) {
            Write-Host "No data rows found." -ForegroundColor Yellow
            return
        }

        $Headers = @($Rows[0].PSObject.Properties.Name)

        if ($ColumnCount -gt $Headers.Count) {
            throw "The requested column count exceeds the available columns ($($Headers.Count))."
        }

        if (-not (Test-Path -LiteralPath $OutputPath -PathType Container)) {
            New-Item -ItemType Directory -Path $OutputPath -Force |
                Out-Null
        }

        $Created = 0
        $Skipped = 0

        foreach ($Row in $Rows) {
            $Parts = @()

            # Use the first N columns, in their Excel order
            for ($c = 0; $c -lt $ColumnCount; $c++) {
                $Value = $Row.($Headers[$c])

                if ($null -ne $Value) {
                    $TextValue = [string]$Value

                    if (-not [string]::IsNullOrWhiteSpace($TextValue)) {
                        $Parts += $TextValue.Trim()
                    }
                }
            }

            # Skip rows where all selected cells are empty
            if ($Parts.Count -eq 0) {
                $Skipped++
                continue
            }

            # Join cell values with a single space
            $FolderName = $Parts -join " "
            $FolderName = Get-ValidFolderName $FolderName

            $Destination = Join-Path $OutputPath $FolderName

            if (Test-Path -LiteralPath $Destination) {
                Write-Host "Already exists: $FolderName" -ForegroundColor Yellow
                $Skipped++
                continue
            }

            New-Item -ItemType Directory -Path $Destination |
                Out-Null

            Write-Host "Created: $FolderName" -ForegroundColor Green
            $Created++
        }

        Write-Host "`nCreated: $Created | Skipped: $Skipped" `
            -ForegroundColor Cyan
    }

    # --------------------------------------------------------
    # OPTION 2: Folder names -> Excel columns
    # --------------------------------------------------------

    function Convert-FoldersToExcel {
        Initialize-ExcelModule

        $SourcePath = Read-Host "Enter source folder path"
        $SourcePath = $SourcePath.Trim().Trim('"')

        if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
            throw "Source folder not found."
        }

        $OutputFile = Read-Host "Enter output Excel file path (.xlsx)"
        $OutputFile = $OutputFile.Trim().Trim('"')

        if ([string]::IsNullOrWhiteSpace($OutputFile) -or
            [IO.Path]::GetExtension($OutputFile) -ine ".xlsx") {
            throw "Output file must have an .xlsx extension."
        }

        $PrefixLength = Read-NonNegativeInteger `
            "Length for column 1 (prefix)"

        $SuffixLength = Read-NonNegativeInteger `
            "Length for column 3 (suffix)"

        $Folders = @(
            Get-ChildItem -LiteralPath $SourcePath -Directory |
                Sort-Object Name
        )

        if ($Folders.Count -eq 0) {
            Write-Host "No subfolders found." -ForegroundColor Yellow
            return
        }

        $Results = @()
        $Skipped = 0

        foreach ($Folder in $Folders) {
            $Name = $Folder.Name

            # If either length is zero, put the full name in column 2
            if ($PrefixLength -eq 0 -or $SuffixLength -eq 0) {
                $Prefix = ""
                $Middle = $Name
                $Suffix = ""
            }
            else {
                if (($PrefixLength + $SuffixLength) -gt $Name.Length) {
                    Write-Host "Skipped (name too short): $Name" `
                        -ForegroundColor Yellow
                    $Skipped++
                    continue
                }

                $Prefix = $Name.Substring(0, $PrefixLength)

                $MiddleLength = $Name.Length - $PrefixLength - $SuffixLength

                $Middle = $Name.Substring(
                    $PrefixLength,
                    $MiddleLength
                )

                $Suffix = $Name.Substring(
                    $Name.Length - $SuffixLength,
                    $SuffixLength
                )
            }

            $Results += [PSCustomObject]@{
                Column1 = $Prefix
                Column2 = $Middle
                Column3 = $Suffix
            }
        }

        if ($Results.Count -eq 0) {
            Write-Host "No folders could be exported." -ForegroundColor Yellow
            return
        }

        $ParentPath = Split-Path -Parent $OutputFile

        if ([string]::IsNullOrWhiteSpace($ParentPath)) {
            $OutputFile = Join-Path (Get-Location).Path $OutputFile
            $ParentPath = Split-Path -Parent $OutputFile
        }

        if (-not (Test-Path -LiteralPath $ParentPath -PathType Container)) {
            New-Item -ItemType Directory -Path $ParentPath -Force |
                Out-Null
        }

        if (Test-Path -LiteralPath $OutputFile) {
            $Overwrite = Read-Host "Excel file already exists. Overwrite? (Y/N)"

            if ($Overwrite -notin @("Y", "y")) {
                Write-Host "Export cancelled." -ForegroundColor Yellow
                return
            }
        }

        $Results | Export-Excel `
            -Path $OutputFile `
            -WorksheetName "Folders" `
            -AutoSize `
            -ClearSheet

        Write-Host "`nExcel file created: $OutputFile" `
            -ForegroundColor Green

        Write-Host "Exported: $($Results.Count) | Skipped: $Skipped" `
            -ForegroundColor Cyan
    }

    # --------------------------------------------------------
    # MAIN MENU
    # --------------------------------------------------------

    while ($true) {
        Clear-Host

        Write-Host "========================================================" -ForegroundColor Cyan
        Write-Host "FOLDER & EXCEL MANAGER" -ForegroundColor Cyan
        Write-Host "========================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Excel -> Create folders"
        Write-Host "2. Folder names -> Excel columns"
        Write-Host "0. Exit"
        Write-Host ""

        $Choice = Read-Host "Select an option"

        try {
            switch ($Choice) {
                "1" {
                    Convert-ExcelToFolders
                    Read-Host "`nPress Enter to return to menu"
                }

                "2" {
                    Convert-FoldersToExcel
                    Read-Host "`nPress Enter to return to menu"
                }

                "0" {
                    Write-Host "Goodbye!" -ForegroundColor Cyan
                    return
                }

                default {
                    Write-Host "Invalid option." -ForegroundColor Red
                    Start-Sleep -Seconds 2
                }
            }
        }
        catch {
            Write-Host "`nERROR: $($_.Exception.Message)" `
                -ForegroundColor Red

            Read-Host "Press Enter to return to menu"
        }
    }
}

while ($true) {
    Clear-Host

    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "PROJECT MENU" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    Write-Host "PROJECT DESCRIPTION" -ForegroundColor Yellow
    Write-Host "--------------------------------------------------------"
    Write-Host "Excel <-> Folder Structure Automation Manager"
    Write-Host "Project Description"
    Write-Host "Windows 10 / Windows PowerShell 5.1+"
    Write-Host "--------------------------------------------------------"
    Write-Host "PROJECT OVERVIEW"
    Write-Host "This project combines two PowerShell scripts into a"
    Write-Host "bidirectional Excel and folder management solution."
    Write-Host ""
    Write-Host "1. AUTOMATIC NUGET + IMPORTEXCEL INSTALLER"
    Write-Host "   Prepares the environment by checking the PowerShell"
    Write-Host "   version, enabling TLS 1.2, installing or verifying"
    Write-Host "   the NuGet provider, configuring PowerShell Gallery,"
    Write-Host "   and installing or loading the ImportExcel module."
    Write-Host "   It also verifies that the module can be loaded and"
    Write-Host "   displays installation status and diagnostic errors."
    Write-Host ""
    Write-Host "2. EXCEL -> FOLDERS"
    Write-Host "   Reads data from an Excel (.xlsx) worksheet and creates"
    Write-Host "   folders based on selected columns in each data row."
    Write-Host "   Selected cell values are trimmed and combined into"
    Write-Host "   folder names. Invalid Windows filename characters"
    Write-Host "   are sanitized, empty rows are skipped, and existing"
    Write-Host "   folders are preserved rather than recreated."
    Write-Host ""
    Write-Host "3. FOLDERS -> EXCEL"
    Write-Host "   Reads the names of subfolders inside a selected"
    Write-Host "   directory and exports them to an Excel (.xlsx) file."
    Write-Host "   Each folder name can be divided into three columns"
    Write-Host "   using configurable prefix and suffix lengths."
    Write-Host "   The middle section is stored in the second column."
    Write-Host "   Short names are skipped when they cannot be split"
    Write-Host "   using the requested lengths."
    Write-Host ""
    Write-Host "4. MAIN MENU AND ERROR HANDLING"
    Write-Host "   Provides an interactive console menu to select"
    Write-Host "   either conversion operation or exit the application."
    Write-Host "   Validates user input and file paths, creates missing"
    Write-Host "   output directories, prompts before overwriting an"
    Write-Host "   existing Excel file, and displays operation results"
    Write-Host "   and error messages."
    Write-Host ""
    Write-Host "KEY FEATURES"
    Write-Host "- Bidirectional Excel and folder conversion."
    Write-Host "- Automatic dependency setup."
    Write-Host "- Folder-name sanitization and basic validation."
    Write-Host "- Duplicate-folder protection."
    Write-Host "- Configurable Excel-to-folder column selection."
    Write-Host "- Configurable folder-name splitting."
    Write-Host "- Interactive menu and error handling."
    Write-Host ""
    Write-Host "REQUIREMENTS"
    Write-Host "- Windows 10"
    Write-Host "- Windows PowerShell 5.1+"
    Write-Host "- Internet access for downloading dependencies,"
    Write-Host "  when they are not already installed."
    Write-Host "- ImportExcel PowerShell module."
    Write-Host ""
    Write-Host "NOTE"
    Write-Host "The installer and the manager are separate scripts."
    Write-Host "Run the installer first when necessary, then launch"
    Write-Host "the Folder-Excel-Manager.ps1 script."
    Write-Host "The current implementation processes direct subfolders"
    Write-Host "only and creates one folder per eligible Excel row."
    Write-Host "--------------------------------------------------------`n"

    Write-Host '1. Automatic NuGet + ImportExcel Installer'
    Write-Host '2. Excel ↔ Folder Structure Automation Manager'
    Write-Host "0. Exit`n"

    $Choice = Read-Host "Select an option"

    switch ($Choice) {
        '1' {
            MenuOption01
            Read-Host "Press Enter to return to menu"
        }
        '2' {
            MenuOption02
            Read-Host "Press Enter to return to menu"
        }
        '0' { break }
        default {
            Write-Host "Invalid selection." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }

    if ($Choice -eq "0") { break }
}