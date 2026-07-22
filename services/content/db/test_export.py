#!/usr/bin/env python3
"""
Тест экспорта каталога упражнений.

Проверяет, что fn_export_exercise_record выдаёт детерминированный JSON
независимо от TimeZone сессии PostgreSQL:
  * reviewedAt — строго UTC ISO 8601 с суффиксом 'Z';
  * sources[].accessedAt — 'YYYY-MM-DD';
  * при двух РАЗНЫХ применённых зонах экспорт идентичен.

Почему числовые зоны, а не имена
--------------------------------
Встроенный в pgserver PostgreSQL не содержит базы именованных зон, поэтому
`SET TIME ZONE 'Europe/Sofia'` там падает. Основной тест использует
переносимые числовые смещения `SET TIME ZONE 0` и `SET TIME ZONE 3` — они
не зависят от tz-базы. Именованная `Europe/Sofia` вынесена в необязательную
интеграционную проверку (_optional_named_zone_check): она выполняется только
если установка PostgreSQL знает эту зону, иначе помечается как SKIP.

Защита от ложноположительного результата
----------------------------------------
`pgserver.psql()` не включает ON_ERROR_STOP и теряет stderr: ошибочный
`SET TIME ZONE` игнорируется, `COPY` всё равно выполняется, и тест раньше
проходил ложно. Здесь используется собственный запуск psql с
`\\set ON_ERROR_STOP on` и захватом stderr: любая SQL-ошибка роняет прогон
с понятной диагностикой (без traceback), а фактически применённая зона
проверяется через current_setting('TimeZone').

Устойчивость к кириллическому профилю Windows
---------------------------------------------
Каталог данных создаётся только в ASCII-пути без пробелов; кластер
пред-инициализируется с явными `--locale=C --encoding=UTF8`, после чего
готовый pgdata передаётся в get_server (initdb пропускается). Это обходит
падение initdb на локали Russian_Russia.1251 и на кириллическом %TEMP%.

Установка и запуск — см. README.md. Кратко (в venv, без --break-system-packages):
    Windows:        python -m venv .venv && .venv\\Scripts\\activate
    macOS / Linux:  python3 -m venv .venv && source .venv/bin/activate
    pip install -r requirements-test.txt
    python test_export.py

Переменная PG_TEST_TMPDIR (необязательно) — свой ASCII-путь для каталога данных.

Коды выхода:
    0 — тест пройден;
    1 — тест упал (несовпадение JSON/формата даты, либо SQL-ошибка в прогоне);
    2 — не установлена зависимость pgserver (инструкция, не traceback);
    3 — окружение не готово: нет ASCII-каталога, либо initdb/запуск PostgreSQL
        упали (диагностика, не traceback).
"""
import os
import sys
import json
import shutil
import tempfile
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
EXERCISE_ID = 'two-hand-swing'


def _fail_env(msg: str) -> None:
    """Диагностика окружения, выход с кодом 3 (без traceback)."""
    sys.stderr.write("\n[ОКРУЖЕНИЕ] " + msg.rstrip() + "\n")
    sys.exit(3)


def _fail_test(msg: str) -> None:
    """Провал теста, выход с кодом 1 (без traceback)."""
    sys.stderr.write("\n[ТЕСТ ПРОВАЛЕН] " + msg.rstrip() + "\n")
    sys.exit(1)


# --- Мягкая проверка зависимости: инструкция вместо traceback --------------
try:
    import pgserver
    from pgserver import initdb as _pg_initdb  # noqa: F401  (проверка наличия)
    from pgserver._commands import POSTGRES_BIN_PATH
except ModuleNotFoundError:
    sys.stderr.write(
        "\n[ПРОПУЩЕНО] Не установлена зависимость 'pgserver'.\n\n"
        "Установите её в виртуальном окружении (НЕ через --break-system-packages):\n\n"
        "  Windows:\n"
        "    python -m venv .venv\n"
        "    .venv\\Scripts\\activate\n"
        "    pip install -r requirements-test.txt\n\n"
        "  macOS / Linux:\n"
        "    python3 -m venv .venv\n"
        "    source .venv/bin/activate\n"
        "    pip install -r requirements-test.txt\n\n"
        "Затем повторите:  python test_export.py\n"
    )
    sys.exit(2)


class _SqlError(Exception):
    def __init__(self, returncode, stderr):
        self.returncode = returncode
        self.stderr = (stderr or '').strip()
        super().__init__(self.stderr)


def _psql(db, script: str) -> str:
    """
    Запуск psql со скриптом на stdin, ON_ERROR_STOP включается вызывающим.

    SQL передаётся БАЙТАМИ в UTF-8 (не text=True): на Windows с локалью CP1251
    text-режим кодирует stdin в cp1251 и падает на символах вне неё
    (например '\\u2194' в комментариях schema.sql). PGCLIENTENCODING=UTF8
    заставляет сервер трактовать вход как UTF-8. stdout декодируется как UTF-8,
    stderr — с errors='replace' для безопасной диагностики.

    В отличие от pgserver.psql(): захватывает stderr и бросает _SqlError при
    ненулевом коде — чтобы SQL-ошибка не оставалась незамеченной.
    """
    exe = POSTGRES_BIN_PATH / ('psql.exe' if os.name == 'nt' else 'psql')
    env = {**os.environ, 'PGCLIENTENCODING': 'UTF8'}
    try:
        payload = script.encode('utf-8')
    except UnicodeEncodeError as e:
        _fail_test("Не удалось закодировать SQL-скрипт в UTF-8: %s" % e)
    proc = subprocess.run(
        f'"{exe}" {db.get_uri()}',
        input=payload, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        shell=True, env=env,
    )
    if proc.returncode != 0:
        err = proc.stderr.decode('utf-8', errors='replace').strip()
        raise _SqlError(proc.returncode, err)
    try:
        return proc.stdout.decode('utf-8')
    except UnicodeDecodeError as e:
        _fail_test("Вывод psql не декодируется как UTF-8: %s" % e)


def _pick_ascii_base() -> str:
    """Существующий, записываемый ASCII-каталог без пробелов для pgdata."""
    candidates = []
    env_dir = os.environ.get('PG_TEST_TMPDIR')
    if env_dir:
        candidates.append(env_dir)
    if os.name == 'nt':
        drive = os.environ.get('SystemDrive', 'C:')
        candidates.append(os.path.join(drive + os.sep, 'pg_test_tmp'))
        candidates.append(os.path.join(drive + os.sep, 'Temp'))
    candidates.append(tempfile.gettempdir())

    tried = []
    for base in candidates:
        tried.append(base)
        try:
            os.makedirs(base, exist_ok=True)
        except OSError:
            continue
        if base.isascii() and ' ' not in base and os.access(base, os.W_OK):
            return base

    _fail_env(
        "Не найден ASCII-каталог без пробелов для данных PostgreSQL.\n"
        "Проверенные варианты: " + ", ".join(repr(t) for t in tried) + "\n"
        "Задайте путь явно:\n"
        "    Windows:   set PG_TEST_TMPDIR=C:\\pg_test_tmp\n"
        "    Linux/mac: export PG_TEST_TMPDIR=/tmp/pg_test_tmp"
    )


def _initdb_ascii_locale_c(pgdata: str) -> None:
    """Пред-инициализация с явными --locale=C --encoding=UTF8 (не зависит от системной локали)."""
    exe = POSTGRES_BIN_PATH / ('initdb.exe' if os.name == 'nt' else 'initdb')
    env = {**os.environ, 'LC_ALL': 'C', 'LANG': 'C'}
    # Захват в байтах + безопасное декодирование: не полагаемся на локаль консоли.
    proc = subprocess.run(
        [str(exe), '-D', pgdata,
         '--auth=trust', '--auth-local=trust',
         '--encoding=UTF8', '--locale=C', '-U', 'postgres'],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env,
    )
    if proc.returncode != 0:
        err = proc.stderr.decode('utf-8', errors='replace').strip()
        hint = ""
        if 'invalid byte sequence' in err or '1251' in err:
            hint = ("\nКонфликт системной локали с UTF-8. Тест задаёт --locale=C; "
                    "если ошибка осталась — проверьте, что путь ASCII-only (текущий: %r)." % pgdata)
        _fail_env("initdb не смог создать кластер PostgreSQL (код %d).\nstderr:\n%s%s"
                  % (proc.returncode, err or '(пусто)', hint))


def _run_export(db, tz_value) -> tuple:
    """
    Возвращает (applied_timezone, record_dict) для заданного смещения зоны.
    Один psql-вызов = одна сессия: SET, чтение зоны и экспорт в одном сеансе.
    ON_ERROR_STOP гарантирует падение на любой SQL-ошибке.
    """
    script = (
        "\\set ON_ERROR_STOP on\n"
        f"SET TIME ZONE {tz_value};\n"
        "COPY (SELECT current_setting('TimeZone')) TO STDOUT;\n"
        f"COPY (SELECT fn_export_exercise_record('{EXERCISE_ID}')::text) TO STDOUT;\n"
    )
    out = _psql(db, script)
    lines = [l for l in out.splitlines() if l.strip()]
    # JSON — единственная строка, начинающаяся с '{'
    json_line = next((l for l in lines if l.lstrip().startswith('{')), None)
    # Зона — строка current_setting: не JSON и не тег команды psql.
    # Формат зависит от вида зоны: числовая -> '<+03>-03', именованная -> 'Europe/Sofia'.
    _TAGS = {'SET', 'BEGIN', 'COMMIT', 'ROLLBACK'}
    tz_candidates = [
        l for l in lines
        if not l.lstrip().startswith('{')
        and l.strip() not in _TAGS
        and not l.strip().startswith('COPY')
    ]
    tz_line = tz_candidates[-1] if tz_candidates else None
    if json_line is None or tz_line is None:
        _fail_test("Не удалось разобрать вывод psql для зоны %r:\n%s" % (tz_value, out))
    return tz_line.strip(), json.loads(json_line)


def _load(db, filename):
    # ON_ERROR_STOP, чтобы ошибка в schema.sql/seed не осталась незамеченной
    script = "\\set ON_ERROR_STOP on\n" + open(os.path.join(HERE, filename), encoding='utf-8').read()
    _psql(db, script)


def _optional_named_zone_check(db, expected_record) -> str:
    """
    Необязательная интеграционная проверка именованной зоны 'Europe/Sofia'.
    Если tz-база недоступна (встроенный PostgreSQL) — SKIP, не провал.
    """
    try:
        tz, rec = _run_export(db, "'Europe/Sofia'")
    except _SqlError:
        return "SKIP (нет базы именованных зон в этой сборке PostgreSQL)"
    if rec != expected_record:
        _fail_test("Europe/Sofia: ExerciseRecord отличается от базового экспорта")
    return "OK (применена %s, ExerciseRecord идентичен)" % tz


def main():
    base = _pick_ascii_base()
    pgdata = tempfile.mkdtemp(prefix='pgdata_', dir=base)
    _initdb_ascii_locale_c(pgdata)

    try:
        db = pgserver.get_server(pgdata)  # PG_VERSION уже есть → initdb пропускается
    except Exception as exc:
        shutil.rmtree(pgdata, ignore_errors=True)
        _fail_env("Не удалось запустить PostgreSQL на подготовленном каталоге.\n"
                  "Детали: %s: %s" % (type(exc).__name__, exc))

    try:
        try:
            _load(db, 'schema.sql')
            _load(db, 'seed_example.sql')

            # Две РАЗНЫЕ переносимые числовые зоны
            tz0, rec0 = _run_export(db, 0)   # UTC+0
            tz3, rec3 = _run_export(db, 3)   # UTC+3
        except _SqlError as e:
            _fail_test("SQL-ошибка при подготовке/экспорте (ON_ERROR_STOP):\n%s" % e.stderr)

        # 1. фактически применённые зоны различаются
        if tz0 == tz3:
            _fail_test("Применённые зоны совпали (%r == %r) — тест не проверяет инвариант."
                       % (tz0, tz3))

        # 2. экспортированные записи идентичны при разных зонах
        if rec0 != rec3:
            _fail_test("ExerciseRecord различается при зонах %r и %r" % (tz0, tz3))

        # 3. формат дат и содержимое
        ra = rec0['review']['reviewedAt']
        if not ra.endswith('Z'):
            _fail_test("reviewedAt должен оканчиваться на Z: %r" % ra)
        if ra != '2026-07-22T10:00:00Z':
            _fail_test("неверное UTC-значение reviewedAt: %r" % ra)
        if rec0['schemaVersion'] != 2:
            _fail_test("schemaVersion должен быть 2")
        if rec0['sources'][0]['accessedAt'] != '2026-07-22':
            _fail_test("accessedAt должен быть YYYY-MM-DD")
        if rec0['name'] != 'Двуручный мах':
            _fail_test("кириллический контент должен читаться как UTF-8")

        named = _optional_named_zone_check(db, rec0)

        print("OK: зоны различаются (%s vs %s) | ExerciseRecord идентичен | "
              "reviewedAt=%s" % (tz0, tz3, ra))
        print("    Именованная зона Europe/Sofia: %s" % named)
    finally:
        db.cleanup()
        shutil.rmtree(pgdata, ignore_errors=True)


if __name__ == '__main__':
    main()
