# Skills Integration

Безопасный интеграционный слой для девяти локально проверенных репозиториев skills. Он не запускает их собственные установщики: вместо этого закрепляет версии, собирает только 42 вложенных навыка в автономный staging-каталог и устанавливает их с проверкой конфликтов и хешей.

## Быстрый запуск

```powershell
pwsh .\scripts\stage-skills.ps1 -SourcesRoot .. -StageRoot .\stage
pwsh .\scripts\verify-stage.ps1 -StageRoot .\stage
pwsh .\scripts\install.ps1 -StageRoot .\stage -Target custom -Destination C:\temp\codex-skills-test
```

`-Target codex` и `-Target opencode` выбирают стандартные пользовательские каталоги. Сначала используйте `-WhatIf`. Обновление и удаление применимы только к установкам, созданным этим репозиторием; пользовательские или изменённые файлы не перезаписываются и не удаляются.

## Проверка

```powershell
pwsh .\tests\validate-config.ps1
pwsh .\tests\stage-layout.ps1
pwsh .\tests\install-transaction.ps1
pwsh .\tests\lifecycle.ps1
pwsh .\tests\e2e.ps1
```

Исходные репозитории, глобальные настройки, аккаунт и модель не меняются. Подробности внешних источников и лицензий — в `THIRD_PARTY.md`.
