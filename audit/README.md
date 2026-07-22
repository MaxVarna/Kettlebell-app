# Внешний аудит

Эта папка отделяет задания для независимого review от рабочих файлов проекта.

- Запросы аудита: `audit/requests/[0-9][0-9][0-9]-<topic>.md`.
- Заключения аудитора: `audit/reports/[0-9][0-9][0-9]-<topic>-report.md`.
- Шаблоны и правила: `audit/requests/TEMPLATE.md`, `audit/reports/TEMPLATE.md`, [AUDIT_POLICY.md](AUDIT_POLICY.md). Краткие воспроизводимые журналы проверок: `audit/evidence/`.
- Тайминги и gates: [AUDIT_CADENCE.md](AUDIT_CADENCE.md).

Только файлы с трёхзначным числом в имени считаются фактическими запросами или отчётами. `TEMPLATE.md` и `README.md` не являются заданиями.

Текущий открытый запрос: [002-local-mvp.md](requests/002-local-mvp.md). Предыдущий архитектурный audit: [001-mvp-architecture.md](requests/001-mvp-architecture.md).
