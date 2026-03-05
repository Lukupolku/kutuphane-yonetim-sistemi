import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { api } from '../services/api';
import { SchoolHoldingsList } from '../components/SchoolHoldingsList';
import type { BookWithHoldings } from '../types';

export function BookDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [data, setData] = useState<BookWithHoldings | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) return;
    setLoading(true);
    api.getBookWithHoldings(id).then(result => {
      setData(result);
      setLoading(false);
    });
  }, [id]);

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
          <div className="empty-state-icon">📖</div>
          <p className="empty-state-text">Kitap bulunamadı.</p>
          <button className="btn btn--primary" onClick={() => navigate('/')} style={{ marginTop: '1rem' }}>
            Dashboard'a Dön
          </button>
        </div>
      </div>
    );
  }

  const { book, holdings } = data;
  const totalQuantity = holdings.reduce((sum, h) => sum + h.holding.quantity, 0);

  return (
    <div className="page-container">
      <button className="back-link" onClick={() => navigate(-1)}>
        ← Geri Dön
      </button>

      <div className="book-detail-card">
        <div className="book-detail-header">
          <h1 className="book-detail-title">{book.title}</h1>
          <p className="book-detail-author">{book.authors.join(', ')}</p>
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
            🏫 {holdings.length} okul
          </span>
          <span className="holdings-summary-badge cell-badge cell-badge--quantity">
            📚 {totalQuantity} adet
          </span>
        </div>
      </div>

      <SchoolHoldingsList holdings={holdings} />
    </div>
  );
}
