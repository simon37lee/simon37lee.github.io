import { useState } from 'react';

interface Props {
  onAdd: (name: string, color: string) => void;
}

const DEFAULT_COLOR = '#6cb4a0';

export function HabitForm({ onAdd }: Props) {
  const [name, setName] = useState('');
  const [color, setColor] = useState(DEFAULT_COLOR);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    onAdd(name, color);
    setName('');
    setColor(DEFAULT_COLOR);
  };

  return (
    <form className="habit-form" onSubmit={handleSubmit}>
      <input
        type="text"
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="새 습관 이름 (예: 물 2L 마시기)"
        aria-label="습관 이름"
      />
      <input
        type="color"
        value={color}
        onChange={(e) => setColor(e.target.value)}
        aria-label="습관 색상"
      />
      <button type="submit">습관 추가</button>
    </form>
  );
}
