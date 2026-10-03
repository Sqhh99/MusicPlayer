[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
    [string]$Version,
    [string]$BinaryPath = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $BinaryPath) {
    $BinaryPath = Join-Path $repoRoot 'target\release\Mi.exe'
}
$binary = Get-Item -LiteralPath $BinaryPath
$dist = Join-Path $repoRoot 'dist'
$installer = Join-Path $dist "Mi-$Version-windows-x64-setup.exe"
if (-not (Test-Path -LiteralPath $installer)) {
    throw "Build the installer first: $installer"
}
if ($binary.VersionInfo.ProductName -ne 'Mi' -or $binary.VersionInfo.ProductVersion -ne $Version) {
    throw "Expected a Mi $Version release binary"
}

$staging = Join-Path $dist ('windows-' + [Guid]::NewGuid().ToString('N'))
$portable = Join-Path $dist "Mi-$Version-windows-x64-portable.zip"
New-Item -ItemType Directory -Path $staging | Out-Null
try {
    Copy-Item -LiteralPath $binary.FullName -Destination (Join-Path $staging 'Mi.exe')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'LICENSE'), (Join-Path $repoRoot 'README.md') -Destination $staging
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $portable -Force
} finally {
    Remove-Item -LiteralPath $staging -Recurse -Force
}

foreach ($asset in @($installer, $portable)) {
    $stream = [IO.File]::OpenRead($asset)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = [BitConverter]::ToString($sha256.ComputeHash($stream)).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha256.Dispose()
        $stream.Dispose()
    }
    "$hash  $([IO.Path]::GetFileName($asset))" | Set-Content -LiteralPath "$asset.sha256" -Encoding ascii
}
Write-Host "Created $portable and SHA-256 checksums"
