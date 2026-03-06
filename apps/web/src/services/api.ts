import type { Book, School, Holding, BookWithHoldings, HoldingWithSchool, FilterParams } from '../types';
import { books, schools, holdings } from './mock-data';

// Simulate async API delay
const delay = (ms: number = 50) => new Promise(resolve => setTimeout(resolve, ms));

function filterSchools(params: FilterParams): School[] {
  let result = [...schools];
  if (params.province) result = result.filter(s => s.province === params.province);
  if (params.district) result = result.filter(s => s.district === params.district);
  if (params.schoolId) result = result.filter(s => s.id === params.schoolId);
  if (params.schoolType) result = result.filter(s => s.schoolType === params.schoolType);
  return result;
}

export interface SchoolStats {
  school: School;
  bookCount: number;
  totalCopies: number;
  booksPerStudent: number;
}

export interface ComparisonRow {
  book: Book;
  quantities: Record<string, number>; // schoolId -> quantity (0 = not present)
}

export const api = {
  async getBooks(): Promise<Book[]> {
    await delay();
    return [...books];
  },

  async searchBooks(query: string): Promise<Book[]> {
    await delay();
    const q = query.toLowerCase();
    return books.filter(b =>
      b.title.toLowerCase().includes(q) ||
      b.authors.some(a => a.toLowerCase().includes(q)) ||
      (b.isbn && b.isbn.includes(q))
    );
  },

  async getBookById(id: string): Promise<Book | null> {
    await delay();
    return books.find(b => b.id === id) ?? null;
  },

  async getBookWithHoldings(bookId: string): Promise<BookWithHoldings | null> {
    await delay();
    const book = books.find(b => b.id === bookId);
    if (!book) return null;

    const bookHoldings = holdings.filter(h => h.bookId === bookId);
    const holdingsWithSchools: HoldingWithSchool[] = bookHoldings.map(h => ({
      holding: h,
      school: schools.find(s => s.id === h.schoolId)!,
    }));

    return { book, holdings: holdingsWithSchools };
  },

  async getSchools(params?: FilterParams): Promise<School[]> {
    await delay();
    return params ? filterSchools(params) : [...schools];
  },

  async getProvinces(): Promise<string[]> {
    await delay();
    const provinces = [...new Set(schools.map(s => s.province))];
    return provinces.sort();
  },

  async getDistricts(province: string): Promise<string[]> {
    await delay();
    const districts = [...new Set(
      schools.filter(s => s.province === province).map(s => s.district)
    )];
    return districts.sort();
  },

  async getSchoolHoldings(schoolId: string): Promise<(Holding & { book: Book })[]> {
    await delay();
    return holdings
      .filter(h => h.schoolId === schoolId)
      .map(h => ({
        ...h,
        book: books.find(b => b.id === h.bookId)!,
      }));
  },

  async getBooksByFilter(params: FilterParams): Promise<(Book & { schoolCount: number; totalQuantity: number })[]> {
    await delay();

    let relevantSchoolIds: string[];
    if (params.schoolId) {
      relevantSchoolIds = [params.schoolId];
    } else {
      relevantSchoolIds = filterSchools(params).map(s => s.id);
    }

    const relevantHoldings = holdings.filter(h => relevantSchoolIds.includes(h.schoolId));

    const bookMap = new Map<string, { schoolIds: Set<string>; totalQty: number }>();
    for (const h of relevantHoldings) {
      const entry = bookMap.get(h.bookId) ?? { schoolIds: new Set(), totalQty: 0 };
      entry.schoolIds.add(h.schoolId);
      entry.totalQty += h.quantity;
      bookMap.set(h.bookId, entry);
    }

    let result = Array.from(bookMap.entries()).map(([bookId, info]) => {
      const book = books.find(b => b.id === bookId)!;
      return {
        ...book,
        schoolCount: info.schoolIds.size,
        totalQuantity: info.totalQty,
      };
    });

    if (params.search) {
      const q = params.search.toLowerCase();
      result = result.filter(b =>
        b.title.toLowerCase().includes(q) ||
        b.authors.some((a: string) => a.toLowerCase().includes(q)) ||
        (b.isbn && b.isbn.includes(q))
      );
    }

    return result;
  },

  async getSchoolStats(params: FilterParams): Promise<SchoolStats[]> {
    await delay();

    const filteredSchools = filterSchools(params);

    return filteredSchools.map(school => {
      const schoolHoldings = holdings.filter(h => h.schoolId === school.id);
      const bookCount = new Set(schoolHoldings.map(h => h.bookId)).size;
      const totalCopies = schoolHoldings.reduce((sum, h) => sum + h.quantity, 0);
      const booksPerStudent = school.studentCount > 0 ? totalCopies / school.studentCount : 0;

      return { school, bookCount, totalCopies, booksPerStudent };
    });
  },

  async getComparisonData(params: FilterParams): Promise<{ schools: School[]; rows: ComparisonRow[] }> {
    await delay();

    const filteredSchools = filterSchools(params);

    const schoolIds = new Set(filteredSchools.map(s => s.id));
    const relevantHoldings = holdings.filter(h => schoolIds.has(h.schoolId));

    // Find all books that appear in at least one of these schools
    const bookIds = [...new Set(relevantHoldings.map(h => h.bookId))];
    const relevantBooks = bookIds.map(id => books.find(b => b.id === id)!);

    const rows: ComparisonRow[] = relevantBooks.map(book => {
      const quantities: Record<string, number> = {};
      for (const school of filteredSchools) {
        const holding = relevantHoldings.find(h => h.bookId === book.id && h.schoolId === school.id);
        quantities[school.id] = holding?.quantity ?? 0;
      }
      return { book, quantities };
    });

    return { schools: filteredSchools, rows };
  },
};
