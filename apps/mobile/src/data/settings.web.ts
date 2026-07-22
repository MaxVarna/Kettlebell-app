const animationKey = 'kettlebell-interval.animation-enabled.v1';
const showIntroKey = 'kettlebell-interval.show-intro.v1';
const figureVariantKey = 'kettlebell-interval.figure-variant.v1';

export type FigureVariant = 'male' | 'female';

export const getAnimationEnabled = async () => globalThis.localStorage?.getItem(animationKey) !== 'false';

export const setAnimationEnabledSetting = async (enabled: boolean) => {
  globalThis.localStorage?.setItem(animationKey, enabled ? 'true' : 'false');
};

export const getShowIntro = async () => globalThis.localStorage?.getItem(showIntroKey) !== 'false';

export const setShowIntroSetting = async (enabled: boolean) => {
  globalThis.localStorage?.setItem(showIntroKey, enabled ? 'true' : 'false');
};

export const getFigureVariant = async (): Promise<FigureVariant> =>
  globalThis.localStorage?.getItem(figureVariantKey) === 'female' ? 'female' : 'male';

export const setFigureVariantSetting = async (variant: FigureVariant) => {
  globalThis.localStorage?.setItem(figureVariantKey, variant);
};
