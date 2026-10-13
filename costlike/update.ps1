[CmdletBinding()]
param(
    [switch]$Force
)

Import-Module Chocolatey-AU

# The website's update manifest: the release marked latest, never a draft or a pre-release.
$manifest = 'https://costlike.com/api/updates.json'
$download = 'https://costlike.com/api/download'

function global:au_SearchReplace {
    @{
        'tools\chocolateyinstall.ps1' = @{
            "(?i)(^\s*\`$version\s*=\s*)'.*'"       = "`$1'$($Latest.Version)'"
            "(?i)(^\s*\`$checksum64\s*=\s*)'.*'"    = "`$1'$($Latest.Checksum64)'"
            "(?i)(^\s*\`$checksumArm64\s*=\s*)'.*'" = "`$1'$($Latest.ChecksumArm64)'"
        }
    }
}

# The hashes come from the release's own SHA256SUMS.txt. Before they are pinned, both
# installers are downloaded and hashed here, so a checksum file that disagrees with what
# the site actually serves fails the update instead of shipping a package that cannot
# install.
function global:au_BeforeUpdate ($Package) {
    foreach ($arch in @(@{ Url = $Latest.URL64; Sum = $Latest.Checksum64 }, @{ Url = $Latest.URLArm64; Sum = $Latest.ChecksumArm64 })) {
        Write-Host "Verifying $($arch.Url)"
        $actual = Get-RemoteChecksum -Url $arch.Url -Algorithm sha256
        if ($actual -ne $arch.Sum) {
            throw "Checksum mismatch for $($arch.Url): SHA256SUMS.txt says $($arch.Sum), download hashes to $actual"
        }
    }
}

function global:au_GetLatest {
    $headers = @{ 'User-Agent' = 'costlike-choco-au' }

    $version = $env:COSTLIKE_VERSION
    if (-not $version) {
        $json = Invoke-RestMethod -Uri $manifest -Headers $headers
        if (-not $json.latest) { throw "$manifest names no latest release" }
        $version = $json.latest.version
    }
    $version = $version.Trim().TrimStart('v')
    $tag     = "v$version"

    $url64        = "$download/$tag/CostLike-$version-x64-setup.exe"
    $urlArm64     = "$download/$tag/CostLike-$version-arm64-setup.exe"
    $checksumsUrl = "$download/$tag/SHA256SUMS.txt"

    # sha256sum format: "<hash>  <name>", or "<hash> *<name>" for files hashed in binary mode.
    $sums = @{}
    foreach ($line in ((Invoke-RestMethod -Uri $checksumsUrl -Headers $headers) -split "`r?`n")) {
        if ($line -match '^([0-9a-fA-F]{64})\s+\*?(\S.*?)\s*$') { $sums[$Matches[2]] = $Matches[1].ToLower() }
    }
    $checksum64    = $sums["CostLike-$version-x64-setup.exe"]
    $checksumArm64 = $sums["CostLike-$version-arm64-setup.exe"]
    if (-not $checksum64 -or -not $checksumArm64) {
        throw "$checksumsUrl has no entry for one of the Windows installers of $tag"
    }

    @{
        Version        = $version
        URL64          = $url64
        URLArm64       = $urlArm64
        Checksum64     = $checksum64
        ChecksumType64 = 'sha256'
        ChecksumArm64  = $checksumArm64
    }
}

Push-Location $PSScriptRoot
try {
    # Checksums come from SHA256SUMS.txt (verified in au_BeforeUpdate), not from AU.
    update -ChecksumFor none -Force:$Force
}
finally {
    Pop-Location
}
