# ===================================================================================================================================
#	UNTAR PACKAGE INFORMATION
#	* Package Type: UNTAR Archive
#	* Purpose: Portable File & Folder Package
#	* Compression: None
#	* Structure: Fully Preserved
#	* This UNTAR Archive Contains The Complete Directory Structure And All Files Within The Original Package.
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
# Second Session --- UnTar Script
# ===================================================================================================================================

Read-Host "`n`n`n* Package Type: UNTAR Archive`n* Purpose: Portable File & Folder Package`n* Compression: None`n* Structure: Fully Preserved`n* This TAR Archive Contains The Complete Directory Structure And All Files Within The Original Package.`n* Designed For Reliable, Portable, And Lossless Transfer Of Files And Nested Directories Without Compression.`n* PowerShell Script Designer: Farzad Nafari`n`n`nDear User; The Program You Are Using Is Designed To UnPackage The Folder Or File You Want. Please Follow All The Instructions For The Related Operations And Wait Until The Process Is Completed, Which You Will Be Informed About. To Start, Please Enter The Number.`n`n`nThe Program Has Started, Please Press The [ENTER] Key"

# $Source = "***"
# $TarFile = "***.tar"
# 
# $TotalSize = (Get-ChildItem -LiteralPath $Source -File -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
# 
# Start-Job -ScriptBlock {
#     param($TarFile, $TotalSize)
# 
#     while (-not (Test-Path -LiteralPath $TarFile)) {
#         Start-Sleep -Milliseconds 500
#     }
# 
#     while ($true) {
#         $CurrentSize = (Get-Item -LiteralPath $TarFile).Length
#         $Percent = [Math]::Min(99, [Math]::Round(($CurrentSize / $TotalSize) * 100, 1))
# 
#         Write-Progress -Activity "TAR Creating" -Status "$Percent% Completed" -PercentComplete $Percent
# 
#         Start-Sleep -Milliseconds 500
#     }
# } -ArgumentList $TarFile, $TotalSize
# 

New-Item -ItemType Directory -Path "###" -Force

tar -xf "***.tar" -C "###" | ForEach-Object { Write-Progress -Activity "Creating TAR Archive" -Status "Processing..." -PercentComplete 50 }

# ===================================================================================================================================
# End Session --- End Script
# ===================================================================================================================================

Read-Host "`n`n`nThe Program Has Finished. Please Press The [ENTER] Key"