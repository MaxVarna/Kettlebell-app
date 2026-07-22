import type { RunnerScheme } from '../runner/types';

export type SavedScheme = RunnerScheme & {
  id: string;
  createdAt: string;
  updatedAt: string;
  lastStartedAt?: string;
};

export type SchemeRepository = {
  listSchemes: () => Promise<SavedScheme[]>;
  saveScheme: (scheme: SavedScheme) => Promise<void>;
  deleteScheme: (id: string) => Promise<void>;
  markSchemeStarted: (scheme: SavedScheme) => Promise<SavedScheme>;
};
