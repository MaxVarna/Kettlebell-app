-- =====================================================================
--  КАТАЛОГ ГИРЕВЫХ УПРАЖНЕНИЙ — РЕЛЯЦИОННАЯ СХЕМА (PostgreSQL)
--  Источник истины: docs/EXERCISE_DATA_MODEL.md (ExerciseRecord, schemaVersion 2)
--  Назначение: хранить продуктовый контракт без потери данных и
--              собирать из него клиентскую запись ExerciseRecord.
-- =====================================================================
--  Принципы:
--   * ЯДРО хранит только то, что есть в продуктовой модели.
--     Веса, повторов, подходов, раундов, дистанции, темпа и единиц
--     измерения в ядре НЕТ — они не относятся к упражнению.
--   * Универсальная классификация, каталог мышц, дисциплины, теги и
--     связи между упражнениями вынесены в РЕДАКТОРСКИЙ СЛОЙ (секция 9),
--     он не участвует в экспорте ExerciseRecord.
--   * Экспорт в ExerciseRecord и проверка публикации — секции 7–8.
-- =====================================================================

-- =====================================================================
--  1. ПЕРЕЧИСЛЕНИЯ (строго по контракту)
-- =====================================================================
CREATE TYPE figure_variant      AS ENUM ('male','female');
CREATE TYPE body_orientation    AS ENUM ('front','three_quarter','side');
CREATE TYPE phase_support       AS ENUM ('bilateral','left','right','transition');
CREATE TYPE visual_status       AS ENUM ('missing','generated','reviewed','approved');
CREATE TYPE movement_kind       AS ENUM ('ballistic','grind','complex');
CREATE TYPE laterality          AS ENUM ('bilateral','unilateral','alternating');
CREATE TYPE experience_level    AS ENUM ('basic','intermediate','advanced');
CREATE TYPE anatomy_status      AS ENUM ('missing','draft','reviewed','approved');
CREATE TYPE anatomy_role        AS ENUM ('primary','secondary');
CREATE TYPE source_type         AS ENUM ('professional_standard','textbook','research','supplementary');
CREATE TYPE technique_status    AS ENUM ('draft','source_checked','coach_approved','rejected');
CREATE TYPE phases_status       AS ENUM ('draft','reviewed','approved');
CREATE TYPE support_target_kind AS ENUM ('phase','cue','anatomy');

-- =====================================================================
--  2. УТВЕРЖДЁННЫЕ СТИЛИ ФИГУРЫ И АНАТОМИИ
--     Гарантируют, что запись ссылается только на утверждённый стиль.
-- =====================================================================
CREATE TABLE figure_styles (
    id          VARCHAR(60) PRIMARY KEY,        -- 'approved-athlete-v1', 'approved-anatomy-v1'
    kind        VARCHAR(10) NOT NULL CHECK (kind IN ('athlete','anatomy')),
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    description TEXT
);

-- =====================================================================
--  3. КАТАЛОГ АНАТОМИЧЕСКИХ ЗОН
--     anatomy.primary / anatomy.secondary в контракте — коды зон.
-- =====================================================================
CREATE TABLE anatomy_zones (
    code    VARCHAR(40) PRIMARY KEY,            -- 'glutes', 'hamstrings', ...
    name_en VARCHAR(60) NOT NULL,
    name_ru VARCHAR(60) NOT NULL,
    region  VARCHAR(20)                          -- upper | lower | core | full
);

-- =====================================================================
--  4. ЦЕНТРАЛЬНАЯ СУЩНОСТЬ — УПРАЖНЕНИЕ (ExerciseRecord)
-- =====================================================================
CREATE TABLE exercises (
    id                    VARCHAR(64) PRIMARY KEY,      -- ExerciseId (string)
    schema_version        SMALLINT NOT NULL DEFAULT 2 CHECK (schema_version = 2),
    name                  VARCHAR(160) NOT NULL,

    -- classification.*
    movement_kind         movement_kind    NOT NULL,
    laterality            laterality       NOT NULL,
    experience            experience_level NOT NULL,

    -- assets.* (thumbnailPhaseId задаётся ниже отложенным FK)
    thumbnail_phase_id    VARCHAR(64),
    style_id              VARCHAR(60) NOT NULL REFERENCES figure_styles(id),
    anatomy_style_id      VARCHAR(60) NOT NULL REFERENCES figure_styles(id),

    -- anatomy.asset / anatomy.status (зоны — в отдельной таблице)
    anatomy_asset         TEXT,
    anatomy_status        anatomy_status NOT NULL DEFAULT 'missing',

    -- review.*
    review_technique      technique_status NOT NULL DEFAULT 'draft',
    review_phases         phases_status    NOT NULL DEFAULT 'draft',
    review_visuals        visual_status    NOT NULL DEFAULT 'missing',
    review_anatomy        anatomy_status   NOT NULL DEFAULT 'missing',
    reviewed_at           TIMESTAMPTZ,
    reviewer              VARCHAR(120),
    review_notes          TEXT,

    -- служебное: указатель на текущую опубликованную версию (секция 6)
    current_version       INT,

    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- aliases[] — отдельные строки
CREATE TABLE exercise_aliases (
    exercise_id VARCHAR(64) NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    alias       VARCHAR(160) NOT NULL,
    PRIMARY KEY (exercise_id, alias)
);

-- =====================================================================
--  5. ФАЗЫ, POSEBRIEF, ВИЗУАЛ, MALE/FEMALE ASSETS
-- =====================================================================
CREATE TABLE exercise_phases (
    id                 VARCHAR(64) NOT NULL,            -- PhaseId (string, уникален глобально)
    exercise_id        VARCHAR(64) NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    phase_order        SMALLINT NOT NULL,               -- строгий порядок (order)
    short_name         VARCHAR(80) NOT NULL,            -- редакторская метка
    technique          TEXT NOT NULL,                   -- что происходит в фазе

    -- poseBrief.*
    body_orientation   body_orientation NOT NULL,
    support            phase_support    NOT NULL,
    kettlebell_position TEXT NOT NULL,
    body_position      TEXT NOT NULL,

    -- visual.* (кроме assets — они по фигурам ниже)
    feet_baseline      NUMERIC(4,3) NOT NULL CHECK (feet_baseline >= 0 AND feet_baseline <= 1),
    scale              NUMERIC(5,3) NOT NULL CHECK (scale > 0),
    visual_status      visual_status NOT NULL DEFAULT 'missing',

    PRIMARY KEY (id),
    UNIQUE (exercise_id, id),                            -- для scoped-FK миниатюры
    UNIQUE (exercise_id, phase_order),                   -- уникальный порядок в упражнении
    CONSTRAINT chk_phase_order_positive CHECK (phase_order >= 1)
);
CREATE INDEX idx_phases_exercise ON exercise_phases(exercise_id, phase_order);

-- Отложенный scoped-FK: миниатюра обязана быть фазой ЭТОГО упражнения
ALTER TABLE exercises
  ADD CONSTRAINT fk_thumbnail_phase
  FOREIGN KEY (id, thumbnail_phase_id)
  REFERENCES exercise_phases (exercise_id, id)
  DEFERRABLE INITIALLY DEFERRED;

-- visual.assets: независимые male / female ассеты при единой технике
CREATE TABLE phase_assets (
    phase_id       VARCHAR(64) NOT NULL REFERENCES exercise_phases(id) ON DELETE CASCADE,
    figure_variant figure_variant NOT NULL,
    asset_url      TEXT NOT NULL,
    PRIMARY KEY (phase_id, figure_variant)
);

-- =====================================================================
--  6. CUES (ПОДСКАЗКИ)
-- =====================================================================
CREATE TABLE exercise_cues (
    id          VARCHAR(64) PRIMARY KEY,          -- cue id (string)
    exercise_id VARCHAR(64) NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    text        TEXT NOT NULL,
    sort_order  SMALLINT NOT NULL DEFAULT 0,
    UNIQUE (exercise_id, id)
);

-- =====================================================================
--  7. АНАТОМИЧЕСКИЕ ЗОНЫ УПРАЖНЕНИЯ (primary / secondary)
-- =====================================================================
CREATE TABLE exercise_anatomy_zones (
    exercise_id VARCHAR(64) NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    zone_code   VARCHAR(40) NOT NULL REFERENCES anatomy_zones(code),
    role        anatomy_role NOT NULL,
    PRIMARY KEY (exercise_id, zone_code)          -- зона не может быть и primary, и secondary
);

-- =====================================================================
--  8. СТРУКТУРИРОВАННЫЕ ИСТОЧНИКИ + ПРИВЯЗКА К УТВЕРЖДЕНИЯМ
-- =====================================================================
CREATE TABLE exercise_sources (
    id            VARCHAR(64) PRIMARY KEY,        -- source id (string)
    exercise_id   VARCHAR(64) NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    organization  VARCHAR(160) NOT NULL,
    title         VARCHAR(300) NOT NULL,
    url           TEXT NOT NULL,
    source_type   source_type NOT NULL,
    accessed_at   DATE NOT NULL,
    UNIQUE (exercise_id, id)
);

-- supports[]: источник ↔ конкретное утверждение (фаза / cue / анатомия).
-- claim_path хранит точную строку контракта, напр. 'phase.hike.bodyPosition'.
CREATE TABLE source_supports (
    id           BIGSERIAL PRIMARY KEY,
    source_id    VARCHAR(64) NOT NULL REFERENCES exercise_sources(id) ON DELETE CASCADE,
    target_kind  support_target_kind NOT NULL,
    phase_id     VARCHAR(64) REFERENCES exercise_phases(id) ON DELETE CASCADE,
    cue_id       VARCHAR(64) REFERENCES exercise_cues(id)   ON DELETE CASCADE,
    zone_code    VARCHAR(40) REFERENCES anatomy_zones(code),
    claim_path   VARCHAR(120) NOT NULL,           -- каноническая строка supports
    -- ровно одна цель по kind
    CONSTRAINT chk_support_target CHECK (
        (target_kind='phase'   AND phase_id IS NOT NULL AND cue_id IS NULL AND zone_code IS NULL) OR
        (target_kind='cue'     AND cue_id   IS NOT NULL AND phase_id IS NULL AND zone_code IS NULL) OR
        (target_kind='anatomy' AND zone_code IS NOT NULL AND phase_id IS NULL AND cue_id IS NULL)
    ),
    UNIQUE (source_id, claim_path)
);
CREATE INDEX idx_supports_cue   ON source_supports(cue_id);
CREATE INDEX idx_supports_phase ON source_supports(phase_id);

-- =====================================================================
--  9. ВЕРСИИ ОПУБЛИКОВАННЫХ ЗАПИСЕЙ (иммутабельные снимки)
--     Активная тренировка использует снимок на момент старта.
-- =====================================================================
CREATE TABLE exercise_published_versions (
    exercise_id    VARCHAR(64) NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    version        INT NOT NULL,
    schema_version SMALLINT NOT NULL DEFAULT 2,
    record         JSONB NOT NULL,                -- полный ExerciseRecord на момент публикации
    published_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    published_by   VARCHAR(120),
    PRIMARY KEY (exercise_id, version)
);
-- exercises.current_version -> exercise_published_versions
ALTER TABLE exercises
  ADD CONSTRAINT fk_current_version
  FOREIGN KEY (id, current_version)
  REFERENCES exercise_published_versions (exercise_id, version)
  DEFERRABLE INITIALLY DEFERRED;

-- =====================================================================
--  10. РЕДАКТОРСКИЙ СЛОЙ (дополнительный, НЕ входит в ExerciseRecord)
--      Универсальная классификация, дисциплины, теги, связи упражнений.
-- =====================================================================
CREATE TABLE movement_patterns (
    id SMALLSERIAL PRIMARY KEY, code VARCHAR(30) UNIQUE NOT NULL,
    name_en VARCHAR(60) NOT NULL, name_ru VARCHAR(60) NOT NULL
);
CREATE TABLE disciplines (
    id SMALLSERIAL PRIMARY KEY, code VARCHAR(30) UNIQUE NOT NULL,
    name_en VARCHAR(60) NOT NULL, name_ru VARCHAR(60) NOT NULL
);
CREATE TABLE tags (
    id SERIAL PRIMARY KEY, code VARCHAR(40) UNIQUE NOT NULL,
    name_en VARCHAR(60) NOT NULL, name_ru VARCHAR(60) NOT NULL
);
CREATE TABLE exercise_movement_patterns (
    exercise_id VARCHAR(64) REFERENCES exercises(id) ON DELETE CASCADE,
    pattern_id  SMALLINT REFERENCES movement_patterns(id),
    is_primary  BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (exercise_id, pattern_id)
);
CREATE TABLE exercise_disciplines (
    exercise_id VARCHAR(64) REFERENCES exercises(id) ON DELETE CASCADE,
    discipline_id SMALLINT REFERENCES disciplines(id),
    PRIMARY KEY (exercise_id, discipline_id)
);
CREATE TABLE exercise_tags (
    exercise_id VARCHAR(64) REFERENCES exercises(id) ON DELETE CASCADE,
    tag_id INT REFERENCES tags(id),
    PRIMARY KEY (exercise_id, tag_id)
);
CREATE TABLE exercise_relations (
    id BIGSERIAL PRIMARY KEY,
    from_exercise_id VARCHAR(64) NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    to_exercise_id   VARCHAR(64) NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    relation_type VARCHAR(15) NOT NULL
        CHECK (relation_type IN ('progression','regression','variation','prerequisite','chain_part')),
    sort_order SMALLINT DEFAULT 0,
    CONSTRAINT chk_rel_not_self CHECK (from_exercise_id <> to_exercise_id),
    UNIQUE (from_exercise_id, to_exercise_id, relation_type)
);

-- =====================================================================
--  11. ЭКСПОРТ В КЛИЕНТСКИЙ ExerciseRecord (schemaVersion 2)
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_export_exercise_record(p_exercise_id VARCHAR)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE
    v_record JSONB;
BEGIN
    SELECT jsonb_strip_nulls(jsonb_build_object(
        'schemaVersion', e.schema_version,
        'id',   e.id,
        'name', e.name,
        'aliases', COALESCE((SELECT jsonb_agg(a.alias ORDER BY a.alias)
                             FROM exercise_aliases a WHERE a.exercise_id = e.id), '[]'::jsonb),
        'classification', jsonb_build_object(
            'movementKind', e.movement_kind,
            'laterality',   e.laterality,
            'experience',   e.experience
        ),
        'phases', COALESCE((
            SELECT jsonb_agg(jsonb_build_object(
                'id', p.id,
                'order', p.phase_order,
                'shortName', p.short_name,
                'technique', p.technique,
                'poseBrief', jsonb_build_object(
                    'bodyOrientation', p.body_orientation,
                    'support', p.support,
                    'kettlebellPosition', p.kettlebell_position,
                    'bodyPosition', p.body_position
                ),
                'visual', jsonb_build_object(
                    'feetBaseline', p.feet_baseline,
                    'scale', p.scale,
                    'status', p.visual_status,
                    'assets', COALESCE((
                        SELECT jsonb_object_agg(pa.figure_variant, pa.asset_url)
                        FROM phase_assets pa WHERE pa.phase_id = p.id), '{}'::jsonb)
                )
            ) ORDER BY p.phase_order)
            FROM exercise_phases p WHERE p.exercise_id = e.id), '[]'::jsonb),
        'cues', COALESCE((
            SELECT jsonb_agg(jsonb_build_object(
                'id', c.id,
                'text', c.text,
                'sourceIds', COALESCE((
                    SELECT jsonb_agg(DISTINCT s.source_id)
                    FROM source_supports s WHERE s.cue_id = c.id), '[]'::jsonb)
            ) ORDER BY c.sort_order, c.id)
            FROM exercise_cues c WHERE c.exercise_id = e.id), '[]'::jsonb),
        'anatomy', jsonb_build_object(
            'primary', COALESCE((SELECT jsonb_agg(z.zone_code ORDER BY z.zone_code)
                                 FROM exercise_anatomy_zones z
                                 WHERE z.exercise_id = e.id AND z.role='primary'), '[]'::jsonb),
            'secondary', COALESCE((SELECT jsonb_agg(z.zone_code ORDER BY z.zone_code)
                                   FROM exercise_anatomy_zones z
                                   WHERE z.exercise_id = e.id AND z.role='secondary'), '[]'::jsonb),
            'asset', e.anatomy_asset,
            'status', e.anatomy_status
        ),
        'assets', jsonb_build_object(
            'thumbnailPhaseId', e.thumbnail_phase_id,
            'styleId', e.style_id,
            'anatomyStyleId', e.anatomy_style_id
        ),
        'sources', COALESCE((
            SELECT jsonb_agg(jsonb_build_object(
                'id', src.id,
                'organization', src.organization,
                'title', src.title,
                'url', src.url,
                'sourceType', src.source_type,
                -- accessedAt: DATE без времени, формат фиксируем явно (TZ-независимо)
                'accessedAt', to_char(src.accessed_at, 'YYYY-MM-DD'),
                'supports', COALESCE((
                    SELECT jsonb_agg(ss.claim_path ORDER BY ss.claim_path)
                    FROM source_supports ss WHERE ss.source_id = src.id), '[]'::jsonb)
            ) ORDER BY src.id)
            FROM exercise_sources src WHERE src.exercise_id = e.id), '[]'::jsonb),
        'review', jsonb_build_object(
            'technique', e.review_technique,
            'phases', e.review_phases,
            'visuals', e.review_visuals,
            'anatomy', e.review_anatomy,
            -- reviewedAt: строго UTC ISO 8601 с суффиксом 'Z', не зависит от TimeZone сессии.
            -- AT TIME ZONE 'UTC' переводит timestamptz в настенное время UTC, затем фиксируем формат.
            'reviewedAt', to_char(e.reviewed_at AT TIME ZONE 'UTC',
                                  'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'reviewer', e.reviewer,
            'notes', e.review_notes
        )
    )) INTO v_record
    FROM exercises e WHERE e.id = p_exercise_id;

    IF v_record IS NULL THEN
        RAISE EXCEPTION 'Exercise % not found', p_exercise_id;
    END IF;
    RETURN v_record;
END;
$$;

-- =====================================================================
--  12. ПРОВЕРКА УСЛОВИЙ ПУБЛИКАЦИИ (8 правил из контракта)
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_publication_checklist(p_exercise_id VARCHAR)
RETURNS TABLE (rule_no INT, rule TEXT, passed BOOLEAN, detail TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_phase_cnt INT;
    v_order_ok  BOOLEAN;
    e exercises%ROWTYPE;
BEGIN
    SELECT * INTO e FROM exercises WHERE id = p_exercise_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Exercise % not found', p_exercise_id; END IF;

    SELECT count(*) INTO v_phase_cnt FROM exercise_phases WHERE exercise_id = p_exercise_id;

    -- порядок 1..N уникален и непрерывен
    SELECT (v_phase_cnt > 0
            AND MIN(phase_order)=1
            AND MAX(phase_order)=v_phase_cnt
            AND COUNT(DISTINCT phase_order)=v_phase_cnt)
      INTO v_order_ok
      FROM exercise_phases WHERE exercise_id = p_exercise_id;

    -- 1. фаз ровно 2 или 3, порядок уникален и непрерывен
    rule_no:=1; rule:='Фаз ровно 2 или 3, порядок уникален и непрерывен';
    passed := (v_phase_cnt IN (2,3) AND COALESCE(v_order_ok,FALSE));
    detail := format('фаз=%s, порядок_ок=%s', v_phase_cnt, COALESCE(v_order_ok,FALSE));
    RETURN NEXT;

    -- 2. техника минимум source_checked
    rule_no:=2; rule:='Техника не ниже source_checked';
    passed := e.review_technique IN ('source_checked','coach_approved');
    detail := format('review_technique=%s', e.review_technique);
    RETURN NEXT;

    -- 3. фазы минимум reviewed
    rule_no:=3; rule:='Фазы подтверждены минимум как reviewed';
    passed := e.review_phases IN ('reviewed','approved');
    detail := format('review_phases=%s', e.review_phases);
    RETURN NEXT;

    -- 4. все нужные кадры существуют и с единым визуальным контрактом
    --    (для каждой фазы есть male+female ассеты и статус >= reviewed)
    rule_no:=4; rule:='Все кадры существуют (male+female) и не ниже reviewed';
    passed := NOT EXISTS (
        SELECT 1 FROM exercise_phases p
        WHERE p.exercise_id = p_exercise_id
          AND ( p.visual_status NOT IN ('reviewed','approved')
             OR (SELECT count(*) FROM phase_assets pa WHERE pa.phase_id=p.id)<2 )
    );
    detail := 'проверены наличие male/female и статус каждой фазы';
    RETURN NEXT;

    -- 5. карта зон проверена (anatomy_status >= reviewed) и есть хотя бы одна primary-зона
    rule_no:=5; rule:='Карта зон проверена и содержит зоны';
    passed := e.review_anatomy IN ('reviewed','approved')
              AND EXISTS (SELECT 1 FROM exercise_anatomy_zones z
                          WHERE z.exercise_id=p_exercise_id AND z.role='primary');
    detail := format('review_anatomy=%s', e.review_anatomy);
    RETURN NEXT;

    -- 6. каждый cue связан хотя бы с одним источником
    rule_no:=6; rule:='Каждый cue связан хотя бы с одним источником';
    passed := NOT EXISTS (
        SELECT 1 FROM exercise_cues c
        WHERE c.exercise_id=p_exercise_id
          AND NOT EXISTS (SELECT 1 FROM source_supports s WHERE s.cue_id=c.id)
    );
    detail := 'проверена привязка source_supports для всех cue';
    RETURN NEXT;

    -- 7. заданы миниатюра и утверждённые стили
    rule_no:=7; rule:='Миниатюра задана, стили утверждены';
    passed := e.thumbnail_phase_id IS NOT NULL
              AND EXISTS (SELECT 1 FROM figure_styles fs WHERE fs.id=e.style_id AND fs.is_approved)
              AND EXISTS (SELECT 1 FROM figure_styles fs WHERE fs.id=e.anatomy_style_id AND fs.is_approved);
    detail := format('thumbnail=%s, style=%s, anatomyStyle=%s',
                     e.thumbnail_phase_id, e.style_id, e.anatomy_style_id);
    RETURN NEXT;

    -- 8. нет веса/повторов/подходов/таймингов — гарантировано схемой ядра
    rule_no:=8; rule:='Ядро не содержит веса/повторов/подходов/таймингов';
    passed := TRUE;
    detail := 'обеспечено структурой схемы (таких полей в ядре нет)';
    RETURN NEXT;
END;
$$;

-- Булевый итог: можно ли публиковать
CREATE OR REPLACE FUNCTION fn_can_publish(p_exercise_id VARCHAR)
RETURNS BOOLEAN LANGUAGE sql AS $$
    SELECT bool_and(passed) FROM fn_publication_checklist(p_exercise_id);
$$;

-- Публикация: проверяет условия и пишет иммутабельный снимок ExerciseRecord
CREATE OR REPLACE FUNCTION fn_publish_exercise(p_exercise_id VARCHAR, p_by VARCHAR DEFAULT NULL)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_next INT; v_rec JSONB;
BEGIN
    IF NOT fn_can_publish(p_exercise_id) THEN
        RAISE EXCEPTION 'Упражнение % не прошло условия публикации', p_exercise_id;
    END IF;
    SELECT COALESCE(MAX(version),0)+1 INTO v_next
      FROM exercise_published_versions WHERE exercise_id=p_exercise_id;
    v_rec := fn_export_exercise_record(p_exercise_id);
    INSERT INTO exercise_published_versions(exercise_id, version, schema_version, record, published_by)
      VALUES (p_exercise_id, v_next, 2, v_rec, p_by);
    UPDATE exercises SET current_version=v_next, updated_at=now() WHERE id=p_exercise_id;
    RETURN v_next;
END;
$$;

-- =====================================================================
--  КОНЕЦ СХЕМЫ
-- =====================================================================
