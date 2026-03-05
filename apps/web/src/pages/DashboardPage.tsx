import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { BookOpenText, Layers, School } from 'lucide-react';
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

  const totalBooks = books.length;
  const totalQuantity = books.reduce((sum, b) => sum + b.totalQuantity, 0);
  const totalHoldings = books.reduce((sum, b) => sum + b.schoolCount, 0);

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">Genel Bakış</h1>
        <p className="page-subtitle">Okulların kütüphane envanterlerini görüntüleyin ve filtreleyin</p>
      </div>

      <div className="stats-grid">
        <div className="stat-card stat-card--primary">
          <div className="stat-card-icon">
            <BookOpenText size={20} />
          </div>
          <div className="stat-card-label">Farklı Eser</div>
          <div className="stat-card-value">{totalBooks}</div>
          <div className="stat-card-detail">benzersiz kitap</div>
        </div>
        <div className="stat-card stat-card--accent">
          <div className="stat-card-icon">
            <Layers size={20} />
          </div>
          <div className="stat-card-label">Toplam Kopya</div>
          <div className="stat-card-value">{totalQuantity}</div>
          <div className="stat-card-detail">fiziksel adet</div>
        </div>
        <div className="stat-card">
          <div className="stat-card-icon">
            <School size={20} />
          </div>
          <div className="stat-card-label">Okul Kaydı</div>
          <div className="stat-card-value">{totalHoldings}</div>
          <div className="stat-card-detail">envanter girişi</div>
        </div>
      </div>

      <HierarchyFilter onFilterChange={setFilter} />

      <div className="scope-bar">
        <span className="scope-label">{scopeLabel}</span>
        <span className="scope-count">{books.length} farklı kitap</span>
      </div>

      <BookTable
        books={books}
        loading={loading}
        onBookClick={(id) => navigate(`/books/${id}`)}
      />
    </div>
  );
}
