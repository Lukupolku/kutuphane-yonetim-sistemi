import { ArrowUp, ArrowDown, ArrowUpDown } from 'lucide-react';
import type { SortState } from '../hooks/useSort';

interface SortHeaderProps {
  label: string;
  sortKey: string;
  sort: SortState;
  onToggle: (key: string) => void;
  className?: string;
}

export function SortHeader({ label, sortKey, sort, onToggle, className }: SortHeaderProps) {
  const isActive = sort.key === sortKey;

  return (
    <th
      className={`sortable-th ${className ?? ''} ${isActive ? 'sort-active' : ''}`}
      onClick={() => onToggle(sortKey)}
    >
      <span className="sortable-th-inner">
        {label}
        <span className="sort-icon">
          {isActive && sort.dir === 'asc' && <ArrowUp size={13} />}
          {isActive && sort.dir === 'desc' && <ArrowDown size={13} />}
          {!isActive && <ArrowUpDown size={13} />}
        </span>
      </span>
    </th>
  );
}
