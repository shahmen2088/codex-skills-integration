<!-- codex-skills-integration:start -->
For simple exact-match requests, use the matching skill directly. Use `skill-router` only when the choice is ambiguous, `workflow-router` for a composite workflow, and `skill-conflict-resolver` only for an actual instruction conflict. Preserve system constraints, actual permissions, and explicit user choices. `model-router` may recommend but never change a model, effort, plan, account, or paid usage; before escalation, classify whether the cause is model capability, context, tool, data, or routing.
<!-- codex-skills-integration:end -->
