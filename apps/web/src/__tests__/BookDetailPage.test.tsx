import { describe, it, expect } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { BookDetailPage } from '../pages/BookDetailPage';

describe('BookDetailPage', () => {
  it('shows book info and holding schools for b1', async () => {
    render(
      <MemoryRouter initialEntries={['/books/b1']}>
        <Routes>
          <Route path="/books/:id" element={<BookDetailPage />} />
        </Routes>
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByText('Küçük Prens')).toBeInTheDocument();
      expect(screen.getByText('Antoine de Saint-Exupéry')).toBeInTheDocument();
      // 3 schools have this book (h1, h2, h3)
      expect(screen.getByText('Atatürk İlkokulu')).toBeInTheDocument();
      expect(screen.getByText('Moda Ortaokulu')).toBeInTheDocument();
      expect(screen.getByText('Alsancak Fen Lisesi')).toBeInTheDocument();
    });
  });

  it('shows total quantity', async () => {
    render(
      <MemoryRouter initialEntries={['/books/b1']}>
        <Routes>
          <Route path="/books/:id" element={<BookDetailPage />} />
        </Routes>
      </MemoryRouter>
    );

    await waitFor(() => {
      // b1: 5+3+2 = 10 total, 3 schools — use getAllByText since filter dropdown also shows count
      expect(screen.getAllByText(/3 okul/).length).toBeGreaterThanOrEqual(1);
      expect(screen.getByText(/10 adet/)).toBeInTheDocument();
    });
  });

  it('shows not found for nonexistent book', async () => {
    render(
      <MemoryRouter initialEntries={['/books/nonexistent']}>
        <Routes>
          <Route path="/books/:id" element={<BookDetailPage />} />
        </Routes>
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByText('Kitap bulunamadı.')).toBeInTheDocument();
    });
  });
});
