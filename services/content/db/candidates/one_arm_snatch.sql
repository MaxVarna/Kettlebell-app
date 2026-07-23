-- Рывок гири одной рукой: замах, подрыв с продеванием кисти и фиксация.
BEGIN;

INSERT INTO anatomy_zones(code,name_en,name_ru,region) VALUES
 ('glutes','Gluteal muscles','Ягодичные мышцы','lower'),('abdominals','Abdominals','Мышцы живота','core'),('deltoids','Deltoids','Дельтовидные','upper')
ON CONFLICT (code) DO NOTHING;

INSERT INTO exercises(id,name,movement_kind,laterality,experience,style_id,anatomy_style_id,anatomy_asset,anatomy_status,review_technique,review_phases,review_visuals,review_anatomy,reviewer,reviewed_at,review_notes)
VALUES ('one-arm-snatch','Рывок гири одной рукой','ballistic','unilateral','advanced','approved-athlete-v1','approved-anatomy-v1','assets/movements/swing-zones-approved-v3.png','reviewed','source_checked','reviewed','reviewed','reviewed','content-pipeline','2026-07-23T00:00:00Z','Трёхфазная запись правой рукой; промежуточный кадр показывает близкую траекторию и продевание кисти.');

INSERT INTO exercise_aliases(exercise_id,alias) VALUES
 ('one-arm-snatch','Рывок гири'),('one-arm-snatch','Single-Arm Kettlebell Snatch');

INSERT INTO exercise_phases(id,exercise_id,phase_order,short_name,technique,body_orientation,support,kettlebell_position,body_position,feet_baseline,scale,visual_status) VALUES
 ('snatch-hike','one-arm-snatch',1,'Замах','Отвести таз назад и провести гирю правой рукой между бёдрами, сохраняя длинную руку и нейтральную спину.','three_quarter','bilateral','Между бёдрами в правой руке; ядро направлено назад по дуге.','Стопы устойчивы; таз отведён назад; корпус собран; плечи ровные.',0.100,1.000,'reviewed'),
 ('snatch-insertion','one-arm-snatch',2,'Подрыв','Мощно разогнуть таз, провести гирю близко к корпусу и направить локоть вверх, начиная продевание кисти в рукоять.','three_quarter','bilateral','Близко к корпусу на уровне груди; правый локоть ведёт движение, гиря не уходит далеко вперёд.','Таз почти разогнут; корпус вертикален; свободная рука уравновешивает движение.',0.100,1.000,'reviewed'),
 ('snatch-lockout','one-arm-snatch',3,'Фиксация','Продеть кисть в рукоять и мягко зафиксировать гирю над правым плечом на прямой руке.','three_quarter','bilateral','Над правым плечом; гиря лежит за нейтральным запястьем, локоть полностью контролируемо разогнут.','Стопы на полу; колени и таз разогнуты; рёбра над тазом; плечевой пояс устойчив.',0.100,1.000,'reviewed');

INSERT INTO phase_assets(phase_id,figure_variant,asset_url) VALUES
 ('snatch-hike','male','assets/movements/clean-press-low-coherent-anchored-v1.png'),('snatch-insertion','male','assets/movements/snatch-high-pull-male-anchored-v1.png'),('snatch-lockout','male','assets/movements/clean-press-overhead-coherent-anchored-v1.png'),
 ('snatch-hike','female','assets/movements/clean-press-low-female-anchored-v3.png'),('snatch-insertion','female','assets/movements/snatch-insertion-female-anchored-v2.png'),('snatch-lockout','female','assets/movements/clean-press-overhead-female-anchored-v2.png');
UPDATE exercises SET thumbnail_phase_id='snatch-lockout' WHERE id='one-arm-snatch';

INSERT INTO exercise_cues(id,exercise_id,text,sort_order) VALUES
 ('snatch-cue-hips','one-arm-snatch','Разгоняй гирю разгибанием таза.',1),
 ('snatch-cue-close','one-arm-snatch','Проводи гирю близко к корпусу.',2),
 ('snatch-cue-punch','one-arm-snatch','Продень кисть в рукоять и мягко поймай гирю сверху.',3);

INSERT INTO exercise_anatomy_zones(exercise_id,zone_code,role) VALUES
 ('one-arm-snatch','glutes','primary'),('one-arm-snatch','deltoids','primary'),('one-arm-snatch','abdominals','secondary');

INSERT INTO exercise_sources(id,exercise_id,organization,title,url,source_type,accessed_at) VALUES
 ('snatch-src-ace','one-arm-snatch','American Council on Exercise','Metabolic Conditioning: Kettlebell Complex','https://www.acefitness.org/resources/pros/expert-articles/5651/metabolic-conditioning-kettlebell-complex/','professional_standard','2026-07-23'),
 ('snatch-src-ace-shape','one-arm-snatch','American Council on Exercise','How to Do the Kettlebell Snatch','https://www.acefitness.org/about-ace/press-room/in-the-news/8250/how-to-do-the-kettlebell-snatch-to-feel-totally-powerful-shape/','professional_standard','2026-07-23'),
 ('snatch-src-emg','one-arm-snatch','PubMed','A Comparison of Muscle Activation Between the Kettlebell Swing, Snatch and Bottoms-Up Carry','https://pubmed.ncbi.nlm.nih.gov/28394829/','research','2026-07-23');

INSERT INTO source_supports(source_id,target_kind,phase_id,cue_id,zone_code,claim_path) VALUES
 ('snatch-src-ace','phase','snatch-hike',NULL,NULL,'phase.snatch-hike.technique'),('snatch-src-ace','phase','snatch-insertion',NULL,NULL,'phase.snatch-insertion.technique'),('snatch-src-ace-shape','phase','snatch-lockout',NULL,NULL,'phase.snatch-lockout.technique'),
 ('snatch-src-ace','cue',NULL,'snatch-cue-hips',NULL,'cue.snatch-hips'),('snatch-src-ace','cue',NULL,'snatch-cue-close',NULL,'cue.snatch-close'),('snatch-src-ace-shape','cue',NULL,'snatch-cue-punch',NULL,'cue.snatch-punch'),
 ('snatch-src-emg','anatomy',NULL,NULL,'glutes','anatomy.glutes'),('snatch-src-emg','anatomy',NULL,NULL,'deltoids','anatomy.deltoids'),('snatch-src-emg','anatomy',NULL,NULL,'abdominals','anatomy.abdominals');
COMMIT;
SELECT * FROM fn_publication_checklist('one-arm-snatch') ORDER BY rule_no;
SELECT fn_can_publish('one-arm-snatch');
