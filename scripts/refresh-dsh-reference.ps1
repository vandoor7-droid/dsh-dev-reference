#Requires -Version 5.1
<#
.SYNOPSIS
  Pull or update the DeepSeek Harness (DSH) source tree + developer docs at a
  specific release tag, as a read-only reference checkout.

.DESCRIPTION
  Resolves the requested DSH version (parameter -> `npm view @deepseek-ai/dsh
  version`), maps it to the repository tag `dsh-v<version>`, clones the public
  repo (blobless) if the destination is empty, fetches all tags, and detaches
  the checkout on that tag. The result is a stable reference for reading
  source and docs/<...>.md at exactly the version a deployment runs.

  The checkout is reference material: never edit inside it and never track the
  master branch (master contains unreleased behavior that represents no
  deployment).

.EXAMPLE
  pwsh refresh-dsh-reference.ps1
  pwsh refresh-dsh-reference.ps1 -Version 0.2.0-rc.2
  pwsh refresh-dsh-reference.ps1 -Destination reference/deepseek-harness
#>
[CmdletBinding()]
param(
    # DSH version such as 0.2.0-rc.2; defaults to the latest published @deepseek-ai/dsh.
    [string]$Version,

    # Where the reference checkout lives. Defaults to the user-level cache so it
    # sits outside every repository; inside a plugin repo, point this at that
    # repo's git-ignored reference/ directory instead.
    [string]$Destination = (Join-Path $HOME '.dsh/reference/deepseek-harness')
)

$ErrorActionPreference = 'Stop'
$repoUrl = 'https://github.com/deepseek-ai/deepseek-harness.git'

if (-not $Version) {
    Write-Host 'Resolving latest @deepseek-ai/dsh version from npm ...'
    try {
        $Version = ((npm view '@deepseek-ai/dsh' version 2>$null) | Select-Object -First 1).Trim()
    } catch { $Version = '' }
    if (-not $Version) {
        throw 'Could not resolve a version from npm. Pass -Version explicitly (e.g. -Version 0.2.0-rc.2).'
    }
}

$tag = "dsh-v$Version"
$Destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)

if (Test-Path (Join-Path $Destination '.git')) {
    Write-Host "Updating existing checkout at $Destination ..."
    git -C $Destination remote set-url origin $repoUrl
    git -C $Destination fetch --tags --force origin
} else {
    if (Test-Path $Destination) {
        $leftover = Get-ChildItem -Force $Destination
        if ($leftover) { throw "Destination $Destination exists, is not a git checkout, and is not empty. Choose another -Destination." }
        Remove-Item $Destination -Recurse -Force
    }
    Write-Host "Cloning (blobless) $repoUrl ..."
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    $parent = Split-Path $Destination -Parent
    git clone --filter=blob:none $repoUrl $Destination
    if ($LASTEXITCODE -ne 0) { throw "git clone failed with exit code $LASTEXITCODE" }
}

git -C $Destination fetch --tags --force origin
if ($LASTEXITCODE -ne 0) { throw "git fetch --tags failed with exit code $LASTEXITCODE" }

$tagExists = git -C $Destination rev-parse --verify --quiet "refs/tags/$tag"
if (-not $tagExists) {
    $available = (git -C $Destination tag -l 'dsh-v*' --sort=-v:refname | Select-Object -First 8) -join ', '
    throw "Tag $tag not found. Newest available release tags: $available"
}

git -C $Destination checkout --detach $tag
if ($LASTEXITCODE -ne 0) { throw "git checkout $tag failed with exit code $LASTEXITCODE" }

$head = (git -C $Destination rev-parse --short HEAD).Trim()
$docs = Join-Path $Destination 'docs'
Write-Host ''
Write-Host "Reference ready:"
Write-Host "  version : $Version  (tag $tag @ $head)"
Write-Host "  source  : $Destination"
Write-Host "  docs    : $docs  (each topic has .md / .zh.md siblings)"
Write-Host "  map     : see references/doc-map.md in this skill"
