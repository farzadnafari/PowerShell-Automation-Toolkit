# ===================================================================================================================================
#	TAR PACKAGE INFORMATION
#	* Package Type: TAR Archive
#	* Purpose: Portable File & Folder Package
#	* Compression: None
#	* Structure: Fully Preserved
#	* This TAR Archive Contains The Complete Directory Structure And All Files Within The Original Package.
#	* Designed For Reliable, Portable, And Lossless Transfer Of Files And Nested Directories Without Compression.
#	* PowerShell Script Designer: Farzad Nafari
# ===================================================================================================================================

# ===================================================================================================================================
# First Session --- Run As Administrator
# ===================================================================================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# ===================================================================================================================================
# Second Session --- Tar Script
# ===================================================================================================================================

Read-Host "Processing Please [PRESS] Enter ..."

tar -cf "***.tar" -C "###" "===" | ForEach-Object { Write-Progress -Activity "Creating TAR Archive" -Status "Processing..." -PercentComplete 50 }

# ===================================================================================================================================
# End Session --- End Script
# ===================================================================================================================================

Read-Host "Please [PRESS] Enter For End Program ..."
