-- Подъём гири на грудь одной рукой: замах и мягкий приём в стойку.
-- Визуальный вариант показывает правую рабочую руку.

BEGIN;

INSERT INTO anatomy_zones(code,name_en,name_ru,region) VALUES
 ('abdominals','Abdominals','Мышцы живота','core'),
 ('deltoids','Deltoids','Дельтовидные','upper')
ON CONFLICT (code) DO NOTHING;

INSERT INTO exercises(
    id,name,movement_kind,laterality,experience,
    style_id,anatomy_style_id,anatomy_asset,anatomy_status,
    review_technique,review_phases,review_visuals,review_anatomy,
    reviewer,reviewed_at,review_notes)
VALUES (
    'one-arm-clean','Подъём гири на грудь','ballistic','unilateral','intermediate',
    'approved-athlete-v1','approved-anatomy-v1',
    'assets/movements/swing-zones-approved-v3.png','reviewed',
    'source_checked','reviewed','reviewed','reviewed',
    'content-pipeline','2026-07-23T00:00:00Z',
    'Использует общие утверждённые кадры замаха и стойки; device-проверка владельцем ожидается.'
);

INSERT INTO exercise_aliases(exercise_id,alias) VALUES
 ('one-arm-clean','Взятие гири на грудь'),
 ('one-arm-clean','Single-Arm Kettlebell Clean');

INSERT INTO exercise_phases(
    id,exercise_id,phase_order,short_name,technique,
    body_orientation,support,kettlebell_position,body_position,
    feet_baseline,scale,visual_status)
VALUES
 ('clean-hike','one-arm-clean',1,'Замах',
  'Отвести таз назад и провести гирю правой рукой между бёдрами, сохраняя длинную руку и нейтральный позвоночник.',
  'three_quarter','bilateral',
  'Между бёдрами в правой руке; ядро продолжает дугу назад.',
  'Стопы устойчивы; колени мягко согнуты; таз отведён назад; корпус длинный и нейтральный.',
  0.100,1.000,'reviewed'),
 ('clean-rack','one-arm-clean',2,'Стойка у груди',
  'Разогнуть таз, провести гирю близко к корпусу и мягко принять её на правое предплечье у плеча.',
  'three_quarter','bilateral',
  'На внешней стороне правого предплечья у плеча; кисть нейтральна, локоть рядом с рёбрами.',
  'Вертикальная устойчивая стойка; таз и колени разогнуты; корпус не отклонён назад.',
  0.100,1.000,'reviewed');

INSERT INTO phase_assets(phase_id,figure_variant,asset_url) VALUES
 ('clean-hike','male','assets/movements/clean-press-low-coherent-anchored-v1.png'),
 ('clean-rack','male','assets/movements/clean-press-rack-coherent-anchored-v1.png'),
 ('clean-hike','female','assets/movements/clean-press-low-female-anchored-v3.png'),
 ('clean-rack','female','assets/movements/clean-press-rack-female-anchored-v2.png');

UPDATE exercises SET thumbnail_phase_id='clean-rack' WHERE id='one-arm-clean';

INSERT INTO exercise_cues(id,exercise_id,text,sort_order) VALUES
 ('clean-cue-hips','one-arm-clean','Разгони гирю разгибанием таза, а не сгибанием руки.',1),
 ('clean-cue-close','one-arm-clean','Проведи гирю близко к корпусу.',2),
 ('clean-cue-soft','one-arm-clean','Прими гирю мягко на предплечье у плеча.',3);

INSERT INTO exercise_anatomy_zones(exercise_id,zone_code,role) VALUES
 ('one-arm-clean','glutes','primary'),
 ('one-arm-clean','abdominals','secondary'),
 ('one-arm-clean','deltoids','secondary');

INSERT INTO exercise_sources(
    id,exercise_id,organization,title,url,source_type,accessed_at)
VALUES
 ('clean-src-ace','one-arm-clean','American Council on Exercise',
  'Clean and Press',
  'https://www.acefitness.org/resources/everyone/exercise-library/383/clean-and-press/',
  'professional_standard','2026-07-23'),
 ('clean-src-nasm','one-arm-clean','National Academy of Sports Medicine',
  'Off the Mat Training for Martial Arts',
  'https://blog.nasm.org/mma/off-the-mat-training-for-martial-arts',
  'professional_standard','2026-07-23'),
 ('clean-src-emg','one-arm-clean','PubMed',
  'Electromyographical Comparison of Muscle Activation Patterns Across Three Commonly Performed Kettlebell Exercises',
  'https://pubmed.ncbi.nlm.nih.gov/28394829/',
  'research','2026-07-23');

INSERT INTO source_supports(source_id,target_kind,phase_id,cue_id,zone_code,claim_path) VALUES
 ('clean-src-ace','phase','clean-hike',NULL,NULL,'phase.clean-hike.technique'),
 ('clean-src-ace','phase','clean-rack',NULL,NULL,'phase.clean-rack.technique'),
 ('clean-src-nasm','phase','clean-rack',NULL,NULL,'phase.clean-rack.independent-check'),
 ('clean-src-ace','cue',NULL,'clean-cue-hips',NULL,'cue.clean-hips'),
 ('clean-src-ace','cue',NULL,'clean-cue-close',NULL,'cue.clean-close'),
 ('clean-src-nasm','cue',NULL,'clean-cue-soft',NULL,'cue.clean-soft'),
 ('clean-src-emg','anatomy',NULL,NULL,'glutes','anatomy.glutes'),
 ('clean-src-emg','anatomy',NULL,NULL,'abdominals','anatomy.abdominals'),
 ('clean-src-emg','anatomy',NULL,NULL,'deltoids','anatomy.deltoids');

COMMIT;

SELECT * FROM fn_publication_checklist('one-arm-clean') ORDER BY rule_no;
SELECT fn_can_publish('one-arm-clean');
