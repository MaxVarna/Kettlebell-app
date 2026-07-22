import type { SavedScheme, SchemeRepository } from './schemes.types';

const key = 'kettlebell-interval.schemes.v1';

const read = (): SavedScheme[] => {
  const raw = globalThis.localStorage?.getItem(key);
  if (!raw) return [];
  try { return JSON.parse(raw) as SavedScheme[]; } catch { return []; }
};

export const listSchemes: SchemeRepository['listSchemes'] = async () =>
  read().sort((a, b) => (b.lastStartedAt ?? b.updatedAt).localeCompare(a.lastStartedAt ?? a.updatedAt));

export const saveScheme: SchemeRepository['saveScheme'] = async (scheme) => {
  globalThis.localStorage?.setItem(key, JSON.stringify([scheme, ...read().filter((item) => item.id !== scheme.id)]));
};

export const deleteScheme: SchemeRepository['deleteScheme'] = async (id) => {
  globalThis.localStorage?.setItem(key, JSON.stringify(read().filter((item) => item.id !== id)));
};

export const markSchemeStarted: SchemeRepository['markSchemeStarted'] = async (scheme) => {
  const now = new Date().toISOString();
  const updated = { ...scheme, lastStartedAt: now, updatedAt: now };
  await saveScheme(updated);
  return updated;
};
