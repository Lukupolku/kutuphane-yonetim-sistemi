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

  // Load provinces on mount
  useEffect(() => {
    api.getProvinces().then(setProvinces);
  }, []);

  // Load districts when province changes
  useEffect(() => {
    if (selectedProvince) {
      api.getDistricts(selectedProvince).then(setDistricts);
    } else {
      setDistricts([]);
    }
    setSelectedDistrict('');
    setSelectedSchool('');
  }, [selectedProvince]);

  // Load schools when district changes
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

  // Notify parent of filter changes
  useEffect(() => {
    const params: FilterParams = {};
    if (selectedProvince) params.province = selectedProvince;
    if (selectedDistrict) params.district = selectedDistrict;
    if (selectedSchool) params.schoolId = selectedSchool;
    onFilterChange(params);
  }, [selectedProvince, selectedDistrict, selectedSchool]);

  return (
    <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', padding: '1rem', background: '#f5f5f5', borderRadius: '8px' }}>
      <div>
        <label htmlFor="province-select" style={{ display: 'block', fontSize: '0.85rem', marginBottom: '4px', fontWeight: 600 }}>İl</label>
        <select
          id="province-select"
          value={selectedProvince}
          onChange={e => setSelectedProvince(e.target.value)}
          style={{ padding: '8px 12px', borderRadius: '4px', border: '1px solid #ccc', minWidth: '160px' }}
        >
          <option value="">Tüm İller</option>
          {provinces.map(p => <option key={p} value={p}>{p}</option>)}
        </select>
      </div>

      <div>
        <label htmlFor="district-select" style={{ display: 'block', fontSize: '0.85rem', marginBottom: '4px', fontWeight: 600 }}>İlçe</label>
        <select
          id="district-select"
          value={selectedDistrict}
          onChange={e => setSelectedDistrict(e.target.value)}
          disabled={!selectedProvince}
          style={{ padding: '8px 12px', borderRadius: '4px', border: '1px solid #ccc', minWidth: '160px' }}
        >
          <option value="">Tüm İlçeler</option>
          {districts.map(d => <option key={d} value={d}>{d}</option>)}
        </select>
      </div>

      <div>
        <label htmlFor="school-select" style={{ display: 'block', fontSize: '0.85rem', marginBottom: '4px', fontWeight: 600 }}>Okul</label>
        <select
          id="school-select"
          value={selectedSchool}
          onChange={e => setSelectedSchool(e.target.value)}
          disabled={!selectedProvince}
          style={{ padding: '8px 12px', borderRadius: '4px', border: '1px solid #ccc', minWidth: '200px' }}
        >
          <option value="">Tüm Okullar</option>
          {schools.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
        </select>
      </div>
    </div>
  );
}
