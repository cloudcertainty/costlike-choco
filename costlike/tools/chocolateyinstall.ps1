$ErrorActionPreference = 'Stop'

$version = '0.11.2'

$url64         = "https://costlike.com/api/download/v$version/CostLike-$version-x64-setup.exe"
$checksum64    = '04fa490b8a00e91fad11eb80edc20ae58fb0febef333961a2ee355bed4e4a80e'
$urlArm64      = "https://costlike.com/api/download/v$version/CostLike-$version-arm64-setup.exe"
$checksumArm64 = '1243a195b84a0382804671f7ca08013d02822c2f877f0b6efeb9be118dd32cef'

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
