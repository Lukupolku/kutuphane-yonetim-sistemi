import { Outlet, Link, useLocation } from 'react-router-dom';

export function Layout() {
  const location = useLocation();

  const navItems = [
    { path: '/', label: 'Dashboard', icon: '◫' },
    { path: '/search', label: 'Kitap Ara', icon: '⌕' },
  ];

  return (
    <div className="app-layout">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="sidebar-brand-icon">📚</div>
          <div className="sidebar-brand-title">Kütüphane Yönetim Sistemi</div>
          <div className="sidebar-brand-subtitle">Milli Eğitim Bakanlığı</div>
        </div>

        <nav className="sidebar-nav">
          <div className="sidebar-section-label">Ana Menü</div>
          {navItems.map(item => (
            <Link
              key={item.path}
              to={item.path}
              className={`sidebar-link ${location.pathname === item.path ? 'active' : ''}`}
            >
              <span className="sidebar-link-icon">{item.icon}</span>
              {item.label}
            </Link>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="sidebar-footer-text">
            MEB Kütüphane Yönetim Sistemi — MVP
          </div>
        </div>
      </aside>

      <main className="main-content">
        <Outlet />
      </main>
    </div>
  );
}
