export type { Book, BookSource } from './book';
export type { School, SchoolType } from './school';
export type { Holding, HoldingSource } from './holding';

export interface Author {
  id: string;
  name: string;
  birthYear: number;
  deathYear: number | null;
  genres: string[];
  categories: string[];
  literaryMovement: string;
  suitability: 'uygun' | 'secici' | 'rehberli';
  note: string;
  photoUrl?: string | null;
}

import type { Book } from './book';
import type { School } from './school';
import type { Holding } from './holding';

export interface HoldingWithSchool {
  holding: Holding;
  school: School;
}

export interface BookWithHoldings {
  book: Book;
  holdings: HoldingWithSchool[];
}

export interface FilterParams {
  province?: string;
  district?: string;
  schoolId?: string;
  schoolType?: import('./school').SchoolType;
  search?: string;
}
