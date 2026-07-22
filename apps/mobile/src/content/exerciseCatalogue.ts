import type { ImageSourcePropType } from 'react-native';
import { generatedExerciseRecords, generatedExerciseVisuals } from './generated/exerciseCatalogue.generated';
import type { ExerciseRecordV2, ExerciseVisualSet, FigureVariant } from './exerciseCatalogue.types';

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
  sourceRecord?: ExerciseRecordV2;
};

const legacyExerciseVisuals: Readonly<Record<string, ExerciseVisualSet>> = {
  'two-hand-swing': {
    thumbnail: {
      male: require('../../assets/movements/swing-top-anchored-v1.png'),
      female: require('../../assets/movements/swing-top-anchored-v1.png'),
    },
    frames: {
      male: [require('../../assets/movements/swing-bottom-anchored-v1.png'), require('../../assets/movements/swing-top-anchored-v1.png')],
      female: [require('../../assets/movements/swing-bottom-anchored-v1.png'), require('../../assets/movements/swing-top-anchored-v1.png')],
    },
    anatomy: require('../../assets/movements/swing-zones-approved-v3.png'),
  },
  'goblet-squat': {
    thumbnail: {
      male: require('../../assets/movements/goblet-squat-standing-anchored-v1.png'),
      female: require('../../assets/movements/goblet-squat-standing-anchored-v1.png'),
    },
    frames: {
      male: [require('../../assets/movements/goblet-squat-standing-anchored-v1.png'), require('../../assets/movements/goblet-squat-bottom-anchored-v1.png')],
      female: [require('../../assets/movements/goblet-squat-standing-anchored-v1.png'), require('../../assets/movements/goblet-squat-bottom-anchored-v1.png')],
    },
    anatomy: require('../../assets/movements/goblet-squat-zones.png'),
  },
  'clean-and-press': {
    thumbnail: {
      male: require('../../assets/movements/clean-press-rack-coherent-anchored-v1.png'),
      female: require('../../assets/movements/clean-press-rack-coherent-anchored-v1.png'),
    },
    frames: {
      male: [
        require('../../assets/movements/clean-press-low-coherent-anchored-v1.png'),
        require('../../assets/movements/clean-press-rack-coherent-anchored-v1.png'),
        require('../../assets/movements/clean-press-overhead-coherent-anchored-v1.png'),
      ],
      female: [
        require('../../assets/movements/clean-press-low-coherent-anchored-v1.png'),
        require('../../assets/movements/clean-press-rack-coherent-anchored-v1.png'),
        require('../../assets/movements/clean-press-overhead-coherent-anchored-v1.png'),
      ],
    },
  },
};

const exerciseVisuals: Readonly<Record<string, ExerciseVisualSet>> = {
  ...legacyExerciseVisuals,
  ...generatedExerciseVisuals,
};

const fallbackVisual = legacyExerciseVisuals['two-hand-swing']!;

export const exerciseThumbnail = (exerciseId: string, variant: FigureVariant): ImageSourcePropType => {
  const visual = exerciseVisuals[exerciseId] ?? fallbackVisual;
  return visual.thumbnail[variant] ?? visual.thumbnail.male;
};

export const exerciseFrames = (exerciseId: string, variant: FigureVariant): readonly ImageSourcePropType[] => {
  const visual = exerciseVisuals[exerciseId] ?? fallbackVisual;
  return visual.frames[variant] ?? visual.frames.male;
};

export const exerciseAnatomy = (exerciseId: string): ImageSourcePropType | null =>
  exerciseVisuals[exerciseId]?.anatomy ?? null;

const publishedExerciseRecords: readonly ExerciseRecordV2[] = generatedExerciseRecords;

const generatedEditorialQueue: readonly ExerciseRecord[] = publishedExerciseRecords.map((record) => {
  const thumbnailPhase = record.phases.find((phase) => phase.id === record.assets.thumbnailPhaseId) ?? record.phases[0]!;
  return {
    id: record.id,
    name: record.name,
    movementKind: record.classification.movementKind,
    keyPose: thumbnailPhase.technique,
    cueDrafts: record.cues.map((cue) => cue.text),
    zoneMap: [...record.anatomy.primary, ...record.anatomy.secondary],
    sourceUrls: record.sources.map((source) => source.url),
    review: {
      status: record.review.technique === 'coach_approved' ? 'approved' : 'source_checked',
      reviewedAt: record.review.reviewedAt,
      reviewer: record.review.reviewer,
    },
    assets: {
      thumbnail: thumbnailPhase.visual.assets.male,
      runnerStatic: thumbnailPhase.visual.assets.male,
      zoneMap: record.anatomy.asset,
      motionReady: record.phases.length >= 2 && record.phases.length <= 3,
    },
    sourceRecord: record,
  };
});

/**
 * Editorial queue, deliberately separate from movements exposed in the builder.
 * Source-checked records are safe for the initial catalogue; a trainer can later add a deeper review.
 */
const legacyExerciseEditorialQueue: readonly ExerciseRecord[] = [
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
];

export const exerciseEditorialQueue: readonly ExerciseRecord[] = [
  ...legacyExerciseEditorialQueue,
  ...generatedEditorialQueue,
];

export const catalogueExercises = exerciseEditorialQueue.filter(
  (exercise) =>
    (exercise.review.status === 'source_checked' || exercise.review.status === 'approved') &&
    Boolean(exercise.assets.thumbnail) &&
    Boolean(exercise.assets.runnerStatic),
);
