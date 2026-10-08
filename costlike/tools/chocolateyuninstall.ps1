$ErrorActionPreference = 'Stop'

# The mode chocolateyinstall.ps1 used; packages installed before it was recorded used
# the default.
$modeFile = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) 'install-mode.txt'
$mode = if (Test-Path $modeFile) { (Get-Content $modeFile -Raw).Trim() } else { '/allusers' }

# The installer writes the uninstall string as: "<install dir>\Uninstall CostLike.exe" /allusers
# (or /currentuser). Matching on that mode leaves alone a copy installed the other way,
# such as a per-user install someone made by hand.
[array]$keys = Get-UninstallRegistryKey -SoftwareName 'CostLike*' |
  Where-Object { $_.UninstallString -match "^\s*`"([^`"]+)`"\s*$([regex]::Escape($mode))\s*$" }

if ($keys.Count -eq 0) {
  Write-Warning "$env:ChocolateyPackageName has already been uninstalled by other means."
  return
}

foreach ($key in $keys) {
  $null = $key.UninstallString -match '^\s*"([^"]+)"'
  $packageArgs = @{
    packageName    = $env:ChocolateyPackageName
    fileType       = 'exe'
    file           = $Matches[1]
    silentArgs     = "$mode /S"
    validExitCodes = @(0)
  }
  Uninstall-ChocolateyPackage @packageArgs
}
