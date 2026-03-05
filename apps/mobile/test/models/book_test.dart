import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/book.dart';

void main() {
  group('Book', () {
    test('fromJson creates Book from valid JSON', () {
      final json = {
        'id': 'b1',
        'isbn': '9789750718533',
        'title': 'Küçük Prens',
        'authors': ['Antoine de Saint-Exupéry'],
        'publisher': 'Can Yayınları',
        'publishedDate': '2020',
        'pageCount': 96,
        'coverImageUrl': null,
        'language': 'tr',
        'source': 'GOOGLE_BOOKS',
        'createdAt': '2026-01-15T10:00:00Z',
      };
      final book = Book.fromJson(json);
      expect(book.id, 'b1');
      expect(book.isbn, '9789750718533');
      expect(book.title, 'Küçük Prens');
      expect(book.authors, ['Antoine de Saint-Exupéry']);
      expect(book.source, BookSource.googleBooks);
    });

    test('fromJson handles null isbn', () {
      final json = {
        'id': 'b10',
        'isbn': null,
        'title': 'İstanbul Hatırası',
        'authors': ['Ahmet Ümit'],
        'language': 'tr',
        'source': 'MANUAL',
        'createdAt': '2026-01-20T10:00:00Z',
      };
      final book = Book.fromJson(json);
      expect(book.isbn, isNull);
      expect(book.source, BookSource.manual);
    });

    test('toJson produces valid JSON', () {
      final book = Book(
        id: 'b1',
        isbn: '9789750718533',
        title: 'Küçük Prens',
        authors: ['Antoine de Saint-Exupéry'],
        language: 'tr',
        source: BookSource.googleBooks,
        createdAt: DateTime.parse('2026-01-15T10:00:00Z'),
      );
      final json = book.toJson();
      expect(json['id'], 'b1');
      expect(json['isbn'], '9789750718533');
      expect(json['source'], 'GOOGLE_BOOKS');
    });
  });
}
