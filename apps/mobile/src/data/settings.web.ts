const animationKey = 'kettlebell-interval.animation-enabled.v1';

export const getAnimationEnabled = async () => globalThis.localStorage?.getItem(animationKey) !== 'false';

export const setAnimationEnabledSetting = async (enabled: boolean) => {
  globalThis.localStorage?.setItem(animationKey, enabled ? 'true' : 'false');
};
