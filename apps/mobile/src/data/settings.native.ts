import * as SQLite from 'expo-sqlite';

let databasePromise: Promise<SQLite.SQLiteDatabase> | undefined;

const database = async () => {
  databasePromise ??= SQLite.openDatabaseAsync('kettlebell-interval.db');
  const db = await databasePromise;
  await db.execAsync(`
    CREATE TABLE IF NOT EXISTS app_settings (
      key TEXT PRIMARY KEY NOT NULL,
      value TEXT NOT NULL
    );
  `);
  return db;
};

export const getAnimationEnabled = async () => {
  const db = await database();
  const row = await db.getFirstAsync<{ value: string }>('SELECT value FROM app_settings WHERE key = ?', 'animation-enabled');
  return row?.value !== 'false';
};

export const setAnimationEnabledSetting = async (enabled: boolean) => {
  const db = await database();
  await db.runAsync(
    'INSERT INTO app_settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
    'animation-enabled',
    enabled ? 'true' : 'false',
  );
};
