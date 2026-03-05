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
    return <div style={{ padding: '2rem', textAlign: 'center' }}>Yükleniyor...</div>;
  }

  if (!data) {
    return (
      <div style={{ padding: '2rem', textAlign: 'center' }}>
        <p>Kitap bulunamadı.</p>
        <button onClick={() => navigate('/')} style={{ marginTop: '1rem', padding: '8px 16px', cursor: 'pointer' }}>
          Dashboard'a Dön
        </button>
      </div>
    );
  }

  const { book, holdings } = data;
  const totalQuantity = holdings.reduce((sum, h) => sum + h.holding.quantity, 0);

  return (
    <div style={{ padding: '1.5rem', maxWidth: '900px', margin: '0 auto' }}>
      <button
        onClick={() => navigate(-1)}
        style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#0066cc', fontSize: '0.95rem', marginBottom: '1rem', padding: 0 }}
      >
        ← Geri
      </button>

      <div style={{ background: '#f9f9f9', borderRadius: '8px', padding: '1.5rem', marginBottom: '2rem' }}>
        <h1 style={{ fontSize: '1.5rem', marginBottom: '0.5rem' }}>{book.title}</h1>
        <p style={{ color: '#555', fontSize: '1.1rem', marginBottom: '1rem' }}>{book.authors.join(', ')}</p>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '0.75rem' }}>
          {book.isbn && (
            <div>
              <span style={{ fontSize: '0.85rem', color: '#888' }}>ISBN</span>
              <p style={{ fontFamily: 'monospace', margin: '2px 0' }}>{book.isbn}</p>
            </div>
          )}
          {book.publisher && (
            <div>
              <span style={{ fontSize: '0.85rem', color: '#888' }}>Yayınevi</span>
              <p style={{ margin: '2px 0' }}>{book.publisher}</p>
            </div>
          )}
          {book.publishedDate && (
            <div>
              <span style={{ fontSize: '0.85rem', color: '#888' }}>Basım Yılı</span>
              <p style={{ margin: '2px 0' }}>{book.publishedDate}</p>
            </div>
          )}
          {book.pageCount && (
            <div>
              <span style={{ fontSize: '0.85rem', color: '#888' }}>Sayfa Sayısı</span>
              <p style={{ margin: '2px 0' }}>{book.pageCount}</p>
            </div>
          )}
        </div>
      </div>

      <div style={{ marginBottom: '1rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h2 style={{ fontSize: '1.2rem' }}>Bu Kitaba Sahip Okullar</h2>
        <span style={{ color: '#666' }}>
          {holdings.length} okul, toplam {totalQuantity} adet
        </span>
      </div>

      <SchoolHoldingsList holdings={holdings} />
    </div>
  );
}
