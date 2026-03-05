import type { HoldingWithSchool } from '../types';

interface SchoolHoldingsListProps {
  holdings: HoldingWithSchool[];
}

export function SchoolHoldingsList({ holdings }: SchoolHoldingsListProps) {
  if (holdings.length === 0) {
    return <p style={{ color: '#666', padding: '1rem' }}>Bu kitap henüz hiçbir okulda kayıtlı değil.</p>;
  }

  return (
    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
      <thead>
        <tr style={{ borderBottom: '2px solid #e0e0e0', textAlign: 'left' }}>
          <th style={{ padding: '12px 8px' }}>Okul Adı</th>
          <th style={{ padding: '12px 8px' }}>İl</th>
          <th style={{ padding: '12px 8px' }}>İlçe</th>
          <th style={{ padding: '12px 8px', textAlign: 'center' }}>Adet</th>
          <th style={{ padding: '12px 8px' }}>Eklenme Tarihi</th>
          <th style={{ padding: '12px 8px' }}>Kaynak</th>
        </tr>
      </thead>
      <tbody>
        {holdings.map(({ holding, school }) => (
          <tr key={holding.id} style={{ borderBottom: '1px solid #eee' }}>
            <td style={{ padding: '10px 8px', fontWeight: 500 }}>{school.name}</td>
            <td style={{ padding: '10px 8px' }}>{school.province}</td>
            <td style={{ padding: '10px 8px' }}>{school.district}</td>
            <td style={{ padding: '10px 8px', textAlign: 'center' }}>{holding.quantity}</td>
            <td style={{ padding: '10px 8px' }}>{new Date(holding.addedAt).toLocaleDateString('tr-TR')}</td>
            <td style={{ padding: '10px 8px' }}>
              {formatSource(holding.source)}
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

function formatSource(source: string): string {
  switch (source) {
    case 'BARCODE_SCAN': return 'Barkod Tarama';
    case 'COVER_OCR': return 'Kapak OCR';
    case 'SHELF_OCR': return 'Raf OCR';
    case 'MANUAL': return 'Manuel Giriş';
    default: return source;
  }
}
