export function downloadCsv(filename: string, headers: string[], rows: string[][]) {
  const bom = '\uFEFF'; // UTF-8 BOM for Turkish chars in Excel
  const csvContent = [
    headers.join(';'),
    ...rows.map(row => row.map(cell => `"${cell.replace(/"/g, '""')}"`).join(';'))
  ].join('\n');

  const blob = new Blob([bom + csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
