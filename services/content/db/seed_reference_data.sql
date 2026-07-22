-- Справочники, необходимые кандидатам и генератору мобильного каталога.
-- В отличие от seed_example.sql этот файл не создаёт демонстрационное упражнение.

INSERT INTO figure_styles(id,kind,is_approved,description) VALUES
 ('approved-athlete-v1','athlete',TRUE,'Утверждённый стиль основной фигуры'),
 ('approved-anatomy-v1','anatomy',TRUE,'Утверждённый стиль карты зон');

INSERT INTO anatomy_zones(code,name_en,name_ru,region) VALUES
 ('glutes','Glutes','Ягодичные','lower'),
 ('hamstrings','Hamstrings','Бицепс бедра','lower'),
 ('lower_back','Lower Back','Поясница','core'),
 ('lats','Latissimus Dorsi','Широчайшие','upper');
