import * as SQLite from 'expo-sqlite';
import type { SavedScheme, SchemeRepository } from './schemes.types';

let databasePromise: Promise<SQLite.SQLiteDatabase> | undefined;

const database = async () => {
  databasePromise ??= SQLite.openDatabaseAsync('kettlebell-interval.db');
  const db = await databasePromise;
  await db.execAsync(`
    CREATE TABLE IF NOT EXISTS workout_schemes (
      id TEXT PRIMARY KEY NOT NULL,
      updated_at INTEGER NOT NULL,
      payload TEXT NOT NULL
    );
  `);
  return db;
};

export const listSchemes: SchemeRepository['listSchemes'] = async () => {
  const db = await database();
  const rows = await db.getAllAsync<{ payload: string }>('SELECT payload FROM workout_schemes ORDER BY updated_at DESC');
  return rows.map((row) => JSON.parse(row.payload) as SavedScheme);
};

export const saveScheme: SchemeRepository['saveScheme'] = async (scheme) => {
  const db = await database();
  await db.runAsync(
    'INSERT INTO workout_schemes (id, updated_at, payload) VALUES (?, ?, ?) ON CONFLICT(id) DO UPDATE SET updated_at = excluded.updated_at, payload = excluded.payload',
    scheme.id,
    Date.parse(scheme.updatedAt),
    JSON.stringify(scheme),
  );
};

export const deleteScheme: SchemeRepository['deleteScheme'] = async (id) => {
  const db = await database();
  await db.runAsync('DELETE FROM workout_schemes WHERE id = ?', id);
};

export const markSchemeStarted: SchemeRepository['markSchemeStarted'] = async (scheme) => {
  const now = new Date().toISOString();
  const updated = { ...scheme, lastStartedAt: now, updatedAt: now };
  await saveScheme(updated);
  return updated;
};
