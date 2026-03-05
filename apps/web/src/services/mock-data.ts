import type { Book, School, Holding } from '../types';

import booksData from '../data/books.json';
import schoolsData from '../data/schools.json';
import holdingsData from '../data/holdings.json';

export const books: Book[] = booksData as Book[];
export const schools: School[] = schoolsData as School[];
export const holdings: Holding[] = holdingsData as Holding[];
