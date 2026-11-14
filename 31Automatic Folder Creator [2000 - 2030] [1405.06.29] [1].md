
> [!INFO] ایجاد ساختار پوشه‌بندی ده‌گانه گردش کار بر اساس دسته‌بندی و سال
> مسیر فعلی اجرای PowerShell را به‌عنوان محل اصلی ایجاد ساختار پوشه‌ها تعیین می‌کند.
> ده پوشه اصلی با دسته‌بندی‌های System، Software، Financial، Career، Skills، Projects، Life، Knowledge، Education و Miscellaneous ایجاد می‌کند.
> نام‌گذاری پوشه‌های اصلی با شماره‌گذاری دو رقمی از 01 تا 10 انجام می‌شود.
> برای هر پوشه اصلی، مجموعه‌ای از زیرپوشه‌های سالانه با بازه زمانی 2000 تا 2030 ایجاد می‌کند.
> نام هر زیرپوشه سالانه با قالب [YEAR] ساخته می‌شود.
> در مجموع 10 پوشه اصلی و 310 زیرپوشه سالانه ایجاد می‌کند.
> ساختار نهایی امکان دسته‌بندی اطلاعات و فعالیت‌ها را بر اساس موضوع و سال فراهم می‌کند.
> از پارامتر Force استفاده می‌کند تا در صورت وجود پوشه‌های قبلی، عملیات بدون ایجاد خطای تکراری ادامه پیدا کند.
> تمام پوشه‌ها در مسیر فعلی PowerShell ساخته می‌شوند و هیچ فایل موجودی حذف یا جابه‌جا نمی‌شود.
> پس از تکمیل عملیات، پیام موفقیت‌آمیز بودن ایجاد ساختار پوشه‌ها را نمایش می‌دهد.


> [!INFO] Creation Of A Ten-Category Workflow Folder Structure Organized By Year
> Sets The Current PowerShell Working Directory As The Root Location For Creating The Folder Structure.
> Creates Ten Main Folders Named System, Software, Financial, Career, Skills, Projects, Life, Knowledge, Education, And Miscellaneous.
> Numbers The Main Folders Sequentially Using A Two-Digit Format From 01 To 10.
> Creates A Collection Of Year-Based Subfolders Inside Each Main Folder, Covering The Period From 2000 To 2030.
> Names Each Year-Based Subfolder Using The [YEAR] Naming Convention.
> Creates A Total Of 10 Main Folders And 310 Annual Subfolders.
> Provides A Structured Environment For Organizing Information And Activities By Category And Year.
> Uses The Force Parameter To Continue Without Duplicate-Directory Errors When Existing Folders Are Encountered.
> Creates All Directories In The Current PowerShell Location Without Deleting Or Moving Existing Files.
> Displays A Success Message After Completing The Folder Structure Creation.


```
$root = Get-Location

$folders = @(
    "01.Work Flow [System]",
    "02.Work Flow [Software]",
    "03.Work Flow [Financial]",
    "04.Work Flow [Career]",
    "05.Work Flow [Skills]",
    "06.Work Flow [Projects]",
    "07.Work Flow [Life]",
    "08.Work Flow [Knowledge]",
    "09.Work Flow [Education]",
    "10.Work Flow [Miscellaneous]"
)

foreach ($folder in $folders) {
    $parentPath = Join-Path $root $folder
    New-Item -ItemType Directory -Path $parentPath -Force | Out-Null

    foreach ($year in 2000..2030) {
        $yearPath = Join-Path $parentPath "[$year]"
        New-Item -ItemType Directory -Path $yearPath -Force | Out-Null
    }
}

Write-Host "Folder structure created successfully." -ForegroundColor Green
```

