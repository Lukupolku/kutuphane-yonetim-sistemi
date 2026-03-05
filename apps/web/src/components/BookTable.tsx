import { useState } from 'react';
import { Search, BookX } from 'lucide-react';
import type { Book } from '../types';

interface BookTableRow extends Book {
  schoolCount?: number;
  totalQuantity?: number;
}

interface BookTableProps {
  books: BookTableRow[];
  loading?: boolean;
  onBookClick?: (bookId: string) => void;
}

export function BookTable({ books, loading, onBookClick }: BookTableProps) {
  const [search, setSearch] = useState('');

  const filtered = search
    ? books.filter(b =>
        b.title.toLowerCase().includes(search.toLowerCase()) ||
        b.authors.some(a => a.toLowerCase().includes(search.toLowerCase())) ||
        (b.isbn && b.isbn.includes(search))
      )
    : books;

  const hasStats = books[0]?.schoolCount !== undefined;

  return (
    <div>
      <div className="search-container">
        <span className="search-icon">
          <Search size={18} />
        </span>
        <input
          type="text"
          className="search-input"
          placeholder="Tabloda ara (başlık, yazar, ISBN)..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          aria-label="Kitap ara"
        />
      </div>

      {loading ? (
        <div className="loading-state">
          <div className="loading-spinner" />
          <p>Yükleniyor...</p>
        </div>
      ) : filtered.length === 0 ? (
        <div className="empty-state">
          <div className="empty-state-icon">
            <BookX size={40} strokeWidth={1.5} />
          </div>
          <p className="empty-state-text">Kitap bulunamadı.</p>
        </div>
      ) : (
        <div className="data-table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                <th>Başlık</th>
                <th>Yazar</th>
                <th>ISBN</th>
                {hasStats && <th className="center">Okul Sayısı</th>}
                {hasStats && <th className="center">Toplam Adet</th>}
              </tr>
            </thead>
            <tbody>
              {filtered.map(book => (
                <tr
                  key={book.id}
                  className={onBookClick ? 'clickable' : ''}
                  onClick={() => onBookClick?.(book.id)}
                >
                  <td className="cell-title">{book.title}</td>
                  <td className="cell-secondary">{book.authors.join(', ')}</td>
                  <td className="cell-mono">{book.isbn ?? '—'}</td>
                  {hasStats && (
                    <td className="cell-center">
                      <span className="cell-badge cell-badge--school">{book.schoolCount}</span>
                    </td>
                  )}
                  {hasStats && (
                    <td className="cell-center">
                      <span className="cell-badge cell-badge--quantity">{book.totalQuantity}</span>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
