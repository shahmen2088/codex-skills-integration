$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$lock = Get-Content -LiteralPath (Join-Path $root 'config/source-lock.json') -Raw | ConvertFrom-Json
$maps = @(Get-Content -LiteralPath (Join-Path $root 'config/reference-map.json') -Raw | ConvertFrom-Json)
if (@($lock.repositories).Count -ne 9) { throw 'Expected nine locked repositories' }
$skills = @($lock.repositories | ForEach-Object { $_.skills })
if ($skills.Count -ne 42 -or @($skills | Sort-Object -Unique).Count -ne 42) { throw 'Expected 42 unique nested skills' }
foreach ($map in $maps) {
  $repo = @($lock.repositories | Where-Object name -eq $map.repository)
  if ($repo.Count -ne 1 -or $map.skill -notin $repo[0].skills) { throw "Invalid reference map entry: $($map.repository)/$($map.skill)" }
  if ($map.source -notmatch '^references/.+\.md$' -or $map.destination -notmatch '^references/.+\.md$') { throw 'Reference maps must remain inside references/' }
}
Write-Output 'PASS: source lock and reference map define nine repositories and 42 unique skills'
