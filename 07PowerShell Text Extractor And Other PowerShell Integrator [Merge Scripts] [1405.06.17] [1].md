
> [!INFO] ادغام خودکار تمام اسکریپت‌های پاورشل در یک فایل متنی
> مسیر پوشه‌ای را که اسکریپت اصلی در آن قرار دارد به‌صورت خودکار شناسایی می‌کند.
> فایل خروجی با نام ALL_SCRIPTS.txt را در همان پوشه ایجاد می‌کند.
> در صورت وجود فایل خروجی قبلی، آن را حذف کرده و یک فایل جدید برای ذخیره اطلاعات ایجاد می‌کند.
> تمام فایل‌های دارای پسوند PS1 موجود در پوشه را شناسایی کرده و اسکریپت اصلی را از فهرست پردازش حذف می‌کند.
> فایل‌های شناسایی‌شده را بر اساس نام مرتب کرده و به‌ترتیب پردازش می‌کند.
> پیش از محتوای هر اسکریپت، نام فایل، مسیر کامل و جداکننده‌های مشخصی را در فایل خروجی درج می‌کند.
> محتوای کامل هر فایل پاورشل را با استفاده از System.IO.File و ReadAllText خوانده و در فایل خروجی قرار می‌دهد.
> پس از محتوای هر اسکریپت، نشانگر پایان فایل را درج کرده و تعداد فایل‌های ادغام‌شده و خطادار را محاسبه می‌کند.
> خطاهای مربوط به فایل‌های مفقود یا مشکلات خواندن و نوشتن را مدیریت کرده و جزئیات آن‌ها را در فایل خروجی ثبت می‌کند.
> در پایان، تعداد کل اسکریپت‌ها، عملیات موفق، خطاها، مسیر فایل خروجی و وضعیت نهایی ادغام را نمایش می‌دهد و با سه مرحله فشردن کلید Enter منتظر خروج کاربر می‌ماند.


> [!INFO] Automatically Merging All PowerShell Scripts Into A Single Text File
> Automatically Detects The Directory Containing The Currently Executed Script.
> Creates An Output File Named ALL_SCRIPTS.txt Within The Same Directory.
> Removes Any Previously Existing Output File And Creates A New File To Store The Collected Data.
> Identifies All PS1 Files In The Directory And Excludes The Currently Executed Script From Processing.
> Sorts The Identified Files Alphabetically By Name And Processes Them Sequentially.
> Inserts The File Name, Full Path, And Clearly Defined Separators Before Each Script's Content.
> Reads The Complete Contents Of Each PowerShell File Using System.IO.File And ReadAllText And Writes Them Into The Output File.
> Adds An End-Of-File Marker After Each Script And Counts Successfully Merged Files And Failed Operations.
> Handles Missing Files And Reading Or Writing Errors And Records Their Details In The Output File.
> Displays The Total Number Of Scripts, Successful Merges, Errors, Output File Path, And Final Merge Status And Waits For Three Enter Key Presses Before Exiting.


```
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
```

