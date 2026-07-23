-- Тяга гири одной рукой в наклоне: нижняя точка и контролируемая тяга к тазу.
BEGIN;

INSERT INTO anatomy_zones(code,name_en,name_ru,region) VALUES
 ('latissimus','Latissimus dorsi','Широчайшие мышцы спины','upper'),
 ('biceps','Biceps','Бицепсы','upper'),
 ('abdominals','Abdominals','Мышцы живота','core')
ON CONFLICT (code) DO NOTHING;

INSERT INTO exercises(id,name,movement_kind,laterality,experience,style_id,anatomy_style_id,anatomy_asset,anatomy_status,review_technique,review_phases,review_visuals,review_anatomy,reviewer,reviewed_at,review_notes)
VALUES ('one-arm-row','Тяга гири в наклоне','grind','unilateral','basic','approved-athlete-v1','approved-anatomy-v1','assets/movements/one-arm-row-zones-v1.png','reviewed','source_checked','reviewed','reviewed','reviewed','content-pipeline','2026-07-23T00:00:00Z','Две фазы нормализованы по уровню стоп; финальная device-проверка владельцем ожидается.');

INSERT INTO exercise_aliases(exercise_id,alias) VALUES
 ('one-arm-row','Одноручная тяга гири в наклоне'),('one-arm-row','Single-Arm Kettlebell Row');

INSERT INTO exercise_phases(id,exercise_id,phase_order,short_name,technique,body_orientation,support,kettlebell_position,body_position,feet_baseline,scale,visual_status) VALUES
 ('row-low','one-arm-row',1,'Нижняя точка','Отвести таз назад, опереться свободной рукой о бедро и удерживать гирю на длинной правой руке под плечом.','three_quarter','bilateral','Под правым плечом; рука почти вертикальна, гиря не касается пола.','Стопы устойчивы; спина нейтральна; таз отведён назад; плечи остаются на одном уровне.',0.100,1.000,'reviewed'),
 ('row-pull','one-arm-row',2,'Тяга','Провести правый локоть назад и подтянуть гирю к правой стороне таза без разворота корпуса.','three_quarter','bilateral','Рядом с правой стороной корпуса на уровне нижних рёбер и таза.','Таз и корпус сохраняют положение; лопатка движется к позвоночнику; шея продолжает линию спины.',0.100,1.000,'reviewed');

INSERT INTO phase_assets(phase_id,figure_variant,asset_url) VALUES
 ('row-low','male','assets/movements/one-arm-row-low-male-anchored-v1.png'),('row-pull','male','assets/movements/one-arm-row-pull-male-anchored-v1.png'),
 ('row-low','female','assets/movements/one-arm-row-low-female-anchored-v1.png'),('row-pull','female','assets/movements/one-arm-row-pull-female-anchored-v1.png');
UPDATE exercises SET thumbnail_phase_id='row-pull' WHERE id='one-arm-row';

INSERT INTO exercise_cues(id,exercise_id,text,sort_order) VALUES
 ('row-cue-spine','one-arm-row','Сохраняй длинную нейтральную спину.',1),
 ('row-cue-elbow','one-arm-row','Веди локоть назад к тазу.',2),
 ('row-cue-square','one-arm-row','Не разворачивай плечи вслед за гирей.',3);

INSERT INTO exercise_anatomy_zones(exercise_id,zone_code,role) VALUES
 ('one-arm-row','latissimus','primary'),('one-arm-row','biceps','secondary'),('one-arm-row','abdominals','secondary');

INSERT INTO exercise_sources(id,exercise_id,organization,title,url,source_type,accessed_at) VALUES
 ('row-src-nasm','one-arm-row','National Academy of Sports Medicine','Kettlebell Workout','https://blog.nasm.org/kettlebell-workout','professional_standard','2026-07-23'),
 ('row-src-ace','one-arm-row','American Council on Exercise','Bent-over Row','https://www.acefitness.org/resources/everyone/exercise-library/12/bent-over-row/','professional_standard','2026-07-23'),
 ('row-src-ace-research','one-arm-row','American Council on Exercise','What Is the Best Back Exercise?','https://www.acefitness.org/continuing-education/certified/april-2018/6959/ace-sponsored-research-what-is-the-best-back-exercise/','research','2026-07-23');

INSERT INTO source_supports(source_id,target_kind,phase_id,cue_id,zone_code,claim_path) VALUES
 ('row-src-nasm','phase','row-low',NULL,NULL,'phase.row-low.technique'),('row-src-nasm','phase','row-pull',NULL,NULL,'phase.row-pull.technique'),
 ('row-src-ace','cue',NULL,'row-cue-spine',NULL,'cue.row-spine'),('row-src-nasm','cue',NULL,'row-cue-elbow',NULL,'cue.row-elbow'),('row-src-ace','cue',NULL,'row-cue-square',NULL,'cue.row-square'),
 ('row-src-ace-research','anatomy',NULL,NULL,'latissimus','anatomy.latissimus'),('row-src-ace-research','anatomy',NULL,NULL,'biceps','anatomy.biceps'),('row-src-ace','anatomy',NULL,NULL,'abdominals','anatomy.abdominals');
COMMIT;
SELECT * FROM fn_publication_checklist('one-arm-row') ORDER BY rule_no;
SELECT fn_can_publish('one-arm-row');

