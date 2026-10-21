$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$sources = Split-Path -Parent $root
. (Join-Path $root 'scripts/common.ps1')
$temporary = Join-Path $root ".test-work/lifecycle-$PID"
try {
  $stage = Join-Path $temporary 'stage'; $nextStage = Join-Path $temporary 'stage-next'; $destination = Join-Path $temporary 'destination'
  & (Join-Path $root 'scripts/stage-skills.ps1') -SourcesRoot $sources -StageRoot $stage
  & (Join-Path $root 'scripts/install.ps1') -StageRoot $stage -Target custom -Destination $destination
  & (Join-Path $root 'scripts/update.ps1') -StageRoot $stage -Destination $destination
  Copy-Item -LiteralPath $stage -Destination $nextStage -Recurse
  $changedReference = Join-Path $nextStage 'skills/skill-router/references/routing-contract.md'
  Add-Content -LiteralPath $changedReference -Value "`n<!-- integration update test -->"
  $nextManifestPath = Join-Path $nextStage 'manifest.json'
  $nextManifest = Get-Content -LiteralPath $nextManifestPath -Raw | ConvertFrom-Json
  $changedSkill = @($nextManifest.skills | Where-Object name -eq 'skill-router')[0]
  $changedSkill.files = @(Get-IntegrationFileRecords -Root (Join-Path $nextStage 'skills/skill-router'))
  $nextManifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $nextManifestPath -Encoding utf8
  & (Join-Path $root 'scripts/update.ps1') -StageRoot $nextStage -Destination $destination
  $backup = @(Get-ChildItem -LiteralPath (Join-Path $destination '.codex-skills-integration/backups') -Directory | Select-Object -First 1)[0]
  if (-not $backup) { throw 'Updated skill was not backed up' }
  $backupCopy = Join-Path $temporary 'backup-copy'; $restored = Join-Path $temporary 'restored'
  Copy-Item -LiteralPath $backup.FullName -Destination $backupCopy -Recurse
  & (Join-Path $root 'scripts/restore.ps1') -BackupPath $backupCopy -Destination $restored
  if (-not (Test-Path -LiteralPath (Join-Path $restored 'skill-router/SKILL.md'))) { throw 'Backup restore failed' }
  Add-Content -LiteralPath (Join-Path $destination 'skill-router/SKILL.md') -Value "`nuser modification"
  $blocked = $false
  try { & (Join-Path $root 'scripts/update.ps1') -StageRoot $nextStage -Destination $destination } catch { $blocked = $true }
  if (-not $blocked) { throw 'Modified managed skill was not protected during update' }
  & (Join-Path $root 'scripts/uninstall.ps1') -Destination $destination
  if (-not (Test-Path -LiteralPath (Join-Path $destination 'skill-router/SKILL.md'))) { throw 'Modified skill was removed during uninstall' }
  Write-Output 'PASS: update and uninstall preserve user modifications'
} finally {
  if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
  $testRoot = Split-Path -Parent $temporary
  if ((Test-Path -LiteralPath $testRoot) -and @((Get-ChildItem -LiteralPath $testRoot -Force)).Count -eq 0) { Remove-Item -LiteralPath $testRoot -Force }
}
