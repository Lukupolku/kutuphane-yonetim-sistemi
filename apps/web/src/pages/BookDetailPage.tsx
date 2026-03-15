import { useState, useEffect, useMemo } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, School, BookCopy, BookX, MapPin } from 'lucide-react';
import { api } from '../services/api';
import { SchoolHoldingsList } from '../components/SchoolHoldingsList';
import type { BookWithHoldings, HoldingWithSchool, Author } from '../types';

export function BookDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [data, setData] = useState<BookWithHoldings | null>(null);
  const [authorInfo, setAuthorInfo] = useState<Author | null>(null);
  const [loading, setLoading] = useState(true);
  const [filterProvince, setFilterProvince] = useState('');
  const [filterDistrict, setFilterDistrict] = useState('');

  useEffect(() => {
    if (!id) return;
    setLoading(true);
    api.getBookWithHoldings(id).then(async result => {
      setData(result);
      if (result) {
        const author = await api.getAuthorByName(result.book.authors[0]);
        setAuthorInfo(author);
      }
      setLoading(false);
    });
  }, [id]);

  // Derive provinces and districts from holdings
  const provinces = useMemo(() => {
    if (!data) return [];
    const set = new Set(data.holdings.map(h => h.school.province));
    return [...set].sort();
  }, [data]);

  const districts = useMemo(() => {
    if (!data || !filterProvince) return [];
    const set = new Set(
      data.holdings
        .filter(h => h.school.province === filterProvince)
        .map(h => h.school.district)
    );
    return [...set].sort();
  }, [data, filterProvince]);

  // Reset district when province changes
  useEffect(() => {
    setFilterDistrict('');
  }, [filterProvince]);

  // Filter holdings
  const filteredHoldings: HoldingWithSchool[] = useMemo(() => {
    if (!data) return [];
    let result = data.holdings;
    if (filterProvince) {
      result = result.filter(h => h.school.province === filterProvince);
    }
    if (filterDistrict) {
      result = result.filter(h => h.school.district === filterDistrict);
    }
    return result;
  }, [data, filterProvince, filterDistrict]);

  if (loading) {
    return (
      <div className="page-container">
        <div className="loading-state">
          <div className="loading-spinner" />
          <p>Yükleniyor...</p>
        </div>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="page-container">
        <div className="empty-state">
          <div className="empty-state-icon">
            <BookX size={40} strokeWidth={1.5} />
          </div>
          <p className="empty-state-text">Kitap bulunamadı.</p>
          <button className="btn btn--primary" onClick={() => navigate('/')} style={{ marginTop: '1rem' }}>
            Genel Bakışa Dön
          </button>
        </div>
      </div>
    );
  }

  const { book, holdings } = data;
  const totalQuantity = holdings.reduce((sum, h) => sum + h.holding.quantity, 0);
  const filteredQuantity = filteredHoldings.reduce((sum, h) => sum + h.holding.quantity, 0);

  return (
    <div className="page-container">
      <button className="back-link" onClick={() => navigate(-1)}>
        <ArrowLeft size={16} />
        Geri Dön
      </button>

      <div className="book-detail-card">
        <div className="book-detail-header" style={{ display: 'flex', gap: '1.5rem', alignItems: 'flex-start' }}>
          {book.coverImageUrl ? (
            <img
              src={book.coverImageUrl}
              alt={book.title}
              style={{ width: 120, borderRadius: 8, boxShadow: '0 2px 8px rgba(0,0,0,0.15)', flexShrink: 0 }}
            />
          ) : (
            <div style={{ width: 120, height: 170, borderRadius: 8, background: 'linear-gradient(135deg, #8b1a2b, #c0392b)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 36, fontWeight: 700, flexShrink: 0 }}>
              {book.title.charAt(0)}
            </div>
          )}
          <div>
            <h1 className="book-detail-title">{book.title}</h1>
            <p className="book-detail-author">
              {authorInfo ? (
                <span
                  style={{ cursor: 'pointer', textDecoration: 'underline', textDecorationColor: 'rgba(139,26,43,0.3)' }}
                  onClick={(e) => { e.stopPropagation(); navigate(`/authors/${authorInfo.id}`); }}
                >
                  {book.authors.join(', ')}
                </span>
              ) : (
                book.authors.join(', ')
              )}
            </p>
          </div>
        </div>
        <div className="book-detail-meta">
          {book.isbn && (
            <div className="meta-item">
              <span className="meta-item-label">ISBN</span>
              <span className="meta-item-value meta-item-value--mono">{book.isbn}</span>
            </div>
          )}
          {book.publisher && (
            <div className="meta-item">
              <span className="meta-item-label">Yayınevi</span>
              <span className="meta-item-value">{book.publisher}</span>
            </div>
          )}
          {book.publishedDate && (
            <div className="meta-item">
              <span className="meta-item-label">Basım Yılı</span>
              <span className="meta-item-value">{book.publishedDate}</span>
            </div>
          )}
          {book.pageCount && (
            <div className="meta-item">
              <span className="meta-item-label">Sayfa Sayısı</span>
              <span className="meta-item-value">{book.pageCount}</span>
            </div>
          )}
          <div className="meta-item">
            <span className="meta-item-label">Dil</span>
            <span className="meta-item-value">{book.language === 'tr' ? 'Türkçe' : book.language}</span>
          </div>
        </div>
      </div>

      <div className="holdings-header">
        <h2 className="holdings-title">Bu Kitaba Sahip Okullar</h2>
        <div className="holdings-summary">
          <span className="holdings-summary-badge cell-badge cell-badge--school">
            <School size={14} style={{ marginRight: 4 }} />
            {holdings.length} okul
          </span>
          <span className="holdings-summary-badge cell-badge cell-badge--quantity">
            <BookCopy size={14} style={{ marginRight: 4 }} />
            {totalQuantity} adet
          </span>
        </div>
      </div>

      {/* Holdings filter */}
      {provinces.length > 1 && (
        <div className="filter-bar" style={{ marginBottom: 'var(--space-lg)' }}>
          <div className="filter-bar-title">
            <MapPin size={14} />
            Okulları Filtrele
          </div>
          <div className="filter-bar-fields">
            <div className="filter-group">
              <label htmlFor="holding-province" className="filter-label">İl</label>
              <select
                id="holding-province"
                className="filter-select"
                value={filterProvince}
                onChange={e => setFilterProvince(e.target.value)}
              >
                <option value="">Tüm İller ({holdings.length} okul)</option>
                {provinces.map(p => (
                  <option key={p} value={p}>{p}</option>
                ))}
              </select>
            </div>

            <div className="filter-group">
              <label htmlFor="holding-district" className="filter-label">İlçe</label>
              <select
                id="holding-district"
                className="filter-select"
                value={filterDistrict}
                onChange={e => setFilterDistrict(e.target.value)}
                disabled={!filterProvince}
              >
                <option value="">Tüm İlçeler</option>
                {districts.map(d => (
                  <option key={d} value={d}>{d}</option>
                ))}
              </select>
            </div>
          </div>
        </div>
      )}

      {/* Show filtered count if filter active */}
      {(filterProvince || filterDistrict) && (
        <div className="scope-bar">
          <span className="scope-label">
            {filterDistrict ? `${filterProvince} / ${filterDistrict}` : filterProvince}
          </span>
          <span className="scope-count">
            {filteredHoldings.length} okul, {filteredQuantity} adet
          </span>
        </div>
      )}

      <SchoolHoldingsList holdings={filteredHoldings} />
    </div>
  );
}
