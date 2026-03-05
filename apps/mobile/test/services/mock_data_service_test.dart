import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/book.dart';
import 'package:kutuphane_mobile/models/school.dart';
import 'package:kutuphane_mobile/models/holding.dart';
import 'package:kutuphane_mobile/services/mock_data_service.dart';

void main() {
  group('MockDataService', () {
    group('parseBooks', () {
      test('parses JSON string into list of Book objects', () {
        const jsonString = '''
        [
          {"id":"b1","isbn":"9789750718533","title":"Kucuk Prens","authors":["Antoine de Saint-Exupery"],"publisher":"Can Yayinlari","publishedDate":"2020","pageCount":96,"coverImageUrl":null,"language":"tr","source":"GOOGLE_BOOKS","createdAt":"2026-01-15T10:00:00Z"},
          {"id":"b2","isbn":"9789750726439","title":"Sefiller","authors":["Victor Hugo"],"publisher":"Is Bankasi","publishedDate":"2019","pageCount":1488,"coverImageUrl":null,"language":"tr","source":"GOOGLE_BOOKS","createdAt":"2026-01-15T10:05:00Z"}
        ]
        ''';

        final books = MockDataService.parseBooks(jsonString);

        expect(books, isA<List<Book>>());
        expect(books.length, 2);
        expect(books[0].id, 'b1');
        expect(books[0].title, 'Kucuk Prens');
        expect(books[0].isbn, '9789750718533');
        expect(books[0].authors, ['Antoine de Saint-Exupery']);
        expect(books[0].source, BookSource.googleBooks);
        expect(books[1].id, 'b2');
        expect(books[1].title, 'Sefiller');
      });

      test('parses empty JSON array', () {
        const jsonString = '[]';
        final books = MockDataService.parseBooks(jsonString);
        expect(books, isEmpty);
      });

      test('parses books with null isbn', () {
        const jsonString = '''
        [
          {"id":"b10","isbn":null,"title":"Istanbul Hatirasi","authors":["Ahmet Umit"],"publisher":"Everest","publishedDate":"2010","pageCount":456,"coverImageUrl":null,"language":"tr","source":"MANUAL","createdAt":"2026-01-20T10:00:00Z"}
        ]
        ''';
        final books = MockDataService.parseBooks(jsonString);
        expect(books.length, 1);
        expect(books[0].isbn, isNull);
        expect(books[0].source, BookSource.manual);
      });
    });

    group('parseSchools', () {
      test('parses JSON string into list of School objects', () {
        const jsonString = '''
        [
          {"id":"s1-ankara-cankaya-ataturk-ilk","name":"Ataturk Ilkokulu","province":"Ankara","district":"Cankaya","schoolType":"ILKOKUL","ministryCode":"06001001"},
          {"id":"s5-istanbul-kadikoy-moda-orta","name":"Moda Ortaokulu","province":"Istanbul","district":"Kadikoy","schoolType":"ORTAOKUL","ministryCode":"34001001"}
        ]
        ''';

        final schools = MockDataService.parseSchools(jsonString);

        expect(schools, isA<List<School>>());
        expect(schools.length, 2);
        expect(schools[0].id, 's1-ankara-cankaya-ataturk-ilk');
        expect(schools[0].name, 'Ataturk Ilkokulu');
        expect(schools[0].province, 'Ankara');
        expect(schools[0].schoolType, SchoolType.ilkokul);
        expect(schools[1].schoolType, SchoolType.ortaokul);
      });

      test('parses empty JSON array', () {
        const jsonString = '[]';
        final schools = MockDataService.parseSchools(jsonString);
        expect(schools, isEmpty);
      });
    });

    group('parseHoldings', () {
      test('parses JSON string into list of Holding objects', () {
        const jsonString = '''
        [
          {"id":"h1","bookId":"b1","schoolId":"s1-ankara-cankaya-ataturk-ilk","quantity":5,"addedBy":"Ayse Ogretmen","addedAt":"2026-02-01T10:00:00Z","source":"BARCODE_SCAN"},
          {"id":"h3","bookId":"b1","schoolId":"s9-izmir-konak-alsancak-lise","quantity":2,"addedBy":"Fatma Hanim","addedAt":"2026-02-03T09:00:00Z","source":"COVER_OCR"}
        ]
        ''';

        final holdings = MockDataService.parseHoldings(jsonString);

        expect(holdings, isA<List<Holding>>());
        expect(holdings.length, 2);
        expect(holdings[0].id, 'h1');
        expect(holdings[0].bookId, 'b1');
        expect(holdings[0].quantity, 5);
        expect(holdings[0].source, HoldingSource.barcodeScan);
        expect(holdings[1].source, HoldingSource.coverOcr);
      });

      test('parses empty JSON array', () {
        const jsonString = '[]';
        final holdings = MockDataService.parseHoldings(jsonString);
        expect(holdings, isEmpty);
      });
    });

    group('parse methods with actual mock data files', () {
      test('parseBooks handles full books.json', () {
        final jsonString = File('assets/mock-data/books.json').readAsStringSync();
        final books = MockDataService.parseBooks(jsonString);
        expect(books.length, 15);
        expect(books.first.id, 'b1');
        expect(books.last.id, 'b15');
      });

      test('parseSchools handles full schools.json', () {
        final jsonString = File('assets/mock-data/schools.json').readAsStringSync();
        final schools = MockDataService.parseSchools(jsonString);
        expect(schools.length, 12);
        expect(schools.first.province, 'Ankara');
      });

      test('parseHoldings handles full holdings.json', () {
        final jsonString = File('assets/mock-data/holdings.json').readAsStringSync();
        final holdings = MockDataService.parseHoldings(jsonString);
        expect(holdings.length, 35);
        expect(holdings.first.bookId, 'b1');
      });
    });
  });
}
