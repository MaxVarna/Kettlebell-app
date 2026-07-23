#!/usr/bin/env python3
"""Проверка опубликованной записи двуручного свинга на реальном PostgreSQL."""

import json
import os
import shutil
import tempfile

import test_export as support


HERE = os.path.dirname(os.path.abspath(__file__))
CANDIDATE = os.path.join(HERE, 'candidates', 'two_hand_swing.sql')


def _copy_scalar(db, expression: str) -> str:
    output = support._psql(
        db,
        "\\set ON_ERROR_STOP on\n"
        f"COPY (SELECT ({expression})::text) TO STDOUT;\n",
    )
    return [line.strip() for line in output.splitlines() if line.strip()][-1]


def main() -> None:
    base = support._pick_ascii_base()
    pgdata = tempfile.mkdtemp(prefix='pgdata_', dir=base)
    support._initdb_ascii_locale_c(pgdata)
    try:
        db = support.pgserver.get_server(pgdata)
    except Exception as exc:
        shutil.rmtree(pgdata, ignore_errors=True)
        support._fail_env(f'Не удалось запустить PostgreSQL: {type(exc).__name__}: {exc}')

    try:
        support._load(db, 'schema.sql')
        support._load(db, 'seed_reference_data.sql')
        support._psql(db, "\\set ON_ERROR_STOP on\n" + open(CANDIDATE, encoding='utf-8').read())
        record = json.loads(_copy_scalar(db, "fn_export_exercise_record('two-hand-swing')"))
        assert _copy_scalar(db, "fn_can_publish('two-hand-swing')") == 'true'
        assert record['schemaVersion'] == 2
        assert [phase['id'] for phase in record['phases']] == ['swing-hike', 'swing-float']
        assert all(set(phase['visual']['assets']) == {'male', 'female'} for phase in record['phases'])
        assert record['assets']['thumbnailPhaseId'] == 'swing-float'
        assert record['anatomy']['primary'] == ['glutes']
        assert set(record['anatomy']['secondary']) == {'abdominals', 'deltoids'}
        assert all(cue['sourceIds'] for cue in record['cues'])
        print('OK: two-hand-swing | 2 динамические фазы | male+female | checklist пройден')
    except support._SqlError as exc:
        support._fail_test('SQL-ошибка при проверке two-hand-swing:\n' + exc.stderr)
    finally:
        db.cleanup()
        shutil.rmtree(pgdata, ignore_errors=True)


if __name__ == '__main__':
    main()
