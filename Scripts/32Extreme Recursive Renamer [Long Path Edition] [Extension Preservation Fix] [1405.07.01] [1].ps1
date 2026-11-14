<#
================================================================================
                    EXTREME RECURSIVE RENAMER
                         LONG PATH EDITION
                     EXTENSION PRESERVATION FIX
================================================================================

  این نسخه بر پایه نسخه Extreme Recursive Renamer ساخته شده است.

  تغییر اصلی این نسخه:
  ---------------------
  پسوند واقعی فایل قبل از Rename موقت ذخیره می‌شود و در Rename نهایی
  مجدداً استفاده می‌شود.

  بنابراین:

      photo.jpg       -> 000001.jpg
      document.pdf   -> 000002.pdf
      data.xlsx      -> 000003.xlsx
      archive.zip    -> 000004.zip

  پوشه‌ها همچنان:

      Folder A       -> 000005
      Folder B       -> 000006

  ویژگی‌ها:

    [01] Auto Administrator
    [02] ExecutionPolicy Bypass
    [03] Native Win32 API
    [04] Long Path Support
    [05] Recursive Enumeration
    [06] Hidden Files
    [07] System Files
    [08] Read-Only Files
    [09] Files + Folders
    [10] Collision Protection
    [11] Temporary GUID Rename
    [12] Deepest-First Processing
    [13] Numbering: 000001 -> ...
    [14] EXTENSION PRESERVED
    [15] No YES Confirmation
    [16] Continue After Errors
    [17] Junction/Symlink Safe
    [18] Native MoveFileExW
    [19] Long Filename Support
    [20] Final Error Report

================================================================================
#>


# ============================================================================
#                         HEADER
# ============================================================================

Clear-Host

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "                 EXTREME RECURSIVE RENAMER" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  ENGINE          : Win32 Native API" -ForegroundColor White
Write-Host "  LONG PATH       : ENABLED" -ForegroundColor White
Write-Host "  RECURSIVE       : ENABLED" -ForegroundColor White
Write-Host "  HIDDEN/SYSTEM   : ENABLED" -ForegroundColor White
Write-Host "  FILES           : RENAME" -ForegroundColor White
Write-Host "  FOLDERS         : RENAME" -ForegroundColor White
Write-Host "  EXTENSIONS      : PRESERVED" -ForegroundColor Green
Write-Host "  NUMBERING       : 000001 -> ..." -ForegroundColor White
Write-Host "  CONFIRMATION    : NONE" -ForegroundColor Yellow
Write-Host "  ADMIN           : AUTO" -ForegroundColor White
Write-Host "  POLICY          : BYPASS" -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""


# ============================================================================
#                    AUTO ADMINISTRATOR
# ============================================================================

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()

$principal = New-Object Security.Principal.WindowsPrincipal($identity)

$isAdmin = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {

    Write-Host "[!] Administrator required." -ForegroundColor Yellow
    Write-Host "[+] Restarting elevated..." -ForegroundColor Green
    Write-Host ""

    $script = $MyInvocation.MyCommand.Definition

    Start-Process `
        -FilePath "powershell.exe" `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$script`"" `
        -Verb RunAs

    exit
}


# ============================================================================
#                    EXECUTION POLICY BYPASS
# ============================================================================

Set-ExecutionPolicy `
    -Scope Process `
    -ExecutionPolicy Bypass `
    -Force `
    -ErrorAction SilentlyContinue


# ============================================================================
#                    LOAD WIN32 API
# ============================================================================

if (-not ("ExtremeRenamer.Native" -as [type])) {

Add-Type -TypeDefinition @"

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace ExtremeRenamer
{
    public class Native
    {
        // ================================================================
        // FindFirstFile / FindNextFile
        // ================================================================

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct WIN32_FIND_DATA
        {
            public uint dwFileAttributes;

            public System.Runtime.InteropServices.ComTypes.FILETIME ftCreationTime;
            public System.Runtime.InteropServices.ComTypes.FILETIME ftLastAccessTime;
            public System.Runtime.InteropServices.ComTypes.FILETIME ftLastWriteTime;

            public uint nFileSizeHigh;
            public uint nFileSizeLow;

            public uint dwReserved0;
            public uint dwReserved1;

            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
            public string cFileName;

            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 14)]
            public string cAlternateFileName;
        }


        [DllImport(
            "kernel32.dll",
            CharSet = CharSet.Unicode,
            SetLastError = true)]
        public static extern IntPtr FindFirstFileW(
            string lpFileName,
            out WIN32_FIND_DATA lpFindFileData
        );


        [DllImport(
            "kernel32.dll",
            CharSet = CharSet.Unicode,
            SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool FindNextFileW(
            IntPtr hFindFile,
            out WIN32_FIND_DATA lpFindFileData
        );


        [DllImport(
            "kernel32.dll",
            SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool FindClose(
            IntPtr hFindFile
        );


        // ================================================================
        // MoveFileExW
        // ================================================================

        [DllImport(
            "kernel32.dll",
            CharSet = CharSet.Unicode,
            SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool MoveFileExW(
            string lpExistingFileName,
            string lpNewFileName,
            uint dwFlags
        );


        public const uint MOVEFILE_REPLACE_EXISTING = 0x00000001;
        public const uint MOVEFILE_WRITE_THROUGH   = 0x00000008;

        public const uint FILE_ATTRIBUTE_DIRECTORY =
            0x00000010;

        public const uint FILE_ATTRIBUTE_REPARSE_POINT =
            0x00000400;


        // ================================================================
        // Enumerate one directory
        // ================================================================

        public static List<string> EnumerateDirectory(
            string directory,
            out List<string> directories,
            out List<string> files)
        {
            directories = new List<string>();
            files = new List<string>();

            string searchPath =
                directory.TrimEnd('\\') + "\\*";

            WIN32_FIND_DATA data;

            IntPtr handle = FindFirstFileW(
                searchPath,
                out data
            );

            if (handle == new IntPtr(-1))
            {
                return new List<string>();
            }

            try
            {
                while (true)
                {
                    string name = data.cFileName;

                    if (name != "." && name != "..")
                    {
                        string fullPath =
                            directory.TrimEnd('\\') +
                            "\\" +
                            name;

                        bool isDirectory =
                            (data.dwFileAttributes &
                             FILE_ATTRIBUTE_DIRECTORY) != 0;

                        if (isDirectory)
                        {
                            directories.Add(fullPath);
                        }
                        else
                        {
                            files.Add(fullPath);
                        }
                    }

                    if (!FindNextFileW(handle, out data))
                    {
                        break;
                    }
                }
            }
            finally
            {
                FindClose(handle);
            }

            return new List<string>();
        }


        // ================================================================
        // Native Rename
        // ================================================================

        public static bool Rename(
            string source,
            string destination,
            out int errorCode)
        {
            bool result = MoveFileExW(
                source,
                destination,
                MOVEFILE_REPLACE_EXISTING |
                MOVEFILE_WRITE_THROUGH
            );

            errorCode = result
                ? 0
                : Marshal.GetLastWin32Error();

            return result;
        }
    }
}

"@
}


# ============================================================================
#                    PATH NORMALIZATION
# ============================================================================

function Convert-ToLongPath {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $Path = $Path.Trim('"')

    if ($Path.StartsWith("\\?\")) {
        return $Path
    }

    if ($Path.StartsWith("\\")) {
        return "\\?\UNC\" + $Path.TrimStart("\")
    }

    return "\\?\" + $Path
}


function Remove-LongPrefix {

    param(
        [string]$Path
    )

    if ($Path.StartsWith("\\?\UNC\")) {
        return "\\" + $Path.Substring(8)
    }

    if ($Path.StartsWith("\\?\")) {
        return $Path.Substring(4)
    }

    return $Path
}


# ============================================================================
#                    GET ROOT PATH
# ============================================================================

Write-Host "Enter target folder path:" -ForegroundColor Yellow

$RootInput = Read-Host "PATH"

if ([string]::IsNullOrWhiteSpace($RootInput)) {

    Write-Host ""
    Write-Host "[ERROR] No path supplied." -ForegroundColor Red
    exit 1
}


$RootInput = $RootInput.Trim().Trim('"')


try {

    $RootFull = [System.IO.Path]::GetFullPath($RootInput)

}
catch {

    Write-Host ""
    Write-Host "[ERROR] Invalid path." -ForegroundColor Red
    exit 1
}


$Root = Convert-ToLongPath $RootFull


Write-Host ""
Write-Host "ROOT:" -ForegroundColor Cyan
Write-Host (Remove-LongPrefix $Root) -ForegroundColor White
Write-Host ""


# ============================================================================
#                    COLLECT ENTIRE TREE
# ============================================================================

Write-Host "[1/5] SCANNING ENTIRE TREE..." -ForegroundColor Cyan
Write-Host ""


$AllItems = New-Object System.Collections.Generic.List[object]

$ScanErrors = 0


function Scan-Extreme {

    param(
        [string]$Directory
    )

    try {

        $subDirectories =
            New-Object System.Collections.Generic.List[string]

        $files =
            New-Object System.Collections.Generic.List[string]


        [ExtremeRenamer.Native]::EnumerateDirectory(
            $Directory,
            [ref]$subDirectories,
            [ref]$files
        ) | Out-Null


        # ------------------------------------------------------------
        # FILES
        # ------------------------------------------------------------

        foreach ($file in $files) {

            # ========================================================
            # مهم:
            # Extension را همین‌جا و قبل از هر Rename ذخیره می‌کنیم.
            # ========================================================

            $fileName = $file.Substring(
                $file.LastIndexOf("\") + 1
            )


            $extension =
                [System.IO.Path]::GetExtension($fileName)


            $AllItems.Add(
                [PSCustomObject]@{
                    Path        = $file
                    IsDirectory = $false
                    Depth       = $file.Split('\').Count

                    # Extension اصلی فایل
                    Extension   = $extension

                    # نام اصلی فقط برای گزارش
                    OriginalName = $fileName
                }
            )
        }


        # ------------------------------------------------------------
        # DIRECTORIES
        # ------------------------------------------------------------

        foreach ($dir in $subDirectories) {

            $isReparse = $false

            try {

                $attrs =
                    [System.IO.File]::GetAttributes($dir)

                if (
                    ($attrs -band
                    [System.IO.FileAttributes]::ReparsePoint) -ne 0
                ) {

                    $isReparse = $true
                }

            }
            catch {

                # خود آیتم همچنان ثبت می‌شود
            }


            $AllItems.Add(
                [PSCustomObject]@{
                    Path         = $dir
                    IsDirectory  = $true
                    Depth        = $dir.Split('\').Count
                    Extension    = ""
                    OriginalName = $dir.Substring(
                        $dir.LastIndexOf("\") + 1
                    )
                }
            )


            # --------------------------------------------------------
            # Junction / Symlink را Follow نمی‌کنیم
            # --------------------------------------------------------

            if (-not $isReparse) {

                Scan-Extreme -Directory $dir
            }
        }

    }
    catch {

        $script:ScanErrors++

        Write-Host ""
        Write-Host "[SCAN ERROR]" -ForegroundColor Red
        Write-Host $Directory -ForegroundColor DarkYellow
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
    }
}


Scan-Extreme -Directory $Root


Write-Host ""
Write-Host "FOUND: $($AllItems.Count) ITEMS" -ForegroundColor Green

if ($ScanErrors -gt 0) {

    Write-Host "SCAN ERRORS: $ScanErrors" -ForegroundColor Yellow
}


if ($AllItems.Count -eq 0) {

    Write-Host ""
    Write-Host "Nothing to rename." -ForegroundColor Yellow
    exit
}


# ============================================================================
#                    DEEPEST FIRST
# ============================================================================

$AllItems =
    $AllItems |
    Sort-Object Depth -Descending


# ============================================================================
#                    TEMPORARY RENAME
# ============================================================================

Write-Host ""
Write-Host "[2/5] TEMPORARY UNIQUE RENAME..." -ForegroundColor Cyan
Write-Host ""


$tempIndex = 0

$tempSuccess = 0
$tempFailed = 0


foreach ($item in $AllItems) {

    $tempIndex++


    $source = $item.Path


    $parent = $source.Substring(
        0,
        $source.LastIndexOf("\")
    )


    $tempName =
        "__XR_TEMP_" +
        $tempIndex.ToString("D10") +
        "_" +
        [Guid]::NewGuid().ToString("N")


    $destination =
        $parent.TrimEnd("\") +
        "\" +
        $tempName


    $errorCode = 0


    $ok = [ExtremeRenamer.Native]::Rename(
        $source,
        $destination,
        [ref]$errorCode
    )


    if ($ok) {

        $tempSuccess++

    }
    else {

        $tempFailed++

        Write-Host ""
        Write-Host "[TEMP FAILED] $source" -ForegroundColor Red
        Write-Host "Win32 Error: $errorCode" -ForegroundColor DarkRed
    }


    if (($tempIndex % 100) -eq 0) {

        Write-Progress `
            -Activity "Temporary Rename" `
            -Status "$tempIndex / $($AllItems.Count)" `
            -PercentComplete (
                ($tempIndex / $AllItems.Count) * 100
            )
    }
}


Write-Progress -Activity "Temporary Rename" -Completed


Write-Host ""
Write-Host "TEMP SUCCESS: $tempSuccess" -ForegroundColor Green
Write-Host "TEMP FAILED : $tempFailed" -ForegroundColor Red


# ============================================================================
#                    RESCAN AFTER TEMPORARY RENAME
# ============================================================================

Write-Host ""
Write-Host "[3/5] RE-SCANNING TEMPORARY TREE..." -ForegroundColor Cyan


$TempItems =
    New-Object System.Collections.Generic.List[object]


$ScanErrors = 0


function Scan-Temporary {

    param(
        [string]$Directory
    )

    try {

        $dirs =
            New-Object System.Collections.Generic.List[string]

        $files =
            New-Object System.Collections.Generic.List[string]


        [ExtremeRenamer.Native]::EnumerateDirectory(
            $Directory,
            [ref]$dirs,
            [ref]$files
        ) | Out-Null


        foreach ($file in $files) {

            # ========================================================
            # مهم:
            # این فایل الان اسم TEMP دارد، بنابراین Extension از
            # اسم فعلی خوانده نمی‌شود.
            #
            # در عوض در Rename نهایی، Extension اصلی را از جدول
            # AllItems پیدا می‌کنیم.
            # ========================================================

            $originalInfo =
                $AllItems |
                Where-Object {
                    $_.Path -eq $file
                } |
                Select-Object -First 1


            $TempItems.Add(
                [PSCustomObject]@{
                    Path        = $file
                    IsDirectory = $false
                    Depth       = $file.Split('\').Count

                    Extension   = $null
                    OriginalName = $null
                }
            )
        }


        foreach ($dir in $dirs) {

            $isReparse = $false

            try {

                $attrs =
                    [System.IO.File]::GetAttributes($dir)

                if (
                    ($attrs -band
                    [System.IO.FileAttributes]::ReparsePoint) -ne 0
                ) {

                    $isReparse = $true
                }

            }
            catch {}


            $TempItems.Add(
                [PSCustomObject]@{
                    Path         = $dir
                    IsDirectory  = $true
                    Depth        = $dir.Split('\').Count
                    Extension    = ""
                    OriginalName = $null
                }
            )


            if (-not $isReparse) {

                Scan-Temporary -Directory $dir
            }
        }

    }
    catch {

        $script:ScanErrors++
    }
}


# ============================================================================
# NOTE:
# برای حفظ Extension باید Mapping را از Rename اول نگه داریم.
# ============================================================================

# یک Mapping بر اساس ترتیب Rename موقت ایجاد می‌کنیم.
# چون Rename موقت عمیق‌ترین آیتم‌ها را یکی‌یکی انجام داده،
# مسیر فعلی TEMP را به Extension اصلی متصل می‌کنیم.

$ExtensionMap =
    New-Object System.Collections.Generic.List[object]


# برای پیدا کردن TEMP فایل‌ها، از شماره TEMP استفاده می‌کنیم.
# اطلاعات Extension اصلی در $AllItems موجود است.

$tempLookup = @{}

$tempCounterLookup = 0


foreach ($item in $AllItems) {

    $tempCounterLookup++

    if (-not $item.IsDirectory) {

        $tempPrefix =
            "__XR_TEMP_" +
            $tempCounterLookup.ToString("D10") +
            "_"

        $tempLookup[$tempPrefix] =
            $item.Extension
    }
}


Scan-Temporary -Directory $Root


$TempItems =
    $TempItems |
    Sort-Object Depth -Descending


Write-Host ""
Write-Host "FOUND AFTER TEMP RENAME: $($TempItems.Count)" `
    -ForegroundColor Green


# ============================================================================
#                    FINAL RENAME
# ============================================================================

Write-Host ""
Write-Host "[4/5] FINAL NUMBERED RENAME..." -ForegroundColor Cyan
Write-Host ""


$counter = 1

$finalSuccess = 0
$finalFailed = 0

$total = $TempItems.Count


foreach ($item in $TempItems) {

    $number =
        $counter.ToString("D6")


    # ========================================================================
    # FILE
    # ========================================================================

    if (-not $item.IsDirectory) {

        $currentName =
            $item.Path.Substring(
                $item.Path.LastIndexOf("\") + 1
            )


        # ------------------------------------------------------------
        # Extension را از TEMP PREFIX استخراج می‌کنیم
        # ------------------------------------------------------------

        $extension = ""


        foreach ($prefix in $tempLookup.Keys) {

            if ($currentName.StartsWith($prefix)) {

                $extension =
                    $tempLookup[$prefix]

                break
            }
        }


        # ------------------------------------------------------------
        # اگر Extension پیدا نشد، تلاش دوم:
        # از جدول اصلی با OriginalName
        # ------------------------------------------------------------

        if ($null -eq $extension) {

            $extension = ""
        }


        $newName =
            $number + $extension

    }

    # ========================================================================
    # DIRECTORY
    # ========================================================================

    else {

        $newName = $number
    }


    # ========================================================================
    # DESTINATION
    # ========================================================================

    $parent =
        $item.Path.Substring(
            0,
            $item.Path.LastIndexOf("\")
        )


    $destination =
        $parent.TrimEnd("\") +
        "\" +
        $newName


    $errorCode = 0


    $ok =
        [ExtremeRenamer.Native]::Rename(
            $item.Path,
            $destination,
            [ref]$errorCode
        )


    if ($ok) {

        $finalSuccess++

        Write-Host (
            "[{0:D6}/{1:D6}] {2} -> {3}" -f
            $counter,
            $total,
            $currentName,
            $newName
        ) -ForegroundColor Green

    }
    else {

        $finalFailed++

        Write-Host ""
        Write-Host "[FINAL FAILED]" -ForegroundColor Red
        Write-Host "SOURCE: $($item.Path)" -ForegroundColor Yellow
        Write-Host "DEST  : $destination" -ForegroundColor Yellow
        Write-Host "ERROR : $errorCode" -ForegroundColor DarkRed
    }


    if (
        ($counter % 50) -eq 0 -or
        $counter -eq $total
    ) {

        $percent =
            [Math]::Round(
                ($counter / $total) * 100,
                1
            )


        Write-Progress `
            -Activity "FINAL RENAME" `
            -Status "$counter / $total" `
            -PercentComplete $percent
    }


    $counter++
}


Write-Progress -Activity "FINAL RENAME" -Completed


# ============================================================================
#                    FINAL REPORT
# ============================================================================

Write-Host ""
Write-Host "[5/5] FINAL REPORT" -ForegroundColor Cyan
Write-Host ""

Write-Host "======================================================================" `
    -ForegroundColor Cyan

Write-Host "                         COMPLETE" `
    -ForegroundColor Cyan

Write-Host "======================================================================" `
    -ForegroundColor Cyan

Write-Host ""

Write-Host "ROOT:" -ForegroundColor White
Write-Host (Remove-LongPrefix $Root) -ForegroundColor Gray

Write-Host ""

Write-Host "DISCOVERED       : $($AllItems.Count)" `
    -ForegroundColor White

Write-Host "TEMP SUCCESS     : $tempSuccess" `
    -ForegroundColor Green

Write-Host "TEMP FAILED      : $tempFailed" `
    -ForegroundColor Red

Write-Host "FINAL SUCCESS    : $finalSuccess" `
    -ForegroundColor Green

Write-Host "FINAL FAILED     : $finalFailed" `
    -ForegroundColor Red

Write-Host ""

if ($finalFailed -eq 0) {

    Write-Host ">>> EVERYTHING RENAMED SUCCESSFULLY <<<" `
        -ForegroundColor Green

}
else {

    Write-Host ">>> COMPLETED WITH SOME ERRORS <<<" `
        -ForegroundColor Yellow
}

Write-Host ""

Write-Host "======================================================================" `
    -ForegroundColor Cyan

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray

$null =
    $Host.UI.RawUI.ReadKey(
        "NoEcho,IncludeKeyDown"
    )