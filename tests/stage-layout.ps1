$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$sources = Split-Path -Parent $root
$temporary = Join-Path $root ".test-work/stage-$PID"
try {
  & (Join-Path $root 'scripts/stage-skills.ps1') -SourcesRoot $sources -StageRoot $temporary
  & (Join-Path $root 'scripts/verify-stage.ps1') -StageRoot $temporary
  $manifest = Get-Content -LiteralPath (Join-Path $temporary 'manifest.json') -Raw | ConvertFrom-Json
  if (@($manifest.skills).Count -ne 42) { throw 'Stage has unexpected skill count' }
  foreach ($skill in @($manifest.skills)) {
    $text = Get-Content -LiteralPath (Join-Path $temporary "skills/$($skill.name)/SKILL.md") -Raw
    if ($text -match '\.\./\.\./references/') { throw "Unrewritten reference: $($skill.name)" }
  }
  Write-Output 'PASS: staged layout is self-contained'
} finally {
  if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
  $testRoot = Split-Path -Parent $temporary
  if ((Test-Path -LiteralPath $testRoot) -and @((Get-ChildItem -LiteralPath $testRoot -Force)).Count -eq 0) { Remove-Item -LiteralPath $testRoot -Force }
}
