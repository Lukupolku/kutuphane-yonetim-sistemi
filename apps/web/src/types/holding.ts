export type HoldingSource = 'BARCODE_SCAN' | 'COVER_OCR' | 'SHELF_OCR' | 'MANUAL';

export interface Holding {
  id: string;
  bookId: string;
  schoolId: string;
  quantity: number;
  addedBy: string;
  addedAt: string;
  source: HoldingSource;
}
