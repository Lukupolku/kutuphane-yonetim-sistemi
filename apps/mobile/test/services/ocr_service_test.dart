import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/services/ocr_service.dart';

void main() {
  group('OcrService', () {
    group('parseBookTitle', () {
      test('extracts clean title from multi-line OCR text (title-cased)', () {
        const ocrText = 'KÜÇÜK PRENS\nAntoine de Saint-Exupéry\nCan Yayınları';

        final result = OcrService.parseBookTitle(ocrText);

        expect(result.title, 'Küçük Prens');
        expect(result.author, 'Antoine De Saint-exupéry');
      });

      test('handles single line (author should be null)', () {
        const ocrText = 'SEFILLER';

        final result = OcrService.parseBookTitle(ocrText);

        expect(result.title, 'Sefiller');
        expect(result.author, isNull);
      });

      test('skips empty lines to find title and author', () {
        const ocrText = '\n  \nKÜÇÜK PRENS\n\nAntoine de Saint-Exupéry';

        final result = OcrService.parseBookTitle(ocrText);

        expect(result.title, 'Küçük Prens');
        expect(result.author, 'Antoine De Saint-exupéry');
      });

      test('handles text with only whitespace lines', () {
        const ocrText = '   \n  \n  ';

        final result = OcrService.parseBookTitle(ocrText);

        expect(result.title, '');
        expect(result.author, isNull);
      });
    });

    group('parseShelfTexts', () {
      test('splits multi-line text into candidates', () {
        const ocrText =
            'Küçük Prens\nSefiller\nSuç ve Ceza\nSavaş ve Barış';

        final result = OcrService.parseShelfTexts(ocrText);

        expect(result, [
          'Küçük Prens',
          'Sefiller',
          'Suç ve Ceza',
          'Savaş ve Barış',
        ]);
      });

      test('filters out short lines (less than 3 chars)', () {
        const ocrText = 'Küçük Prens\nab\n\nSefiller\nXY\n   \nSuç ve Ceza';

        final result = OcrService.parseShelfTexts(ocrText);

        expect(result, [
          'Küçük Prens',
          'Sefiller',
          'Suç ve Ceza',
        ]);
      });

      test('filters out empty lines', () {
        const ocrText = '\n\nKüçük Prens\n\n';

        final result = OcrService.parseShelfTexts(ocrText);

        expect(result, ['Küçük Prens']);
      });

      test('returns empty list for empty input', () {
        const ocrText = '';

        final result = OcrService.parseShelfTexts(ocrText);

        expect(result, isEmpty);
      });
    });

    group('_titleCase (via parseBookTitle)', () {
      test('converts uppercase text to title case', () {
        const ocrText = 'KÜÇÜK PRENS';
        final result = OcrService.parseBookTitle(ocrText);
        expect(result.title, 'Küçük Prens');
      });

      test('converts lowercase text to title case', () {
        const ocrText = 'küçük prens';
        final result = OcrService.parseBookTitle(ocrText);
        expect(result.title, 'Küçük Prens');
      });

      test('handles mixed case text', () {
        const ocrText = 'kÜçÜk pReNs';
        final result = OcrService.parseBookTitle(ocrText);
        expect(result.title, 'Küçük Prens');
      });

      test('handles single word', () {
        const ocrText = 'SEFILLER';
        final result = OcrService.parseBookTitle(ocrText);
        expect(result.title, 'Sefiller');
      });
    });
  });
}
