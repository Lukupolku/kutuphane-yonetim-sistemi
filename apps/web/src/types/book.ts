export type BookSource = 'GOOGLE_BOOKS' | 'OPEN_LIBRARY' | 'MANUAL' | 'OCR';

export interface Book {
  id: string;
  isbn: string | null;
  title: string;
  authors: string[];
  publisher: string | null;
  publishedDate: string | null;
  pageCount: number | null;
  coverImageUrl: string | null;
  description: string | null;
  language: string;
  source: BookSource;
  createdAt: string;
}
