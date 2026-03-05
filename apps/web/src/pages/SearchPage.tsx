import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../services/api';
import { BookTable } from '../components/BookTable';
import type { Book } from '../types';

export function SearchPage() {
  const navigate = useNavigate();
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Book[]>([]);
  const [searched, setSearched] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSearch = async () => {
    if (!query.trim()) return;
    setLoading(true);
    setSearched(true);
    const books = await api.searchBooks(query.trim());
    setResults(books);
    setLoading(false);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') handleSearch();
  };

  return (
    <div style={{ padding: '1.5rem', maxWidth: '900px', margin: '0 auto' }}>
      <h1 style={{ fontSize: '1.5rem', marginBottom: '1rem' }}>Kitap Ara</h1>

      <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1.5rem' }}>
        <input
          type="text"
          placeholder="Başlık, yazar veya ISBN ile ara..."
          value={query}
          onChange={e => setQuery(e.target.value)}
          onKeyDown={handleKeyDown}
          aria-label="Kitap arama"
          style={{ flex: 1, padding: '10px 14px', borderRadius: '6px', border: '1px solid #ccc', fontSize: '1rem' }}
        />
        <button
          onClick={handleSearch}
          disabled={loading || !query.trim()}
          style={{
            padding: '10px 24px',
            borderRadius: '6px',
            border: 'none',
            background: '#1a365d',
            color: 'white',
            fontSize: '1rem',
            cursor: 'pointer',
          }}
        >
          Ara
        </button>
      </div>

      {loading && <p style={{ textAlign: 'center', color: '#666' }}>Aranıyor...</p>}

      {searched && !loading && results.length === 0 && (
        <p style={{ textAlign: 'center', color: '#666', padding: '2rem' }}>
          "{query}" için sonuç bulunamadı.
        </p>
      )}

      {results.length > 0 && (
        <>
          <p style={{ color: '#666', marginBottom: '0.5rem' }}>{results.length} sonuç bulundu</p>
          <BookTable
            books={results}
            onBookClick={(id) => navigate(`/books/${id}`)}
          />
        </>
      )}
    </div>
  );
}
