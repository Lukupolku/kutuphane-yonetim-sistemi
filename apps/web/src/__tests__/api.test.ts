import { describe, it, expect } from 'vitest';
import { api } from '../services/api';

describe('API Service (mock)', () => {
  it('getBooks returns all 15 books', async () => {
    const books = await api.getBooks();
    expect(books.length).toBe(15);
  });

  it('searchBooks filters by title', async () => {
    const books = await api.searchBooks('prens');
    expect(books.length).toBe(1);
    expect(books[0].title).toBe('Küçük Prens');
  });

  it('searchBooks filters by author', async () => {
    const books = await api.searchBooks('orwell');
    expect(books.length).toBe(2); // 1984 and Hayvan Ciftligi
  });

  it('searchBooks filters by ISBN', async () => {
    const books = await api.searchBooks('9789750718533');
    expect(books.length).toBe(1);
    expect(books[0].title).toBe('Küçük Prens');
  });

  it('getSchools returns all 12 schools without filter', async () => {
    const schools = await api.getSchools();
    expect(schools.length).toBe(12);
  });

  it('getSchools filters by province', async () => {
    const schools = await api.getSchools({ province: 'Ankara' });
    expect(schools.length).toBe(4);
  });

  it('getSchools filters by province and district', async () => {
    const schools = await api.getSchools({ province: 'İstanbul', district: 'Kadıköy' });
    expect(schools.length).toBe(2);
  });

  it('getBookWithHoldings returns book with holdings', async () => {
    const result = await api.getBookWithHoldings('b1');
    expect(result).not.toBeNull();
    expect(result!.book.title).toBe('Küçük Prens');
    expect(result!.holdings.length).toBe(3); // s1, s5, s9
  });

  it('getBookWithHoldings returns null for unknown book', async () => {
    const result = await api.getBookWithHoldings('nonexistent');
    expect(result).toBeNull();
  });

  it('getProvinces returns unique sorted provinces', async () => {
    const provinces = await api.getProvinces();
    expect(provinces).toEqual(['Ankara', 'İstanbul', 'İzmir']);
  });

  it('getDistricts returns districts for province', async () => {
    const districts = await api.getDistricts('Ankara');
    expect(districts.length).toBe(2);
    expect(districts).toContain('Çankaya');
    expect(districts).toContain('Keçiören');
  });

  it('getSchoolHoldings returns books for a school', async () => {
    const holdings = await api.getSchoolHoldings('s1-ankara-cankaya-ataturk-ilk');
    expect(holdings.length).toBe(3); // b1, b6, b11
  });

  it('getBooksByFilter filters by province', async () => {
    const result = await api.getBooksByFilter({ province: 'Ankara' });
    // Should return books that have holdings in Ankara schools
    expect(result.length).toBeGreaterThan(0);
    result.forEach(b => {
      expect(b.schoolCount).toBeGreaterThan(0);
      expect(b.totalQuantity).toBeGreaterThan(0);
    });
  });

  it('getBooksByFilter with search narrows results', async () => {
    const result = await api.getBooksByFilter({ search: '1984' });
    expect(result.length).toBe(1);
    expect(result[0].title).toBe('1984');
  });
});
