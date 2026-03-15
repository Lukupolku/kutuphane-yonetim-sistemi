import { useState, useMemo } from 'react';
import { Search, BookX } from 'lucide-react';
import { useSort } from '../hooks/useSort';
import { SortHeader } from './SortHeader';
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
        (b.isbn && b.isbn.includes(search)) ||
        (b.publisher && b.publisher.toLowerCase().includes(search.toLowerCase()))
      )
    : books;

  const withSortKeys = useMemo(() =>
    filtered.map(b => ({ ...b, authorStr: b.authors.join(', ') })),
    [filtered]
  );
  const { sorted, sort, toggle } = useSort(withSortKeys);
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
          placeholder="Tabloda ara (başlık, yazar, yayınevi, ISBN)..."
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
                <th style={{ width: 50 }}></th>
                <SortHeader label="Başlık" sortKey="title" sort={sort} onToggle={toggle} />
                <SortHeader label="Yazar" sortKey="authorStr" sort={sort} onToggle={toggle} />
                <SortHeader label="Yayınevi" sortKey="publisher" sort={sort} onToggle={toggle} />
                <th>ISBN</th>
                {hasStats && <SortHeader label="Okul Sayısı" sortKey="schoolCount" sort={sort} onToggle={toggle} className="center" />}
                {hasStats && <SortHeader label="Toplam Nüsha" sortKey="totalQuantity" sort={sort} onToggle={toggle} className="center" />}
              </tr>
            </thead>
            <tbody>
              {sorted.map(book => (
                <tr
                  key={book.id}
                  className={onBookClick ? 'clickable' : ''}
                  onClick={() => onBookClick?.(book.id)}
                >
                  <td style={{ width: 50, padding: '0.25rem' }}>
                    {book.coverImageUrl ? (
                      <img src={book.coverImageUrl} alt="" style={{ width: 40, height: 56, objectFit: 'cover', borderRadius: 4 }} />
                    ) : (
                      <div style={{ width: 40, height: 56, borderRadius: 4, background: 'linear-gradient(135deg, #8b1a2b, #c0392b)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 16, fontWeight: 700 }}>
                        {book.title.charAt(0)}
                      </div>
                    )}
                  </td>
                  <td className="cell-title">{book.title}</td>
                  <td className="cell-secondary">{book.authors.join(', ')}</td>
                  <td className="cell-secondary">{book.publisher ?? '—'}</td>
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
