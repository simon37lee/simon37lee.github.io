import type { Habit } from '../lib/types';
import { HabitCard } from './HabitCard';

interface Props {
  habits: Habit[];
  onToggleDay: (habitId: string, dateKey: string) => void;
  onDelete: (habitId: string) => void;
}

export function HabitList({ habits, onToggleDay, onDelete }: Props) {
  if (habits.length === 0) {
    return <p className="empty-state">아직 등록된 습관이 없습니다. 위에서 습관을 추가해보세요.</p>;
  }

  return (
    <div className="habit-list">
      {habits.map((habit) => (
        <HabitCard key={habit.id} habit={habit} onToggleDay={onToggleDay} onDelete={onDelete} />
      ))}
    </div>
  );
}
