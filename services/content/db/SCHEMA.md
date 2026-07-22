# Реляционная схема каталога упражнений

Хранит продуктовый контракт `ExerciseRecord` (`schemaVersion: 2`) из `docs/EXERCISE_DATA_MODEL.md` без потери данных и собирает из реляционных таблиц готовую клиентскую запись. Контракт — источник истины; схема приведена под него.

Диалект — PostgreSQL. Проверено на реальном движке: DDL, seed, экспорт записи и все 8 условий публикации проходят; негативные проверки корректно роняют публикацию.

## Что в ядре и чего в нём нет

Ядро хранит только то, что есть в продуктовой модели упражнения. В нём **нет** веса, повторений, подходов, раундов, дистанции, темпа, индивидуальных таймингов и таблицы единиц измерения — эти параметры к упражнению не относятся. Отсутствие таких полей в ядре само по себе выполняет 8-е условие публикации.

Универсальная классификация (`movement_patterns`), дисциплины, теги, каталог мышц и связи между упражнениями (`exercise_relations`) сохранены как **редакторский слой** (секция 10 в `schema.sql`). Он не участвует в экспорте `ExerciseRecord` и нужен редакторам для навигации и построения обучающих цепочек.

## Соответствие контракту

| Поле `ExerciseRecord` | Где хранится |
|---|---|
| `id`, `name`, `schemaVersion` | `exercises` |
| `aliases[]` | `exercise_aliases` |
| `classification.{movementKind,laterality,experience}` | `exercises` (ENUM-поля) |
| `phases[]` + `order` | `exercise_phases` (`UNIQUE(exercise_id, phase_order)`) |
| `phases[].poseBrief.*` | `exercise_phases` (`body_orientation`, `support`, `kettlebell_position`, `body_position`) |
| `phases[].visual.{feetBaseline,scale,status}` | `exercise_phases` |
| `phases[].visual.assets.{male,female}` | `phase_assets` (по одной строке на фигуру) |
| `cues[]` + `sourceIds` | `exercise_cues` + `source_supports` |
| `anatomy.{primary,secondary}` | `exercise_anatomy_zones` (роль primary/secondary) |
| `anatomy.{asset,status}` | `exercises` |
| `assets.thumbnailPhaseId` | `exercises.thumbnail_phase_id` (scoped-FK на фазу того же упражнения) |
| `assets.{styleId,anatomyStyleId}` | `exercises` → `figure_styles` (только `is_approved`) |
| `sources[]` | `exercise_sources` |
| `sources[].supports[]` | `source_supports.claim_path` |
| `review.{technique,phases,visuals,anatomy,...}` | `exercises` (раздельные статусы) |

## Ключевые решения

**Фазы — центр модели.** Строгий порядок гарантирован `UNIQUE(exercise_id, phase_order)` и проверкой непрерывности при публикации (1..N без пропусков). Ограничение «ровно 2 или 3 фазы» — не жёсткий constraint таблицы (черновик может иметь больше), а правило публикации: более длинные последовательности остаются черновиком и не попадают в каталог.

**Male/female раздельно, техника общая.** `phase_assets` держит независимые ассеты по фигурам, а техника, `feetBaseline`, `scale` и ракурс — общие поля фазы. Если для профиля нет нужного варианта, упражнение не считается визуально готовым (правило 4).

**Утверждённые стили.** `style_id` и `anatomy_style_id` ссылаются на `figure_styles`; публикация требует `is_approved = true`, поэтому запись не может ссылаться на неутверждённый стиль.

**Проверяемость источников.** `source_supports` привязывает источник к конкретному утверждению тремя видами цели: фаза, cue или анатомическая зона. Поле `claim_path` хранит точную строку контракта (`phase.hike.bodyPosition`, `cue.hip-drive`, `anatomy.glutes`). Из этой же таблицы вычисляется `cues[].sourceIds`, что позволяет проверить «каждый опубликованный cue связан хотя бы с одним источником».

**Раздельные статусы проверки.** `review_technique`, `review_phases`, `review_visuals`, `review_anatomy` — независимые перечисления, каждое со своей шкалой из контракта.

**Версии публикаций.** `exercise_published_versions` хранит иммутабельный JSONB-снимок `ExerciseRecord` на момент публикации. Активная тренировка использует снимок на момент старта, поэтому поздняя правка каталога не меняет прошлые результаты. `exercises.current_version` указывает на актуальную версию.

## Формат дат при экспорте

Все даты в `ExerciseRecord` детерминированы и не зависят от `TimeZone` сессии PostgreSQL:

- `review.reviewedAt` (`timestamptz` в БД) экспортируется как UTC ISO 8601 с суффиксом `Z`, например `2026-07-22T10:00:00Z`. Внутри `fn_export_exercise_record` значение приводится через `... AT TIME ZONE 'UTC'` и форматируется `to_char(...)` — настройка `TimeZone` сессии на результат не влияет.
- `sources[].accessedAt` (`date` в БД) экспортируется как `YYYY-MM-DD` через явный `to_char` — без времени и зоны.

Гарантия закреплена тестом `test_export.py`: экспорт при `TimeZone = UTC` и `TimeZone = Europe/Sofia` даёт идентичный JSON, а `reviewedAt` оканчивается на `Z`.

## Экспорт и публикация (функции в `schema.sql`)

- `fn_export_exercise_record(id) → jsonb` — собирает клиентскую запись `ExerciseRecord` (`schemaVersion: 2`) точно по форме контракта.
- `fn_publication_checklist(id)` — возвращает 8 правил публикации с результатом и деталями по каждому.
- `fn_can_publish(id) → boolean` — сводный итог (все правила пройдены).
- `fn_publish_exercise(id, by)` — проверяет условия, пишет снимок в `exercise_published_versions`, обновляет `current_version`, возвращает номер версии. При невыполнении условий бросает исключение.

## 8 условий публикации

1. фаз ровно 2 или 3, порядок уникален и непрерывен;
2. техника не ниже `source_checked`;
3. фазы не ниже `reviewed`;
4. у каждой фазы есть male и female ассеты, визуальный статус не ниже `reviewed`;
5. карта зон проверена (`anatomy` не ниже `reviewed`) и содержит хотя бы одну primary-зону;
6. каждый cue связан хотя бы с одним источником;
7. заданы миниатюра и утверждённые стили фигуры и анатомии;
8. в ядре нет веса/повторов/подходов/таймингов (обеспечено структурой).

## Файлы

- `schema.sql` — DDL, ENUM-типы, экспорт и функции публикации.
- `seed_example.sql` — упражнение «двуручный мах» (2 фазы) как эталон полного `ExerciseRecord`.

## Источники (методология классификации)

- [The Seven Basic Human Movements — StrongFirst](https://www.strongfirst.com/seven-basic-human-movements/)
- [Swing Versus Snatch — StrongFirst](https://www.strongfirst.com/swing-versus-snatch/)
- [Kettlebell lifting — Wikipedia (Girevoy Sport)](https://en.wikipedia.org/wiki/Kettlebell_lifting)
