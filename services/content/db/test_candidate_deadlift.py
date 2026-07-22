#!/usr/bin/env python3
"""Проверка черновой записи kettlebell-deadlift на реальном PostgreSQL."""

import json
import os
import shutil
import tempfile

import test_export as support


HERE = os.path.dirname(os.path.abspath(__file__))
CANDIDATE = os.path.join(HERE, 'candidates', 'kettlebell_deadlift.sql')


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
        support._fail_env(
            "Не удалось запустить PostgreSQL для проверки кандидата.\n"
            f"Детали: {type(exc).__name__}: {exc}"
        )

    try:
        support._load(db, 'schema.sql')
        support._load(db, 'seed_reference_data.sql')
        support._psql(
            db,
            "\\set ON_ERROR_STOP on\n"
            + open(CANDIDATE, encoding='utf-8').read(),
        )

        record = json.loads(
            _copy_scalar(db, "fn_export_exercise_record('kettlebell-deadlift')")
        )
        can_publish = _copy_scalar(
            db, "fn_can_publish('kettlebell-deadlift')"
        )

        assert record['schemaVersion'] == 2
        assert record['name'] == 'Становая тяга с гирей'
        assert len(record['phases']) == 2
        assert [phase['id'] for phase in record['phases']] == [
            'deadlift-bottom', 'deadlift-stand'
        ]
        assert len(record['cues']) == 3
        assert all(
            set(phase['visual']['assets']) == {'male', 'female'}
            for phase in record['phases']
        )
        male_assets = {
            phase['id']: phase['visual']['assets']['male']
            for phase in record['phases']
        }
        assert male_assets == {
            'deadlift-bottom': 'assets/movements/kettlebell-deadlift-bottom-male-anchored-v2.png',
            'deadlift-stand': 'assets/movements/kettlebell-deadlift-stand-male-anchored-v2.png',
        }
        female_assets = {
            phase['id']: phase['visual']['assets']['female']
            for phase in record['phases']
        }
        assert female_assets == {
            'deadlift-bottom': 'assets/movements/kettlebell-deadlift-bottom-female-anchored-v2.png',
            'deadlift-stand': 'assets/movements/kettlebell-deadlift-stand-female-anchored-v2.png',
        }
        assert record['review']['phases'] == 'reviewed'
        assert record['review']['visuals'] == 'approved'
        assert all(
            phase['visual']['status'] == 'approved'
            for phase in record['phases']
        )
        assert record['review']['anatomy'] == 'reviewed'
        assert record['anatomy']['asset'] == (
            'assets/movements/kettlebell-deadlift-zones-v1.png'
        )
        assert record['classification'] == {
            'movementKind': 'grind',
            'laterality': 'bilateral',
            'experience': 'basic',
        }
        assert can_publish == 'true', (
            'Утверждённая карточка должна проходить публикационный checklist'
        )

        print(
            'OK: kettlebell-deadlift экспортируется как ExerciseRecord v2 '
            '| 2 фазы | checklist публикации пройден'
        )
    except support._SqlError as exc:
        support._fail_test(
            'SQL-ошибка при проверке kettlebell-deadlift:\n' + exc.stderr
        )
    finally:
        db.cleanup()
        shutil.rmtree(pgdata, ignore_errors=True)


if __name__ == '__main__':
    main()
