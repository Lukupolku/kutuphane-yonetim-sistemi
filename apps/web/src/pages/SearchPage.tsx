import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, SearchX } from 'lucide-react';
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
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">Kitap Ara</h1>
        <p className="page-subtitle">Başlık, yazar veya ISBN numarası ile tüm katalogda arama yapın</p>
      </div>

      <div className="search-bar-row">
        <div className="search-container">
          <span className="search-icon">
            <Search size={18} />
          </span>
          <input
            type="text"
            className="search-input"
            placeholder="Başlık, yazar veya ISBN ile ara..."
            value={query}
            onChange={e => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            aria-label="Kitap arama"
          />
        </div>
        <button
          className="btn-search"
          onClick={handleSearch}
          disabled={loading || !query.trim()}
        >
          Ara
        </button>
      </div>

      {loading && (
        <div className="loading-state">
          <div className="loading-spinner" />
          <p>Aranıyor...</p>
        </div>
      )}

      {searched && !loading && results.length === 0 && (
        <div className="empty-state">
          <div className="empty-state-icon">
            <SearchX size={40} strokeWidth={1.5} />
          </div>
          <p className="empty-state-text">"{query}" için sonuç bulunamadı.</p>
        </div>
      )}

      {results.length > 0 && (
        <>
          <p className="results-count">{results.length} sonuç bulundu</p>
          <BookTable
            books={results}
            onBookClick={(id) => navigate(`/books/${id}`)}
          />
        </>
      )}
    </div>
  );
}
