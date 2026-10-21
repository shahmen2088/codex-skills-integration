[CmdletBinding(SupportsShouldProcess)]
param([Parameter(Mandatory)][string]$BackupPath, [Parameter(Mandatory)][string]$Destination)

$backupFull = [IO.Path]::GetFullPath($BackupPath)
$destinationFull = [IO.Path]::GetFullPath($Destination)
if (-not (Test-Path -LiteralPath $backupFull)) { throw "Backup path not found: $backupFull" }
$items = @(Get-ChildItem -LiteralPath $backupFull -Directory)
if ($items.Count -eq 0) { throw "Backup contains no skill directories: $backupFull" }
foreach ($item in $items) {
  $targetSkill = Join-Path $destinationFull $item.Name
  if (Test-Path -LiteralPath $targetSkill) { throw "Refusing restore over existing destination: $targetSkill" }
}
if (-not $PSCmdlet.ShouldProcess($destinationFull, "restore $($items.Count) backed-up skills")) { return }
New-Item -ItemType Directory -Force -Path $destinationFull | Out-Null
foreach ($item in $items) { Move-Item -LiteralPath $item.FullName -Destination (Join-Path $destinationFull $item.Name) }
Write-Output "PASS: restored $($items.Count) backed-up skills to $destinationFull"
