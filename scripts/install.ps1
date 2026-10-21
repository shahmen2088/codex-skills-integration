[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory)][string]$StageRoot,
  [ValidateSet('codex','opencode','custom')][string]$Target = 'custom',
  [string]$Destination
)

. (Join-Path $PSScriptRoot 'common.ps1')
if ($Target -eq 'codex') { $Destination = Join-Path $env:USERPROFILE '.codex\skills' }
elseif ($Target -eq 'opencode') { $Destination = Join-Path $env:USERPROFILE '.config\opencode\skills' }
elseif ([string]::IsNullOrWhiteSpace($Destination)) { throw 'Destination is required when Target is custom' }

& (Join-Path $PSScriptRoot 'verify-stage.ps1') -StageRoot $StageRoot
$destinationFull = [IO.Path]::GetFullPath($Destination)
$stage = Read-IntegrationJson (Join-Path $StageRoot 'manifest.json')
$managedRoot = Join-Path $destinationFull '.codex-skills-integration'
$managedPath = Join-Path $managedRoot 'manifest.json'
$previous = if (Test-Path -LiteralPath $managedPath) { Read-IntegrationJson $managedPath } else { $null }
$previousByName = @{}
if ($previous) { foreach ($skill in @($previous.skills)) { $previousByName[$skill.name] = $skill } }
$alreadyCurrent = $true
foreach ($skill in @($stage.skills)) {
  $targetSkill = Join-Path $destinationFull $skill.name
  if (Test-Path -LiteralPath $targetSkill) {
    if (-not $previousByName.ContainsKey($skill.name)) { throw "Refusing user-owned destination: $targetSkill" }
    $actual = Get-IntegrationFileRecords -Root $targetSkill
    if (-not (Test-IntegrationRecordsMatch -Expected $previousByName[$skill.name].files -Actual $actual)) { throw "Refusing modified managed destination: $targetSkill" }
    if (-not (Test-IntegrationRecordsMatch -Expected $skill.files -Actual $actual)) { throw "Managed destination needs update, not install: $targetSkill" }
  } else { $alreadyCurrent = $false }
}
if ($previous -and $alreadyCurrent -and @($previous.skills).Count -eq @($stage.skills).Count) { Write-Output 'PASS: managed installation is already current'; return }
if (-not $PSCmdlet.ShouldProcess($destinationFull, "install $($stage.skillCount) staged skills")) { return }

$temporary = Join-Path $destinationFull ".codex-skills-integration-tmp-$PID"
$moved = @()
try {
  New-Item -ItemType Directory -Force -Path $temporary | Out-Null
  foreach ($skill in @($stage.skills)) { Copy-Item -LiteralPath (Join-Path $StageRoot "skills/$($skill.name)") -Destination (Join-Path $temporary $skill.name) -Recurse }
  New-Item -ItemType Directory -Force -Path $destinationFull | Out-Null
  foreach ($skill in @($stage.skills)) {
    $source = Join-Path $temporary $skill.name
    $targetSkill = Join-Path $destinationFull $skill.name
    if (-not (Test-Path -LiteralPath $targetSkill)) { Move-Item -LiteralPath $source -Destination $targetSkill; $moved += $targetSkill }
  }
  New-Item -ItemType Directory -Force -Path $managedRoot | Out-Null
  Write-IntegrationJson -Value $stage -Path $managedPath
  Remove-Item -LiteralPath $temporary -Recurse -Force
  Write-Output "PASS: installed $($stage.skillCount) managed skills to $destinationFull"
} catch {
  foreach ($path in @($moved)) { if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force } }
  if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
  throw
}
