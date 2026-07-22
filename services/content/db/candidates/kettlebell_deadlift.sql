-- Черновая запись: становая тяга с одной гирей между стопами.
-- Требует предварительного применения schema.sql и seed_example.sql.
-- Все контентные и визуальные проверки пройдены; публикация выполняется отдельным явным действием.

BEGIN;

INSERT INTO anatomy_zones(code,name_en,name_ru,region) VALUES
 ('quadriceps','Quadriceps','Квадрицепсы','lower')
ON CONFLICT (code) DO NOTHING;

INSERT INTO exercises(
    id,name,movement_kind,laterality,experience,
    style_id,anatomy_style_id,anatomy_asset,anatomy_status,
    review_technique,review_phases,review_visuals,review_anatomy,
    reviewer,reviewed_at,review_notes)
VALUES (
    'kettlebell-deadlift','Становая тяга с гирей','grind','bilateral','basic',
    'approved-athlete-v1','approved-anatomy-v1','assets/movements/kettlebell-deadlift-zones-v1.png','reviewed',
    'source_checked','reviewed','approved','reviewed',
    'owner','2026-07-22T00:00:00Z',
    'Мужская пара v2 проверена владельцем в анимации на телефоне; женские визуалы проверены отдельно; анатомическая схема утверждена.'
);

INSERT INTO exercise_aliases(exercise_id,alias) VALUES
 ('kettlebell-deadlift','Тяга гири с пола'),
 ('kettlebell-deadlift','Kettlebell Deadlift');

INSERT INTO exercise_phases(
    id,exercise_id,phase_order,short_name,technique,
    body_orientation,support,kettlebell_position,body_position,
    feet_baseline,scale,visual_status)
VALUES
 ('deadlift-bottom','kettlebell-deadlift',1,'Нижняя позиция',
  'Из устойчивой стойки отвести таз назад, мягко согнуть колени и взять гирю двумя руками, сохраняя нейтральный позвоночник.',
  'side','bilateral',
  'На полу по центру между стопами; рукоять удерживается двумя руками.',
  'Стопы примерно между шириной таза и плеч; колени мягко согнуты; таз отведён назад; корпус длинный и нейтральный; плечи над гирей.',
  0.100,1.000,'approved'),
 ('deadlift-stand','kettlebell-deadlift',2,'Стойка',
  'Одновременно разогнуть колени и таз до обычной вертикальной стойки, не отклоняя корпус назад.',
  'side','bilateral',
  'Свободно висит в прямых руках перед тазом.',
  'Обе стопы остаются на полу; таз и колени разогнуты; корпус и голова нейтральны; отклонения назад нет.',
  0.100,1.000,'approved');

INSERT INTO phase_assets(phase_id,figure_variant,asset_url) VALUES
 ('deadlift-bottom','male','assets/movements/kettlebell-deadlift-bottom-male-anchored-v2.png'),
 ('deadlift-stand','male','assets/movements/kettlebell-deadlift-stand-male-anchored-v2.png'),
 ('deadlift-bottom','female','assets/movements/kettlebell-deadlift-bottom-female-anchored-v2.png'),
 ('deadlift-stand','female','assets/movements/kettlebell-deadlift-stand-female-anchored-v2.png');

UPDATE exercises
SET thumbnail_phase_id='deadlift-stand'
WHERE id='kettlebell-deadlift';

INSERT INTO exercise_cues(id,exercise_id,text,sort_order) VALUES
 ('deadlift-cue-hinge','kettlebell-deadlift','Отведи таз назад и держи спину нейтральной.',1),
 ('deadlift-cue-stand','kettlebell-deadlift','Встань, одновременно разгибая колени и таз.',2),
 ('deadlift-cue-finish','kettlebell-deadlift','В верхней точке стой прямо — не отклоняйся назад.',3);

INSERT INTO exercise_anatomy_zones(exercise_id,zone_code,role) VALUES
 ('kettlebell-deadlift','glutes','primary'),
 ('kettlebell-deadlift','hamstrings','primary'),
 ('kettlebell-deadlift','quadriceps','primary'),
 ('kettlebell-deadlift','lower_back','secondary');

INSERT INTO exercise_sources(
    id,exercise_id,organization,title,url,source_type,accessed_at)
VALUES
 ('deadlift-src-nsca','kettlebell-deadlift','NSCA',
  'Resistance Training Progressions for the Older Adult—Deadlifts',
  'https://dxpprod.nsca.com/contentassets/b70b70c5cb96417bbc58d5b6756a689e/ptq-8.3.1-resistance-training-progressions-for-the-older-adult-deadlifts.pdf',
  'professional_standard','2026-07-22'),
 ('deadlift-src-barbend','kettlebell-deadlift','BarBend',
  'How to Do the Kettlebell Deadlift to Master Your Hip Hinge',
  'https://barbend.com/kettlebell-deadlift/',
  'supplementary','2026-07-22'),
 ('deadlift-src-plos-review','kettlebell-deadlift','PLOS ONE',
  'Electromyographic activity in deadlift exercise and its variants: a systematic review',
  'https://doi.org/10.1371/journal.pone.0229507',
  'research','2026-07-22');

INSERT INTO source_supports(source_id,target_kind,phase_id,cue_id,zone_code,claim_path) VALUES
 ('deadlift-src-nsca','phase','deadlift-bottom',NULL,NULL,'phase.deadlift-bottom.bodyPosition'),
 ('deadlift-src-nsca','phase','deadlift-bottom',NULL,NULL,'phase.deadlift-bottom.kettlebellPosition'),
 ('deadlift-src-nsca','phase','deadlift-stand',NULL,NULL,'phase.deadlift-stand.bodyPosition'),
 ('deadlift-src-barbend','phase','deadlift-bottom',NULL,NULL,'phase.deadlift-bottom.hinge'),
 ('deadlift-src-barbend','phase','deadlift-stand',NULL,NULL,'phase.deadlift-stand.finish'),
 ('deadlift-src-nsca','cue',NULL,'deadlift-cue-hinge',NULL,'cue.deadlift-hinge'),
 ('deadlift-src-barbend','cue',NULL,'deadlift-cue-hinge',NULL,'cue.deadlift-hinge-independent-check'),
 ('deadlift-src-nsca','cue',NULL,'deadlift-cue-stand',NULL,'cue.deadlift-stand'),
 ('deadlift-src-barbend','cue',NULL,'deadlift-cue-finish',NULL,'cue.deadlift-finish'),
 ('deadlift-src-plos-review','anatomy',NULL,NULL,'glutes','anatomy.glutes'),
 ('deadlift-src-plos-review','anatomy',NULL,NULL,'hamstrings','anatomy.hamstrings'),
 ('deadlift-src-plos-review','anatomy',NULL,NULL,'quadriceps','anatomy.quadriceps'),
 ('deadlift-src-plos-review','anatomy',NULL,NULL,'lower_back','anatomy.lower_back');

COMMIT;

-- Ожидаемый результат: TRUE; фактическая публикация остаётся отдельным явным действием.
SELECT * FROM fn_publication_checklist('kettlebell-deadlift') ORDER BY rule_no;
SELECT fn_can_publish('kettlebell-deadlift');
