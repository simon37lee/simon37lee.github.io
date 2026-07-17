import type { Habit } from './types';
import { addDays, toDateKey, todayKey } from './date';

export function currentStreak(habit: Habit): number {
  const today = new Date();
  let cursor = habit.completions[toDateKey(today)] ? today : addDays(today, -1);
  let streak = 0;
  while (habit.completions[toDateKey(cursor)]) {
    streak += 1;
    cursor = addDays(cursor, -1);
  }
  return streak;
}

export function longestStreak(habit: Habit): number {
  const doneDates = Object.keys(habit.completions)
    .filter((key) => habit.completions[key])
    .sort();

  let longest = 0;
  let current = 0;
  let prevDate: Date | null = null;

  for (const key of doneDates) {
    const date = new Date(`${key}T00:00:00`);
    if (prevDate && toDateKey(addDays(prevDate, 1)) === key) {
      current += 1;
    } else {
      current = 1;
    }
    longest = Math.max(longest, current);
    prevDate = date;
  }

  return longest;
}

export function isDoneToday(habit: Habit): boolean {
  return Boolean(habit.completions[todayKey()]);
}
