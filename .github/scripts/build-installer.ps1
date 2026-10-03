[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
    [string]$Version,
    [string]$BinaryPath = '',
    [string]$CompilerPath = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $BinaryPath) {
    $BinaryPath = Join-Path $repoRoot 'target\release\Mi.exe'
}
$binary = Get-Item -LiteralPath $BinaryPath
if ($binary.VersionInfo.ProductName -ne 'Mi' -or
    $binary.VersionInfo.ProductVersion -ne $Version -or
    $binary.VersionInfo.FileVersion -ne $Version) {
    throw "Expected Mi $Version with embedded version information: $($binary.FullName)"
}

if (-not $CompilerPath) {
    $compiler = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    $CompilerPath = if ($compiler) { $compiler.Source } else {
        Join-Path "${env:ProgramFiles(x86)}" 'Inno Setup 6\ISCC.exe'
    }
}
if (-not (Test-Path -LiteralPath $CompilerPath)) {
    throw 'Install Inno Setup 6 or pass its ISCC.exe location with -CompilerPath.'
}
& $CompilerPath /Qp "/DMyAppVersion=$Version" "/DMyAppBinaryPath=$($binary.FullName)" (Join-Path $repoRoot 'installer\Mi.iss')
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup failed with exit code $LASTEXITCODE"
}
$installer = Join-Path $repoRoot "dist\Mi-$Version-windows-x64-setup.exe"
if (-not (Test-Path -LiteralPath $installer)) {
    throw "Installer was not created: $installer"
}
Write-Host "Created $installer"
