-- Пример: двуручный мах (2 фазы). Демонстрирует полный ExerciseRecord v2.

INSERT INTO figure_styles(id,kind,is_approved,description) VALUES
 ('approved-athlete-v1','athlete',TRUE,'Утверждённый стиль основной фигуры'),
 ('approved-anatomy-v1','anatomy',TRUE,'Утверждённый стиль карты зон');

INSERT INTO anatomy_zones(code,name_en,name_ru,region) VALUES
 ('glutes','Glutes','Ягодичные','lower'),
 ('hamstrings','Hamstrings','Бицепс бедра','lower'),
 ('lower_back','Lower Back','Поясница','core'),
 ('lats','Latissimus Dorsi','Широчайшие','upper');

INSERT INTO exercises(id,name,movement_kind,laterality,experience,
    style_id,anatomy_style_id,anatomy_asset,anatomy_status,
    review_technique,review_phases,review_visuals,review_anatomy,reviewer,reviewed_at)
VALUES ('two-hand-swing','Двуручный мах','ballistic','bilateral','basic',
    'approved-athlete-v1','approved-anatomy-v1','anatomy/two-hand-swing.svg','reviewed',
    'source_checked','reviewed','reviewed','reviewed','coach','2026-07-22T10:00:00Z');

INSERT INTO exercise_aliases(exercise_id,alias) VALUES
 ('two-hand-swing','Russian Swing'),('two-hand-swing','Гиревой мах');

INSERT INTO exercise_phases(id,exercise_id,phase_order,short_name,technique,
    body_orientation,support,kettlebell_position,body_position,feet_baseline,scale,visual_status)
VALUES
 ('swing-hike','two-hand-swing',1,'Заброс','Гиря заводится назад за бёдра, спина нейтральна',
  'side','bilateral','между ног, сзади','таз отведён назад, шарнир',0.100,1.000,'reviewed'),
 ('swing-float','two-hand-swing',2,'Полёт','Мощное разгибание таза выносит гирю до уровня груди',
  'side','bilateral','на уровне груди, руки прямые','полное разгибание таза и колен',0.100,1.000,'reviewed');

INSERT INTO phase_assets(phase_id,figure_variant,asset_url) VALUES
 ('swing-hike','male','assets/male/swing-hike.png'),
 ('swing-hike','female','assets/female/swing-hike.png'),
 ('swing-float','male','assets/male/swing-float.png'),
 ('swing-float','female','assets/female/swing-float.png');

UPDATE exercises SET thumbnail_phase_id='swing-float' WHERE id='two-hand-swing';

INSERT INTO exercise_cues(id,exercise_id,text,sort_order) VALUES
 ('cue-hip-drive','two-hand-swing','Разгоняй гирю тазом, а не руками',1),
 ('cue-neutral-spine','two-hand-swing','Держи нейтральную спину на всей траектории',2);

INSERT INTO exercise_anatomy_zones(exercise_id,zone_code,role) VALUES
 ('two-hand-swing','glutes','primary'),
 ('two-hand-swing','hamstrings','primary'),
 ('two-hand-swing','lower_back','secondary'),
 ('two-hand-swing','lats','secondary');

INSERT INTO exercise_sources(id,exercise_id,organization,title,url,source_type,accessed_at) VALUES
 ('src-sf-7moves','two-hand-swing','StrongFirst','The Seven Basic Human Movements',
  'https://www.strongfirst.com/seven-basic-human-movements/','professional_standard','2026-07-22'),
 ('src-sf-swing','two-hand-swing','StrongFirst','Swing Versus Snatch',
  'https://www.strongfirst.com/swing-versus-snatch/','professional_standard','2026-07-22');

-- Привязка источников к конкретным утверждениям (supports)
INSERT INTO source_supports(source_id,target_kind,phase_id,cue_id,zone_code,claim_path) VALUES
 ('src-sf-swing','cue',NULL,'cue-hip-drive',NULL,'cue.hip-drive'),
 ('src-sf-swing','cue',NULL,'cue-neutral-spine',NULL,'cue.neutral-spine'),
 ('src-sf-swing','phase','swing-hike',NULL,NULL,'phase.swing-hike.bodyPosition'),
 ('src-sf-7moves','anatomy',NULL,NULL,'glutes','anatomy.glutes'),
 ('src-sf-7moves','anatomy',NULL,NULL,'hamstrings','anatomy.hamstrings');
