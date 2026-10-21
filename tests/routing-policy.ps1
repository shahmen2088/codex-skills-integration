$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$policy = Get-Content -LiteralPath (Join-Path $root 'config/routing-policy.json') -Raw | ConvertFrom-Json
$template = Get-Content -LiteralPath (Join-Path $root 'templates/AGENTS-skills-integration.md') -Raw
if ($policy.modelRecommendationController -ne 'model-router' -or -not $policy.budgetSkillsAreAdvisory) { throw 'Model routing controller policy is unsafe' }
if (-not $policy.preserveExplicitUserModelChoice -or -not $policy.requireUserConfirmationForModelSwitch -or -not $policy.requireCauseClassificationBeforeEscalation) { throw 'Model routing safety gate missing' }
if ($template -notmatch 'exact-match' -or $template -notmatch 'Preserve system constraints') { throw 'Routing template lacks required ordering' }
Write-Output 'PASS: routing policy preserves user choice and escalation gates'
