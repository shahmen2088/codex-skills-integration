$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'validate-config.ps1')
& (Join-Path $PSScriptRoot 'routing-policy.ps1')
& (Join-Path $PSScriptRoot 'stage-layout.ps1')
& (Join-Path $PSScriptRoot 'install-transaction.ps1')
& (Join-Path $PSScriptRoot 'lifecycle.ps1')
Write-Output 'PASS: complete integration lifecycle verified in isolated directories'
