import { useCallback, useEffect, useState } from 'react';
import type { Habit, HabitStore } from '../lib/types';
import { loadStore, saveStore } from '../lib/storage';
import { isFutureKey } from '../lib/date';

export function useHabits() {
  const [store, setStore] = useState<HabitStore>(() => loadStore());

  useEffect(() => {
    saveStore(store);
  }, [store]);

  const addHabit = useCallback((name: string, color: string) => {
    const trimmed = name.trim();
    if (!trimmed) return;
    const habit: Habit = {
      id: crypto.randomUUID(),
      name: trimmed,
      color,
      createdAt: new Date().toISOString(),
      completions: {},
    };
    setStore((prev) => ({ ...prev, habits: [...prev.habits, habit] }));
  }, []);

  const deleteHabit = useCallback((id: string) => {
    setStore((prev) => ({ ...prev, habits: prev.habits.filter((h) => h.id !== id) }));
  }, []);

  const toggleDay = useCallback((habitId: string, dateKey: string) => {
    if (isFutureKey(dateKey)) return;
    setStore((prev) => ({
      ...prev,
      habits: prev.habits.map((h) => {
        if (h.id !== habitId) return h;
        const completions = { ...h.completions };
        if (completions[dateKey]) {
          delete completions[dateKey];
        } else {
          completions[dateKey] = true;
        }
        return { ...h, completions };
      }),
    }));
  }, []);

  return { habits: store.habits, addHabit, deleteHabit, toggleDay };
}
