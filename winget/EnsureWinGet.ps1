<#
  EnsureWinGet.ps1 - bootstrap Windows Package Manager (App Installer) for KJLLin Toolbox

  Design:
    - Downloads nothing unless winget is genuinely missing
    - China friendly: Gitee mirror -> ghfast.top proxy -> official GitHub
    - Every file is sha256 verified against a pinned hash
    - Never blocks the Toolbox install: failures warn and exit 0

  Usage:
    powershell -ExecutionPolicy Bypass -File EnsureWinGet.ps1
    powershell -ExecutionPolicy Bypass -File EnsureWinGet.ps1 -CheckOnly
    powershell -ExecutionPolicy Bypass -File EnsureWinGet.ps1 -Force -CheckOnly   # test download path
#>
param(
    [switch]$CheckOnly,
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

function Write-Log([string]$msg) { Write-Host "[EnsureWinGet] $msg" }

$mirrorBase   = 'https://gitee.com/kjllin/kjllin-toolbox-bucket/releases/download/winget-bootstrap/'
$proxyBase    = 'https://ghfast.top/https://github.com/microsoft/winget-cli/releases/download/v1.29.380/'
$officialBase = 'https://github.com/microsoft/winget-cli/releases/download/v1.29.380/'
$depsZip      = 'DesktopAppInstaller_Dependencies.zip'
$bundleFile   = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'

# --- host architecture -----------------------------------------------------
# PROCESSOR_ARCHITECTURE lies inside an x64-emulated process on ARM64, so the
# managed OSArchitecture is asked first and the env var only serves as a fallback.
function Get-HostArch {
    try {
        switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()) {
            'Arm64' { return 'arm64' }
            'X64'   { return 'x64' }
            'X86'   { return 'x86' }
            default { return 'x64' }
        }
    } catch {}
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { return 'arm64' }
    if ($env:PROCESSOR_ARCHITECTURE -eq 'x86') { return 'x86' }
    return 'x64'
}

# --- pinned packages (App Installer 1.29.380, both architectures) ----------
$x64Packages = @(
    [pscustomobject]@{
        File    = 'Microsoft.VCLibs.140.00_14.0.33519.0_x64.appx'
        Size    = 896581
        Sha     = '9C17B521F9D690A1F504DA5108ED6EEC5669EB3A8FD1331EEF43E40D84E74283'
        PkgName = 'Microsoft.VCLibs.140.00'
        Entry   = 'x64/Microsoft.VCLibs.140.00_14.0.33519.0_x64.appx'
        InBundle = $false
    },
    [pscustomobject]@{
        File    = 'Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x64.appx'
        Size    = 6757465
        Sha     = '077A3D1A5D0622BD3004DCA85F5E192D6E98EC79B83D4AA06766759EA6C09C3D'
        PkgName = 'Microsoft.VCLibs.140.00.UWPDesktop'
        Entry   = 'x64/Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x64.appx'
        InBundle = $false
    },
    [pscustomobject]@{
        File    = 'Microsoft.WindowsAppRuntime.1.8_8000.616.304.0_x64.appx'
        Size    = 25431545
        Sha     = 'A31595CC4B5AEBC18466EC24E8D4B566FE0FCAFB52D833B6D139B8691D0E5177'
        PkgName = 'Microsoft.WindowsAppRuntime.1.8'
        Entry   = 'x64/Microsoft.WindowsAppRuntime.1.8_8000.616.304.0_x64.appx'
        InBundle = $false
    },
    [pscustomobject]@{
        File    = 'AppInstaller_x64.msix'
        Size    = 62556620
        Sha     = '2E05D50B493DB869D98643533A0141C2C75FC15F122BF5723AB4A1B93C48D267'
        PkgName = 'Microsoft.DesktopAppInstaller'
        Entry   = 'AppInstaller_x64.msix'
        InBundle = $true
    }
)

$arm64Packages = @(
    [pscustomobject]@{
        File    = 'Microsoft.VCLibs.140.00_14.0.33519.0_arm64.appx'
        Size    = 1570406
        Sha     = 'C73D0F55DDA331F9DCBEFC99FF5A420B62120773D2917387639382AA478533EE'
        PkgName = 'Microsoft.VCLibs.140.00'
        Entry   = 'arm64/Microsoft.VCLibs.140.00_14.0.33519.0_arm64.appx'
        InBundle = $false
    },
    [pscustomobject]@{
        File    = 'Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_arm64.appx'
        Size    = 11161325
        Sha     = '831118F2F5CAC8E29284E4ECC23BF4236436CCC2EA4A7C225C4946F8CFD29DD3'
        PkgName = 'Microsoft.VCLibs.140.00.UWPDesktop'
        Entry   = 'arm64/Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_arm64.appx'
        InBundle = $false
    },
    [pscustomobject]@{
        File    = 'Microsoft.WindowsAppRuntime.1.8_8000.616.304.0_arm64.appx'
        Size    = 23780657
        Sha     = '70A518282C2CE7FF7579870958C059BED48323BEF9B1020632BA10C41BAC27A0'
        PkgName = 'Microsoft.WindowsAppRuntime.1.8'
        Entry   = 'arm64/Microsoft.WindowsAppRuntime.1.8_8000.616.304.0_arm64.appx'
        InBundle = $false
    },
    [pscustomobject]@{
        File    = 'AppInstaller_arm64.msix'
        Size    = 61973708
        Sha     = '0D620E0B049A7A899EB72FD936AC9D1F67EC85C425E27B57AAB8DFADC3ED7FB8'
        PkgName = 'Microsoft.DesktopAppInstaller'
        Entry   = 'AppInstaller_arm64.msix'
        InBundle = $true
    }
)

$hostArch = Get-HostArch
$packages = if ($hostArch -eq 'arm64') { $arm64Packages } else { $x64Packages }

# --- helpers ---------------------------------------------------------------
function Test-WinGetVersion {
    $exe = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
    if (-not (Test-Path $exe)) {
        $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
        if ($cmd) { $exe = $cmd.Source } else { return $null }
    }
    try {
        $out = & $exe --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $out) { return ($out | Select-Object -First 1).Trim() }
    } catch {}
    return $null
}

function Test-PackageInstalled([string]$name) {
    try { return [bool](Get-AppxPackage -Name $name -ErrorAction SilentlyContinue) } catch { return $false }
}

function Get-RemoteFile([string]$url, [string]$outFile, [long]$size, [string]$sha, [string]$label) {
    try {
        if (Test-Path $outFile) { Remove-Item $outFile -Force }
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add('User-Agent', 'KJLLinToolbox/1.0')
        $wc.DownloadFile($url, $outFile)
        $wc.Dispose()
    } catch {
        Write-Log "$label download failed: $($_.Exception.Message)"
        return $false
    }
    if (-not (Test-Path $outFile)) { return $false }
    $actual = (Get-Item $outFile).Length
    if ($size -gt 0 -and $actual -ne $size) {
        Write-Log "$label size mismatch ($actual vs $size)"
        Remove-Item $outFile -Force
        return $false
    }
    if ($sha) {
        $hash = (Get-FileHash $outFile -Algorithm SHA256).Hash
        if ($hash -ne $sha) {
            Write-Log "$label sha256 mismatch ($hash)"
            Remove-Item $outFile -Force
            return $false
        }
    }
    Write-Log "$label ok ($actual bytes)"
    return $true
}

function Expand-Entry([string]$container, [string]$entryName, [string]$fileName, [string]$dest) {
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $zip = [System.IO.Compression.ZipFile]::OpenRead($container)
        $entry = $zip.Entries | Where-Object { $_.FullName -eq $entryName -or $_.Name -eq $fileName } | Select-Object -First 1
        if (-not $entry) {
            Write-Log "entry $entryName not found in $(Split-Path $container -Leaf)"
            $zip.Dispose()
            return $false
        }
        if (Test-Path $dest) { Remove-Item $dest -Force }
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $dest, $true)
        $size = $entry.Length
        $zip.Dispose()
        Write-Log "extracted $fileName ($size bytes)"
        return $true
    } catch {
        Write-Log "extract failed: $($_.Exception.Message)"
        return $false
    }
}

function Obtain-Package($p, [string]$tmp) {
    $dest = Join-Path $tmp $p.File
    if (Get-RemoteFile ($mirrorBase + $p.File) $dest $p.Size $p.Sha 'gitee') { return $dest }

    $containerName = if ($p.InBundle) { $bundleFile } else { $depsZip }
    $container = Join-Path $tmp $containerName
    if (-not (Test-Path $container)) {
        $ok = (Get-RemoteFile ($proxyBase + $containerName) $container 0 '' "ghfast/$containerName") -or `
              (Get-RemoteFile ($officialBase + $containerName) $container 0 '' "official/$containerName")
        if (-not $ok) { return $null }
    }
    if (-not (Expand-Entry $container $p.Entry $p.File $dest)) { return $null }

    $actual = (Get-Item $dest).Length
    if ($actual -ne $p.Size) {
        Write-Log "$($p.File) size mismatch after extract ($actual vs $($p.Size))"
        return $null
    }
    $hash = (Get-FileHash $dest -Algorithm SHA256).Hash
    if ($hash -ne $p.Sha) {
        Write-Log "$($p.File) sha256 mismatch after extract"
        return $null
    }
    return $dest
}

function Install-Appx([string]$path) {
    try {
        Add-AppxPackage -Path $path -ErrorAction Stop
        Write-Log "installed $(Split-Path $path -Leaf)"
        return $true
    } catch {
        Write-Log "Add-AppxPackage failed for $(Split-Path $path -Leaf): $($_.Exception.Message)"
        return $false
    }
}

# --- main ------------------------------------------------------------------
$version = Test-WinGetVersion
if ($version -and -not $Force) {
    Write-Log "winget already available: $version (nothing downloaded)"
    exit 0
}
if ($CheckOnly) {
    Write-Log "winget missing"
    exit 1
}

Write-Log "winget not available, bootstrapping App Installer 1.29.380 ($hostArch)"

if ($hostArch -eq 'x86') {
    Write-Log "32-bit Windows is not supported by this bootstrap, skipping"
    exit 0
}

$tmp = Join-Path $env:TEMP ('kjllin-winget-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

try {
    foreach ($p in $packages) {
        if (-not $DryRun -and (Test-PackageInstalled $p.PkgName)) {
            Write-Log "$($p.PkgName) already installed, skipping"
            continue
        }
        $file = Obtain-Package $p $tmp
        if (-not $file) {
            Write-Log "could not obtain $($p.File)"
            continue
        }
        if ($DryRun) {
            Write-Log "dry run: $($p.File) downloaded and verified, install skipped"
            continue
        }
        Install-Appx $file | Out-Null
    }

    if ($DryRun) {
        Write-Log 'dry run completed'
        exit 0
    }

    $version = Test-WinGetVersion
    if ($version) {
        Write-Log "success: winget $version"
    } else {
        Write-Log "winget is still unavailable after bootstrap ($hostArch packages were used)"
    }
} finally {
    try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}

exit 0
