import { useState, useEffect, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, UserX } from 'lucide-react';
import { api } from '../services/api';
import type { Author, Book } from '../types';

export function AuthorsPage() {
  const navigate = useNavigate();
  const [authors, setAuthors] = useState<Author[]>([]);
  const [books, setBooks] = useState<Book[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([api.getAuthors(), api.getBooks()]).then(([a, b]) => {
      setAuthors(a);
      setBooks(b);
      setLoading(false);
    });
  }, []);

  const bookCountMap = useMemo(() => {
    const map: Record<string, number> = {};
    for (const author of authors) {
      map[author.name] = books.filter(b => b.authors.includes(author.name)).length;
    }
    return map;
  }, [authors, books]);

  const filtered = useMemo(() => {
    if (!search) return authors;
    const q = search.toLowerCase();
    return authors.filter(a =>
      a.name.toLowerCase().includes(q) ||
      a.genres.some(g => g.toLowerCase().includes(q)) ||
      a.literaryMovement.toLowerCase().includes(q) ||
      a.categories.some(c => c.toLowerCase().includes(q))
    );
  }, [authors, search]);

  // Sort by name
  const sorted = useMemo(() =>
    [...filtered].sort((a, b) => a.name.localeCompare(b.name, 'tr')),
    [filtered]
  );

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">Yazarlar</h1>
        <p className="page-subtitle">{authors.length} yazar — isim, tür veya akım ile arayın</p>
      </div>

      <div className="search-container">
        <span className="search-icon"><Search size={18} /></span>
        <input
          type="text"
          className="search-input"
          placeholder="Yazar ara (isim, tür, akım)..."
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
      </div>

      {loading ? (
        <div className="loading-state">
          <div className="loading-spinner" />
          <p>Yükleniyor...</p>
        </div>
      ) : sorted.length === 0 ? (
        <div className="empty-state">
          <div className="empty-state-icon"><UserX size={40} strokeWidth={1.5} /></div>
          <p className="empty-state-text">Yazar bulunamadı.</p>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '1rem', marginTop: '1rem' }}>
          {sorted.map(author => {
            const count = bookCountMap[author.name] || 0;
            const lifeSpan = author.deathYear
              ? `${author.birthYear}–${author.deathYear}`
              : `${author.birthYear}–`;
            return (
              <div
                key={author.id}
                onClick={() => navigate(`/authors/${author.id}`)}
                style={{
                  display: 'flex', gap: '1rem', padding: '1rem',
                  background: '#fff', borderRadius: 12, border: '1px solid #e5e7eb',
                  cursor: 'pointer', transition: 'box-shadow 0.2s',
                }}
                onMouseEnter={e => (e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.1)')}
                onMouseLeave={e => (e.currentTarget.style.boxShadow = 'none')}
              >
                {author.photoUrl ? (
                  <img src={author.photoUrl} alt={author.name}
                    style={{
                      width: 56, height: 56, borderRadius: '50%', flexShrink: 0,
                      objectFit: 'cover'
                    }} />
                ) : (
                  <div style={{
                    width: 56, height: 56, borderRadius: '50%', flexShrink: 0,
                    background: 'linear-gradient(135deg, #8b1a2b, #c0392b)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    color: '#fff', fontSize: 22, fontWeight: 700
                  }}>
                    {author.name.charAt(0)}
                  </div>
                )}
                <div style={{ minWidth: 0, flex: 1 }}>
                  <div style={{ fontWeight: 600, fontSize: '0.95rem', color: '#1a1a2e' }}>{author.name}</div>
                  <div style={{ fontSize: '0.8rem', color: '#888', marginTop: 2 }}>
                    {lifeSpan} · {author.literaryMovement}
                  </div>
                  <div style={{ display: 'flex', gap: '0.5rem', marginTop: 6, flexWrap: 'wrap' }}>
                    {author.genres.slice(0, 3).map(g => (
                      <span key={g} style={{
                        fontSize: '0.7rem', padding: '2px 8px', borderRadius: 99,
                        background: '#f3f4f6', color: '#555'
                      }}>{g}</span>
                    ))}
                    <span style={{
                      fontSize: '0.7rem', padding: '2px 8px', borderRadius: 99,
                      background: '#fef3c7', color: '#92400e', fontWeight: 600
                    }}>{count} eser</span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
