import assert from 'node:assert/strict';
import test from 'node:test';
import { initialRunnerState, pause, reconcile, remainingSeconds, resume, skip, start } from './engine';
import type { RunnerScheme } from './types';

const scheme: RunnerScheme = {
  title: 'Тест',
  movements: [
    { id: 'swing', name: 'Свинг', cue: '' },
    { id: 'squat', name: 'Гоблет-присед', cue: '' },
  ],
  rhythm: { preparationSec: 2, workSec: 3, restSec: 4 },
  cycleCount: 2,
};

test('starts at preparation and counts from a deadline', () => {
  const state = start(scheme, 1_000);
  assert.equal(state.phase, 'preparation');
  assert.equal(remainingSeconds(state, 1_001), 2);
  assert.equal(remainingSeconds(state, 3_000), 0);
});

test('reconciles missed phases after backgrounding', () => {
  const started = start(scheme, 0);
  const restored = reconcile(scheme, started, 9_500);
  assert.deepEqual(
    { phase: restored.phase, movement: restored.movementIndex, cycle: restored.cycleIndex },
    { phase: 'work', movement: 1, cycle: 0 },
  );
  assert.equal(remainingSeconds(restored, 9_500), 3);
});

test('keeps the saved order and one shared rhythm through every cycle', () => {
  const started = start(scheme, 0);
  const secondMovement = reconcile(scheme, started, 9_500);
  assert.deepEqual(
    { phase: secondMovement.phase, movement: secondMovement.movementIndex, cycle: secondMovement.cycleIndex },
    { phase: 'work', movement: 1, cycle: 0 },
  );

  const nextCycle = reconcile(scheme, secondMovement, 16_500);
  assert.deepEqual(
    { phase: nextCycle.phase, movement: nextCycle.movementIndex, cycle: nextCycle.cycleIndex },
    { phase: 'preparation', movement: 0, cycle: 1 },
  );

  assert.equal(reconcile(scheme, nextCycle, 32_000).phase, 'completed');
});

test('uses preparation once per cycle, not before every movement', () => {
  const firstRest = reconcile(scheme, start(scheme, 0), 5_000);
  assert.equal(firstRest.phase, 'rest');
  const secondMovement = reconcile(scheme, firstRest, 9_000);
  assert.deepEqual(
    { phase: secondMovement.phase, movement: secondMovement.movementIndex, cycle: secondMovement.cycleIndex },
    { phase: 'work', movement: 1, cycle: 0 },
  );
});

test('pause preserves remaining time', () => {
  const started = start(scheme, 0);
  const paused = pause(started, 1_300);
  assert.equal(paused.phaseEndsAtMs, null);
  assert.equal(paused.pausedRemainingMs, 700);
  const resumed = resume(paused, 10_000);
  assert.equal(remainingSeconds(resumed, 10_000), 1);
  assert.equal(reconcile(scheme, resumed, 10_700).phase, 'work');
});

test('skip advances to the next interval and keeps a paused runner paused', () => {
  const started = start(scheme, 0);
  const skipped = skip(scheme, started, 500);
  assert.equal(skipped.phase, 'work');
  assert.equal(remainingSeconds(skipped, 500), 3);

  const paused = pause(started, 500);
  const skippedWhilePaused = skip(scheme, paused, 1_000);
  assert.equal(skippedWhilePaused.phase, 'work');
  assert.equal(skippedWhilePaused.phaseEndsAtMs, null);
  assert.equal(remainingSeconds(skippedWhilePaused, 1_000), 3);
});

test('an untouched initial state is harmless', () => {
  assert.deepEqual(reconcile(scheme, initialRunnerState(), 999_999), initialRunnerState());
});
