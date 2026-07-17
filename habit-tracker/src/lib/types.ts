export interface Habit {
  id: string;
  name: string;
  color: string;
  createdAt: string;
  completions: Record<string, boolean>;
}

export interface HabitStore {
  version: 1;
  habits: Habit[];
}
