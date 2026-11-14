# =====================================================================
# POWERSHELL SCRIPT UNBLOCK / RUNNER
# =====================================================================

$ScriptPath = "***A***.ps1"

# Check file
if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
    Write-Host "ERROR: Script file not found:" -ForegroundColor Red
    Write-Host $ScriptPath -ForegroundColor Yellow
    Pause
    exit 1
}

# Unblock downloaded script
Unblock-File -LiteralPath $ScriptPath -ErrorAction SilentlyContinue

# Run with ExecutionPolicy Bypass
PowerShell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File $ScriptPath

Read-Host "Press ENTER to exit"

Read-Host "Press ENTER to exit"

Read-Host "Press ENTER to exit"