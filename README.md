# costlike-choco

[Chocolatey](https://community.chocolatey.org/) package for
[CostLike](https://costlike.com) - a desktop app for cloud cost management
across AWS, Azure, Google Cloud, Hetzner Cloud and GitHub, with a local cache
and a built-in MCP server.

The package sources live in [`costlike/`](./costlike); releases are produced
and pushed to the Chocolatey community feed by the
[`Update & publish`](./.github/workflows/publish.yml) GitHub Actions workflow.

## Install

```powershell
choco install costlike
choco upgrade  costlike
```

Installs for all users by default. For the current user only:

```powershell
choco install costlike --params "'/CurrentUser'"
```

ARM64 Windows gets the native ARM64 build; other 64-bit Windows gets x64.

## Where versions come from

The app repository is private, so nothing here talks to GitHub releases.
Everything comes from the public download proxy on costlike.com:

| URL | Used for |
|---|---|
| `https://costlike.com/api/updates.json` | `latest.version` - the release marked latest (never a draft or pre-release) |
| `https://costlike.com/api/download/v<ver>/SHA256SUMS.txt` | the pinned SHA256 of each installer |
| `https://costlike.com/api/download/v<ver>/CostLike-<ver>-x64-setup.exe` | x64 installer, downloaded at install time |
| `https://costlike.com/api/download/v<ver>/CostLike-<ver>-arm64-setup.exe` | ARM64 installer |

The versioned URLs stream the file directly (no redirect) and must keep
working for as long as the package version is on the feed - so a release
that has been pushed to Chocolatey must never be set back to draft or deleted.

A release promoted in the app repo can take up to an hour to show up in
`updates.json` (the proxy caches the release list). The daily run picks it up
the next morning; run the workflow by hand to publish sooner.

### What ends up in git

Each published version leaves behind:

- A commit: `costlike: bump to <version>`
- An annotated tag: `v<version>`
- A workflow run with `costlike.<version>.nupkg` attached as an artifact.

## Setup

One repository secret: `CHOCO_API_KEY`, the API key from your
[chocolatey.org account](https://community.chocolatey.org/account).

## Build the package locally (optional)

You only need this to smoke-test changes before pushing.

```powershell
cd costlike
choco pack
choco install costlike -s "$(Resolve-Path .)" -y
choco uninstall costlike -y
```

For a clean-room test, use the official
[chocolatey-test-environment](https://github.com/chocolatey/chocolatey-test-environment).

## Running the AU updater locally (optional)

```powershell
Install-Module -Name Chocolatey-AU -Force -Scope CurrentUser
cd costlike
./update.ps1          # updates if a newer release exists
./update.ps1 -Force   # re-runs regardless
$env:COSTLIKE_VERSION = 'v0.10.0'; ./update.ps1 -Force   # pin a specific version
```

The updater takes the hashes from the release's `SHA256SUMS.txt`, then
downloads both installers and fails if either disagrees, so a bad checksum
file never reaches the feed.

## Moderation

First-time submissions to the Chocolatey community feed go through human
moderation (usually a few days to a couple of weeks). While a version is in
moderation, additional pushes for the same package id are blocked by the feed
with a bare HTTP 403; this is normal and resolves on its own once the
moderator approves the pending version. After approval, subsequent version
bumps are reviewed automatically. If moderators request changes, edit the
nuspec / install script on a branch, open a PR, merge, then re-run the
workflow to re-push.

## Notes

- The package does **not** embed the installer; it downloads the signed
  installer from costlike.com at install time and verifies it with the pinned
  SHA256 checksums.
- Uninstalling leaves the local database and settings in place.
- CostLike is proprietary software, licensed under the
  [End User Licence Agreement](./costlike/tools/LICENSE.txt). The copy here
  comes from `build/license.txt` in the app repository; refresh it when the
  agreement changes.
