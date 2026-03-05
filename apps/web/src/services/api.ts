import type { Book, School, Holding, BookWithHoldings, HoldingWithSchool, FilterParams } from '../types';
import { books, schools, holdings } from './mock-data';

// Simulate async API delay
const delay = (ms: number = 50) => new Promise(resolve => setTimeout(resolve, ms));

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
    let result = [...schools];
    if (params?.province) {
      result = result.filter(s => s.province === params.province);
    }
    if (params?.district) {
      result = result.filter(s => s.district === params.district);
    }
    return result;
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

    // Get relevant school IDs based on filter
    let relevantSchoolIds: string[];
    if (params.schoolId) {
      relevantSchoolIds = [params.schoolId];
    } else {
      let filteredSchools = [...schools];
      if (params.province) filteredSchools = filteredSchools.filter(s => s.province === params.province);
      if (params.district) filteredSchools = filteredSchools.filter(s => s.district === params.district);
      relevantSchoolIds = filteredSchools.map(s => s.id);
    }

    // Get holdings for those schools
    const relevantHoldings = holdings.filter(h => relevantSchoolIds.includes(h.schoolId));

    // Group by book
    const bookMap = new Map<string, { schoolIds: Set<string>; totalQty: number }>();
    for (const h of relevantHoldings) {
      const entry = bookMap.get(h.bookId) ?? { schoolIds: new Set(), totalQty: 0 };
      entry.schoolIds.add(h.schoolId);
      entry.totalQty += h.quantity;
      bookMap.set(h.bookId, entry);
    }

    // Build result
    let result = Array.from(bookMap.entries()).map(([bookId, info]) => {
      const book = books.find(b => b.id === bookId)!;
      return {
        ...book,
        schoolCount: info.schoolIds.size,
        totalQuantity: info.totalQty,
      };
    });

    // Apply text search if present
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
};
