import type { Habit } from '../lib/types';
import { isDoneToday } from '../lib/streaks';
import { todayKey } from '../lib/date';
import { HeatmapCalendar } from './HeatmapCalendar';
import { StreakBadge } from './StreakBadge';

interface Props {
  habit: Habit;
  onToggleDay: (habitId: string, dateKey: string) => void;
  onDelete: (habitId: string) => void;
}

export function HabitCard({ habit, onToggleDay, onDelete }: Props) {
  const doneToday = isDoneToday(habit);

  const handleDelete = () => {
    if (window.confirm(`"${habit.name}" 습관을 삭제할까요? 기록도 함께 사라집니다.`)) {
      onDelete(habit.id);
    }
  };

  return (
    <div className="habit-card">
      <div className="habit-card-header">
        <span className="habit-color-dot" style={{ backgroundColor: habit.color }} />
        <h3>{habit.name}</h3>
        <div className="habit-card-actions">
          <button
            type="button"
            className={doneToday ? 'today-toggle done' : 'today-toggle'}
            onClick={() => onToggleDay(habit.id, todayKey())}
          >
            {doneToday ? '오늘 완료 ✓' : '오늘 체크하기'}
          </button>
          <button type="button" className="link delete-btn" onClick={handleDelete}>
            삭제
          </button>
        </div>
      </div>

      <StreakBadge habit={habit} />

      <HeatmapCalendar habit={habit} onToggleDay={(dateKey) => onToggleDay(habit.id, dateKey)} />
    </div>
  );
}
