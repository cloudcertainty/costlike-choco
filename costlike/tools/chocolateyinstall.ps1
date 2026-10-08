$ErrorActionPreference = 'Stop'

$version = '0.10.0'

$url64         = "https://costlike.com/api/download/v$version/CostLike-$version-x64-setup.exe"
$checksum64    = '906985927c29769b263fa6f8092070f7c4c2a60f4504d3cf68c5406915456889'
$urlArm64      = "https://costlike.com/api/download/v$version/CostLike-$version-arm64-setup.exe"
$checksumArm64 = 'ae332bfb427260de07976f97249a434e223c6e2a461b99ce136364b2b51069ff'

# The x64 and ARM64 builds are separate (the main process is compiled to CPU-specific
# bytecode). Read the machine-level value: an emulated x64 shell on ARM64 reports AMD64
# in its own environment.
if ([Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE', 'Machine') -eq 'ARM64') {
  Write-Host 'ARM64 Windows detected, installing the native ARM64 build.'
  $url64      = $urlArm64
  $checksum64 = $checksumArm64
}

# electron-builder's NSIS installer: /S is silent, /allusers or /currentuser picks the
# install mode that would otherwise be asked on the first page.
$pp = Get-PackageParameters
$installMode = if ($pp['CurrentUser']) { '/currentuser' } else { '/allusers' }

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url64bit       = $url64
  checksum64     = $checksum64
  checksumType64 = 'sha256'
  softwareName   = 'CostLike*'
  silentArgs     = "/S $installMode"
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs

# Remembered for the uninstall, so it removes this install and not a separate per-user
# copy someone installed by hand.
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Content -Path (Join-Path $toolsDir 'install-mode.txt') -Value $installMode
