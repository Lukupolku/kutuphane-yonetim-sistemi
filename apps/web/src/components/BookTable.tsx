import { useState } from 'react';
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

  return (
    <div>
      <div style={{ marginBottom: '1rem' }}>
        <input
          type="text"
          placeholder="Kitap ara (başlık, yazar, ISBN)..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          aria-label="Kitap ara"
          style={{ width: '100%', padding: '10px 14px', borderRadius: '6px', border: '1px solid #ccc', fontSize: '1rem' }}
        />
      </div>

      {loading ? (
        <p style={{ textAlign: 'center', padding: '2rem', color: '#666' }}>Yükleniyor...</p>
      ) : filtered.length === 0 ? (
        <p style={{ textAlign: 'center', padding: '2rem', color: '#666' }}>Kitap bulunamadı.</p>
      ) : (
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '2px solid #e0e0e0', textAlign: 'left' }}>
              <th style={{ padding: '12px 8px' }}>Başlık</th>
              <th style={{ padding: '12px 8px' }}>Yazar</th>
              <th style={{ padding: '12px 8px' }}>ISBN</th>
              {books[0]?.schoolCount !== undefined && <th style={{ padding: '12px 8px', textAlign: 'center' }}>Okul Sayısı</th>}
              {books[0]?.totalQuantity !== undefined && <th style={{ padding: '12px 8px', textAlign: 'center' }}>Toplam Adet</th>}
            </tr>
          </thead>
          <tbody>
            {filtered.map(book => (
              <tr
                key={book.id}
                onClick={() => onBookClick?.(book.id)}
                style={{ borderBottom: '1px solid #eee', cursor: onBookClick ? 'pointer' : 'default' }}
                onMouseOver={e => (e.currentTarget.style.background = '#f9f9f9')}
                onMouseOut={e => (e.currentTarget.style.background = 'transparent')}
              >
                <td style={{ padding: '10px 8px', fontWeight: 500 }}>{book.title}</td>
                <td style={{ padding: '10px 8px', color: '#555' }}>{book.authors.join(', ')}</td>
                <td style={{ padding: '10px 8px', fontFamily: 'monospace', fontSize: '0.9rem' }}>{book.isbn ?? '—'}</td>
                {book.schoolCount !== undefined && <td style={{ padding: '10px 8px', textAlign: 'center' }}>{book.schoolCount}</td>}
                {book.totalQuantity !== undefined && <td style={{ padding: '10px 8px', textAlign: 'center' }}>{book.totalQuantity}</td>}
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
