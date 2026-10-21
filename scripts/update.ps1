[CmdletBinding(SupportsShouldProcess)]
param([Parameter(Mandatory)][string]$StageRoot, [Parameter(Mandatory)][string]$Destination)

. (Join-Path $PSScriptRoot 'common.ps1')
& (Join-Path $PSScriptRoot 'verify-stage.ps1') -StageRoot $StageRoot
$destinationFull = [IO.Path]::GetFullPath($Destination)
$managedRoot = Join-Path $destinationFull '.codex-skills-integration'
$managedPath = Join-Path $managedRoot 'manifest.json'
if (-not (Test-Path -LiteralPath $managedPath)) { throw 'No managed installation found; use install.ps1 first' }
$previous = Read-IntegrationJson $managedPath
$stage = Read-IntegrationJson (Join-Path $StageRoot 'manifest.json')
foreach ($skill in @($previous.skills)) {
  $target = Join-Path $destinationFull $skill.name
  if (-not (Test-Path -LiteralPath $target) -or -not (Test-IntegrationRecordsMatch -Expected $skill.files -Actual (Get-IntegrationFileRecords $target))) { throw "Refusing update: managed skill changed or missing: $target" }
}
$changed = @($stage.skills | Where-Object {
  $before = @($previous.skills | Where-Object name -eq $_.name | Select-Object -First 1)
  -not $before -or -not (Test-IntegrationRecordsMatch -Expected $before.files -Actual $_.files)
})
if ($changed.Count -eq 0) { Write-Output 'PASS: managed installation is already current'; return }
if (-not $PSCmdlet.ShouldProcess($destinationFull, "update $($changed.Count) managed skills")) { return }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $managedRoot "backups/$stamp"
$temporary = Join-Path $destinationFull ".codex-skills-integration-update-$PID"
$replaced = @()
try {
  New-Item -ItemType Directory -Force -Path $temporary, $backupRoot | Out-Null
  foreach ($skill in $changed) { Copy-Item -LiteralPath (Join-Path $StageRoot "skills/$($skill.name)") -Destination (Join-Path $temporary $skill.name) -Recurse }
  foreach ($skill in $changed) {
    $target = Join-Path $destinationFull $skill.name
    $backup = Join-Path $backupRoot $skill.name
    Move-Item -LiteralPath $target -Destination $backup
    Move-Item -LiteralPath (Join-Path $temporary $skill.name) -Destination $target
    $replaced += [pscustomobject]@{ target = $target; backup = $backup }
  }
  Write-IntegrationJson -Value $stage -Path $managedPath
  Remove-Item -LiteralPath $temporary -Recurse -Force
  Write-Output "PASS: updated $($changed.Count) managed skills; backup: $backupRoot"
} catch {
  foreach ($entry in @($replaced | Sort-Object { $_.target } -Descending)) {
    if (-not (Test-Path -LiteralPath $entry.target) -and (Test-Path -LiteralPath $entry.backup)) { Move-Item -LiteralPath $entry.backup -Destination $entry.target }
  }
  if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
  throw
}
