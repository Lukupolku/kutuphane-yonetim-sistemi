import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Download } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { HierarchyFilter } from '../components/HierarchyFilter';
import { BookTable } from '../components/BookTable';
import { api } from '../services/api';
import type { FilterParams, Book } from '../types';
import { downloadCsv } from '../utils/csv-export';

type BookWithStats = Book & { schoolCount: number; totalQuantity: number };

export function SearchPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const isSchool = user?.role === 'school';

  const [showAll, setShowAll] = useState(false);
  const [filter, setFilter] = useState<FilterParams>(() => {
    if (isSchool && user?.schoolId) return { schoolId: user.schoolId };
    if (user?.role === 'district') return { province: user.province!, district: user.district! };
    if (user?.role === 'province') return { province: user.province! };
    return {};
  });
  const [books, setBooks] = useState<BookWithStats[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    if (showAll) {
      api.getBooks().then(result => {
        setBooks(result.map(b => ({ ...b, schoolCount: 0, totalQuantity: 0 })));
        setLoading(false);
      });
    } else {
      api.getBooksByFilter(filter).then(result => {
        setBooks(result);
        setLoading(false);
      });
    }
  }, [filter, showAll]);

  const scopeLabel = isSchool
    ? user?.schoolName ?? 'Okul'
    : filter.district
    ? `${filter.province} / ${filter.district}`
    : filter.province
    ? filter.province
    : 'Tüm Türkiye';

  const handleExportCsv = () => {
    const headers = ['Kitap', 'Yazar', 'Yayınevi', 'ISBN', 'Okul Sayısı', 'Toplam Nüsha'];
    const rows = books.map(b => [
      b.title,
      b.authors.join(', '),
      b.publisher ?? '',
      b.isbn ?? '',
      String(b.schoolCount),
      String(b.totalQuantity),
    ]);
    downloadCsv(`kitap-listesi-${scopeLabel}.csv`, headers, rows);
  };

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">Kitap Kataloğu</h1>
        <p className="page-subtitle">Başlık, yazar veya ISBN ile arama yapın — {scopeLabel}</p>
      </div>

      <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem' }}>
        <button
          className={`btn ${!showAll ? 'btn--primary' : 'btn-secondary'}`}
          onClick={() => setShowAll(false)}
          style={{ fontSize: '0.85rem' }}
        >
          Envanterdeki Kitaplar
        </button>
        <button
          className={`btn ${showAll ? 'btn--primary' : 'btn-secondary'}`}
          onClick={() => setShowAll(true)}
          style={{ fontSize: '0.85rem' }}
        >
          Tüm Katalog ({showAll ? books.length : '...'})
        </button>
      </div>

      {!isSchool && !showAll && <HierarchyFilter onFilterChange={setFilter} />}

      <div className="scope-bar">
        <span className="scope-label">{scopeLabel}</span>
        <span className="scope-count">{books.length} farklı kitap</span>
        <div className="scope-actions">
          <button className="btn btn-secondary" onClick={handleExportCsv} disabled={books.length === 0}>
            <Download size={16} /> Kitap Listesi CSV
          </button>
        </div>
      </div>

      <BookTable
        books={books}
        loading={loading}
        onBookClick={(id) => navigate(`/books/${id}`)}
      />
    </div>
  );
}
