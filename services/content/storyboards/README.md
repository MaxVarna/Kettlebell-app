# Storyboard production sources

Каждый каталог содержит мужской и женский прозрачный storyboard, manifest нарезки и JSON-отчёт сборки. Финальные фазы создаются `build_storyboard_motion_set.py` одним масштабом на весь набор и общей линией стоп.

Статус пяти наборов: `generated`, до ручного review владельцем и landmark-проверки публикация запрещена (`publish: false`).

## Prompt set v1

Все источники созданы встроенным ImageGen в режиме `scientific-educational` с локальными утверждёнными референсами:

- male: `apps/mobile/assets/movements/clean-press-rack-coherent-anchored-v1.png`;
- female: `apps/mobile/assets/movements/clean-press-rack-female-storyboard-anchored-v1.png`.

Общие инварианты: один и тот же персонаж во всех панелях; белая футболка, шорты и обувь; тонкая тёмно-синяя линия; оранжевая гиря `#F3AE2B`; одинаковая линия стоп; без текста, теней и обрезки. Генерация выполнялась на плоском зелёном фоне с последующим удалением chroma key.

Упражнения и фазы:

1. `halo`: гиря перед грудью → за правой стороной головы → за левой стороной головы.
2. `front-squat`: правая стойка с гирей → нижняя позиция фронтального приседа.
3. `high-windmill`: широкая вертикальная стойка с правой рукой над головой → наклон к левой ноге при неизменной рабочей руке.
4. `figure-eight`: гиря у левой ноги → передача между ног → гиря у правой ноги.
5. `bottom-up-press`: перевёрнутая гиря у правого плеча → перевёрнутая гиря над головой.

Технические источники поз:

- ACE Halo: https://www.acefitness.org/resources/everyone/exercise-library/394/halo/
- NASM Kettlebell Front Squat: https://www.nasm.org/resource-center/exercise-library/kettlebell-front-squat
- ACE High Windmill: https://www.acefitness.org/resources/everyone/exercise-library/386/high-windmill/
- ACE Figure Eight: https://www.acefitness.org/resources/everyone/exercise-library/382/figure-eight/
- ACE Bottom-up Press: https://www.acefitness.org/resources/everyone/exercise-library/396/bottom-up-press/
