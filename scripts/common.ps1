Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-IntegrationJson {
  param([Parameter(Mandatory)][string]$Path)
  Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Write-IntegrationJson {
  param([Parameter(Mandatory)]$Value, [Parameter(Mandatory)][string]$Path)
  $parent = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  $Value | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Path -Encoding utf8
}

function Get-IntegrationRelativePath {
  param([Parameter(Mandatory)][string]$Base, [Parameter(Mandatory)][string]$Path)
  [IO.Path]::GetRelativePath($Base, $Path).Replace('\', '/')
}

function Get-IntegrationFileRecords {
  param([Parameter(Mandatory)][string]$Root)
  @(
    Get-ChildItem -LiteralPath $Root -Recurse -File | ForEach-Object {
      [pscustomobject]@{
        path = Get-IntegrationRelativePath -Base $Root -Path $_.FullName
        sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
      }
    } | Sort-Object path
  )
}

function Get-IntegrationPathMap {
  param([Parameter(Mandatory)]$Records)
  $map = @{}
  foreach ($record in @($Records)) { $map[$record.path] = $record.sha256 }
  $map
}

function Test-IntegrationRecordsMatch {
  param([Parameter(Mandatory)]$Expected, [Parameter(Mandatory)]$Actual)
  $expectedMap = Get-IntegrationPathMap $Expected
  $actualMap = Get-IntegrationPathMap $Actual
  if ($expectedMap.Count -ne $actualMap.Count) { return $false }
  foreach ($path in $expectedMap.Keys) {
    if (-not $actualMap.ContainsKey($path) -or $actualMap[$path] -ne $expectedMap[$path]) { return $false }
  }
  return $true
}

function Assert-IntegrationDirectoryIsWithin {
  param([Parameter(Mandatory)][string]$Parent, [Parameter(Mandatory)][string]$Child)
  $parentFull = [IO.Path]::GetFullPath($Parent).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
  $childFull = [IO.Path]::GetFullPath($Child)
  if (-not $childFull.StartsWith($parentFull, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Path escapes its allowed directory: $Child"
  }
}
