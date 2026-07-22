import type { RunnerPhase, RunnerScheme, RunnerState } from './types';

const milliseconds = (seconds: number) => seconds * 1_000;

export const initialRunnerState = (): RunnerState => ({
  phase: 'preparation',
  cycleIndex: 0,
  movementIndex: 0,
  phaseEndsAtMs: null,
  pausedRemainingMs: null,
});

export const phaseDurationMs = (scheme: RunnerScheme, phase: Exclude<RunnerPhase, 'completed'>) =>
  milliseconds(scheme.rhythm[`${phase}Sec`]);

export const start = (scheme: RunnerScheme, nowMs: number): RunnerState => ({
  ...initialRunnerState(),
  phaseEndsAtMs: nowMs + phaseDurationMs(scheme, 'preparation'),
});

export const pause = (state: RunnerState, nowMs: number): RunnerState => {
  if (state.phase === 'completed' || state.phaseEndsAtMs === null) return state;

  return {
    ...state,
    phaseEndsAtMs: null,
    pausedRemainingMs: Math.max(0, state.phaseEndsAtMs - nowMs),
  };
};

export const resume = (state: RunnerState, nowMs: number): RunnerState => {
  if (state.phase === 'completed' || state.pausedRemainingMs === null) return state;

  return {
    ...state,
    phaseEndsAtMs: nowMs + state.pausedRemainingMs,
    pausedRemainingMs: null,
  };
};

const nextPhase = (scheme: RunnerScheme, state: RunnerState): Omit<RunnerState, 'phaseEndsAtMs' | 'pausedRemainingMs'> => {
  if (state.phase === 'preparation') {
    return { ...state, phase: 'work' };
  }

  if (state.phase === 'work') {
    return { ...state, phase: 'rest' };
  }

  const isLastMovement = state.movementIndex === scheme.movements.length - 1;
  const isLastCycle = state.cycleIndex === scheme.cycleCount - 1;

  if (isLastMovement && isLastCycle) {
    return { ...state, phase: 'completed' };
  }

  if (!isLastMovement) {
    return {
      ...state,
      phase: 'work',
      movementIndex: state.movementIndex + 1,
    };
  }

  return {
    ...state,
    phase: 'preparation',
    cycleIndex: state.cycleIndex + 1,
    movementIndex: 0,
  };
};

/** Moves to the next interval immediately while preserving whether the runner was paused. */
export const skip = (scheme: RunnerScheme, state: RunnerState, nowMs: number): RunnerState => {
  if (state.phase === 'completed') return state;

  const advanced = nextPhase(scheme, state);
  if (advanced.phase === 'completed') return { ...advanced, phaseEndsAtMs: null, pausedRemainingMs: null };

  const durationMs = phaseDurationMs(scheme, advanced.phase);
  const paused = state.pausedRemainingMs !== null || state.phaseEndsAtMs === null;
  return {
    ...advanced,
    phaseEndsAtMs: paused ? null : nowMs + durationMs,
    pausedRemainingMs: paused ? durationMs : null,
  };
};

/** Advances every elapsed phase, so returning from the background never relies on missed UI ticks. */
export const reconcile = (scheme: RunnerScheme, state: RunnerState, nowMs: number): RunnerState => {
  if (state.phase === 'completed' || state.phaseEndsAtMs === null) return state;

  let current = state;
  let endAtMs = current.phaseEndsAtMs;

  while (endAtMs !== null && nowMs >= endAtMs) {
    const advanced = nextPhase(scheme, current);
    if (advanced.phase === 'completed') {
      return { ...advanced, phaseEndsAtMs: null, pausedRemainingMs: null };
    }

    current = { ...advanced, phaseEndsAtMs: endAtMs, pausedRemainingMs: null };
    endAtMs += phaseDurationMs(scheme, advanced.phase);
    current = { ...current, phaseEndsAtMs: endAtMs };
  }

  return current;
};

export const remainingSeconds = (state: RunnerState, nowMs: number) => {
  const remainingMs = state.pausedRemainingMs ?? (state.phaseEndsAtMs === null ? 0 : state.phaseEndsAtMs - nowMs);
  return Math.max(0, Math.ceil(remainingMs / 1_000));
};
