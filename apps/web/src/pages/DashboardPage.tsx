import { useState, useEffect, useMemo } from 'react';
import { BookOpenText, Layers, School, FileSpreadsheet, Download, Users, BarChart3 } from 'lucide-react';
import { HierarchyFilter } from '../components/HierarchyFilter';
import { ExcelImportModal } from '../components/ExcelImportModal';
import { SortHeader } from '../components/SortHeader';
import { useSort } from '../hooks/useSort';
import { useAuth } from '../contexts/AuthContext';
import { api } from '../services/api';
import type { SchoolStats } from '../services/api';
import type { FilterParams, Book } from '../types';
import { downloadCsv } from '../utils/csv-export';

type BookWithStats = Book & { schoolCount: number; totalQuantity: number };

export function DashboardPage() {
  const { user } = useAuth();
  const isSchool = user?.role === 'school';

  const [filter, setFilter] = useState<FilterParams>(() => {
    if (isSchool && user?.schoolId) return { schoolId: user.schoolId };
    if (user?.role === 'district') return { province: user.province!, district: user.district! };
    if (user?.role === 'province') return { province: user.province! };
    return {};
  });
  const [books, setBooks] = useState<BookWithStats[]>([]);
  const [schoolStats, setSchoolStats] = useState<SchoolStats[]>([]);
  const [loading, setLoading] = useState(true);
  const [showImport, setShowImport] = useState(false);

  useEffect(() => {
    setLoading(true);
    Promise.all([
      api.getBooksByFilter(filter),
      isSchool ? Promise.resolve([]) : api.getSchoolStats(filter),
    ]).then(([booksResult, statsResult]) => {
      setBooks(booksResult);
      setSchoolStats(statsResult);
      setLoading(false);
    });
  }, [filter, isSchool]);

  const scopeLabel = isSchool
    ? user?.schoolName ?? 'Okul'
    : filter.schoolId
    ? 'Seçili Okul'
    : filter.district
    ? `${filter.province} / ${filter.district}`
    : filter.province
    ? filter.province
    : 'Tüm Türkiye';

  const totalBooks = books.length;
  const totalQuantity = books.reduce((sum, b) => sum + b.totalQuantity, 0);
  const totalSchools = schoolStats.length;
  const totalStudents = schoolStats.reduce((sum, s) => sum + s.school.studentCount, 0);
  const avgBooksPerStudent = totalStudents > 0 ? (totalQuantity / totalStudents) : 0;
  const avgBooksPerSchool = totalSchools > 0 ? (totalQuantity / totalSchools) : 0;

  // Flatten school stats for sorting
  const flatStats = useMemo(() =>
    schoolStats.map(s => ({
      ...s,
      name: s.school.name,
      schoolType: s.school.schoolType,
      studentCount: s.school.studentCount,
    })),
    [schoolStats]
  );
  const { sorted: sortedStats, sort: statsSort, toggle: statsToggle } = useSort(flatStats, 'booksPerStudent', 'desc');

  // Flatten books for inventory sort
  const booksWithAuthorStr = useMemo(() =>
    books.map(b => ({ ...b, authorStr: b.authors.join(', ') })),
    [books]
  );
  const { sorted: sortedBooks, sort: booksSort, toggle: booksToggle } = useSort(booksWithAuthorStr);

  const handleExportSchoolStats = () => {
    const headers = ['Okul', 'İl', 'İlçe', 'Tür', 'Öğrenci', 'Farklı Eser', 'Toplam Kopya', 'Öğrenci Başına'];
    const rows = schoolStats.map(s => [
      s.school.name,
      s.school.province,
      s.school.district,
      s.school.schoolType,
      String(s.school.studentCount),
      String(s.bookCount),
      String(s.totalCopies),
      s.booksPerStudent.toFixed(2),
    ]);
    downloadCsv(`okul-istatistikleri-${scopeLabel}.csv`, headers, rows);
  };

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">
          {isSchool ? 'Okul Envanteri' : 'Genel Bakış'}
        </h1>
        <p className="page-subtitle">
          {isSchool
            ? `${user?.schoolName} — kitap envanterini görüntüleyin ve yönetin`
            : 'Okulların kütüphane istatistiklerini görüntüleyin ve filtreleyin'}
        </p>
      </div>

      <div className="stats-grid">
        <div className="stat-card stat-card--primary">
          <div className="stat-card-icon">
            <BookOpenText size={20} />
          </div>
          <div className="stat-card-label">Farklı Eser</div>
          <div className="stat-card-value">{totalBooks}</div>
          <div className="stat-card-detail">benzersiz kitap</div>
        </div>
        <div className="stat-card stat-card--accent">
          <div className="stat-card-icon">
            <Layers size={20} />
          </div>
          <div className="stat-card-label">Toplam Kopya</div>
          <div className="stat-card-value">{totalQuantity}</div>
          <div className="stat-card-detail">fiziksel adet</div>
        </div>
        {!isSchool && (
          <>
            <div className="stat-card">
              <div className="stat-card-icon">
                <School size={20} />
              </div>
              <div className="stat-card-label">Okul Sayısı</div>
              <div className="stat-card-value">{totalSchools}</div>
              <div className="stat-card-detail">envanter girişi</div>
            </div>
            <div className="stat-card">
              <div className="stat-card-icon">
                <Users size={20} />
              </div>
              <div className="stat-card-label">Öğrenci Başına</div>
              <div className="stat-card-value">{avgBooksPerStudent.toFixed(1)}</div>
              <div className="stat-card-detail">kitap / öğrenci</div>
            </div>
            <div className="stat-card">
              <div className="stat-card-icon">
                <BarChart3 size={20} />
              </div>
              <div className="stat-card-label">Okul Başına</div>
              <div className="stat-card-value">{avgBooksPerSchool.toFixed(0)}</div>
              <div className="stat-card-detail">ortalama kopya</div>
            </div>
          </>
        )}
      </div>

      {!isSchool && <HierarchyFilter onFilterChange={setFilter} />}

      <div className="scope-bar">
        <span className="scope-label">{scopeLabel}</span>
        <div className="scope-actions">
          {isSchool && (
            <button className="btn btn-primary" onClick={() => setShowImport(true)}>
              <FileSpreadsheet size={16} /> Excel'den Yükle
            </button>
          )}
          {!isSchool && schoolStats.length > 0 && (
            <button className="btn btn-secondary" onClick={handleExportSchoolStats}>
              <Download size={16} /> Okul İstatistikleri CSV
            </button>
          )}
        </div>
      </div>

      <ExcelImportModal
        open={showImport}
        onClose={() => setShowImport(false)}
        onImport={(rows) => {
          console.log('Imported books:', rows);
          setShowImport(false);
          alert(`${rows.length} kitap başarıyla yüklendi (mock).`);
        }}
      />

      {loading && (
        <div className="loading-state">
          <div className="loading-spinner" />
          <p>Yükleniyor...</p>
        </div>
      )}

      {/* School stats table — only for non-school roles */}
      {!isSchool && !loading && schoolStats.length > 0 && (
        <div className="school-stats-section">
          <h2 className="section-title">Okul Bazlı İstatistikler</h2>
          <div className="data-table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <SortHeader label="Okul" sortKey="name" sort={statsSort} onToggle={statsToggle} />
                  <SortHeader label="Tür" sortKey="schoolType" sort={statsSort} onToggle={statsToggle} />
                  <SortHeader label="Öğrenci" sortKey="studentCount" sort={statsSort} onToggle={statsToggle} className="center" />
                  <SortHeader label="Farklı Eser" sortKey="bookCount" sort={statsSort} onToggle={statsToggle} className="center" />
                  <SortHeader label="Toplam Kopya" sortKey="totalCopies" sort={statsSort} onToggle={statsToggle} className="center" />
                  <SortHeader label="Öğr. Başına" sortKey="booksPerStudent" sort={statsSort} onToggle={statsToggle} className="center" />
                </tr>
              </thead>
              <tbody>
                {sortedStats.map(s => (
                  <tr key={s.school.id}>
                    <td className="cell-title">{s.school.name}</td>
                    <td>
                      <span className="cell-badge cell-badge--school">
                        {s.school.schoolType === 'ILKOKUL' ? 'İlkokul' :
                         s.school.schoolType === 'ORTAOKUL' ? 'Ortaokul' : 'Lise'}
                      </span>
                    </td>
                    <td className="cell-center">{s.school.studentCount}</td>
                    <td className="cell-center">{s.bookCount}</td>
                    <td className="cell-center">
                      <span className="cell-badge cell-badge--quantity">{s.totalCopies}</span>
                    </td>
                    <td className="cell-center">
                      <span className={`books-per-student ${s.booksPerStudent < 0.1 ? 'low' : s.booksPerStudent >= 0.3 ? 'high' : 'mid'}`}>
                        {s.booksPerStudent.toFixed(2)}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* School role: show own book list */}
      {isSchool && !loading && (
        <div className="school-stats-section">
          <h2 className="section-title">Envanter Listesi</h2>
          <div className="data-table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <SortHeader label="Başlık" sortKey="title" sort={booksSort} onToggle={booksToggle} />
                  <SortHeader label="Yazar" sortKey="authorStr" sort={booksSort} onToggle={booksToggle} />
                  <SortHeader label="Yayınevi" sortKey="publisher" sort={booksSort} onToggle={booksToggle} />
                  <th>ISBN</th>
                  <SortHeader label="Adet" sortKey="totalQuantity" sort={booksSort} onToggle={booksToggle} className="center" />
                </tr>
              </thead>
              <tbody>
                {sortedBooks.map(book => (
                  <tr key={book.id}>
                    <td className="cell-title">{book.title}</td>
                    <td className="cell-secondary">{book.authors.join(', ')}</td>
                    <td className="cell-secondary">{book.publisher ?? '—'}</td>
                    <td className="cell-mono">{book.isbn ?? '—'}</td>
                    <td className="cell-center">
                      <span className="cell-badge cell-badge--quantity">{book.totalQuantity}</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
