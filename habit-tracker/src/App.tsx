import { useHabits } from './hooks/useHabits';
import { HabitForm } from './components/HabitForm';
import { HabitList } from './components/HabitList';

export function App() {
  const { habits, addHabit, deleteHabit, toggleDay } = useHabits();

  return (
    <div className="habit-app">
      <HabitForm onAdd={addHabit} />
      <HabitList habits={habits} onToggleDay={toggleDay} onDelete={deleteHabit} />
    </div>
  );
}
