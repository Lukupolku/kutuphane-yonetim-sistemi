import { Outlet, Link, useLocation, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Search, GitCompareArrows, LogOut, User } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

const roleLabels = {
  ministry: 'Bakanlık',
  province: 'İl Müdürlüğü',
  district: 'İlçe Müdürlüğü',
  school: 'Okul',
} as const;

export function Layout() {
  const location = useLocation();
  const navigate = useNavigate();
  const { user, logout } = useAuth();

  const navItems = [
    { path: '/', label: 'Genel Bakış', icon: LayoutDashboard },
    { path: '/search', label: 'Kitap Kataloğu', icon: Search },
    ...(user?.role !== 'school' ? [{ path: '/compare', label: 'Karşılaştırma', icon: GitCompareArrows }] : []),
  ];

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const scopeText = user?.role === 'school'
    ? user.schoolName
    : user?.role === 'district'
    ? `${user.province} / ${user.district}`
    : user?.role === 'province'
    ? user.province
    : 'Tüm Türkiye';

  return (
    <div className="app-layout">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <img
            src="/meb-logo-text.png"
            alt="MEB Logo"
            className="sidebar-brand-logo"
          />
          <div className="sidebar-brand-title">Kütüphane Yönetim Sistemi</div>
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

        {user && (
          <div className="sidebar-user">
            <div className="sidebar-user-info">
              <div className="sidebar-user-avatar">
                <User size={16} />
              </div>
              <div className="sidebar-user-details">
                <div className="sidebar-user-name">{user.username}</div>
                <div className="sidebar-user-role">{roleLabels[user.role]}</div>
                {scopeText && (
                  <div className="sidebar-user-scope">{scopeText}</div>
                )}
              </div>
            </div>
            <button className="sidebar-logout" onClick={handleLogout} title="Çıkış Yap">
              <LogOut size={16} />
            </button>
          </div>
        )}

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
