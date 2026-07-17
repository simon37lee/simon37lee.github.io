import type { HabitStore } from './types';

const STORAGE_KEY = 'habit-tracker:v1';

const EMPTY_STORE: HabitStore = { version: 1, habits: [] };

export function loadStore(): HabitStore {
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return EMPTY_STORE;
    const parsed = JSON.parse(raw);
    if (parsed && parsed.version === 1 && Array.isArray(parsed.habits)) {
      return parsed as HabitStore;
    }
    return EMPTY_STORE;
  } catch {
    return EMPTY_STORE;
  }
}

export function saveStore(store: HabitStore): void {
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(store));
}
