[CmdletBinding()]
param([Parameter(Mandatory)][string]$Destination)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$lock = Get-Content -LiteralPath (Join-Path $repoRoot 'config/source-lock.json') -Raw | ConvertFrom-Json
$destinationFull = [IO.Path]::GetFullPath($Destination)
if (Test-Path -LiteralPath $destinationFull) { throw "Destination already exists: $destinationFull" }
$temporary = "$destinationFull.tmp-$PID"
foreach ($source in @($lock.repositories)) {
  $probe = Join-Path $temporary "$($source.name)/.git/objects/pack/pack-0123456789012345678901234567890123456789.keep"
  if ($probe.Length -gt 240) { throw "Destination path is too deep for safe Git checkout: $destinationFull" }
}
try {
  New-Item -ItemType Directory -Force -Path $temporary | Out-Null
  foreach ($source in @($lock.repositories)) {
    $target = Join-Path $temporary $source.name
    & git clone --quiet --no-checkout $source.url $target
    if ($LASTEXITCODE -ne 0) { throw "Clone failed: $($source.url)" }
    & git -c "safe.directory=$target" -C $target checkout --quiet --detach $source.commit
    if ($LASTEXITCODE -ne 0) { throw "Pinned commit is unavailable: $($source.name)@$($source.commit)" }
    $head = (& git -c "safe.directory=$target" -C $target rev-parse HEAD).Trim()
    if ($head -ne $source.commit) { throw "Pinned commit mismatch after checkout: $($source.name)" }
  }
  Move-Item -LiteralPath $temporary -Destination $destinationFull
  Write-Output "PASS: acquired $(@($lock.repositories).Count) pinned source repositories to $destinationFull"
} catch {
  if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force -ErrorAction SilentlyContinue }
  throw
}
