# Skills Integration

Безопасный интеграционный слой для девяти локально проверенных репозиториев skills. Он не запускает их собственные установщики: вместо этого закрепляет версии, собирает только 42 вложенных навыка в автономный staging-каталог и устанавливает их с проверкой конфликтов и хешей.

## Быстрый запуск

```powershell
git clone https://github.com/shahmen2088/codex-skills-integration.git
cd codex-skills-integration
pwsh .\scripts\acquire-sources.ps1 -Destination .\sources
pwsh .\scripts\stage-skills.ps1 -SourcesRoot .\sources -StageRoot .\stage
pwsh .\scripts\verify-stage.ps1 -StageRoot .\stage
pwsh .\scripts\install.ps1 -StageRoot .\stage -Target custom -Destination C:\temp\codex-skills-test
```

`-Target codex` и `-Target opencode` выбирают стандартные пользовательские каталоги. Сначала используйте `-WhatIf`. Обновление и удаление применимы только к установкам, созданным этим репозиторием; пользовательские или изменённые файлы не перезаписываются и не удаляются.

## Готовый промпт для установки в Codex

Скопируйте этот текст в новый чат Codex после клонирования репозитория:

```text
Установи набор из репозитория https://github.com/shahmen2088/codex-skills-integration в мой глобальный Codex безопасно.

1. Прочитай README.md и не изменяй девять исходных репозиториев.
2. Запусти `scripts/acquire-sources.ps1 -Destination .\sources`; он должен получить ровно девять публичных репозиториев на закреплённых коммитах. Не продолжай, если хотя бы один commit не совпал.
3. Запусти staging из `./sources` и проверь его: 42 навыка, уникальные имена, автономные ссылки внутри каждого навыка.
4. Выполни предварительный просмотр установки с -WhatIf для Target codex.
5. Покажи только список конфликтов, если они есть. Ничего не перезаписывай и не удаляй без моего отдельного подтверждения.
6. Если конфликтов нет, установи навыки через scripts/install.ps1; после этого повторно проверь managed manifest и количество установленных навыков.
7. Не меняй модель, тариф, аккаунт, AGENTS.md, конфигурацию Codex или OpenCode. Не публикуй и не отправляй данные во внешние сервисы, кроме девяти публичных источников из source-lock.json.
8. В конце сообщи: хеш закреплённого набора, число установленных навыков, путь установки и команды update/uninstall.
```

Для OpenCode замените в пунктах 3–5 `codex` на `opencode`. Если OpenCode отсутствует в системе, сначала остановитесь и сообщите об этом — не устанавливайте его автоматически.

## Проверка

```powershell
pwsh .\tests\validate-config.ps1
pwsh .\tests\acquire-sources.ps1
pwsh .\tests\stage-layout.ps1
pwsh .\tests\install-transaction.ps1
pwsh .\tests\lifecycle.ps1
pwsh .\tests\e2e.ps1
```

Исходные репозитории, глобальные настройки, аккаунт и модель не меняются. Подробности внешних источников и лицензий — в `THIRD_PARTY.md`.
