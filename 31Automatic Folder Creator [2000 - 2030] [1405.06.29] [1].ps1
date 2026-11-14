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