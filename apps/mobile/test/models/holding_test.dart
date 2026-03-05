import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/holding.dart';

void main() {
  group('Holding', () {
    test('fromJson creates Holding', () {
      final json = {
        'id': 'h1',
        'bookId': 'b1',
        'schoolId': 's1-ankara-cankaya-ataturk-ilk',
        'quantity': 5,
        'addedBy': 'Ayşe Öğretmen',
        'addedAt': '2026-02-01T10:00:00Z',
        'source': 'BARCODE_SCAN',
      };
      final holding = Holding.fromJson(json);
      expect(holding.bookId, 'b1');
      expect(holding.quantity, 5);
      expect(holding.source, HoldingSource.barcodeScan);
    });

    test('toJson produces valid JSON', () {
      final holding = Holding(
        id: 'h1',
        bookId: 'b1',
        schoolId: 's1',
        quantity: 5,
        addedBy: 'Test',
        addedAt: DateTime.parse('2026-02-01T10:00:00Z'),
        source: HoldingSource.barcodeScan,
      );
      expect(holding.toJson()['source'], 'BARCODE_SCAN');
    });
  });
}
