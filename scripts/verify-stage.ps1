[CmdletBinding()]
param([Parameter(Mandatory)][string]$StageRoot)

. (Join-Path $PSScriptRoot 'common.ps1')
$stageFull = [IO.Path]::GetFullPath($StageRoot)
$manifestPath = Join-Path $stageFull 'manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath)) { throw "Missing stage manifest: $manifestPath" }
$manifest = Read-IntegrationJson $manifestPath
if ($manifest.version -ne 1 -or $manifest.skillCount -ne 42 -or @($manifest.skills).Count -ne 42) { throw 'Stage manifest must contain exactly 42 skills' }
$names = @($manifest.skills.name)
if (@($names | Sort-Object -Unique).Count -ne 42) { throw 'Stage has duplicate skill names' }
$unsafe = 'явный запрос пользователя → системные ограничения и безопасность'
foreach ($skill in @($manifest.skills)) {
  $skillDir = Join-Path $stageFull "skills/$($skill.name)"
  $skillFile = Join-Path $skillDir 'SKILL.md'
  if (-not (Test-Path -LiteralPath $skillFile)) { throw "Missing SKILL.md: $($skill.name)" }
  $text = Get-Content -LiteralPath $skillFile -Raw
  if ($text -match [regex]::Escape($unsafe)) { throw "Unsafe priority remains in $($skill.name)" }
  if ($text -match '\.\./\.\./references/') { throw "External reference remains in $($skill.name)" }
  if ($text -notmatch "(?m)^name:\s*$([regex]::Escape($skill.name))\s*$") { throw "Frontmatter name mismatch: $($skill.name)" }
  $links = [regex]::Matches($text, '\]\(([^)]+)\)') | ForEach-Object { $_.Groups[1].Value }
  foreach ($link in $links) {
    $pathPart = [Uri]::UnescapeDataString(($link -split '#', 2)[0])
    if ([string]::IsNullOrWhiteSpace($pathPart) -or $pathPart -match '^[a-zA-Z][a-zA-Z0-9+.-]*:' ) { continue }
    if ($pathPart.StartsWith('/')) { throw "Absolute Markdown link in $($skill.name): $link" }
    $resolved = [IO.Path]::GetFullPath((Join-Path $skillDir $pathPart))
    Assert-IntegrationDirectoryIsWithin -Parent $skillDir -Child $resolved
    if (-not (Test-Path -LiteralPath $resolved)) { throw "Broken staged link in $($skill.name): $link" }
  }
  $actual = Get-IntegrationPathMap (Get-IntegrationFileRecords -Root $skillDir)
  $expected = Get-IntegrationPathMap $skill.files
  if ($actual.Count -ne $expected.Count) { throw "File count mismatch in $($skill.name)" }
  foreach ($path in $expected.Keys) { if (-not $actual.ContainsKey($path) -or $actual[$path] -ne $expected[$path]) { throw "Hash mismatch in $($skill.name): $path" } }
}
Write-Output 'PASS: verified 42 self-contained staged skills'
