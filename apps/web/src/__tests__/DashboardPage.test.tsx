import { describe, it, expect } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { AuthProvider } from '../contexts/AuthContext';
import { DashboardPage } from '../pages/DashboardPage';

function renderWithProviders(ui: React.ReactElement) {
  return render(
    <AuthProvider>
      <MemoryRouter>
        {ui}
      </MemoryRouter>
    </AuthProvider>
  );
}

describe('DashboardPage', () => {
  it('renders stats and filter', async () => {
    renderWithProviders(<DashboardPage />);

    await waitFor(() => {
      expect(screen.getByText('Genel Bakış')).toBeInTheDocument();
      expect(screen.getByLabelText('İl')).toBeInTheDocument();
      expect(screen.getByText('Farklı Eser')).toBeInTheDocument();
    });
  });

  it('shows scope label for all Turkey by default', async () => {
    renderWithProviders(<DashboardPage />);

    await waitFor(() => {
      expect(screen.getByText(/Tüm Türkiye/)).toBeInTheDocument();
    });
  });

  it('shows school stats table', async () => {
    renderWithProviders(<DashboardPage />);

    await waitFor(() => {
      expect(screen.getByText('Okul Bazlı İstatistikler')).toBeInTheDocument();
      expect(screen.getByText('Atatürk İlkokulu')).toBeInTheDocument();
    });
  });
});
