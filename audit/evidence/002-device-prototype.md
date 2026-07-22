# Device prototype evidence — Audit 002

**Статус:** pending  
**Дата начала:** не заполнено  
**Владелец теста:** не заполнено

## Устройства

| Платформа | Модель | ОС | Expo Go | Locale | Результат |
|---|---|---|---|---|---|
| Android | — | — | — | ru/en | pending |
| iPhone | — | — | — | ru/en | pending |

## Сценарии

| ID | Android | iPhone | Evidence / заметка |
|---|---|---|---|
| Base flow + history | pending | pending | — |
| DP-01 | pending | pending | — |
| DP-02 | pending | pending | — |
| DP-03 | pending | pending | — |
| DP-04 | pending | pending | — |
| DP-05 | pending | pending | — |
| DP-06 | pending | pending | — |
| System Reduce Motion | pending | pending | — |
| TalkBack/VoiceOver | pending | pending | — |
| Timezone/clock reconciliation | pending | pending | — |
| SQLite migration v1→v2 | not run | not run | Требует отдельного fixture/device пути. |
| Local notifications | not implemented | not implemented | Следующий implementation slice. |
| iOS native build/Xcode | n/a | not run | Требует Mac/Xcode. |

## Итог

Не заполнять «passed» без наблюдаемого результата на реальном устройстве. P0/P1 findings и не пройденные обязательные проверки перенести в новый audit request или `docs/DECISIONS.md` с владельцем.

