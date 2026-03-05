import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/book.dart';
import 'package:kutuphane_mobile/repositories/mock_book_repository.dart';
import 'package:kutuphane_mobile/services/isbn_lookup_service.dart';

void main() {
  late MockBookRepository repository;
  late IsbnLookupService service;
  late List<Book> seedBooks;

  setUp(() {
    seedBooks = [
      Book(
        id: 'b1',
        isbn: '9789750718533',
        title: 'Kucuk Prens',
        authors: ['Antoine de Saint-Exupery'],
        language: 'tr',
        source: BookSource.googleBooks,
        createdAt: DateTime.parse('2026-01-15T10:00:00Z'),
      ),
      Book(
        id: 'b2',
        isbn: '9789750726439',
        title: 'Sefiller',
        authors: ['Victor Hugo'],
        publisher: 'Is Bankasi Kultur Yayinlari',
        language: 'tr',
        source: BookSource.openLibrary,
        createdAt: DateTime.parse('2026-01-16T10:00:00Z'),
      ),
      Book(
        id: 'b3',
        isbn: null,
        title: 'Istanbul Hatirasi',
        authors: ['Ahmet Umit'],
        language: 'tr',
        source: BookSource.manual,
        createdAt: DateTime.parse('2026-01-17T10:00:00Z'),
      ),
    ];
    repository = MockBookRepository(seedBooks);
    service = IsbnLookupService(bookRepository: repository);
  });

  group('IsbnLookupService', () {
    group('lookupByIsbn', () {
      test('returns book from repository if exists', () async {
        final book = await service.lookupByIsbn('9789750718533');
        expect(book, isNotNull);
        expect(book!.id, 'b1');
        expect(book.title, 'Kucuk Prens');
      });

      test('returns null for unknown ISBN', () async {
        final book = await service.lookupByIsbn('0000000000000');
        expect(book, isNull);
      });
    });

    group('searchByTitle', () {
      test('returns matches from repository', () async {
        final results = await service.searchByTitle('kucuk');
        expect(results, hasLength(1));
        expect(results.first.id, 'b1');
        expect(results.first.title, 'Kucuk Prens');
      });

      test('returns empty for no matches', () async {
        final results = await service.searchByTitle('nonexistent');
        expect(results, isEmpty);
      });
    });
  });
}
