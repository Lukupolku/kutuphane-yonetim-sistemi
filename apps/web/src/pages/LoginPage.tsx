import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { LogIn } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import type { UserRole } from '../contexts/AuthContext';
import { api } from '../services/api';
import type { School } from '../types';

const roleLabels: Record<UserRole, string> = {
  ministry: 'Bakanlık',
  province: 'İl Müdürlüğü',
  district: 'İlçe Müdürlüğü',
  school: 'Okul',
};

export function LoginPage() {
  const navigate = useNavigate();
  const { login } = useAuth();

  const [role, setRole] = useState<UserRole>('school');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');

  const [provinces, setProvinces] = useState<string[]>([]);
  const [districts, setDistricts] = useState<string[]>([]);
  const [schools, setSchools] = useState<School[]>([]);

  const [selectedProvince, setSelectedProvince] = useState('');
  const [selectedDistrict, setSelectedDistrict] = useState('');
  const [selectedSchool, setSelectedSchool] = useState('');

  useEffect(() => {
    api.getProvinces().then(setProvinces);
  }, []);

  useEffect(() => {
    if (selectedProvince) {
      api.getDistricts(selectedProvince).then(setDistricts);
    } else {
      setDistricts([]);
    }
    setSelectedDistrict('');
    setSelectedSchool('');
  }, [selectedProvince]);

  useEffect(() => {
    if (selectedProvince && selectedDistrict) {
      api.getSchools({ province: selectedProvince, district: selectedDistrict }).then(setSchools);
    } else if (selectedProvince) {
      api.getSchools({ province: selectedProvince }).then(setSchools);
    } else {
      setSchools([]);
    }
    setSelectedSchool('');
  }, [selectedProvince, selectedDistrict]);

  const needsProvince = role === 'province' || role === 'district' || role === 'school';
  const needsDistrict = role === 'district' || role === 'school';
  const needsSchool = role === 'school';

  const canSubmit = () => {
    if (!username.trim() || !password.trim()) return false;
    if (needsProvince && !selectedProvince) return false;
    if (needsDistrict && !selectedDistrict) return false;
    if (needsSchool && !selectedSchool) return false;
    return true;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!canSubmit()) return;

    const school = schools.find(s => s.id === selectedSchool);

    login({
      username: username.trim(),
      role,
      province: needsProvince ? selectedProvince : undefined,
      district: needsDistrict ? selectedDistrict : undefined,
      schoolId: needsSchool ? selectedSchool : undefined,
      schoolName: school?.name,
    });

    navigate('/');
  };

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="login-header">
          <img
            src="/meb-logo-text.png"
            alt="T.C. Millî Eğitim Bakanlığı"
            className="login-meb-logo"
          />
          <h1 className="login-title">Kütüphane Yönetim Sistemi</h1>
        </div>

        <form className="login-form" onSubmit={handleSubmit}>
          <div className="login-field">
            <label htmlFor="role">Giriş Türü</label>
            <select
              id="role"
              className="filter-select"
              value={role}
              onChange={e => {
                setRole(e.target.value as UserRole);
                setSelectedProvince('');
              }}
            >
              {Object.entries(roleLabels).map(([value, label]) => (
                <option key={value} value={value}>{label}</option>
              ))}
            </select>
          </div>

          {needsProvince && (
            <div className="login-field">
              <label htmlFor="login-province">İl</label>
              <select
                id="login-province"
                className="filter-select"
                value={selectedProvince}
                onChange={e => setSelectedProvince(e.target.value)}
              >
                <option value="">İl seçin</option>
                {provinces.map(p => <option key={p} value={p}>{p}</option>)}
              </select>
            </div>
          )}

          {needsDistrict && (
            <div className="login-field">
              <label htmlFor="login-district">İlçe</label>
              <select
                id="login-district"
                className="filter-select"
                value={selectedDistrict}
                onChange={e => setSelectedDistrict(e.target.value)}
                disabled={!selectedProvince}
              >
                <option value="">İlçe seçin</option>
                {districts.map(d => <option key={d} value={d}>{d}</option>)}
              </select>
            </div>
          )}

          {needsSchool && (
            <div className="login-field">
              <label htmlFor="login-school">Okul</label>
              <select
                id="login-school"
                className="filter-select"
                value={selectedSchool}
                onChange={e => setSelectedSchool(e.target.value)}
                disabled={!selectedProvince}
              >
                <option value="">Okul seçin</option>
                {schools.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
            </div>
          )}

          <div className="login-field">
            <label htmlFor="username">Kullanıcı Adı</label>
            <input
              id="username"
              type="text"
              className="login-input"
              placeholder="Kullanıcı adınızı girin"
              value={username}
              onChange={e => setUsername(e.target.value)}
            />
          </div>

          <div className="login-field">
            <label htmlFor="password">Şifre</label>
            <input
              id="password"
              type="password"
              className="login-input"
              placeholder="Şifrenizi girin"
              value={password}
              onChange={e => setPassword(e.target.value)}
            />
          </div>

          <button type="submit" className="login-button" disabled={!canSubmit()}>
            <LogIn size={18} />
            Giriş Yap
          </button>

          <p className="login-hint">
            Mock mod — herhangi bir kullanıcı adı ve şifre ile giriş yapabilirsiniz.
          </p>
        </form>
      </div>
    </div>
  );
}
