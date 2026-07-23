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

const exerciseVisuals: Readonly<Record<string, ExerciseVisualSet>> = {
  ...generatedExerciseVisuals,
};

const fallbackVisual = generatedExerciseVisuals['two-hand-swing']!;

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

export const exerciseEditorialQueue: readonly ExerciseRecord[] = generatedEditorialQueue;

export const catalogueExercises = exerciseEditorialQueue.filter(
  (exercise) =>
    (exercise.review.status === 'source_checked' || exercise.review.status === 'approved') &&
    Boolean(exercise.assets.thumbnail) &&
    Boolean(exercise.assets.runnerStatic),
);
