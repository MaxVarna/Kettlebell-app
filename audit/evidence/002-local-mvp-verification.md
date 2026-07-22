# Verification evidence — Audit 002 local MVP

**Дата:** 2026-07-20  
**Рабочая папка:** `D:\Kettlebell app`  
**Назначение:** воспроизводимое краткое свидетельство локальных проверок для Audit 002. Это не заменяет реальные device tests.

## Команды и результаты

| Команда | Рабочая папка | Результат |
|---|---|---|
| `npm run domain:test` | корень | 11/11 passed |
| `npm run mobile:test` | корень | 7/7 passed |
| `npm run typecheck` | корень | passed для domain и mobile |
| `npx expo config --type public --json` | `apps/mobile` | valid Expo SDK 54 configuration для Android/iOS |
| `npx expo export --platform android --output-dir .verification-expo` | `apps/mobile` | passed; 593 modules; Hermes bundle 1.86 MB |
| `npx expo export --platform ios --output-dir .verification-expo-ios` | `apps/mobile` | passed; 595 modules; Hermes bundle 1.85 MB |
| `npx expo install --check` | `apps/mobile` | dependencies up to date |

## Генерируемые bundle artifacts

Экспортные директории намеренно игнорируются Git: это локальные verification outputs, не исходный код и не store artifacts.

- Android: `apps/mobile/.verification-expo/metadata.json` — 150 bytes; bundle `index-9aeb5bd757a490591dc362b7a076fbae.hbc`.
- iOS: `apps/mobile/.verification-expo-ios/metadata.json` — 142 bytes; bundle `index-936f7aff99a492d8ee5b867c59b9dc3a.hbc`.

## Непроверенное

- запуск на реальном Android/iPhone и Expo Go;
- iOS native build/Xcode;
- SQLite migration и recovery при force-close на устройстве;
- background/notification delivery matrix;
- реальные редакционно проверенные animation assets.

