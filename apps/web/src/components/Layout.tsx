import { useState, useEffect } from 'react';
import { Outlet, Link, useLocation, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Search, GitCompareArrows, ShieldCheck, User, LogOut, X, Menu } from 'lucide-react';
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
  const [showLogoutModal, setShowLogoutModal] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  // Close sidebar on route change (mobile)
  useEffect(() => {
    setSidebarOpen(false);
  }, [location.pathname]);

  const navItems = [
    { path: '/', label: 'Genel Bakış', icon: LayoutDashboard },
    { path: '/search', label: 'Kitap Kataloğu', icon: Search },
    ...(user?.role !== 'school' ? [{ path: '/compare', label: 'Karşılaştırma', icon: GitCompareArrows }] : []),
  ];

  const handleLogout = () => {
    setShowLogoutModal(false);
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
      {/* Mobile top navbar */}
      <header className="mobile-header">
        <img src="/favicon.png" alt="MEB" className="mobile-header-logo" />
        <span className="mobile-header-title">Okul Kütüphaneleri</span>
        <button className="mobile-menu-btn" onClick={() => setSidebarOpen(true)}>
          <Menu size={22} />
        </button>
      </header>

      {/* Sidebar overlay for mobile */}
      {sidebarOpen && (
        <div className="sidebar-overlay" onClick={() => setSidebarOpen(false)} />
      )}

      <aside className={`sidebar ${sidebarOpen ? 'sidebar--open' : ''}`}>
        <div className="sidebar-brand">
          <img
            src="/meb-logo-text.png"
            alt="MEB Logo"
            className="sidebar-brand-logo"
          />
          <div className="sidebar-brand-title">Okul Kütüphaneleri Yönetim Sistemi</div>
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
            <button className="sidebar-safe-logout" onClick={() => setShowLogoutModal(true)}>
              <ShieldCheck size={16} />
              <span>Güvenli Çıkış</span>
            </button>
          </div>
        )}

        <div className="sidebar-footer">
          <div className="sidebar-footer-text">
            MEB Okul Kütüphaneleri Yönetim Sistemi
          </div>
        </div>
      </aside>

      <main className="main-content">
        <Outlet />
      </main>

      {showLogoutModal && (
        <div className="modal-overlay" onClick={() => setShowLogoutModal(false)}>
          <div className="modal-card" onClick={e => e.stopPropagation()}>
            <button className="modal-close" onClick={() => setShowLogoutModal(false)}>
              <X size={18} />
            </button>
            <div className="modal-icon">
              <LogOut size={28} />
            </div>
            <h3 className="modal-title">Çıkış Yap</h3>
            <p className="modal-message">
              Oturumunuzu kapatmak istediğinize emin misiniz?
            </p>
            <div className="modal-actions">
              <button className="modal-btn modal-btn-cancel" onClick={() => setShowLogoutModal(false)}>
                İptal
              </button>
              <button className="modal-btn modal-btn-confirm" onClick={handleLogout}>
                <LogOut size={16} />
                Çıkış Yap
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
