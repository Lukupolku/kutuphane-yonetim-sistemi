import { useState, useEffect } from 'react';
import { MapPin } from 'lucide-react';
import { api } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import type { School, SchoolType, FilterParams } from '../types';

interface HierarchyFilterProps {
  onFilterChange: (params: FilterParams) => void;
}

const kademeLabels: Record<SchoolType, string> = {
  ILKOKUL: 'İlkokul',
  ORTAOKUL: 'Ortaokul',
  LISE: 'Lise',
};

export function HierarchyFilter({ onFilterChange }: HierarchyFilterProps) {
  const { user } = useAuth();

  const [provinces, setProvinces] = useState<string[]>([]);
  const [districts, setDistricts] = useState<string[]>([]);
  const [schools, setSchools] = useState<School[]>([]);

  const lockedProvince = user?.role === 'province' || user?.role === 'district' ? user.province : undefined;
  const lockedDistrict = user?.role === 'district' ? user.district : undefined;

  const [selectedProvince, setSelectedProvince] = useState<string>(lockedProvince ?? '');
  const [selectedDistrict, setSelectedDistrict] = useState<string>(lockedDistrict ?? '');
  const [selectedSchool, setSelectedSchool] = useState<string>('');
  const [selectedKademe, setSelectedKademe] = useState<SchoolType | ''>('');

  useEffect(() => {
    if (lockedProvince) {
      setProvinces([lockedProvince]);
    } else {
      api.getProvinces().then(setProvinces);
    }
  }, [lockedProvince]);

  useEffect(() => {
    if (selectedProvince) {
      if (lockedDistrict) {
        setDistricts([lockedDistrict]);
      } else {
        api.getDistricts(selectedProvince).then(setDistricts);
      }
    } else {
      setDistricts([]);
    }
    if (!lockedDistrict) setSelectedDistrict('');
    setSelectedSchool('');
  }, [selectedProvince, lockedDistrict]);

  useEffect(() => {
    if (selectedProvince) {
      const params: FilterParams = { province: selectedProvince };
      if (selectedDistrict) params.district = selectedDistrict;
      if (selectedKademe) params.schoolType = selectedKademe;
      api.getSchools(params).then(setSchools);
    } else {
      setSchools([]);
    }
    setSelectedSchool('');
  }, [selectedProvince, selectedDistrict, selectedKademe]);

  useEffect(() => {
    const params: FilterParams = {};
    if (selectedProvince) params.province = selectedProvince;
    if (selectedDistrict) params.district = selectedDistrict;
    if (selectedSchool) params.schoolId = selectedSchool;
    if (selectedKademe) params.schoolType = selectedKademe;
    onFilterChange(params);
  }, [selectedProvince, selectedDistrict, selectedSchool, selectedKademe]);

  return (
    <div className="filter-bar">
      <div className="filter-bar-title">
        <MapPin size={14} />
        Coğrafi Filtre
      </div>
      <div className="filter-bar-fields">
        <div className="filter-group">
          <label htmlFor="province-select" className="filter-label">İl</label>
          <select
            id="province-select"
            className="filter-select"
            value={selectedProvince}
            onChange={e => setSelectedProvince(e.target.value)}
            disabled={!!lockedProvince}
          >
            <option value="">Tüm İller</option>
            {provinces.map(p => <option key={p} value={p}>{p}</option>)}
          </select>
        </div>

        <div className="filter-group">
          <label htmlFor="district-select" className="filter-label">İlçe</label>
          <select
            id="district-select"
            className="filter-select"
            value={selectedDistrict}
            onChange={e => setSelectedDistrict(e.target.value)}
            disabled={!!lockedDistrict || !selectedProvince}
          >
            <option value="">Tüm İlçeler</option>
            {districts.map(d => <option key={d} value={d}>{d}</option>)}
          </select>
        </div>

        <div className="filter-group">
          <label htmlFor="kademe-select" className="filter-label">Kademe</label>
          <select
            id="kademe-select"
            className="filter-select"
            value={selectedKademe}
            onChange={e => setSelectedKademe(e.target.value as SchoolType | '')}
          >
            <option value="">Tüm Kademeler</option>
            {(Object.keys(kademeLabels) as SchoolType[]).map(k => (
              <option key={k} value={k}>{kademeLabels[k]}</option>
            ))}
          </select>
        </div>

        <div className="filter-group">
          <label htmlFor="school-select" className="filter-label">Okul</label>
          <select
            id="school-select"
            className="filter-select"
            value={selectedSchool}
            onChange={e => setSelectedSchool(e.target.value)}
            disabled={!selectedProvince}
          >
            <option value="">Tüm Okullar</option>
            {schools.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
          </select>
        </div>
      </div>
    </div>
  );
}
