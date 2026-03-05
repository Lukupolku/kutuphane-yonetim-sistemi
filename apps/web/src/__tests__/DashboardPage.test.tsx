import { describe, it, expect } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { DashboardPage } from '../pages/DashboardPage';

describe('DashboardPage', () => {
  it('renders filter and book table', async () => {
    render(
      <MemoryRouter>
        <DashboardPage />
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByText('Kütüphane Envanter Dashboard')).toBeInTheDocument();
      expect(screen.getByLabelText('İl')).toBeInTheDocument();
      // Should show books after loading
      expect(screen.getByText('Küçük Prens')).toBeInTheDocument();
    });
  });

  it('shows scope label for all Turkey by default', async () => {
    render(
      <MemoryRouter>
        <DashboardPage />
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByText(/Tüm Türkiye/)).toBeInTheDocument();
    });
  });
});
