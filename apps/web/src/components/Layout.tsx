import { Outlet, Link, useLocation } from 'react-router-dom';

export function Layout() {
  const location = useLocation();

  const navItems = [
    { path: '/', label: 'Dashboard' },
    { path: '/search', label: 'Kitap Ara' },
  ];

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <header style={{
        background: '#1a365d',
        color: 'white',
        padding: '0 1.5rem',
        display: 'flex',
        alignItems: 'center',
        height: '60px',
        gap: '2rem',
      }}>
        <Link to="/" style={{ color: 'white', textDecoration: 'none', fontWeight: 700, fontSize: '1.1rem' }}>
          Kütüphane Yönetim Sistemi
        </Link>
        <nav style={{ display: 'flex', gap: '1rem' }}>
          {navItems.map(item => (
            <Link
              key={item.path}
              to={item.path}
              style={{
                color: location.pathname === item.path ? '#fff' : 'rgba(255,255,255,0.7)',
                textDecoration: 'none',
                padding: '0.5rem 1rem',
                borderRadius: '4px',
                background: location.pathname === item.path ? 'rgba(255,255,255,0.15)' : 'transparent',
                fontSize: '0.95rem',
              }}
            >
              {item.label}
            </Link>
          ))}
        </nav>
      </header>
      <main style={{ flex: 1, background: '#fafafa' }}>
        <Outlet />
      </main>
      <footer style={{ padding: '1rem 1.5rem', textAlign: 'center', color: '#999', fontSize: '0.85rem', borderTop: '1px solid #eee' }}>
        MEB Kütüphane Yönetim Sistemi — MVP
      </footer>
    </div>
  );
}
