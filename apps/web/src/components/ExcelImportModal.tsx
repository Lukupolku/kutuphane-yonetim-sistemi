import { useState, useRef } from 'react';
import { Upload, FileSpreadsheet, X, Check, AlertCircle } from 'lucide-react';
import * as XLSX from 'xlsx';

interface ImportRow {
  title: string;
  author: string;
  publisher: string;
  isbn: string;
  quantity: number;
  selected: boolean;
}

interface ExcelImportModalProps {
  open: boolean;
  onClose: () => void;
  onImport: (rows: Omit<ImportRow, 'selected'>[]) => void;
}

export function ExcelImportModal({ open, onClose, onImport }: ExcelImportModalProps) {
  const [rows, setRows] = useState<ImportRow[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [fileName, setFileName] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  if (!open) return null;

  const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setFileName(file.name);
    setError(null);

    const reader = new FileReader();
    reader.onload = (evt) => {
      try {
        const data = new Uint8Array(evt.target?.result as ArrayBuffer);
        const workbook = XLSX.read(data, { type: 'array' });
        const sheet = workbook.Sheets[workbook.SheetNames[0]];
        const json = XLSX.utils.sheet_to_json<Record<string, unknown>>(sheet, { header: 1 });

        if (json.length < 2) {
          setError('Excel dosyası boş veya sadece başlık satırı var.');
          return;
        }

        // Skip header row, parse data rows
        const parsed: ImportRow[] = [];
        for (let i = 1; i < json.length; i++) {
          const row = json[i] as unknown[];
          if (!row || !row[0]) continue;
          const title = String(row[0] ?? '').trim();
          if (!title) continue;

          parsed.push({
            title,
            author: String(row[1] ?? '').trim(),
            publisher: String(row[2] ?? '').trim(),
            isbn: String(row[3] ?? '').trim(),
            quantity: Number(row[4]) || 1,
            selected: true,
          });
        }

        if (parsed.length === 0) {
          setError('Geçerli satır bulunamadı. İlk sütun (Başlık) zorunludur.');
          return;
        }

        setRows(parsed);
      } catch {
        setError('Dosya okunamadı. Lütfen geçerli bir Excel dosyası seçin.');
      }
    };
    reader.readAsArrayBuffer(file);
  };

  const toggleRow = (index: number) => {
    setRows(prev => prev.map((r, i) => i === index ? { ...r, selected: !r.selected } : r));
  };

  const toggleAll = () => {
    const allSelected = rows.every(r => r.selected);
    setRows(prev => prev.map(r => ({ ...r, selected: !allSelected })));
  };

  const selectedCount = rows.filter(r => r.selected).length;

  const handleImport = () => {
    const selected = rows.filter(r => r.selected).map(({ selected: _, ...rest }) => rest);
    onImport(selected);
    handleReset();
  };

  const handleReset = () => {
    setRows([]);
    setError(null);
    setFileName(null);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content excel-import-modal" onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <h2><FileSpreadsheet size={20} /> Excel'den Yükle</h2>
          <button className="modal-close" onClick={onClose}><X size={20} /></button>
        </div>

        <div className="excel-template-info">
          <AlertCircle size={16} />
          <div>
            <strong>Şablon Formatı</strong> — İlk satır başlık olmalıdır:
            <div className="template-columns">
              <span className="template-col required">Başlık*</span>
              <span className="template-col">Yazar</span>
              <span className="template-col">Yayınevi</span>
              <span className="template-col">ISBN</span>
              <span className="template-col">Adet</span>
            </div>
            <small>* Zorunlu alan. Adet boşsa 1 kabul edilir.</small>
          </div>
        </div>

        {rows.length === 0 ? (
          <div className="excel-upload-area">
            <input
              ref={fileInputRef}
              type="file"
              accept=".xlsx,.xls"
              onChange={handleFile}
              style={{ display: 'none' }}
            />
            <button
              className="excel-upload-btn"
              onClick={() => fileInputRef.current?.click()}
            >
              <Upload size={24} />
              <span>Excel Dosyası Seç</span>
              <small>.xlsx veya .xls</small>
            </button>
            {error && <p className="excel-error">{error}</p>}
          </div>
        ) : (
          <>
            <div className="excel-file-info">
              <span>{fileName}</span>
              <span>{selectedCount}/{rows.length} seçili</span>
              <button className="btn-text" onClick={toggleAll}>
                {rows.every(r => r.selected) ? 'Tümünü Kaldır' : 'Tümünü Seç'}
              </button>
            </div>
            <div className="excel-preview-table">
              <table>
                <thead>
                  <tr>
                    <th style={{ width: 40 }}></th>
                    <th>Başlık</th>
                    <th>Yazar</th>
                    <th>Yayınevi</th>
                    <th>ISBN</th>
                    <th style={{ width: 60 }}>Adet</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((row, i) => (
                    <tr key={i} className={row.selected ? '' : 'row-deselected'}>
                      <td>
                        <input
                          type="checkbox"
                          checked={row.selected}
                          onChange={() => toggleRow(i)}
                        />
                      </td>
                      <td>{row.title}</td>
                      <td>{row.author || '—'}</td>
                      <td>{row.publisher || '—'}</td>
                      <td className="monospace">{row.isbn || '—'}</td>
                      <td>{row.quantity}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="modal-actions">
              <button className="btn btn-secondary" onClick={handleReset}>
                Farklı Dosya
              </button>
              <button
                className="btn btn-primary"
                disabled={selectedCount === 0}
                onClick={handleImport}
              >
                <Check size={16} />
                {selectedCount} Kitap Ekle
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
