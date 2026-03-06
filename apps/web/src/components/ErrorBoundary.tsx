import { Component, type ReactNode, type ErrorInfo } from 'react';
import { AlertTriangle, RefreshCw, Home } from 'lucide-react';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false, error: null };

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('[ErrorBoundary]', error, info.componentStack);
  }

  render() {
    if (!this.state.hasError) return this.props.children;

    return (
      <div className="error-page">
        <div className="error-card">
          <div className="error-icon">
            <AlertTriangle size={36} />
          </div>
          <h1 className="error-title">Beklenmeyen Bir Hata Oluştu</h1>
          <p className="error-message">
            Uygulama beklenmeyen bir hata ile karşılaştı. Sayfayı yenileyerek tekrar deneyebilirsiniz.
          </p>
          {this.state.error && (
            <details className="error-details">
              <summary>Hata Detayı</summary>
              <code>{this.state.error.message}</code>
            </details>
          )}
          <div className="error-actions">
            <button
              className="error-btn error-btn-primary"
              onClick={() => window.location.reload()}
            >
              <RefreshCw size={16} />
              Sayfayı Yenile
            </button>
            <button
              className="error-btn error-btn-secondary"
              onClick={() => {
                this.setState({ hasError: false, error: null });
                window.location.href = '/';
              }}
            >
              <Home size={16} />
              Ana Sayfaya Dön
            </button>
          </div>
        </div>
      </div>
    );
  }
}
