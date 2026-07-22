/**
 * Builds a closed, reversible keyframe path.
 * Three frames become 0 → 1 → 2 → 1 → 0, so a loop never jumps
 * directly from the final pose back to the initial pose.
 */
export const framePlaybackOrder = (frameCount: number): number[] => {
  if (frameCount <= 0) return [];
  if (frameCount === 1) return [0];

  const forward = Array.from({ length: frameCount }, (_, index) => index);
  const backward = Array.from({ length: frameCount - 1 }, (_, index) => frameCount - index - 2);
  return [...forward, ...backward];
};

/** Advances without pausing twice on the duplicated first frame at the loop boundary. */
export const nextPlaybackCursor = (order: readonly number[], cursor: number) => {
  if (order.length <= 1) return 0;
  return cursor >= order.length - 1 ? 1 : cursor + 1;
};
