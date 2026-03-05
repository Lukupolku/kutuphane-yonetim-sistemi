import type { HoldingWithSchool } from '../types';

interface SchoolHoldingsListProps {
  holdings: HoldingWithSchool[];
}

export function SchoolHoldingsList({ holdings }: SchoolHoldingsListProps) {
  if (holdings.length === 0) {
    return (
      <div className="empty-state">
        <div className="empty-state-icon">🏫</div>
        <p className="empty-state-text">Bu kitap henüz hiçbir okulda kayıtlı değil.</p>
      </div>
    );
  }

  return (
    <div className="data-table-wrapper">
      <table className="data-table">
        <thead>
          <tr>
            <th>Okul Adı</th>
            <th>İl</th>
            <th>İlçe</th>
            <th className="center">Adet</th>
            <th>Eklenme Tarihi</th>
            <th>Kaynak</th>
          </tr>
        </thead>
        <tbody>
          {holdings.map(({ holding, school }) => (
            <tr key={holding.id}>
              <td className="cell-title">{school.name}</td>
              <td className="cell-secondary">{school.province}</td>
              <td className="cell-secondary">{school.district}</td>
              <td className="cell-center">
                <span className="cell-badge cell-badge--quantity">{holding.quantity}</span>
              </td>
              <td className="cell-secondary">
                {new Date(holding.addedAt).toLocaleDateString('tr-TR')}
              </td>
              <td>
                <SourceBadge source={holding.source} />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function SourceBadge({ source }: { source: string }) {
  const config: Record<string, { label: string; className: string }> = {
    BARCODE_SCAN: { label: 'Barkod', className: 'source-badge--barcode' },
    COVER_OCR: { label: 'Kapak OCR', className: 'source-badge--cover' },
    SHELF_OCR: { label: 'Raf OCR', className: 'source-badge--shelf' },
    MANUAL: { label: 'Manuel', className: 'source-badge--manual' },
  };

  const { label, className } = config[source] ?? { label: source, className: 'source-badge--manual' };

  return <span className={`source-badge ${className}`}>{label}</span>;
}
