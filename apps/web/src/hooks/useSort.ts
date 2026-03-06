import { useState, useMemo } from 'react';

export type SortDir = 'asc' | 'desc' | null;

export interface SortState {
  key: string;
  dir: SortDir;
}

export function useSort<T>(items: T[], defaultKey?: string, defaultDir?: SortDir) {
  const [sort, setSort] = useState<SortState>({
    key: defaultKey ?? '',
    dir: defaultDir ?? null,
  });

  const toggle = (key: string) => {
    setSort(prev => {
      if (prev.key !== key) return { key, dir: 'asc' };
      if (prev.dir === 'asc') return { key, dir: 'desc' };
      if (prev.dir === 'desc') return { key: '', dir: null };
      return { key, dir: 'asc' };
    });
  };

  const sorted = useMemo(() => {
    if (!sort.key || !sort.dir) return items;

    return [...items].sort((a, b) => {
      const av = (a as Record<string, unknown>)[sort.key];
      const bv = (b as Record<string, unknown>)[sort.key];

      if (av == null && bv == null) return 0;
      if (av == null) return 1;
      if (bv == null) return -1;

      let cmp: number;
      if (typeof av === 'number' && typeof bv === 'number') {
        cmp = av - bv;
      } else {
        cmp = String(av).localeCompare(String(bv), 'tr');
      }

      return sort.dir === 'desc' ? -cmp : cmp;
    });
  }, [items, sort]);

  return { sorted, sort, toggle };
}
