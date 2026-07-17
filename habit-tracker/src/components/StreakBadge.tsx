import type { Habit } from '../lib/types';
import { currentStreak, longestStreak } from '../lib/streaks';

interface Props {
  habit: Habit;
}

export function StreakBadge({ habit }: Props) {
  const current = currentStreak(habit);
  const longest = longestStreak(habit);

  return (
    <div className="streak-badge">
      <span>🔥 {current}일 연속</span>
      <span className="streak-best">최장 {longest}일</span>
    </div>
  );
}
