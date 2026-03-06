export type { Book, BookSource } from './book';
export type { School, SchoolType } from './school';
export type { Holding, HoldingSource } from './holding';

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
