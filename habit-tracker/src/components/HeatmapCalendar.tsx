import type { Habit } from '../lib/types';
import { addDays, toDateKey, todayKey } from '../lib/date';

interface Props {
  habit: Habit;
  onToggleDay: (dateKey: string) => void;
}

const WEEKS = 53;
const DAYS_PER_WEEK = 7;

function buildWeeks(): string[][] {
  const today = new Date();
  const totalDays = WEEKS * DAYS_PER_WEEK;
  // Align the grid so the last column ends on today's day-of-week.
  const start = addDays(today, -(totalDays - 1) - today.getDay());

  const weeks: string[][] = [];
  for (let w = 0; w < WEEKS; w += 1) {
    const week: string[] = [];
    for (let d = 0; d < DAYS_PER_WEEK; d += 1) {
      week.push(toDateKey(addDays(start, w * DAYS_PER_WEEK + d)));
    }
    weeks.push(week);
  }
  return weeks;
}

export function HeatmapCalendar({ habit, onToggleDay }: Props) {
  const weeks = buildWeeks();
  const today = todayKey();

  return (
    <div className="heatmap" role="grid" aria-label={`${habit.name} 완료 기록`}>
      {weeks.map((week, i) => (
        <div className="heatmap-week" key={i}>
          {week.map((dateKey) => {
            const done = Boolean(habit.completions[dateKey]);
            const isFuture = dateKey > today;
            return (
              <button
                key={dateKey}
                type="button"
                className="heatmap-cell"
                data-done={done}
                disabled={isFuture}
                title={`${dateKey}${done ? ' · 완료' : ''}`}
                style={done ? { ['--habit-color' as string]: habit.color } : undefined}
                onClick={() => onToggleDay(dateKey)}
              />
            );
          })}
        </div>
      ))}
    </div>
  );
}
