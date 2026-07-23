-- Гоблет-присед: вертикальная стойка и нижняя позиция приседа.
-- Требует schema.sql и seed_reference_data.sql.

BEGIN;

INSERT INTO anatomy_zones(code,name_en,name_ru,region) VALUES
 ('quadriceps','Quadriceps','Квадрицепсы','lower'),
 ('abdominals','Abdominals','Мышцы живота','core')
ON CONFLICT (code) DO NOTHING;

INSERT INTO exercises(
    id,name,movement_kind,laterality,experience,
    style_id,anatomy_style_id,anatomy_asset,anatomy_status,
    review_technique,review_phases,review_visuals,review_anatomy,
    reviewer,reviewed_at,review_notes)
VALUES (
    'goblet-squat','Гоблет-присед','grind','bilateral','basic',
    'approved-athlete-v1','approved-anatomy-v1',
    'assets/movements/goblet-lunge-zones-v2.png','reviewed',
    'source_checked','reviewed','reviewed','reviewed',
    'content-pipeline','2026-07-23T00:00:00Z',
    'Мужская и женская пары нормализованы автоматически; окончательная проверка анимации владельцем на телефоне ожидается.'
);

INSERT INTO exercise_aliases(exercise_id,alias) VALUES
 ('goblet-squat','Присед с гирей у груди'),
 ('goblet-squat','Goblet Squat');

INSERT INTO exercise_phases(
    id,exercise_id,phase_order,short_name,technique,
    body_orientation,support,kettlebell_position,body_position,
    feet_baseline,scale,visual_status)
VALUES
 ('goblet-stand','goblet-squat',1,'Стойка',
  'Стоять устойчиво, удерживая гирю двумя руками у груди и сохраняя вертикальный нейтральный корпус.',
  'three_quarter','bilateral',
  'У верхней части груди; обе кисти удерживают рукоять по бокам.',
  'Стопы примерно на ширине плеч, носки слегка развёрнуты; колени и таз разогнуты; грудная клетка над тазом.',
  0.100,1.000,'reviewed'),
 ('goblet-bottom','goblet-squat',2,'Нижняя позиция',
  'Одновременно согнуть таз и колени, опускаясь между стопами без потери устойчивой опоры и нейтрального положения спины.',
  'three_quarter','bilateral',
  'Остаётся у груди; локти направлены вниз и немного вперёд.',
  'Пятки на полу; колени следуют направлению носков; таз опущен; грудная клетка остаётся поднятой.',
  0.100,1.000,'reviewed');

INSERT INTO phase_assets(phase_id,figure_variant,asset_url) VALUES
 ('goblet-stand','male','assets/movements/goblet-squat-standing-anchored-v1.png'),
 ('goblet-bottom','male','assets/movements/goblet-squat-bottom-anchored-v1.png'),
 ('goblet-stand','female','assets/movements/goblet-squat-standing-female-anchored-v2.png'),
 ('goblet-bottom','female','assets/movements/goblet-squat-bottom-female-anchored-v2.png');

UPDATE exercises SET thumbnail_phase_id='goblet-stand' WHERE id='goblet-squat';

INSERT INTO exercise_cues(id,exercise_id,text,sort_order) VALUES
 ('goblet-cue-chest','goblet-squat','Держи гирю у груди, а корпус — собранным.',1),
 ('goblet-cue-knees','goblet-squat','Направляй колени туда же, куда смотрят носки.',2),
 ('goblet-cue-stand','goblet-squat','Встань, сохраняя устойчивую опору всей стопой.',3);

INSERT INTO exercise_anatomy_zones(exercise_id,zone_code,role) VALUES
 ('goblet-squat','quadriceps','primary'),
 ('goblet-squat','glutes','primary'),
 ('goblet-squat','hamstrings','secondary'),
 ('goblet-squat','abdominals','secondary');

INSERT INTO exercise_sources(
    id,exercise_id,organization,title,url,source_type,accessed_at)
VALUES
 ('goblet-src-ace-kb','goblet-squat','American Council on Exercise',
  'How to Get Started With Kettlebells',
  'https://www.acefitness.org/resources/pros/expert-articles/5269/how-to-get-started-with-kettlebells/',
  'professional_standard','2026-07-23'),
 ('goblet-src-ace-library','goblet-squat','American Council on Exercise',
  'Goblet Squat',
  'https://www.acefitness.org/resources/everyone/exercise-library/362/goblet-squat/',
  'professional_standard','2026-07-23'),
 ('goblet-src-nasm','goblet-squat','National Academy of Sports Medicine',
  'Goblet Squat',
  'https://www.nasm.org/resource-center/exercise-library/goblet-squat',
  'professional_standard','2026-07-23');

INSERT INTO source_supports(source_id,target_kind,phase_id,cue_id,zone_code,claim_path) VALUES
 ('goblet-src-ace-kb','phase','goblet-stand',NULL,NULL,'phase.goblet-stand.technique'),
 ('goblet-src-ace-kb','phase','goblet-bottom',NULL,NULL,'phase.goblet-bottom.technique'),
 ('goblet-src-nasm','phase','goblet-stand',NULL,NULL,'phase.goblet-stand.independent-check'),
 ('goblet-src-nasm','phase','goblet-bottom',NULL,NULL,'phase.goblet-bottom.independent-check'),
 ('goblet-src-ace-library','cue',NULL,'goblet-cue-chest',NULL,'cue.goblet-chest'),
 ('goblet-src-nasm','cue',NULL,'goblet-cue-knees',NULL,'cue.goblet-knees'),
 ('goblet-src-ace-kb','cue',NULL,'goblet-cue-stand',NULL,'cue.goblet-stand'),
 ('goblet-src-nasm','anatomy',NULL,NULL,'quadriceps','anatomy.quadriceps'),
 ('goblet-src-nasm','anatomy',NULL,NULL,'glutes','anatomy.glutes'),
 ('goblet-src-nasm','anatomy',NULL,NULL,'hamstrings','anatomy.hamstrings'),
 ('goblet-src-nasm','anatomy',NULL,NULL,'abdominals','anatomy.abdominals');

COMMIT;

SELECT * FROM fn_publication_checklist('goblet-squat') ORDER BY rule_no;
SELECT fn_can_publish('goblet-squat');
