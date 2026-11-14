# =====================================================================
# Document Line Spacing Normalizer
# =====================================================================
# This script processes text files and Microsoft Word documents.
# It accepts either a single file or a folder containing multiple files.
# Supported input formats are TXT and DOCX.
# The script extracts text while preserving paragraph structure.
# Users can define a minimum number of blank lines between text lines.
# Users can also define a maximum number of permitted blank lines.
# A replacement value is used when spacing falls outside the permitted range.
# The script preserves all original text and only adjusts blank line spacing.
# Each processed document is saved in a separate output folder.
# The output folder is automatically created beside this PowerShell script.
# Original source files are never modified or overwritten.
# Multiple documents can be processed automatically in one execution.
# The script validates user input before starting document processing.
# Microsoft Word does not need to be installed for DOCX processing.
# Legacy DOC files are not supported; convert them to DOCX first.
# =====================================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$ScriptDirectory = $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($ScriptDirectory)) {
    $ScriptDirectory = (Get-Location).Path
}

$OutputDirectory = Join-Path $ScriptDirectory "Normalized Documents"

# ------------------------------------------------------------
# Helper: Read TXT File
# ------------------------------------------------------------

function Get-TextFileContent {
    param (
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    return [System.IO.File]::ReadAllText($FilePath)
}

# ------------------------------------------------------------
# Helper: Extract DOCX Text
# ------------------------------------------------------------

function Get-WordDocumentContent {
    param (
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $Archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)

    try {

        $DocumentEntry = $Archive.GetEntry("word/document.xml")

        if ($null -eq $DocumentEntry) {
            throw "Invalid DOCX document structure."
        }

        $Reader = [System.IO.StreamReader]::new($DocumentEntry.Open())

        try {
            [xml]$DocumentXml = $Reader.ReadToEnd()
        }
        finally {
            $Reader.Dispose()
        }

        $NamespaceManager = [System.Xml.XmlNamespaceManager]::new(
            $DocumentXml.NameTable
        )

        $NamespaceManager.AddNamespace(
            "w",
            "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
        )

        $Paragraphs = $DocumentXml.SelectNodes(
            "//w:body/w:p",
            $NamespaceManager
        )

        $Result = [System.Collections.Generic.List[string]]::new()

        foreach ($Paragraph in $Paragraphs) {

            $Builder = [System.Text.StringBuilder]::new()

            foreach ($Node in $Paragraph.ChildNodes) {

                if ($Node.LocalName -eq "r") {

                    foreach ($RunNode in $Node.ChildNodes) {

                        switch ($RunNode.LocalName) {

                            "t" {
                                [void]$Builder.Append($RunNode.InnerText)
                            }

                            "tab" {
                                [void]$Builder.Append("`t")
                            }

                            "br" {
                                [void]$Builder.Append("`n")
                            }

                            "cr" {
                                [void]$Builder.Append("`n")
                            }
                        }
                    }
                }
            }

            $Result.Add($Builder.ToString())
        }

        return ($Result -join "`n")
    }
    finally {
        $Archive.Dispose()
    }
}

# ------------------------------------------------------------
# Helper: Normalize Blank Lines
# ------------------------------------------------------------

function Normalize-TextSpacing {

    param (
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [int]$Minimum,

        [Parameter(Mandatory)]
        [int]$Maximum,

        [Parameter(Mandatory)]
        [int]$Replacement
    )

    $Normalized = $Text -replace "`r`n", "`n"
    $Normalized = $Normalized -replace "`r", "`n"

    $Lines = [System.Collections.Generic.List[string]]::new()

    foreach ($Line in $Normalized.Split(
        [string[]]@("`n"),
        [System.StringSplitOptions]::None
    )) {
        $Lines.Add($Line)
    }

    $Result = [System.Collections.Generic.List[string]]::new()

    $Index = 0

    while ($Index -lt $Lines.Count) {

        $CurrentLine = $Lines[$Index]

        $Result.Add($CurrentLine)

        $Index++

        if (-not [string]::IsNullOrWhiteSpace($CurrentLine)) {

            $BlankCount = 0

            while (
                $Index -lt $Lines.Count -and
                [string]::IsNullOrWhiteSpace($Lines[$Index])
            ) {
                $BlankCount++
                $Index++
            }

            if ($Index -lt $Lines.Count) {

                if (
                    $BlankCount -lt $Minimum -or
                    $BlankCount -gt $Maximum
                ) {
                    $BlankCount = $Replacement
                }

                for ($i = 0; $i -lt $BlankCount; $i++) {
                    $Result.Add("")
                }
            }
            else {

                for ($i = 0; $i -lt $BlankCount; $i++) {
                    $Result.Add("")
                }
            }
        }
    }

    return ($Result -join "`r`n")
}

# ------------------------------------------------------------
# Helper: Get Valid Integer Input
# ------------------------------------------------------------

function Read-ValidatedInteger {

    param (
        [string]$Message,
        [int]$MinimumValue = 0
    )

    while ($true) {

        $InputValue = Read-Host $Message

        $Number = 0

        if (
            [int]::TryParse($InputValue, [ref]$Number) -and
            $Number -ge $MinimumValue
        ) {
            return $Number
        }

        Write-Host "Invalid input. Please enter a valid integer." -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# Main Execution
# ------------------------------------------------------------

Clear-Host

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "       DOCUMENT SPACING NORMALIZER" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Get input path

$InputPath = Read-Host "Enter the input file or folder path"

$InputPath = $InputPath.Trim().Trim('"')

if (-not (Test-Path -LiteralPath $InputPath)) {
    Write-Host "The specified path does not exist." -ForegroundColor Red
    Read-Host "Press ENTER to exit"
    exit
}

# Get spacing configuration

Write-Host ""
Write-Host "Configure blank line spacing:" -ForegroundColor Yellow
Write-Host ""

$Minimum = Read-ValidatedInteger "Enter minimum blank lines"
$Maximum = Read-ValidatedInteger "Enter maximum blank lines"

while ($Maximum -lt $Minimum) {
    Write-Host "Maximum must be greater than or equal to minimum." -ForegroundColor Red
    $Maximum = Read-ValidatedInteger "Enter maximum blank lines"
}

$Replacement = Read-ValidatedInteger "Enter replacement blank lines"

# Create output directory

if (-not (Test-Path -LiteralPath $OutputDirectory)) {

    New-Item -Path $OutputDirectory -ItemType Directory -Force |
        Out-Null
}

# Collect input files

$Item = Get-Item -LiteralPath $InputPath

if ($Item.PSIsContainer) {

    $Files = @(
        Get-ChildItem -LiteralPath $InputPath -File -Recurse |
        Where-Object {
            $_.Extension -in @(".txt", ".docx")
        }
    )

}
else {

    if ($Item.Extension -notin @(".txt", ".docx")) {
        Write-Host "Unsupported file format. Use TXT or DOCX." -ForegroundColor Red
        Read-Host "Press ENTER to exit"
        exit
    }

    $Files = @($Item)
}

if ($Files.Count -eq 0) {
    Write-Host "No supported documents were found." -ForegroundColor Yellow
    Read-Host "Press ENTER to exit"
    exit
}

# Process documents

$SuccessCount = 0
$FailedCount = 0

Write-Host ""
Write-Host "Starting document processing..." -ForegroundColor Cyan
Write-Host ""

foreach ($File in $Files) {

    try {

        Write-Host "Processing: $($File.Name)" -ForegroundColor Yellow

        switch ($File.Extension.ToLowerInvariant()) {

            ".txt" {
                $Content = Get-TextFileContent -FilePath $File.FullName
            }

            ".docx" {
                $Content = Get-WordDocumentContent -FilePath $File.FullName
            }

        }

        $ProcessedContent = Normalize-TextSpacing `
            -Text $Content `
            -Minimum $Minimum `
            -Maximum $Maximum `
            -Replacement $Replacement

        $OutputName = [System.IO.Path]::GetFileNameWithoutExtension(
            $File.Name
        ) + ".txt"

        $OutputPath = Join-Path $OutputDirectory $OutputName

        $ProcessedContent | Set-Content `
            -LiteralPath $OutputPath `
            -Encoding UTF8

        Write-Host "Completed: $OutputName" -ForegroundColor Green

        $SuccessCount++

    }
    catch {

        Write-Host "Failed: $($File.Name)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkRed

        $FailedCount++
    }
}

# Final report

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "             PROCESSING SUMMARY" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

Write-Host "Total files: $($Files.Count)"
Write-Host "Successfully processed: $SuccessCount" -ForegroundColor Green
Write-Host "Failed files: $FailedCount" -ForegroundColor Red

Write-Host ""
Write-Host "Output directory:" -ForegroundColor Yellow
Write-Host $OutputDirectory -ForegroundColor White

Write-Host ""
Write-Host "Processing completed." -ForegroundColor Green

Read-Host "Press ENTER to exit"