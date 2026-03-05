import { useState, useEffect } from 'react';
import { api } from '../services/api';
import type { School, FilterParams } from '../types';

interface HierarchyFilterProps {
  onFilterChange: (params: FilterParams) => void;
}

export function HierarchyFilter({ onFilterChange }: HierarchyFilterProps) {
  const [provinces, setProvinces] = useState<string[]>([]);
  const [districts, setDistricts] = useState<string[]>([]);
  const [schools, setSchools] = useState<School[]>([]);

  const [selectedProvince, setSelectedProvince] = useState<string>('');
  const [selectedDistrict, setSelectedDistrict] = useState<string>('');
  const [selectedSchool, setSelectedSchool] = useState<string>('');

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
    if (selectedProvince) {
      const params: FilterParams = { province: selectedProvince };
      if (selectedDistrict) params.district = selectedDistrict;
      api.getSchools(params).then(setSchools);
    } else {
      setSchools([]);
    }
    setSelectedSchool('');
  }, [selectedProvince, selectedDistrict]);

  useEffect(() => {
    const params: FilterParams = {};
    if (selectedProvince) params.province = selectedProvince;
    if (selectedDistrict) params.district = selectedDistrict;
    if (selectedSchool) params.schoolId = selectedSchool;
    onFilterChange(params);
  }, [selectedProvince, selectedDistrict, selectedSchool]);

  return (
    <div className="filter-bar">
      <div className="filter-bar-title">
        <span>📍</span> Coğrafi Filtre
      </div>
      <div className="filter-bar-fields">
        <div className="filter-group">
          <label htmlFor="province-select" className="filter-label">İl</label>
          <select
            id="province-select"
            className="filter-select"
            value={selectedProvince}
            onChange={e => setSelectedProvince(e.target.value)}
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
            disabled={!selectedProvince}
          >
            <option value="">Tüm İlçeler</option>
            {districts.map(d => <option key={d} value={d}>{d}</option>)}
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
