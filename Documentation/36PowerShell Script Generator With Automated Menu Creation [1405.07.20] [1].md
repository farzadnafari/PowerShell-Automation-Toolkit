
> [!INFO] تولیدکننده خودکار قالب منو و توابع PowerShell
> تعداد و عناوین گزینه‌های منوی تعاملی را از طریق یک فایل متنی پیکربندی دریافت می‌کند.
> مستندات پروژه شامل نام، نسخه، هدف، توضیحات و اطلاعات تکمیلی را از یک فایل متنی جداگانه استخراج می‌کند.
> تعداد گزینه‌های منو، معتبر بودن تنظیمات و کافی بودن عناوین ورودی را پیش از تولید اسکریپت بررسی می‌کند.
> برای هر گزینه منو، یک تابع مستقل با نام‌گذاری ترتیبی مانند MenuOption01 و MenuOption02 ایجاد می‌کند.
> داخل هر تابع یک بخش Placeholder قرار می‌دهد تا کاربر بتواند دستورات و منطق اختصاصی خود را به آن اضافه کند.
> مستندات دریافت‌شده را به کامنت‌های PowerShell تبدیل کرده و در ابتدای فایل خروجی قرار می‌دهد.
> یک منوی تعاملی شماره‌گذاری‌شده ایجاد می‌کند که هر گزینه را به تابع متناظر آن متصل می‌کند.
> با انتخاب هر گزینه، تابع مربوطه اجرا شده و پس از پایان عملیات، برای بازگشت به منوی اصلی درخواست فشردن Enter نمایش داده می‌شود.
> از گزینه صفر برای خروج از حلقه منوی اصلی، اعتبارسنجی انتخاب‌ها و نمایش پیام خطا برای ورودی‌های نامعتبر پشتیبانی می‌کند.
> اسکریپت نهایی را با کدگذاری UTF-8 همراه با BOM و پشتیبانی از متون فارسی و انگلیسی در مسیر دلخواه کاربر با پسوند PS1 تولید می‌کند.


> [!INFO] PowerShell Menu And Function Template Generator
> Retrieves The Number And Titles Of Interactive Menu Options From A Text Configuration File.
> Extracts Project Documentation, Including Name, Version, Purpose, Description, And Additional Information From A Separate Text File.
> Validates The Menu Option Count, Configuration Values, And Availability Of Sufficient Menu Titles Before Generating The Script.
> Creates A Separate Function For Each Menu Option Using Sequential Naming Such As MenuOption01 And MenuOption02.
> Inserts A Placeholder Inside Each Function So The User Can Add Custom Commands And Application Logic.
> Converts The Retrieved Documentation Into PowerShell Comments And Places It At The Beginning Of The Output File.
> Generates A Numbered Interactive Menu That Connects Each Menu Option To Its Corresponding Function.
> Executes The Selected Function And Prompts The User To Press Enter Before Returning To The Main Menu.
> Supports Option Zero For Exiting The Main Menu Loop, Validates Selections, And Displays Error Messages For Invalid Inputs.
> Generates The Final Script Using UTF-8 Encoding With BOM, Supports Persian And English Text, And Saves It To The User-Defined Destination With The PS1 Extension.


```
# ============================================================
# PROJECT NAME: PowerShell Menu and Function Template Generator
# VERSION: 1.0.0
# PLATFORM: Windows PowerShell 5.1 or later
# FILE TYPE: PowerShell Script (.ps1)
# ============================================================
#
# DESCRIPTION:
# This script automatically generates a structured PowerShell
# script using two user-provided text configuration files.
#
# The generated script contains project documentation, a
# numbered interactive menu, and a separate function for each
# configured menu option.
#
# The primary objective is to simplify the creation of reusable
# PowerShell automation projects by eliminating repetitive
# manual coding and providing a consistent script structure.
#
# --------------------------------------------------------
# INPUT FILE 1: MENU CONFIGURATION
# --------------------------------------------------------
#
# The first input file defines the number and titles of the
# menu options that will appear in the generated script.
#
# The first line must contain a positive integer representing
# the total number of menu options to generate.
#
# Every subsequent non-empty line represents the title of
# one menu option.
#
# Example:
#
# 4
# Install Dependencies
# Create Folders from Excel
# Export Folder Names to Excel
# Generate Operation Report
#
# In this example, the generator creates four menu options
# and four corresponding function definitions.
#
# The first line is interpreted as configuration data and
# is not treated as a menu title.
#
# Additional titles beyond the specified number are ignored.
# If fewer titles are provided than required, the generator
# reports an error instead of creating an incomplete menu.
#
# --------------------------------------------------------
# INPUT FILE 2: PROJECT DOCUMENTATION
# --------------------------------------------------------
#
# The second input file contains the documentation that will
# appear at the beginning of the generated PowerShell script.
#
# This file can contain the project name, author, version,
# purpose, description, requirements, implementation notes,
# maintenance information, and other relevant documentation.
#
# Each line is converted into a PowerShell comment by adding
# the comment character at the beginning of the line.
#
# This keeps the project documentation readable while ensuring
# that it is not interpreted as executable PowerShell code.
#
# --------------------------------------------------------
# OUTPUT FILE
# --------------------------------------------------------
#
# The generator creates a new PowerShell script at the output
# path specified by the user.
#
# The output filename must have the .ps1 extension.
#
# The destination directory is created automatically if it
# does not already exist and can be created successfully.
#
# The generated file contains the project documentation,
# function definitions, menu presentation, and menu routing.
#
# --------------------------------------------------------
# GENERATED FUNCTION STRUCTURE
# --------------------------------------------------------
#
# One uniquely named function is generated for every menu item.
#
# Function names follow a sequential naming convention:
#
# MenuOption01
# MenuOption02
# MenuOption03
# MenuOption04
#
# The numbering continues according to the configured menu
# count, using two-digit identifiers for the initial sequence.
#
# Each function initially contains a placeholder comment.
# The user can replace the placeholder with custom PowerShell
# commands, file operations, automation logic, or other code.
#
# The function definitions are generated separately from the
# main menu to improve readability and maintainability.
#
# --------------------------------------------------------
# MAIN MENU OPERATION
# --------------------------------------------------------
#
# The generated script displays a numbered interactive menu.
#
# Each menu title is associated with a corresponding function.
#
# When a valid menu option is selected, the associated function
# is executed.
#
# After the function returns, the user is prompted to press
# Enter before returning to the main menu.
#
# Selecting option zero terminates the main menu loop.
#
# Invalid selections display an error message and allow the
# user to select another option.
#
# --------------------------------------------------------
# DESIGN AND IMPLEMENTATION PRINCIPLES
# --------------------------------------------------------
#
# 1. Separate menu presentation from application functionality.
# 2. Generate predictable and unique function names.
# 3. Minimize repetitive manual script development.
# 4. Keep generated scripts readable and easy to extend.
# 5. Preserve project documentation in the output file.
# 6. Use text files for simple and portable configuration.
# 7. Provide basic input validation and error reporting.
# 8. Allow each menu function to be developed independently.
#
# --------------------------------------------------------
# ENCODING AND INTERNATIONALIZATION
# --------------------------------------------------------
#
# Input files are read using UTF-8 encoding.
#
# The generated file is written using UTF-8 encoding with a
# byte-order mark for compatibility with Windows PowerShell 5.1.
#
# Unicode text, including Persian and English text, can be
# included in menu titles and project documentation.
#
# Menu titles are intended for display and are not interpreted
# as executable PowerShell commands.
#
# --------------------------------------------------------
# REQUIREMENTS
# --------------------------------------------------------
#
# - Windows PowerShell 5.1 or a compatible PowerShell version.
# - Read access to both input text files.
# - Write access to the output directory.
# - A valid output filename ending in .ps1.
#
# No external PowerShell modules or Microsoft Excel installation
# are required by the template generator itself.
#
# v
# ERROR HANDLING AND SAFETY
# --------------------------------------------------------
#
# The generator checks whether the input files exist and whether
# the menu configuration contains a valid positive integer.
#
# It also verifies that enough menu titles are available and
# that the output filename uses the expected file extension.
#
# These checks help prevent common configuration errors.
# They do not guarantee that subsequently added custom code
# will be free of syntax errors or runtime failures.
#
# The generated functions are placeholders and must be completed
# and tested before the resulting script is used operationally.
#
# Existing output files may be overwritten when the generator
# saves a new version. Back up important custom code beforehand.
#
# Avoid using the exit command inside a menu function unless
# terminating the entire PowerShell script is intentional.
#
# --------------------------------------------------------
# VERSION HISTORY
# --------------------------------------------------------
#
# Version 1.0.0
# Initial release of the automated menu and function generator.
#
# ============================================================

$ErrorActionPreference = "Stop"

# ============================================================
# POWERSHELL MENU GENERATOR
# ============================================================

Clear-Host

$Header = @(
    "============================================================"
    "POWERSHELL MENU AND FUNCTION GENERATOR"
    "============================================================"
    "Version    : 1.0.0"
    "Platform   : Windows PowerShell 5.1"
    "============================================================"
)

foreach ($Line in $Header) {
    Write-Host $Line -ForegroundColor Cyan
}

Write-Host ""

try {
    # --------------------------------------------------------
    # STEP 1: GET MENU CONFIGURATION FILE
    # --------------------------------------------------------

    $MenuFile = Read-Host "Enter menu TXT file path"
    $MenuFile = $MenuFile.Trim().Trim('"')

    if (-not (Test-Path -LiteralPath $MenuFile -PathType Leaf)) {
        throw "Menu configuration file was not found."
    }

    $MenuLines = @(Get-Content -LiteralPath $MenuFile -Encoding UTF8)

    if ($MenuLines.Count -eq 0) {
        throw "Menu configuration file is empty."
    }

    $MenuCount = 0

    if (-not [int]::TryParse($MenuLines[0].Trim(), [ref]$MenuCount)) {
        throw "The first line of the menu file must be a number."
    }

    if ($MenuCount -lt 1) {
        throw "The menu option count must be greater than zero."
    }

    $MenuTitles = @(
        $MenuLines |
        Select-Object -Skip 1 |
        Where-Object {
            -not [string]::IsNullOrWhiteSpace($_)
        }
    )

    if ($MenuTitles.Count -lt $MenuCount) {
        throw "The number of menu titles is less than the configured menu count."
    }

    $MenuTitles = @($MenuTitles | Select-Object -First $MenuCount)

    # --------------------------------------------------------
    # STEP 2: GET PROJECT DESCRIPTION FILE
    # --------------------------------------------------------

    Write-Host ""

    $DescriptionFile = Read-Host "Enter project description TXT path"
    $DescriptionFile = $DescriptionFile.Trim().Trim('"')

    if (-not (Test-Path -LiteralPath $DescriptionFile -PathType Leaf)) {
        throw "Project description file was not found."
    }

    $DescriptionLines = @(
        Get-Content -LiteralPath $DescriptionFile -Encoding UTF8
    )

    # Add "# " at the beginning of every description line.
    $CommentLines = @(
        foreach ($Line in $DescriptionLines) {
            "# " + $Line
        }
    )

    # --------------------------------------------------------
    # STEP 3: GET OUTPUT FILE PATH
    # --------------------------------------------------------

    Write-Host ""

    $OutputFile = Read-Host "Enter output PS1 file path"
    $OutputFile = $OutputFile.Trim().Trim('"')

    if ([string]::IsNullOrWhiteSpace($OutputFile)) {
        throw "Output path cannot be empty."
    }

    if ([IO.Path]::GetExtension($OutputFile) -ine ".ps1") {
        throw "Output filename must end with .ps1."
    }

    # --------------------------------------------------------
    # STEP 4: BUILD THE GENERATED SCRIPT
    # --------------------------------------------------------

    $Code = [System.Collections.Generic.List[string]]::new()

    # Project documentation at the beginning of the output file.
    foreach ($Line in $CommentLines) {
        $Code.Add($Line)
    }

    $Code.Add("")
    $Code.Add("# ========================================================")
    $Code.Add("# GENERATED MENU APPLICATION")
    $Code.Add("# ========================================================")
    $Code.Add("# Menu functions are defined below.")
    $Code.Add("# Insert your own PowerShell code inside each function.")
    $Code.Add("")

    # --------------------------------------------------------
    # STEP 5: GENERATE EMPTY FUNCTIONS
    # --------------------------------------------------------

    for ($i = 0; $i -lt $MenuCount; $i++) {

        $FunctionNumber = $i + 1
        $FunctionName = "MenuOption" + $FunctionNumber.ToString("D2")

        $Code.Add("function " + $FunctionName + " {")
        $Code.Add("    # Insert your code below this line.")
        $Code.Add("")
        $Code.Add("    # Your PowerShell commands go here.")
        $Code.Add("")
        $Code.Add("}")
        $Code.Add("")
    }

    # --------------------------------------------------------
    # STEP 6: GENERATE MENU DISPLAY
    # --------------------------------------------------------

    $Code.Add("while (`$true) {")
    $Code.Add("    Clear-Host")
    $Code.Add("")
    $Code.Add('    Write-Host "========================================================" -ForegroundColor Cyan')
    $Code.Add('    Write-Host "PROJECT MENU" -ForegroundColor Cyan')
    $Code.Add('    Write-Host "========================================================" -ForegroundColor Cyan')
    $Code.Add("")

    # Display project description in the generated menu.
    $Code.Add('    Write-Host "PROJECT DESCRIPTION" -ForegroundColor Yellow')
    $Code.Add('    Write-Host "--------------------------------------------------------"')

    foreach ($Line in $DescriptionLines) {
        $SafeDisplayLine = $Line.Replace('"', '`"')
        $Code.Add('    Write-Host "' + $SafeDisplayLine + '"')
    }

    $Code.Add('    Write-Host "--------------------------------------------------------`n"')
    $Code.Add("")

    # Display menu options.
    for ($i = 0; $i -lt $MenuCount; $i++) {

        $Number = $i + 1
        $Title = $MenuTitles[$i].Trim()

        # Escape single quotes for PowerShell single-quoted strings.
        $SafeTitle = $Title.Replace("'", "''")

        $MenuLine = "    Write-Host '" +
                    $Number +
                    ". " +
                    $SafeTitle +
                    "'"

        $Code.Add($MenuLine)
    }

    $Code.Add('    Write-Host "0. Exit`n"')
    $Code.Add("")
    $Code.Add('    $Choice = Read-Host "Select an option"')
    $Code.Add("")
    $Code.Add('    switch ($Choice) {')

    # --------------------------------------------------------
    # STEP 7: CONNECT MENU OPTIONS TO FUNCTIONS
    # --------------------------------------------------------

    for ($i = 0; $i -lt $MenuCount; $i++) {

        $Number = $i + 1
        $FunctionName = "MenuOption" + $Number.ToString("D2")

        $Code.Add("        '" + $Number + "' {")
        $Code.Add("            " + $FunctionName)
        $Code.Add('            Read-Host "Press Enter to return to menu"')
        $Code.Add("        }")
    }

    $Code.Add("        '0' { break }")
    $Code.Add("        default {")
    $Code.Add('            Write-Host "Invalid selection." -ForegroundColor Red')
    $Code.Add("            Start-Sleep -Seconds 2")
    $Code.Add("        }")
    $Code.Add("    }")
    $Code.Add("")
    $Code.Add('    if ($Choice -eq "0") { break }')
    $Code.Add("}")
    $Code.Add("")

    # --------------------------------------------------------
    # STEP 8: CREATE OUTPUT DIRECTORY
    # --------------------------------------------------------

    $OutputDirectory = Split-Path -Parent $OutputFile

    if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
        $OutputFile = Join-Path (Get-Location).Path $OutputFile
        $OutputDirectory = Split-Path -Parent $OutputFile
    }

    if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force |
            Out-Null
    }

    # --------------------------------------------------------
    # STEP 9: WRITE OUTPUT SCRIPT
    # --------------------------------------------------------

    Set-Content -LiteralPath $OutputFile `
        -Value $Code.ToArray() `
        -Encoding UTF8

    # --------------------------------------------------------
    # STEP 10: DISPLAY RESULT
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "SCRIPT CREATED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host ("Menu options : " + $MenuCount)
    Write-Host ("Functions    : " + $MenuCount)
    Write-Host ("Output file  : " + $OutputFile)
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host "ERROR WHILE GENERATING SCRIPT" -ForegroundColor Red
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host ""
}

Read-Host "Press Enter to exit"
```

