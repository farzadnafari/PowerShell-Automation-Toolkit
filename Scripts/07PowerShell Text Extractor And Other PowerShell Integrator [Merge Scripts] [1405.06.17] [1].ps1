# Get the folder containing this script
$FolderPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define the output file
$OutputFile = Join-Path $FolderPath "ALL_SCRIPTS.txt"

# Get the current script name
$CurrentScript = $MyInvocation.MyCommand.Name

# Remove the previous output file
if (Test-Path $OutputFile) {
    Remove-Item $OutputFile -Force
}

# Get all PS1 files except this script
$Scripts = Get-ChildItem -Path $FolderPath -Filter "*.ps1" |
    Where-Object {
        $_.Name -ne $CurrentScript
    } |
    Sort-Object Name

# Create the output file
New-Item -Path $OutputFile -ItemType File -Force | Out-Null

$SuccessCount = 0
$ErrorCount = 0

# Process every PowerShell script
foreach ($Script in $Scripts) {

    $FilePath = $Script.FullName
    $FileName = $Script.Name

    Add-Content -Path $OutputFile -Value ""
    Add-Content -Path $OutputFile -Value "============================================================"
    Add-Content -Path $OutputFile -Value "FILE: $FileName"
    Add-Content -Path $OutputFile -Value "PATH: $FilePath"
    Add-Content -Path $OutputFile -Value "============================================================"
    Add-Content -Path $OutputFile -Value ""

    try {

        if (Test-Path -LiteralPath $FilePath) {

            $Content = [System.IO.File]::ReadAllText($FilePath)

            Add-Content -Path $OutputFile -Value $Content

            Add-Content -Path $OutputFile -Value ""
            Add-Content -Path $OutputFile -Value "END OF FILE: $FileName"
            Add-Content -Path $OutputFile -Value ""

            $SuccessCount++

        }
        else {

            Add-Content -Path $OutputFile -Value "[ERROR] FILE NOT FOUND: $FilePath"

            $ErrorCount++
        }

    }
    catch {

        Add-Content -Path $OutputFile -Value "[ERROR] $($_.Exception.Message)"

        $ErrorCount++
    }
}

# Display final result
Write-Host ""
Write-Host "========================================"
Write-Host "MERGE OPERATION FINISHED"
Write-Host "========================================"
Write-Host ""
Write-Host "Total scripts found : $($Scripts.Count)"
Write-Host "Successfully merged : $SuccessCount"
Write-Host "Failed              : $ErrorCount"
Write-Host ""
Write-Host "Output file:"
Write-Host $OutputFile
Write-Host ""

if ($ErrorCount -eq 0) {
    Write-Host "STATUS: SUCCESS"
}
else {
    Write-Host "STATUS: COMPLETED WITH ERRORS"
}

Write-Host ""

Read-Host "Press ENTER to exit"

Read-Host "Press ENTER to exit"

Read-Host "Press ENTER to exit"