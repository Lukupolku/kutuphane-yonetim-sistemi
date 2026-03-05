import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { HierarchyFilter } from '../components/HierarchyFilter';
import { BookTable } from '../components/BookTable';
import { api } from '../services/api';
import type { FilterParams, Book } from '../types';

type BookWithStats = Book & { schoolCount: number; totalQuantity: number };

export function DashboardPage() {
  const navigate = useNavigate();
  const [filter, setFilter] = useState<FilterParams>({});
  const [books, setBooks] = useState<BookWithStats[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    api.getBooksByFilter(filter).then(result => {
      setBooks(result);
      setLoading(false);
    });
  }, [filter]);

  const scopeLabel = filter.schoolId
    ? 'Seçili Okul'
    : filter.district
    ? `${filter.province} / ${filter.district}`
    : filter.province
    ? filter.province
    : 'Tüm Türkiye';

  return (
    <div style={{ padding: '1.5rem' }}>
      <h1 style={{ fontSize: '1.5rem', marginBottom: '1rem' }}>Kütüphane Envanter Dashboard</h1>

      <HierarchyFilter onFilterChange={setFilter} />

      <div style={{ margin: '1rem 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h2 style={{ fontSize: '1.1rem', color: '#444' }}>
          {scopeLabel} — {books.length} farklı kitap
        </h2>
      </div>

      <BookTable
        books={books}
        loading={loading}
        onBookClick={(id) => navigate(`/books/${id}`)}
      />
    </div>
  );
}
