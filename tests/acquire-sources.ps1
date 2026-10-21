$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$shortBase = [IO.Path]::GetFullPath((Join-Path $root '..\..\..\..\..'))
$temporary = Join-Path $shortBase ".integration-acquire-$PID"
try {
  $sources = Join-Path $temporary 'sources'
  & (Join-Path $root 'scripts/acquire-sources.ps1') -Destination $sources
  $lock = Get-Content -LiteralPath (Join-Path $root 'config/source-lock.json') -Raw | ConvertFrom-Json
  foreach ($source in @($lock.repositories)) {
    $target = Join-Path $sources $source.name
    $head = (& git -c "safe.directory=$target" -C $target rev-parse HEAD).Trim()
    if ($head -ne $source.commit) { throw "Acquired source is not pinned: $($source.name)" }
  }
  $stage = Join-Path $temporary 'stage'
  & (Join-Path $root 'scripts/stage-skills.ps1') -SourcesRoot $sources -StageRoot $stage
  & (Join-Path $root 'scripts/verify-stage.ps1') -StageRoot $stage
  Write-Output 'PASS: all source repositories are acquired at locked commits and produce a valid stage'
} finally {
  if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
  $testRoot = Split-Path -Parent $temporary
  if ((Test-Path -LiteralPath $testRoot) -and @((Get-ChildItem -LiteralPath $testRoot -Force)).Count -eq 0) { Remove-Item -LiteralPath $testRoot -Force }
}
