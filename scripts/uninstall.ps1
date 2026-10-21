[CmdletBinding(SupportsShouldProcess)]
param([Parameter(Mandatory)][string]$Destination)

. (Join-Path $PSScriptRoot 'common.ps1')
$destinationFull = [IO.Path]::GetFullPath($Destination)
$managedRoot = Join-Path $destinationFull '.codex-skills-integration'
$managedPath = Join-Path $managedRoot 'manifest.json'
if (-not (Test-Path -LiteralPath $managedPath)) { throw 'No managed installation found' }
$manifest = Read-IntegrationJson $managedPath
$preserved = @(); $removable = @()
foreach ($skill in @($manifest.skills)) {
  $target = Join-Path $destinationFull $skill.name
  if (-not (Test-Path -LiteralPath $target) -or -not (Test-IntegrationRecordsMatch -Expected $skill.files -Actual (Get-IntegrationFileRecords $target))) { $preserved += $skill }
  else { $removable += $skill }
}
if (-not $PSCmdlet.ShouldProcess($destinationFull, "remove $($removable.Count) managed skills")) { return }
foreach ($skill in $removable) { Remove-Item -LiteralPath (Join-Path $destinationFull $skill.name) -Recurse -Force }
if ($preserved.Count -eq 0) { Remove-Item -LiteralPath $managedRoot -Recurse -Force }
else { Write-IntegrationJson -Value ([pscustomobject]@{version=1;skillCount=$preserved.Count;skills=$preserved}) -Path $managedPath }
if ($preserved.Count -gt 0) { Write-Warning "Preserved modified or missing managed skills: $($preserved.name -join ', ')" }
Write-Output "PASS: removed $($removable.Count) managed skills"
