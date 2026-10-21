$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$sources = Split-Path -Parent $root
$temporary = Join-Path $root ".test-work/install-$PID"
try {
  $stage = Join-Path $temporary 'stage'; $destination = Join-Path $temporary 'destination'; $conflict = Join-Path $temporary 'conflict'
  & (Join-Path $root 'scripts/stage-skills.ps1') -SourcesRoot $sources -StageRoot $stage
  & (Join-Path $root 'scripts/install.ps1') -StageRoot $stage -Target custom -Destination $destination
  if (@(Get-ChildItem -LiteralPath $destination -Directory | Where-Object Name -ne '.codex-skills-integration').Count -ne 42) { throw 'Install count mismatch' }
  & (Join-Path $root 'scripts/install.ps1') -StageRoot $stage -Target custom -Destination $destination
  New-Item -ItemType Directory -Force -Path (Join-Path $conflict 'skill-router') | Out-Null
  $blocked = $false
  try { & (Join-Path $root 'scripts/install.ps1') -StageRoot $stage -Target custom -Destination $conflict } catch { $blocked = $true }
  if (-not $blocked) { throw 'User-owned destination collision was not blocked' }
  Write-Output 'PASS: installation is transactional, rerunnable, and conflict-safe'
} finally {
  if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
  $testRoot = Split-Path -Parent $temporary
  if ((Test-Path -LiteralPath $testRoot) -and @((Get-ChildItem -LiteralPath $testRoot -Force)).Count -eq 0) { Remove-Item -LiteralPath $testRoot -Force }
}
