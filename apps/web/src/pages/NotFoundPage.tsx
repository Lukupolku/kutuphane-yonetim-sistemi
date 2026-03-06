import { useNavigate } from 'react-router-dom';
import { SearchX, Home, ArrowLeft } from 'lucide-react';

export function NotFoundPage() {
  const navigate = useNavigate();

  return (
    <div className="error-page">
      <div className="error-card">
        <div className="error-icon error-icon--404">
          <SearchX size={36} />
        </div>
        <h1 className="error-title">Sayfa Bulunamadı</h1>
        <p className="error-code">404</p>
        <p className="error-message">
          Aradığınız sayfa mevcut değil veya kaldırılmış olabilir.
        </p>
        <div className="error-actions">
          <button
            className="error-btn error-btn-primary"
            onClick={() => navigate('/')}
          >
            <Home size={16} />
            Ana Sayfaya Dön
          </button>
          <button
            className="error-btn error-btn-secondary"
            onClick={() => navigate(-1)}
          >
            <ArrowLeft size={16} />
            Geri Dön
          </button>
        </div>
      </div>
    </div>
  );
}
