-- Двуручный свинг: динамический замах назад и поздняя фаза подъёма.
-- Требует schema.sql и seed_reference_data.sql.

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
    'two-hand-swing','Двуручный свинг','ballistic','bilateral','basic',
    'approved-athlete-v1','approved-anatomy-v1',
    'assets/movements/swing-zones-approved-v3.png','approved',
    'source_checked','approved','approved','approved',
    'owner','2026-07-23T00:00:00Z',
    'Мужская и женская пары проверены владельцем; исправлены динамический замах и ориентация гири в поздней фазе подъёма.'
);

INSERT INTO exercise_aliases(exercise_id,alias) VALUES
 ('two-hand-swing','Гиревой свинг'),
 ('two-hand-swing','Two-Hand Kettlebell Swing');

INSERT INTO exercise_phases(
    id,exercise_id,phase_order,short_name,technique,
    body_orientation,support,kettlebell_position,body_position,
    feet_baseline,scale,visual_status)
VALUES
 ('swing-hike','two-hand-swing',1,'Замах назад',
  'Сохраняя длинные руки и нейтральный позвоночник, отвести таз назад и провести гирю между бёдрами за вертикальную линию тела.',
  'three_quarter','bilateral',
  'За линией коленей между бёдрами; ядро продолжает дугу назад, рукоять удерживается двумя руками.',
  'Стопы устойчивы; колени мягко согнуты; таз отведён назад; голени близки к вертикали; корпус длинный и нейтральный.',
  0.100,1.000,'approved'),
 ('swing-float','two-hand-swing',2,'Подъём',
  'Разогнуть таз и колени, направляя гирю вперёд и вверх по дуге без подъёма руками и без отклонения корпуса назад.',
  'three_quarter','bilateral',
  'На позднем участке дуги перед корпусом; ядро находится дальше от корпуса, чем кисти, и не висит вертикально под рукоятью.',
  'Стопы остаются на полу; таз и колени разогнуты; руки длинные; корпус и голова нейтральны.',
  0.100,1.000,'approved');

INSERT INTO phase_assets(phase_id,figure_variant,asset_url) VALUES
 ('swing-hike','male','assets/movements/swing-hike-male-anchored-v2.png'),
 ('swing-float','male','assets/movements/swing-float-male-anchored-v2.png'),
 ('swing-hike','female','assets/movements/swing-hike-female-anchored-v2.png'),
 ('swing-float','female','assets/movements/swing-float-female-anchored-v2.png');

UPDATE exercises SET thumbnail_phase_id='swing-float' WHERE id='two-hand-swing';

INSERT INTO exercise_cues(id,exercise_id,text,sort_order) VALUES
 ('swing-cue-hips','two-hand-swing','Разгоняй гирю разгибанием таза, а не руками.',1),
 ('swing-cue-spine','two-hand-swing','Сохраняй нейтральную спину и длинные руки.',2),
 ('swing-cue-finish','two-hand-swing','Заверши разгибание таза без отклонения назад.',3);

INSERT INTO exercise_anatomy_zones(exercise_id,zone_code,role) VALUES
 ('two-hand-swing','glutes','primary'),
 ('two-hand-swing','abdominals','secondary'),
 ('two-hand-swing','deltoids','secondary');

INSERT INTO exercise_sources(
    id,exercise_id,organization,title,url,source_type,accessed_at)
VALUES
 ('swing-src-nsca','two-hand-swing','NSCA',
  'Two-Arm Kettlebell Swing',
  'https://www.nsca.com/education/articles/kinetic-select/two-arm-kettlebell-swing/',
  'professional_standard','2026-07-23'),
 ('swing-src-ace','two-hand-swing','American Council on Exercise',
  'Do it Better: The Two-handed Kettlebell Swing',
  'https://www.acefitness.org/continuing-education/prosource/october-2015/5635/do-it-better-ace-s-technique-series-continues-with-the-two-handed-kettlebell-swing/',
  'professional_standard','2026-07-23'),
 ('swing-src-emg','two-hand-swing','PubMed',
  'EMG Analysis and Sagittal Plane Kinematics of the Two-Handed and Single-Handed Kettlebell Swing',
  'https://pubmed.ncbi.nlm.nih.gov/26618061/',
  'research','2026-07-23'),
 ('swing-src-trunk','two-hand-swing','PubMed',
  'Asymmetry of muscle co-activation during the two-armed kettlebell swing',
  'https://pubmed.ncbi.nlm.nih.gov/41487958/',
  'research','2026-07-23');

INSERT INTO source_supports(source_id,target_kind,phase_id,cue_id,zone_code,claim_path) VALUES
 ('swing-src-nsca','phase','swing-hike',NULL,NULL,'phase.swing-hike.technique'),
 ('swing-src-nsca','phase','swing-float',NULL,NULL,'phase.swing-float.technique'),
 ('swing-src-ace','phase','swing-hike',NULL,NULL,'phase.swing-hike.independent-check'),
 ('swing-src-ace','phase','swing-float',NULL,NULL,'phase.swing-float.independent-check'),
 ('swing-src-nsca','cue',NULL,'swing-cue-hips',NULL,'cue.swing-hips'),
 ('swing-src-ace','cue',NULL,'swing-cue-hips',NULL,'cue.swing-hips-independent-check'),
 ('swing-src-nsca','cue',NULL,'swing-cue-spine',NULL,'cue.swing-spine'),
 ('swing-src-nsca','cue',NULL,'swing-cue-finish',NULL,'cue.swing-finish'),
 ('swing-src-emg','anatomy',NULL,NULL,'glutes','anatomy.glutes'),
 ('swing-src-trunk','anatomy',NULL,NULL,'abdominals','anatomy.abdominals'),
 ('swing-src-trunk','anatomy',NULL,NULL,'deltoids','anatomy.deltoids');

COMMIT;

SELECT * FROM fn_publication_checklist('two-hand-swing') ORDER BY rule_no;
SELECT fn_can_publish('two-hand-swing');
