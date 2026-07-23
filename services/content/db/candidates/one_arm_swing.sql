-- Свинг гири одной рукой: замах и свободный вылет до уровня груди.
BEGIN;

INSERT INTO anatomy_zones(code,name_en,name_ru,region) VALUES
 ('glutes','Gluteal muscles','Ягодичные мышцы','lower'),('abdominals','Abdominals','Мышцы живота','core'),('deltoids','Deltoids','Дельтовидные','upper')
ON CONFLICT (code) DO NOTHING;

INSERT INTO exercises(id,name,movement_kind,laterality,experience,style_id,anatomy_style_id,anatomy_asset,anatomy_status,review_technique,review_phases,review_visuals,review_anatomy,reviewer,reviewed_at,review_notes)
VALUES ('one-arm-swing','Свинг гири одной рукой','ballistic','unilateral','intermediate','approved-athlete-v1','approved-anatomy-v1','assets/movements/swing-zones-approved-v3.png','reviewed','source_checked','reviewed','reviewed','reviewed','content-pipeline','2026-07-23T00:00:00Z','Правый рабочий вариант; кадры согласованы по росту фигуры и уровню стоп, а не по внешнему bbox гири.');

INSERT INTO exercise_aliases(exercise_id,alias) VALUES
 ('one-arm-swing','Одноручный свинг'),('one-arm-swing','Single-Arm Kettlebell Swing');

INSERT INTO exercise_phases(id,exercise_id,phase_order,short_name,technique,body_orientation,support,kettlebell_position,body_position,feet_baseline,scale,visual_status) VALUES
 ('one-swing-hike','one-arm-swing',1,'Замах','Отвести таз назад и направить гирю правой рукой высоко между бёдрами, сохраняя длинную руку и нейтральную спину.','three_quarter','bilateral','Между бёдрами в правой руке; ядро продолжает дугу назад.','Стопы устойчивы; голени почти вертикальны; таз отведён назад; плечи остаются ровными.',0.100,1.000,'reviewed'),
 ('one-swing-float','one-arm-swing',2,'Вылет','Резко разогнуть таз и дать гире свободно вылететь на длинной правой руке примерно до уровня груди.','three_quarter','bilateral','Перед корпусом на уровне нижней части груди; рукоять продолжает дугу движения.','Таз и колени разогнуты; рёбра над тазом; свободная левая рука уравновешивает движение.',0.100,1.000,'reviewed');

INSERT INTO phase_assets(phase_id,figure_variant,asset_url) VALUES
 ('one-swing-hike','male','assets/movements/clean-press-low-coherent-anchored-v1.png'),('one-swing-float','male','assets/movements/one-arm-swing-float-male-anchored-v1.png'),
 ('one-swing-hike','female','assets/movements/clean-press-low-female-anchored-v3.png'),('one-swing-float','female','assets/movements/one-arm-swing-float-female-anchored-v1.png');
UPDATE exercises SET thumbnail_phase_id='one-swing-float' WHERE id='one-arm-swing';

INSERT INTO exercise_cues(id,exercise_id,text,sort_order) VALUES
 ('one-swing-cue-hinge','one-arm-swing','Двигай гирю разгибанием таза, а не подъёмом плеча.',1),
 ('one-swing-cue-square','one-arm-swing','Не разворачивай корпус вслед за гирей.',2),
 ('one-swing-cue-arc','one-arm-swing','Позволь гире лететь по дуге на длинной руке.',3);

INSERT INTO exercise_anatomy_zones(exercise_id,zone_code,role) VALUES
 ('one-arm-swing','glutes','primary'),('one-arm-swing','abdominals','secondary'),('one-arm-swing','deltoids','secondary');

INSERT INTO exercise_sources(id,exercise_id,organization,title,url,source_type,accessed_at) VALUES
 ('one-swing-src-nasm','one-arm-swing','National Academy of Sports Medicine','How Kettlebell Workouts Can Take Your Fitness to the Next Level','https://blog.nasm.org/how-kettlebell-workouts-can-take-your-fitness-to-the-next-level','professional_standard','2026-07-23'),
 ('one-swing-src-ace','one-arm-swing','American Council on Exercise','How to Get Started With Kettlebells','https://www.acefitness.org/resources/pros/expert-articles/5269/how-to-get-started-with-kettlebells/','professional_standard','2026-07-23'),
 ('one-swing-src-emg','one-arm-swing','PubMed','A Comparison of Muscle Activation Between the Kettlebell Swing, Snatch and Bottoms-Up Carry','https://pubmed.ncbi.nlm.nih.gov/28394829/','research','2026-07-23');

INSERT INTO source_supports(source_id,target_kind,phase_id,cue_id,zone_code,claim_path) VALUES
 ('one-swing-src-nasm','phase','one-swing-hike',NULL,NULL,'phase.one-swing-hike.technique'),('one-swing-src-ace','phase','one-swing-float',NULL,NULL,'phase.one-swing-float.technique'),
 ('one-swing-src-ace','cue',NULL,'one-swing-cue-hinge',NULL,'cue.one-swing-hinge'),('one-swing-src-nasm','cue',NULL,'one-swing-cue-square',NULL,'cue.one-swing-square'),('one-swing-src-ace','cue',NULL,'one-swing-cue-arc',NULL,'cue.one-swing-arc'),
 ('one-swing-src-emg','anatomy',NULL,NULL,'glutes','anatomy.glutes'),('one-swing-src-emg','anatomy',NULL,NULL,'abdominals','anatomy.abdominals'),('one-swing-src-emg','anatomy',NULL,NULL,'deltoids','anatomy.deltoids');
COMMIT;
SELECT * FROM fn_publication_checklist('one-arm-swing') ORDER BY rule_no;
SELECT fn_can_publish('one-arm-swing');
