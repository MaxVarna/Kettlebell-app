BEGIN;
INSERT INTO anatomy_zones(code,name_en,name_ru,region) VALUES ('abdominals','Abdominals','Мышцы живота','core'),('deltoids','Deltoids','Дельтовидные','upper') ON CONFLICT(code) DO NOTHING;
INSERT INTO exercises(id,name,movement_kind,laterality,experience,style_id,anatomy_style_id,anatomy_status,review_technique,review_phases,review_visuals,review_anatomy,reviewer,reviewed_at,review_notes) VALUES ('kettlebell-halo','Гало с гирей','grind','bilateral','advanced','approved-athlete-v1','approved-anatomy-v1','reviewed','source_checked','draft','generated','reviewed','content-pipeline','2026-07-23T00:00:00Z','Три storyboard-фазы сгенерированы; ожидают проверки владельцем и landmark gate.');
INSERT INTO exercise_aliases VALUES ('kettlebell-halo','Kettlebell Halo'),('kettlebell-halo','Гало');
INSERT INTO exercise_phases(id,exercise_id,phase_order,short_name,technique,body_orientation,support,kettlebell_position,body_position,feet_baseline,scale,visual_status) VALUES
 ('halo-front','kettlebell-halo',1,'Перед грудью','Удерживать гирю за дужки перед верхней частью груди.','three_quarter','bilateral','Перед грудью, двумя руками за дужки.','Стойка устойчивая, корпус вертикален.',0.100,1.000,'generated'),
 ('halo-right','kettlebell-halo',2,'Справа за головой','Провести гирю близко вокруг правой стороны головы, сгибая локти.','three_quarter','bilateral','Позади правой стороны головы.','Корпус и таз остаются неподвижными.',0.100,1.000,'generated'),
 ('halo-left','kettlebell-halo',3,'Слева за головой','Продолжить круг за левой стороной головы и вернуть гирю вперёд.','three_quarter','bilateral','Позади левой стороны головы.','Корпус остаётся собранным и вертикальным.',0.100,1.000,'generated');
INSERT INTO phase_assets VALUES
 ('halo-front','male','assets/movements/halo-front-male-generated-v1.png'),('halo-right','male','assets/movements/halo-right-male-generated-v1.png'),('halo-left','male','assets/movements/halo-left-male-generated-v1.png'),
 ('halo-front','female','assets/movements/halo-front-female-generated-v1.png'),('halo-right','female','assets/movements/halo-right-female-generated-v1.png'),('halo-left','female','assets/movements/halo-left-female-generated-v1.png');
UPDATE exercises SET thumbnail_phase_id='halo-front' WHERE id='kettlebell-halo';
INSERT INTO exercise_cues VALUES ('halo-cue-close','kettlebell-halo','Веди гирю близко вокруг головы, не двигая корпусом.',1);
INSERT INTO exercise_anatomy_zones VALUES ('kettlebell-halo','deltoids','primary'),('kettlebell-halo','abdominals','secondary');
INSERT INTO exercise_sources VALUES ('halo-src-ace','kettlebell-halo','American Council on Exercise','Halo','https://www.acefitness.org/resources/everyone/exercise-library/394/halo/','professional_standard','2026-07-23');
INSERT INTO source_supports(source_id,target_kind,phase_id,cue_id,zone_code,claim_path) VALUES
 ('halo-src-ace','phase','halo-front',NULL,NULL,'phase.halo-front'),('halo-src-ace','phase','halo-right',NULL,NULL,'phase.halo-right'),('halo-src-ace','phase','halo-left',NULL,NULL,'phase.halo-left'),('halo-src-ace','cue',NULL,'halo-cue-close',NULL,'cue.halo-close'),('halo-src-ace','anatomy',NULL,NULL,'deltoids','anatomy.deltoids'),('halo-src-ace','anatomy',NULL,NULL,'abdominals','anatomy.abdominals');
COMMIT;
