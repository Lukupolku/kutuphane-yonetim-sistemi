import { Outlet, Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, Search, BookOpen, GraduationCap } from 'lucide-react';

export function Layout() {
  const location = useLocation();

  const navItems = [
    { path: '/', label: 'Genel Bakış', icon: LayoutDashboard },
    { path: '/search', label: 'Kitap Ara', icon: Search },
  ];

  return (
    <div className="app-layout">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="sidebar-brand-icon">
            <BookOpen size={22} color="#fff" />
          </div>
          <div className="sidebar-brand-title">Kütüphane Yönetim Sistemi</div>
          <div className="sidebar-brand-subtitle">
            <GraduationCap size={11} style={{ marginRight: 4, verticalAlign: 'middle' }} />
            Milli Eğitim Bakanlığı
          </div>
        </div>

        <nav className="sidebar-nav">
          <div className="sidebar-section-label">Ana Menü</div>
          {navItems.map(item => {
            const Icon = item.icon;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`sidebar-link ${location.pathname === item.path ? 'active' : ''}`}
              >
                <span className="sidebar-link-icon">
                  <Icon size={18} />
                </span>
                {item.label}
              </Link>
            );
          })}
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
