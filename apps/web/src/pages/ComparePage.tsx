import { useState, useEffect, useMemo, useCallback } from 'react';
import { GitCompareArrows, Download, Filter, ArrowUp, ArrowDown, ArrowUpDown } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { api } from '../services/api';
import type { ComparisonRow } from '../services/api';
import type { School, SchoolType, FilterParams } from '../types';
import { downloadCsv } from '../utils/csv-export';

const MAX_COMPARE = 8;

type ViewFilter = 'all' | 'missing' | 'shared';
type SortKey = 'title' | 'author' | 'total' | 'coverage' | string; // string for school IDs
type SortDir = 'asc' | 'desc' | null;

function getHeatClass(qty: number, maxQty: number): string {
  if (qty === 0) return '';
  if (maxQty <= 1) return 'heat-1';
  const ratio = qty / maxQty;
  if (ratio <= 0.2) return 'heat-1';
  if (ratio <= 0.4) return 'heat-2';
  if (ratio <= 0.6) return 'heat-3';
  if (ratio <= 0.8) return 'heat-4';
  return 'heat-5';
}

export function ComparePage() {
  const { user } = useAuth();

  const [provinces, setProvinces] = useState<string[]>([]);
  const [districts, setDistricts] = useState<string[]>([]);
  const [selectedProvince, setSelectedProvince] = useState(user?.province ?? '');
  const [selectedDistrict, setSelectedDistrict] = useState(user?.district ?? '');
  const [selectedKademe, setSelectedKademe] = useState<SchoolType | ''>('');

  const [allSchools, setAllSchools] = useState<School[]>([]);
  const [selectedSchoolIds, setSelectedSchoolIds] = useState<Set<string>>(new Set());
  const [rows, setRows] = useState<ComparisonRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [viewFilter, setViewFilter] = useState<ViewFilter>('all');
  const [schoolSearch, setSchoolSearch] = useState('');
  const [schoolKademeFilter, setSchoolKademeFilter] = useState<SchoolType | ''>('');

  const [sortKey, setSortKey] = useState<SortKey>('title');
  const [sortDir, setSortDir] = useState<SortDir>(null);

  const lockedProvince = user?.role === 'province' || user?.role === 'district';
  const lockedDistrict = user?.role === 'district';

  useEffect(() => {
    if (lockedProvince) {
      setProvinces(user?.province ? [user.province] : []);
    } else {
      api.getProvinces().then(setProvinces);
    }
  }, [lockedProvince, user?.province]);

  useEffect(() => {
    if (selectedProvince) {
      if (lockedDistrict) {
        setDistricts(user?.district ? [user.district] : []);
      } else {
        api.getDistricts(selectedProvince).then(setDistricts);
      }
    } else {
      setDistricts([]);
    }
    if (!lockedDistrict) setSelectedDistrict('');
  }, [selectedProvince, lockedDistrict, user?.district]);

  // Fetch available schools when scope changes
  useEffect(() => {
    if (!selectedProvince) {
      setAllSchools([]);
      setSelectedSchoolIds(new Set());
      setRows([]);
      return;
    }

    const params: FilterParams = { province: selectedProvince };
    if (selectedDistrict) params.district = selectedDistrict;
    if (selectedKademe) params.schoolType = selectedKademe;

    api.getSchools(params).then(schools => {
      setAllSchools(schools);
      // Auto-select first N schools
      const autoSelect = new Set(schools.slice(0, MAX_COMPARE).map(s => s.id));
      setSelectedSchoolIds(autoSelect);
    });
  }, [selectedProvince, selectedDistrict, selectedKademe]);

  // Fetch comparison data for selected schools
  useEffect(() => {
    if (selectedSchoolIds.size < 2) {
      setRows([]);
      return;
    }

    setLoading(true);
    const params: FilterParams = { province: selectedProvince };
    if (selectedDistrict) params.district = selectedDistrict;
    if (selectedKademe) params.schoolType = selectedKademe;

    api.getComparisonData(params).then(({ rows }) => {
      // Filter rows to only include selected schools' quantities
      const filtered = rows.map(row => {
        const quantities: Record<string, number> = {};
        for (const id of selectedSchoolIds) {
          quantities[id] = row.quantities[id] ?? 0;
        }
        return { ...row, quantities };
      }).filter(row => Object.values(row.quantities).some(q => q > 0));
      setRows(filtered);
      setLoading(false);
    });
  }, [selectedSchoolIds, selectedProvince, selectedDistrict, selectedKademe]);

  // Selected schools in order
  const compSchools = useMemo(
    () => allSchools.filter(s => selectedSchoolIds.has(s.id)),
    [allSchools, selectedSchoolIds]
  );

  // Filtered display list for school picker
  const displaySchools = useMemo(() => {
    let list = allSchools;
    if (schoolKademeFilter) {
      list = list.filter(s => s.schoolType === schoolKademeFilter);
    }
    if (schoolSearch) {
      const q = schoolSearch.toLowerCase();
      list = list.filter(s => s.name.toLowerCase().includes(q));
    }
    return list;
  }, [allSchools, schoolSearch, schoolKademeFilter]);

  const toggleSchoolSelection = useCallback((id: string) => {
    setSelectedSchoolIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else if (next.size < MAX_COMPARE) {
        next.add(id);
      }
      return next;
    });
  }, []);

  const filteredRows = useMemo(() => rows.filter(row => {
    if (viewFilter === 'all') return true;
    const counts = Object.values(row.quantities);
    const presentCount = counts.filter(q => q > 0).length;
    if (viewFilter === 'missing') return presentCount < compSchools.length && presentCount > 0;
    if (viewFilter === 'shared') return presentCount === compSchools.length;
    return true;
  }), [rows, viewFilter, compSchools.length]);

  // Max quantity across all cells (for heat map scaling)
  const maxQty = useMemo(() => {
    let max = 1;
    for (const row of rows) {
      for (const q of Object.values(row.quantities)) {
        if (q > max) max = q;
      }
    }
    return max;
  }, [rows]);

  // Sorted rows
  const sortedRows = useMemo(() => {
    if (!sortDir) return filteredRows;

    return [...filteredRows].sort((a, b) => {
      let cmp = 0;
      if (sortKey === 'title') {
        cmp = a.book.title.localeCompare(b.book.title, 'tr');
      } else if (sortKey === 'author') {
        cmp = a.book.authors.join(', ').localeCompare(b.book.authors.join(', '), 'tr');
      } else if (sortKey === 'total') {
        const totalA = Object.values(a.quantities).reduce((s, q) => s + q, 0);
        const totalB = Object.values(b.quantities).reduce((s, q) => s + q, 0);
        cmp = totalA - totalB;
      } else if (sortKey === 'coverage') {
        const covA = Object.values(a.quantities).filter(q => q > 0).length;
        const covB = Object.values(b.quantities).filter(q => q > 0).length;
        cmp = covA - covB;
      } else {
        // Sort by specific school column
        cmp = (a.quantities[sortKey] || 0) - (b.quantities[sortKey] || 0);
      }
      return sortDir === 'desc' ? -cmp : cmp;
    });
  }, [filteredRows, sortKey, sortDir]);

  // School column totals
  const schoolTotals = useMemo(() => {
    const totals: Record<string, number> = {};
    for (const s of compSchools) {
      totals[s.id] = rows.reduce((sum, r) => sum + (r.quantities[s.id] || 0), 0);
    }
    return totals;
  }, [rows, compSchools]);

  const grandTotal = useMemo(
    () => Object.values(schoolTotals).reduce((s, v) => s + v, 0),
    [schoolTotals]
  );

  const toggleSort = useCallback((key: SortKey) => {
    if (sortKey !== key) {
      setSortKey(key);
      setSortDir('asc');
    } else if (sortDir === 'asc') {
      setSortDir('desc');
    } else if (sortDir === 'desc') {
      setSortDir(null);
    } else {
      setSortDir('asc');
    }
  }, [sortKey, sortDir]);

  const SortIcon = ({ col }: { col: SortKey }) => {
    const active = sortKey === col && sortDir;
    if (active && sortDir === 'asc') return <ArrowUp size={11} />;
    if (active && sortDir === 'desc') return <ArrowDown size={11} />;
    return <ArrowUpDown size={11} />;
  };

  const handleExportCsv = () => {
    const headers = ['Kitap', 'Yazar', ...compSchools.map(s => s.name), 'Toplam'];
    const csvRows = sortedRows.map(row => {
      const total = Object.values(row.quantities).reduce((s, q) => s + q, 0);
      return [
        row.book.title,
        row.book.authors.join(', '),
        ...compSchools.map(s => String(row.quantities[s.id] || 0)),
        String(total),
      ];
    });
    const district = selectedDistrict || selectedProvince;
    downloadCsv(`kitap-karsilastirma-${district}.csv`, headers, csvRows);
  };

  const allCount = rows.length;
  const missingCount = rows.filter(r => {
    const p = Object.values(r.quantities).filter(q => q > 0).length;
    return p < compSchools.length && p > 0;
  }).length;
  const sharedCount = rows.filter(r =>
    Object.values(r.quantities).every(q => q > 0)
  ).length;

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">Okullar Arası Karşılaştırma</h1>
        <p className="page-subtitle">Hangi kitap hangi okulda var — dağıtım planlaması için</p>
      </div>

      <div className="filter-bar">
        <div className="filter-bar-title">
          <Filter size={14} />
          Kapsam Seçimi
        </div>
        <div className="filter-bar-fields">
          <div className="filter-group">
            <label htmlFor="comp-province" className="filter-label">İl</label>
            <select
              id="comp-province"
              className="filter-select"
              value={selectedProvince}
              onChange={e => setSelectedProvince(e.target.value)}
              disabled={!!lockedProvince}
            >
              <option value="">İl seçin</option>
              {provinces.map(p => <option key={p} value={p}>{p}</option>)}
            </select>
          </div>
          <div className="filter-group">
            <label htmlFor="comp-district" className="filter-label">İlçe</label>
            <select
              id="comp-district"
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
            <label htmlFor="comp-kademe" className="filter-label">Kademe</label>
            <select
              id="comp-kademe"
              className="filter-select"
              value={selectedKademe}
              onChange={e => setSelectedKademe(e.target.value as SchoolType | '')}
            >
              <option value="">Tüm Kademeler</option>
              <option value="ILKOKUL">İlkokul</option>
              <option value="ORTAOKUL">Ortaokul</option>
              <option value="LISE">Lise</option>
            </select>
          </div>
        </div>
      </div>

      {/* School list — active / inactive */}
      {allSchools.length > 0 && (
        <div className="school-list-panel">
          <div className="school-list-header">
            <span className="school-list-title">Okullar</span>
            <span className="school-list-counter">
              {selectedSchoolIds.size} / {allSchools.length} seçili
              {selectedSchoolIds.size >= MAX_COMPARE && <span className="school-list-max"> (maks.)</span>}
            </span>
          </div>
          <div className="school-list-filters">
            <input
              type="text"
              className="school-list-search"
              placeholder="Okul adı ara..."
              value={schoolSearch}
              onChange={e => setSchoolSearch(e.target.value)}
            />
            <select
              className="school-list-kademe-select"
              value={schoolKademeFilter}
              onChange={e => setSchoolKademeFilter(e.target.value as SchoolType | '')}
            >
              <option value="">Tüm Kademeler</option>
              <option value="ILKOKUL">İlkokul</option>
              <option value="ORTAOKUL">Ortaokul</option>
              <option value="LISE">Lise</option>
            </select>
          </div>
          <div className="school-list-grid">
            {displaySchools.map(s => {
              const active = selectedSchoolIds.has(s.id);
              const limitReached = !active && selectedSchoolIds.size >= MAX_COMPARE;
              return (
                <button
                  key={s.id}
                  className={`school-list-item ${active ? 'active' : 'inactive'} ${limitReached ? 'limit' : ''}`}
                  onClick={() => !limitReached && toggleSchoolSelection(s.id)}
                  disabled={limitReached}
                >
                  <span className={`school-list-dot ${active ? 'on' : 'off'}`} />
                  <span className="school-list-name">{s.name}</span>
                  <span className={`cell-badge cell-badge--kademe-${s.schoolType.toLowerCase()}`}>
                    {s.schoolType === 'ILKOKUL' ? 'İlkokul' : s.schoolType === 'ORTAOKUL' ? 'Ortaokul' : 'Lise'}
                  </span>
                </button>
              );
            })}
            {displaySchools.length === 0 && (
              <div style={{ padding: '12px 16px', color: 'var(--color-text-tertiary)', fontSize: '0.82rem' }}>
                Filtreye uygun okul bulunamadı.
              </div>
            )}
          </div>
        </div>
      )}

      {loading && (
        <div className="loading-state">
          <div className="loading-spinner" />
          <p>Karşılaştırma hazırlanıyor...</p>
        </div>
      )}

      {!loading && compSchools.length >= 2 && (
        <>
          <div className="compare-toolbar">
            <div className="compare-filter-chips">
              <button
                className={`compare-chip ${viewFilter === 'all' ? 'active' : ''}`}
                onClick={() => setViewFilter('all')}
              >
                Tümü ({allCount})
              </button>
              <button
                className={`compare-chip compare-chip--warning ${viewFilter === 'missing' ? 'active' : ''}`}
                onClick={() => setViewFilter('missing')}
              >
                Eksik Okullar ({missingCount})
              </button>
              <button
                className={`compare-chip compare-chip--success ${viewFilter === 'shared' ? 'active' : ''}`}
                onClick={() => setViewFilter('shared')}
              >
                Tüm Okullarda ({sharedCount})
              </button>
            </div>
            <button className="btn btn-primary" onClick={handleExportCsv}>
              <Download size={16} /> CSV İndir
            </button>
          </div>

          <div className="heatmap-legend">
            <span className="heatmap-legend-title">Isı Haritası</span>
            <div className="heatmap-legend-items">
              <div className="heatmap-legend-swatch" style={{ background: '#f0fdf4' }} />
              <span className="heatmap-legend-label">Az</span>
              <div className="heatmap-legend-swatch" style={{ background: '#dcfce7' }} />
              <div className="heatmap-legend-swatch" style={{ background: '#bbf7d0' }} />
              <div className="heatmap-legend-swatch" style={{ background: '#86efac' }} />
              <div className="heatmap-legend-swatch" style={{ background: '#4ade80' }} />
              <span className="heatmap-legend-label">Çok</span>
            </div>
            <div className="heatmap-legend-missing">
              <div className="heatmap-legend-swatch" style={{ background: '#fef2f2' }} />
              <span className="heatmap-legend-label">Yok (eksik)</span>
            </div>
          </div>

          <div className="compare-table-wrapper">
            <table className="compare-table">
              <thead>
                <tr>
                  <th
                    className="compare-sticky-col sortable-th"
                    onClick={() => toggleSort('title')}
                  >
                    <span className="sortable-th-inner">
                      Kitap <span className="sort-icon"><SortIcon col="title" /></span>
                    </span>
                  </th>
                  <th
                    className="sortable-th"
                    onClick={() => toggleSort('author')}
                  >
                    <span className="sortable-th-inner">
                      Yazar <span className="sort-icon"><SortIcon col="author" /></span>
                    </span>
                  </th>
                  {compSchools.map(s => (
                    <th
                      key={s.id}
                      className="compare-school-header sortable-th"
                      onClick={() => toggleSort(s.id)}
                    >
                      <span className="compare-school-name">{s.name}</span>
                      <span className="sort-icon"><SortIcon col={s.id} /></span>
                    </th>
                  ))}
                  <th
                    className="compare-total-col sortable-th"
                    onClick={() => toggleSort('total')}
                  >
                    <span className="sortable-th-inner">
                      Toplam <span className="sort-icon"><SortIcon col="total" /></span>
                    </span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {sortedRows.map(row => {
                  const total = Object.values(row.quantities).reduce((s, q) => s + q, 0);
                  return (
                    <tr key={row.book.id}>
                      <td className="compare-sticky-col cell-title">{row.book.title}</td>
                      <td className="cell-secondary">{row.book.authors.join(', ')}</td>
                      {compSchools.map(s => {
                        const qty = row.quantities[s.id];
                        return (
                          <td
                            key={s.id}
                            className={`compare-cell ${qty > 0 ? `has-book ${getHeatClass(qty, maxQty)}` : 'no-book'}`}
                          >
                            {qty > 0 ? qty : '—'}
                          </td>
                        );
                      })}
                      <td className="compare-total-col">
                        <span className="cell-badge cell-badge--quantity">{total}</span>
                      </td>
                    </tr>
                  );
                })}

                {/* Summary row */}
                <tr className="compare-summary-row">
                  <td className="compare-sticky-col cell-title">Toplam</td>
                  <td className="cell-secondary">{sortedRows.length} kitap</td>
                  {compSchools.map(s => (
                    <td key={s.id} className="compare-cell" style={{ fontWeight: 700 }}>
                      {schoolTotals[s.id]}
                    </td>
                  ))}
                  <td className="compare-total-col">
                    <span className="cell-badge cell-badge--quantity">{grandTotal}</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          {sortedRows.length === 0 && (
            <div className="empty-state">
              <p className="empty-state-text">Bu filtreye uygun kitap bulunamadı.</p>
            </div>
          )}
        </>
      )}

      {!loading && !selectedProvince && (
        <div className="empty-state">
          <div className="empty-state-icon">
            <GitCompareArrows size={40} strokeWidth={1.5} />
          </div>
          <p className="empty-state-text">Karşılaştırma için bir il seçin.</p>
        </div>
      )}

      {!loading && selectedProvince && allSchools.length > 0 && selectedSchoolIds.size < 2 && (
        <div className="empty-state">
          <div className="empty-state-icon">
            <GitCompareArrows size={40} strokeWidth={1.5} />
          </div>
          <p className="empty-state-text">Karşılaştırma için en az 2 okul seçin.</p>
        </div>
      )}
    </div>
  );
}
