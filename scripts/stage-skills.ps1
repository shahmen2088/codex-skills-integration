[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$SourcesRoot,
  [Parameter(Mandatory)][string]$StageRoot
)

. (Join-Path $PSScriptRoot 'common.ps1')
$repoRoot = Split-Path -Parent $PSScriptRoot
$lock = Read-IntegrationJson (Join-Path $repoRoot 'config/source-lock.json')
$referenceMap = @(Read-IntegrationJson (Join-Path $repoRoot 'config/reference-map.json'))
$sourcesFull = [IO.Path]::GetFullPath($SourcesRoot)
$stageFull = [IO.Path]::GetFullPath($StageRoot)
if (Test-Path -LiteralPath $stageFull) { throw "Stage root already exists: $stageFull" }
$temporary = "$stageFull.tmp-$PID"

try {
  New-Item -ItemType Directory -Force -Path (Join-Path $temporary 'skills') | Out-Null
  $manifestSkills = @()
  foreach ($entry in @($lock.repositories)) {
    $sourceRepo = Join-Path $sourcesFull $entry.name
    if (-not (Test-Path -LiteralPath (Join-Path $sourceRepo 'skills'))) { throw "Missing source repository or skills directory: $sourceRepo" }
    $head = (& git -c "safe.directory=$sourceRepo" -C $sourceRepo rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $head -ne $entry.commit) { throw "Pinned commit mismatch for $($entry.name): expected $($entry.commit), got $head" }
    $found = @(Get-ChildItem -LiteralPath (Join-Path $sourceRepo 'skills') -Directory | Select-Object -ExpandProperty Name | Sort-Object)
    $expected = @($entry.skills | Sort-Object)
    if (($found -join "`n") -ne ($expected -join "`n")) { throw "Skill inventory mismatch for $($entry.name)" }
    foreach ($skillName in @($entry.skills)) {
      $sourceSkill = Join-Path $sourceRepo "skills/$skillName"
      $destinationSkill = Join-Path $temporary "skills/$skillName"
      Copy-Item -LiteralPath $sourceSkill -Destination $destinationSkill -Recurse
      $skillFile = Join-Path $destinationSkill 'SKILL.md'
      $skillText = Get-Content -LiteralPath $skillFile -Raw
      foreach ($mapping in @($referenceMap | Where-Object { $_.repository -eq $entry.name -and $_.skill -eq $skillName })) {
        $sourceReference = Join-Path $sourceRepo $mapping.source
        if (-not (Test-Path -LiteralPath $sourceReference)) { throw "Missing mapped reference: $sourceReference" }
        $destinationReference = Join-Path $destinationSkill $mapping.destination
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destinationReference) | Out-Null
        Copy-Item -LiteralPath $sourceReference -Destination $destinationReference
        $oldLink = "../../$($mapping.source)"
        if (-not $skillText.Contains($oldLink)) { throw "Expected reference link not found in ${skillName}: $oldLink" }
        $skillText = $skillText.Replace($oldLink, $mapping.destination)
      }
      if ($skillName -eq 'skill-conflict-resolver') {
        $unsafe = 'явный запрос пользователя → системные ограничения и безопасность → проектные инструкции → специализированный skill → общий skill'
        $safe = 'системные ограничения, безопасность и фактические разрешения → явный запрос пользователя → проектные инструкции → специализированный skill → общий skill'
        if (-not $skillText.Contains($unsafe)) { throw 'Expected unsafe priority sentence was not found; refuse unreviewed rewrite' }
        $skillText = $skillText.Replace($unsafe, $safe)
      }
      Set-Content -LiteralPath $skillFile -Value $skillText -Encoding utf8
      $manifestSkills += [pscustomobject]@{
        name = $skillName
        sourceRepository = $entry.name
        sourceCommit = $entry.commit
        files = Get-IntegrationFileRecords -Root $destinationSkill
      }
    }
  }
  $manifest = [pscustomobject]@{ version = 1; skillCount = $manifestSkills.Count; skills = @($manifestSkills | Sort-Object name) }
  Write-IntegrationJson -Value $manifest -Path (Join-Path $temporary 'manifest.json')
  Move-Item -LiteralPath $temporary -Destination $stageFull
  Write-Output "PASS: staged $($manifest.skillCount) self-contained skills to $stageFull"
} catch {
  if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force -ErrorAction SilentlyContinue }
  throw
}
