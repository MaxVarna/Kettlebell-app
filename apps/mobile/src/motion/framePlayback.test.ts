import assert from 'node:assert/strict';
import test from 'node:test';
import { framePlaybackOrder, nextPlaybackCursor } from './framePlayback';

test('two-frame movement returns through its first pose', () => {
  assert.deepEqual(framePlaybackOrder(2), [0, 1, 0]);
});

test('three-frame movement reverses through the middle pose', () => {
  assert.deepEqual(framePlaybackOrder(3), [0, 1, 2, 1, 0]);
});

test('empty and static assets are safe', () => {
  assert.deepEqual(framePlaybackOrder(0), []);
  assert.deepEqual(framePlaybackOrder(1), [0]);
});

test('cursor repeats the movement without duplicating the first frame hold', () => {
  const order = framePlaybackOrder(3);
  let cursor = 0;
  const visited = Array.from({ length: 6 }, () => {
    const frame = order[cursor];
    cursor = nextPlaybackCursor(order, cursor);
    return frame;
  });
  assert.deepEqual(visited, [0, 1, 2, 1, 0, 1]);
});
