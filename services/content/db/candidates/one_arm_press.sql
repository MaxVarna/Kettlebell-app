-- Строгий жим гири одной рукой: стойка у груди и фиксация над головой.
-- Визуальный вариант показывает правую рабочую руку.

BEGIN;

INSERT INTO anatomy_zones(code,name_en,name_ru,region) VALUES
 ('abdominals','Abdominals','Мышцы живота','core'),
 ('deltoids','Deltoids','Дельтовидные','upper'),
 ('triceps','Triceps','Трицепсы','upper')
ON CONFLICT (code) DO NOTHING;

INSERT INTO exercises(
    id,name,movement_kind,laterality,experience,
    style_id,anatomy_style_id,anatomy_asset,anatomy_status,
    review_technique,review_phases,review_visuals,review_anatomy,
    reviewer,reviewed_at,review_notes)
VALUES (
    'one-arm-press','Жим гири одной рукой','grind','unilateral','intermediate',
    'approved-athlete-v1','approved-anatomy-v1',
    'assets/movements/one-arm-press-zones-v1.png','reviewed',
    'source_checked','reviewed','reviewed','reviewed',
    'content-pipeline','2026-07-23T00:00:00Z',
    'Использует утверждённые положения стойки и фиксации из подъёма с жимом; device-проверка владельцем ожидается.'
);

INSERT INTO exercise_aliases(exercise_id,alias) VALUES
 ('one-arm-press','Одноручный жим гири'),
 ('one-arm-press','Single-Arm Kettlebell Press');

INSERT INTO exercise_phases(
    id,exercise_id,phase_order,short_name,technique,
    body_orientation,support,kettlebell_position,body_position,
    feet_baseline,scale,visual_status)
VALUES
 ('press-rack','one-arm-press',1,'Стойка у груди',
  'Удерживать гирю на правом предплечье у плеча, сохраняя нейтральную кисть, устойчивую стойку и собранный корпус.',
  'three_quarter','bilateral',
  'На внешней стороне правого предплечья у плеча; правый локоть рядом с рёбрами.',
  'Стопы устойчивы; таз и колени разогнуты; рёбра расположены над тазом; корпус не отклонён назад.',
  0.100,1.000,'reviewed'),
 ('press-lockout','one-arm-press',2,'Фиксация',
  'Выжать гирю правой рукой вверх до полного контролируемого разгибания локтя без прогиба и помощи ногами.',
  'three_quarter','bilateral',
  'Над правым плечом; гиря лежит за нейтральным запястьем, локоть разогнут.',
  'Стопы остаются на полу; колени и таз неподвижны; рёбра над тазом; правая рука вертикальна.',
  0.100,1.000,'reviewed');

INSERT INTO phase_assets(phase_id,figure_variant,asset_url) VALUES
 ('press-rack','male','assets/movements/clean-press-rack-coherent-anchored-v1.png'),
 ('press-lockout','male','assets/movements/clean-press-overhead-coherent-anchored-v1.png'),
 ('press-rack','female','assets/movements/clean-press-rack-female-anchored-v2.png'),
 ('press-lockout','female','assets/movements/clean-press-overhead-female-anchored-v2.png');

UPDATE exercises SET thumbnail_phase_id='press-rack' WHERE id='one-arm-press';

INSERT INTO exercise_cues(id,exercise_id,text,sort_order) VALUES
 ('press-cue-rack','one-arm-press','Начни из устойчивой стойки с гирей у плеча.',1),
 ('press-cue-stack','one-arm-press','Держи рёбра над тазом — не отклоняйся назад.',2),
 ('press-cue-lock','one-arm-press','Заверши движение устойчивой фиксацией над плечом.',3);

INSERT INTO exercise_anatomy_zones(exercise_id,zone_code,role) VALUES
 ('one-arm-press','deltoids','primary'),
 ('one-arm-press','triceps','primary'),
 ('one-arm-press','abdominals','secondary');

INSERT INTO exercise_sources(
    id,exercise_id,organization,title,url,source_type,accessed_at)
VALUES
 ('press-src-ace','one-arm-press','American Council on Exercise',
  'Single Arm Overhead Press',
  'https://www.acefitness.org/resources/everyone/exercise-library/395/single-arm-overhead-press/',
  'professional_standard','2026-07-23'),
 ('press-src-nasm','one-arm-press','National Academy of Sports Medicine',
  'Kettlebell Workout',
  'https://blog.nasm.org/kettlebell-workout',
  'professional_standard','2026-07-23'),
 ('press-src-kb-emg','one-arm-press','PubMed',
  'The Effect of the Weight and Type of Equipment on Shoulder and Back Muscle Activity during the Overhead Press',
  'https://pubmed.ncbi.nlm.nih.gov/36560129/',
  'research','2026-07-23'),
 ('press-src-standing-emg','one-arm-press','PubMed',
  'Effects of body position and loading modality on muscle activity and strength in shoulder presses',
  'https://pubmed.ncbi.nlm.nih.gov/23096062/',
  'research','2026-07-23');

INSERT INTO source_supports(source_id,target_kind,phase_id,cue_id,zone_code,claim_path) VALUES
 ('press-src-ace','phase','press-rack',NULL,NULL,'phase.press-rack.technique'),
 ('press-src-ace','phase','press-lockout',NULL,NULL,'phase.press-lockout.technique'),
 ('press-src-nasm','phase','press-rack',NULL,NULL,'phase.press-rack.independent-check'),
 ('press-src-nasm','phase','press-lockout',NULL,NULL,'phase.press-lockout.independent-check'),
 ('press-src-ace','cue',NULL,'press-cue-rack',NULL,'cue.press-rack'),
 ('press-src-nasm','cue',NULL,'press-cue-stack',NULL,'cue.press-stack'),
 ('press-src-ace','cue',NULL,'press-cue-lock',NULL,'cue.press-lockout'),
 ('press-src-kb-emg','anatomy',NULL,NULL,'deltoids','anatomy.deltoids'),
 ('press-src-standing-emg','anatomy',NULL,NULL,'triceps','anatomy.triceps'),
 ('press-src-standing-emg','anatomy',NULL,NULL,'abdominals','anatomy.abdominals');

COMMIT;

SELECT * FROM fn_publication_checklist('one-arm-press') ORDER BY rule_no;
SELECT fn_can_publish('one-arm-press');
