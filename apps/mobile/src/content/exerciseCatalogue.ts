export type ExerciseReviewStatus = 'pending_coach_review' | 'source_checked' | 'approved' | 'deferred';

export type ExerciseRecord = {
  id: string;
  name: string;
  movementKind: 'ballistic' | 'grind' | 'complex';
  keyPose: string;
  cueDrafts: readonly string[];
  zoneMap: readonly string[];
  sourceUrls: readonly string[];
  review: {
    status: ExerciseReviewStatus;
    reviewedAt?: string;
    reviewer?: string;
  };
  assets: {
    thumbnail?: string;
    runnerStatic?: string;
    zoneMap?: string;
    motionReady: boolean;
  };
};

/**
 * Editorial queue, deliberately separate from movements exposed in the builder.
 * Source-checked records are safe for the initial catalogue; a trainer can later add a deeper review.
 */
export const exerciseEditorialQueue: readonly ExerciseRecord[] = [
  {
    id: 'two-hand-swing',
    name: 'Двуручный свинг',
    movementKind: 'ballistic',
    keyPose: 'Верхняя позиция: стойка, длинные руки, гиря перед корпусом; спина нейтральна.',
    cueDrafts: ['Петля начинается от разгибания таза.', 'Сохраняй длинные руки и нейтральную спину.'],
    zoneMap: ['плечи', 'корпус', 'ягодицы'],
    sourceUrls: [
      'https://www.acefitness.org/resources/everyone/exercise-library/391/swing/',
      'https://www.nsca.com/education/articles/kinetic-select/two-arm-kettlebell-swing/',
      'https://pubmed.ncbi.nlm.nih.gov/26618061/',
      'https://pubmed.ncbi.nlm.nih.gov/30911671/',
    ],
    review: { status: 'source_checked' },
    assets: {
      thumbnail: 'assets/movements/swing-top.png',
      runnerStatic: 'assets/movements/swing-top.png',
      zoneMap: 'assets/movements/swing-zones-approved-v3.png',
      motionReady: false,
    },
  },
  {
    id: 'goblet-squat',
    name: 'Гоблет-присед',
    movementKind: 'grind',
    keyPose: 'Стойка: гиря двумя руками у груди, локти направлены вперёд; стопы примерно на ширине плеч.',
    cueDrafts: ['Опускайся через таз и колени, уводя таз назад.', 'Сохраняй опору на стопы при подъёме.'],
    zoneMap: ['квадрицепс', 'задняя поверхность бедра'],
    sourceUrls: [
      'https://www.acefitness.org/resources/pros/expert-articles/5269/how-to-get-started-with-kettlebells/',
      'https://pubmed.ncbi.nlm.nih.gov/34341315/',
    ],
    review: { status: 'source_checked' },
    assets: {
      thumbnail: 'assets/movements/goblet-squat-standing.png',
      runnerStatic: 'assets/movements/goblet-squat-standing.png',
      zoneMap: 'assets/movements/goblet-squat-zones.png',
      motionReady: false,
    },
  },
  {
    id: 'clean-and-press',
    name: 'Подъём с жимом',
    movementKind: 'complex',
    keyPose: 'Нижняя позиция, стойка с гирей у груди и фиксация над головой.',
    cueDrafts: ['Проведи гирю к груди и заверши движение устойчивой фиксацией над головой.'],
    zoneMap: [],
    sourceUrls: ['https://www.acefitness.org/resources/everyone/exercise-library/383/clean-and-press/'],
    review: { status: 'source_checked' },
    assets: {
      thumbnail: 'assets/movements/clean-press-rack-coherent-anchored-v1.png',
      runnerStatic: 'assets/movements/clean-press-rack-coherent-anchored-v1.png',
      motionReady: true,
    },
  },
  {
    id: 'kettlebell-deadlift',
    name: 'Становая тяга с гирей',
    movementKind: 'grind',
    keyPose: 'Гиря между стопами; спина нейтральна, движение начинается от таза.',
    cueDrafts: [
      'Отведи таз назад и держи спину нейтральной.',
      'Встань, одновременно разгибая колени и таз.',
      'В верхней точке стой прямо — не отклоняйся назад.',
    ],
    zoneMap: ['ягодицы', 'задняя поверхность бедра', 'квадрицепсы', 'разгибатели позвоночника'],
    sourceUrls: [
      'https://dxpprod.nsca.com/contentassets/b70b70c5cb96417bbc58d5b6756a689e/ptq-8.3.1-resistance-training-progressions-for-the-older-adult-deadlifts.pdf',
      'https://barbend.com/kettlebell-deadlift/',
      'https://doi.org/10.1371/journal.pone.0229507',
    ],
    review: { status: 'approved', reviewedAt: '2026-07-22T00:00:00Z', reviewer: 'owner' },
    assets: {
      thumbnail: 'assets/movements/kettlebell-deadlift-stand-male-anchored-v2.png',
      runnerStatic: 'assets/movements/kettlebell-deadlift-stand-male-anchored-v2.png',
      zoneMap: 'assets/movements/kettlebell-deadlift-zones-v1.png',
      motionReady: true,
    },
  },
];

export const catalogueExercises = exerciseEditorialQueue.filter(
  (exercise) =>
    (exercise.review.status === 'source_checked' || exercise.review.status === 'approved') &&
    Boolean(exercise.assets.thumbnail) &&
    Boolean(exercise.assets.runnerStatic),
);
