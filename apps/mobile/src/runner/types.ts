export type RunnerPhase = 'preparation' | 'work' | 'rest' | 'completed';

export type Movement = {
  id: string;
  name: string;
  cue: string;
};

export type IntervalRhythm = {
  preparationSec: number;
  workSec: number;
  restSec: number;
};

export type RunnerScheme = {
  title: string;
  movements: readonly Movement[];
  rhythm: IntervalRhythm;
  cycleCount: number;
  preparationOnlyAtStart?: boolean;
};

export type RunnerState = {
  phase: RunnerPhase;
  cycleIndex: number;
  movementIndex: number;
  phaseEndsAtMs: number | null;
  pausedRemainingMs: number | null;
};
