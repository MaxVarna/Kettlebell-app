-- Обратный выпад с гирей у груди: стойка и шаг назад.
BEGIN;

INSERT INTO anatomy_zones(code,name_en,name_ru,region) VALUES
 ('quadriceps','Quadriceps','Квадрицепсы','lower'),('glutes','Gluteal muscles','Ягодичные мышцы','lower'),('hamstrings','Hamstrings','Задняя поверхность бедра','lower')
ON CONFLICT (code) DO NOTHING;

INSERT INTO exercises(id,name,movement_kind,laterality,experience,style_id,anatomy_style_id,anatomy_asset,anatomy_status,review_technique,review_phases,review_visuals,review_anatomy,reviewer,reviewed_at,review_notes)
VALUES ('goblet-reverse-lunge','Обратный выпад с гирей у груди','grind','alternating','basic','approved-athlete-v1','approved-anatomy-v1','assets/movements/goblet-lunge-zones-v2.png','reviewed','source_checked','reviewed','reviewed','reviewed','content-pipeline','2026-07-23T00:00:00Z','Стойка переиспользует утверждённый goblet hold; нижняя фаза создана отдельно и выровнена по стопам.');

INSERT INTO exercise_aliases(exercise_id,alias) VALUES
 ('goblet-reverse-lunge','Обратный выпад с гоблет-удержанием'),('goblet-reverse-lunge','Goblet Reverse Lunge');

INSERT INTO exercise_phases(id,exercise_id,phase_order,short_name,technique,body_orientation,support,kettlebell_position,body_position,feet_baseline,scale,visual_status) VALUES
 ('lunge-stand','goblet-reverse-lunge',1,'Стойка','Удерживать гирю двумя руками у груди в устойчивой вертикальной стойке.','three_quarter','bilateral','У верхней части груди, обе кисти удерживают рукоять по бокам.','Стопы под тазом; колени и таз разогнуты; рёбра расположены над тазом.',0.100,1.000,'reviewed'),
 ('lunge-bottom','goblet-reverse-lunge',2,'Выпад назад','Шагнуть правой ногой назад и опустить заднее колено к полу, сохраняя опору на всей передней стопе.','three_quarter','transition','У груди; гиря не меняет положение относительно корпуса.','Переднее колено следует направлению носка; задняя пятка поднята; корпус собран и почти вертикален.',0.100,1.000,'reviewed');

INSERT INTO phase_assets(phase_id,figure_variant,asset_url) VALUES
 ('lunge-stand','male','assets/movements/goblet-squat-standing-anchored-v1.png'),('lunge-bottom','male','assets/movements/reverse-lunge-bottom-male-anchored-v1.png'),
 ('lunge-stand','female','assets/movements/goblet-squat-standing-female-anchored-v2.png'),('lunge-bottom','female','assets/movements/reverse-lunge-bottom-female-anchored-v1.png');
UPDATE exercises SET thumbnail_phase_id='lunge-bottom' WHERE id='goblet-reverse-lunge';

INSERT INTO exercise_cues(id,exercise_id,text,sort_order) VALUES
 ('lunge-cue-step','goblet-reverse-lunge','Шагай назад достаточно далеко для устойчивой опоры.',1),
 ('lunge-cue-foot','goblet-reverse-lunge','Оставляй переднюю стопу полностью на полу.',2),
 ('lunge-cue-torso','goblet-reverse-lunge','Держи корпус собранным и почти вертикальным.',3);

INSERT INTO exercise_anatomy_zones(exercise_id,zone_code,role) VALUES
 ('goblet-reverse-lunge','quadriceps','primary'),('goblet-reverse-lunge','glutes','primary'),('goblet-reverse-lunge','hamstrings','secondary');

INSERT INTO exercise_sources(id,exercise_id,organization,title,url,source_type,accessed_at) VALUES
 ('lunge-src-nasm','goblet-reverse-lunge','National Academy of Sports Medicine','How Kettlebell Workouts Can Take Your Fitness to the Next Level','https://blog.nasm.org/how-kettlebell-workouts-can-take-your-fitness-to-the-next-level','professional_standard','2026-07-23'),
 ('lunge-src-ace','goblet-reverse-lunge','American Council on Exercise','Metabolic Conditioning: Kettlebell Complex','https://www.acefitness.org/resources/pros/expert-articles/5651/metabolic-conditioning-kettlebell-complex/','professional_standard','2026-07-23'),
 ('lunge-src-research','goblet-reverse-lunge','Applied Sciences','Effects of Forward and Backward Lunges on Lower-Limb Muscle Activation','https://www.mdpi.com/2076-3417/14/24/11480','research','2026-07-23');

INSERT INTO source_supports(source_id,target_kind,phase_id,cue_id,zone_code,claim_path) VALUES
 ('lunge-src-nasm','phase','lunge-stand',NULL,NULL,'phase.lunge-stand.technique'),('lunge-src-ace','phase','lunge-bottom',NULL,NULL,'phase.lunge-bottom.technique'),
 ('lunge-src-ace','cue',NULL,'lunge-cue-step',NULL,'cue.lunge-step'),('lunge-src-research','cue',NULL,'lunge-cue-foot',NULL,'cue.lunge-foot'),('lunge-src-ace','cue',NULL,'lunge-cue-torso',NULL,'cue.lunge-torso'),
 ('lunge-src-research','anatomy',NULL,NULL,'quadriceps','anatomy.quadriceps'),('lunge-src-research','anatomy',NULL,NULL,'glutes','anatomy.glutes'),('lunge-src-research','anatomy',NULL,NULL,'hamstrings','anatomy.hamstrings');
COMMIT;
SELECT * FROM fn_publication_checklist('goblet-reverse-lunge') ORDER BY rule_no;
SELECT fn_can_publish('goblet-reverse-lunge');
