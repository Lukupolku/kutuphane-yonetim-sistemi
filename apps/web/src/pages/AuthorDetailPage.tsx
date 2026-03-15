import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, BookOpen, Calendar, Tag, UserX } from 'lucide-react';
import { api } from '../services/api';
import type { Author, Book } from '../types';

const SUITABILITY_LABELS: Record<string, { label: string; color: string }> = {
  uygun: { label: 'Lise İçin Uygun', color: '#27ae60' },
  secici: { label: 'Seçici Okunmalı', color: '#e67e22' },
  rehberli: { label: 'Rehberli Okunmalı', color: '#e74c3c' },
};

export function AuthorDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [author, setAuthor] = useState<Author | null>(null);
  const [books, setBooks] = useState<Book[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) return;
    setLoading(true);
    api.getAuthorById(id).then(async (result) => {
      setAuthor(result);
      if (result) {
        const authorBooks = await api.getBooksByAuthor(result.name);
        setBooks(authorBooks);
      }
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

  if (!author) {
    return (
      <div className="page-container">
        <div className="empty-state">
          <div className="empty-state-icon"><UserX size={40} strokeWidth={1.5} /></div>
          <p className="empty-state-text">Yazar bulunamadı.</p>
          <button className="btn btn--primary" onClick={() => navigate('/authors')} style={{ marginTop: '1rem' }}>
            Yazar Listesine Dön
          </button>
        </div>
      </div>
    );
  }

  const suitability = SUITABILITY_LABELS[author.suitability] || SUITABILITY_LABELS.uygun;
  const lifeSpan = author.deathYear
    ? `${author.birthYear} – ${author.deathYear}`
    : `${author.birthYear} – günümüz`;

  return (
    <div className="page-container">
      <button className="back-link" onClick={() => navigate(-1)}>
        <ArrowLeft size={16} /> Geri Dön
      </button>

      <div className="book-detail-card">
        <div className="book-detail-header" style={{ display: 'flex', gap: '1.5rem', alignItems: 'flex-start' }}>
          <div style={{
            width: 100, height: 100, borderRadius: '50%',
            background: 'linear-gradient(135deg, #8b1a2b, #c0392b)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff', fontSize: 36, fontWeight: 700, flexShrink: 0
          }}>
            {author.name.charAt(0)}
          </div>
          <div>
            <h1 className="book-detail-title">{author.name}</h1>
            <p style={{ color: '#666', marginTop: 4, display: 'flex', alignItems: 'center', gap: 6 }}>
              <Calendar size={14} /> {lifeSpan}
            </p>
            <p style={{ color: '#888', marginTop: 4, fontSize: '0.9rem' }}>{author.literaryMovement}</p>
          </div>
        </div>

        <div className="book-detail-meta">
          <div className="meta-item">
            <span className="meta-item-label">Türler</span>
            <span className="meta-item-value">{author.genres.join(', ')}</span>
          </div>
          <div className="meta-item">
            <span className="meta-item-label">Kategoriler</span>
            <span className="meta-item-value">{author.categories.join(', ')}</span>
          </div>
          <div className="meta-item">
            <span className="meta-item-label">Lise Uygunluğu</span>
            <span className="meta-item-value" style={{ color: suitability.color, fontWeight: 600 }}>
              {suitability.label}
            </span>
          </div>
          <div className="meta-item">
            <span className="meta-item-label">Kitap Sayısı</span>
            <span className="meta-item-value">{books.length}</span>
          </div>
        </div>

        {author.note && (
          <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid #eee', color: '#555', fontSize: '0.9rem', lineHeight: 1.6 }}>
            <Tag size={14} style={{ marginRight: 6, verticalAlign: 'middle' }} />
            {author.note}
          </div>
        )}
      </div>

      <div className="holdings-header" style={{ marginTop: '2rem' }}>
        <h2 className="holdings-title">
          <BookOpen size={20} style={{ marginRight: 8, verticalAlign: 'middle' }} />
          Eserleri
        </h2>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '1rem', marginTop: '1rem' }}>
        {books.map(book => (
          <div
            key={book.id}
            onClick={() => navigate(`/books/${book.id}`)}
            style={{
              display: 'flex', gap: '1rem', padding: '1rem',
              background: '#fff', borderRadius: 12, border: '1px solid #e5e7eb',
              cursor: 'pointer', transition: 'box-shadow 0.2s',
            }}
            onMouseEnter={e => (e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.1)')}
            onMouseLeave={e => (e.currentTarget.style.boxShadow = 'none')}
          >
            {book.coverImageUrl ? (
              <img src={book.coverImageUrl} alt={book.title}
                style={{ width: 60, height: 85, objectFit: 'cover', borderRadius: 6, flexShrink: 0 }} />
            ) : (
              <div style={{
                width: 60, height: 85, borderRadius: 6, flexShrink: 0,
                background: 'linear-gradient(135deg, #8b1a2b, #c0392b)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: '#fff', fontSize: 20, fontWeight: 700
              }}>
                {book.title.charAt(0)}
              </div>
            )}
            <div style={{ minWidth: 0 }}>
              <div style={{ fontWeight: 600, fontSize: '0.95rem', color: '#1a1a2e' }}>{book.title}</div>
              {book.pageCount && (
                <div style={{ fontSize: '0.8rem', color: '#888', marginTop: 4 }}>{book.pageCount} sayfa</div>
              )}
              {book.publisher && (
                <div style={{ fontSize: '0.8rem', color: '#888', marginTop: 2 }}>{book.publisher}</div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
