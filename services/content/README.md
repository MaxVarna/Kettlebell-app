# Контент каталога и программ

Здесь находится источник данных каталога упражнений и воспроизводимая сборка клиентского контента.

Граница модуля: контент должен быть версионирован. Активная и завершённая тренировка использует снимок на момент старта, поэтому позднее обновление каталога не меняет прошлые результаты. Публикация контента в будущем допускается только доверенным серверным процессом; клиент читает опубликованный контент.

## Текущий поток

1. Упражнение описывается SQL-кандидатом в `db/candidates/` и добавляется в `db/candidates/index.json`. Черновик получает `"publish": false`: он загружается и проверяется PostgreSQL, но не экспортируется в приложение до визуального и редакторского gate.
2. PostgreSQL-функция проверяет восемь условий публикации и экспортирует `ExerciseRecord v2`.
3. `scripts/generate_mobile_catalogue.py` проверяет существование всех ассетов и создаёт:
   - `exports/exercises.v2.json` — переносимый снимок опубликованных записей;
   - `apps/mobile/src/content/generated/exerciseCatalogue.generated.ts` — данные и статические `require()` для Metro.
4. Мобильное приложение читает общий реестр; добавление следующего утверждённого упражнения не требует условий по его `id` в `App.tsx`.
5. `scripts/validate_motion_assets.py` проверяет техническую структуру всех фазовых PNG: отдельные male/female-файлы, холст, прозрачные углы, общую линию стоп и существование анатомических схем.
6. `scripts/validate_figure_consistency.py` по landmark-manifest отдельно проверяет реальный калибр и пропорции персонажа. Для нового или изменённого набора фаз нужен сохранённый отчёт `pass`; структурная проверка этот gate не заменяет.
7. Новые изображения создаются единым storyboard на одного персонажа. `scripts/build_storyboard_motion_set.py` применяет ко всем колонкам один масштаб и общую заданную линию стоп; независимая нормализация кадров запрещена.
8. `scripts/validate_storyboard_batch.py` проверяет все выходные PNG и фиксирует SHA-256, холст, прозрачность и отклонение линии стоп. Ручной просмотр выполняется по листу из `build_new_exercises_review_sheet.py`.

После установки тестовых зависимостей из `db/requirements-test.txt` запускать из корня репозитория:

```text
python services/content/scripts/generate_mobile_catalogue.py
python services/content/scripts/generate_mobile_catalogue.py --check
python services/content/scripts/validate_motion_assets.py
python services/content/scripts/validate_figure_consistency.py --manifest docs/visual-probes/<name>-landmarks.json --report docs/visual-probes/<name>-report.json
```

Для обработки и проверки PNG установить `requirements-tools.txt` в виртуальное окружение. Первый режим обновляет артефакты, второй завершается ошибкой, если они расходятся с БД или отсутствует указанный ассет. Сервер и API пока не поднимаются: генерация выполняется на этапе подготовки сборки.
