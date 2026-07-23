-- Подъём гири на грудь с последующим жимом правой рукой: три ключевые фазы.
-- Требует schema.sql и seed_reference_data.sql.

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
    'clean-and-press','Подъём с жимом','complex','unilateral','advanced',
    'approved-athlete-v1','approved-anatomy-v1',
    'assets/movements/clean-press-zones-v1.png','reviewed',
    'source_checked','reviewed','reviewed','reviewed',
    'content-pipeline','2026-07-23T00:00:00Z',
    'Трёхфазная последовательность и правая рабочая рука зафиксированы; окончательная проверка владельцем на телефоне ожидается.'
);

INSERT INTO exercise_aliases(exercise_id,alias) VALUES
 ('clean-and-press','Подъём гири на грудь и жим'),
 ('clean-and-press','Kettlebell Clean and Press');

INSERT INTO exercise_phases(
    id,exercise_id,phase_order,short_name,technique,
    body_orientation,support,kettlebell_position,body_position,
    feet_baseline,scale,visual_status)
VALUES
 ('clean-press-hike','clean-and-press',1,'Замах',
  'Отвести таз назад и провести гирю правой рукой между бёдрами, сохраняя длинную руку и нейтральный позвоночник.',
  'three_quarter','bilateral',
  'Между бёдрами в правой руке; ядро продолжает дугу назад.',
  'Стопы устойчивы; колени мягко согнуты; таз отведён назад; корпус длинный и нейтральный.',
  0.100,1.000,'reviewed'),
 ('clean-press-rack','clean-and-press',2,'Стойка у груди',
  'Разогнуть таз, направить гирю близко к корпусу и мягко принять её на правое предплечье у плеча.',
  'three_quarter','bilateral',
  'На внешней стороне правого предплечья у плеча; кисть нейтральна, локоть рядом с рёбрами.',
  'Вертикальная устойчивая стойка; таз и колени разогнуты; корпус не отклонён назад.',
  0.100,1.000,'reviewed'),
 ('clean-press-lockout','clean-and-press',3,'Фиксация',
  'Из стойки у груди выжать гирю правой рукой вверх до устойчивой фиксации без прогиба и отклонения корпуса.',
  'three_quarter','bilateral',
  'Над правым плечом; локоть разогнут, гиря лежит за нейтральным запястьем.',
  'Стопы остаются на полу; рёбра над тазом; правая рука вертикальна; голова нейтральна.',
  0.100,1.000,'reviewed');

INSERT INTO phase_assets(phase_id,figure_variant,asset_url) VALUES
 ('clean-press-hike','male','assets/movements/clean-press-low-coherent-anchored-v1.png'),
 ('clean-press-rack','male','assets/movements/clean-press-rack-coherent-anchored-v1.png'),
 ('clean-press-lockout','male','assets/movements/clean-press-overhead-coherent-anchored-v1.png'),
 ('clean-press-hike','female','assets/movements/clean-press-low-female-anchored-v2.png'),
 ('clean-press-rack','female','assets/movements/clean-press-rack-female-anchored-v2.png'),
 ('clean-press-lockout','female','assets/movements/clean-press-overhead-female-anchored-v2.png');

UPDATE exercises SET thumbnail_phase_id='clean-press-rack' WHERE id='clean-and-press';

INSERT INTO exercise_cues(id,exercise_id,text,sort_order) VALUES
 ('clean-press-cue-hips','clean-and-press','Подними гирю импульсом от таза, а не сгибанием руки.',1),
 ('clean-press-cue-rack','clean-and-press','Прими гирю мягко на предплечье у плеча.',2),
 ('clean-press-cue-stack','clean-and-press','В жиме держи рёбра над тазом и не отклоняйся назад.',3);

INSERT INTO exercise_anatomy_zones(exercise_id,zone_code,role) VALUES
 ('clean-and-press','deltoids','primary'),
 ('clean-and-press','triceps','primary'),
 ('clean-and-press','glutes','secondary'),
 ('clean-and-press','abdominals','secondary');

INSERT INTO exercise_sources(
    id,exercise_id,organization,title,url,source_type,accessed_at)
VALUES
 ('clean-press-src-ace','clean-and-press','American Council on Exercise',
  'Clean and Press',
  'https://www.acefitness.org/resources/everyone/exercise-library/383/clean-and-press/',
  'professional_standard','2026-07-23'),
 ('clean-press-src-nasm','clean-and-press','National Academy of Sports Medicine',
  'Off the Mat Training for Martial Arts',
  'https://blog.nasm.org/mma/off-the-mat-training-for-martial-arts',
  'professional_standard','2026-07-23'),
 ('clean-press-src-emg','clean-and-press','PubMed',
  'The Effect of the Weight and Type of Equipment on Shoulder and Back Muscle Activity during the Overhead Press',
  'https://pubmed.ncbi.nlm.nih.gov/36560129/',
  'research','2026-07-23'),
 ('clean-press-src-press-emg','clean-and-press','PubMed',
  'Effects of body position and loading modality on muscle activity and strength in shoulder presses',
  'https://pubmed.ncbi.nlm.nih.gov/23096062/',
  'research','2026-07-23');

INSERT INTO source_supports(source_id,target_kind,phase_id,cue_id,zone_code,claim_path) VALUES
 ('clean-press-src-ace','phase','clean-press-hike',NULL,NULL,'phase.clean-press-hike.technique'),
 ('clean-press-src-ace','phase','clean-press-rack',NULL,NULL,'phase.clean-press-rack.technique'),
 ('clean-press-src-ace','phase','clean-press-lockout',NULL,NULL,'phase.clean-press-lockout.technique'),
 ('clean-press-src-nasm','phase','clean-press-rack',NULL,NULL,'phase.clean-press-rack.independent-check'),
 ('clean-press-src-nasm','phase','clean-press-lockout',NULL,NULL,'phase.clean-press-lockout.independent-check'),
 ('clean-press-src-ace','cue',NULL,'clean-press-cue-hips',NULL,'cue.clean-press-hips'),
 ('clean-press-src-ace','cue',NULL,'clean-press-cue-rack',NULL,'cue.clean-press-rack'),
 ('clean-press-src-emg','cue',NULL,'clean-press-cue-stack',NULL,'cue.clean-press-stack'),
 ('clean-press-src-emg','anatomy',NULL,NULL,'deltoids','anatomy.deltoids'),
 ('clean-press-src-press-emg','anatomy',NULL,NULL,'triceps','anatomy.triceps'),
 ('clean-press-src-ace','anatomy',NULL,NULL,'glutes','anatomy.glutes'),
 ('clean-press-src-emg','anatomy',NULL,NULL,'abdominals','anatomy.abdominals');

COMMIT;

SELECT * FROM fn_publication_checklist('clean-and-press') ORDER BY rule_no;
SELECT fn_can_publish('clean-and-press');
