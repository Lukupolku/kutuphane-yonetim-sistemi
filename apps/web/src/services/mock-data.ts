import type { Book, School, Holding, Author } from '../types';

import booksData from '../data/books.json';
import schoolsData from '../data/schools.json';
import holdingsData from '../data/holdings.json';
import authorsData from '../data/authors.json';

export const books: Book[] = booksData as Book[];
export const schools: School[] = schoolsData as School[];
export const holdings: Holding[] = holdingsData as Holding[];
export const authors: Author[] = authorsData as Author[];
