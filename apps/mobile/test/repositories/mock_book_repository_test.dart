import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/book.dart';
import 'package:kutuphane_mobile/repositories/book_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_book_repository.dart';

void main() {
  late BookRepository repository;
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
  });

  group('MockBookRepository', () {
    group('getAll', () {
      test('returns all seeded books', () async {
        final books = await repository.getAll();
        expect(books, hasLength(3));
      });

      test('returns empty list when no books seeded', () async {
        final emptyRepo = MockBookRepository([]);
        final books = await emptyRepo.getAll();
        expect(books, isEmpty);
      });
    });

    group('getById', () {
      test('returns book when found', () async {
        final book = await repository.getById('b1');
        expect(book, isNotNull);
        expect(book!.id, 'b1');
        expect(book.title, 'Kucuk Prens');
      });

      test('returns null when not found', () async {
        final book = await repository.getById('nonexistent');
        expect(book, isNull);
      });
    });

    group('getByIsbn', () {
      test('returns book when ISBN found', () async {
        final book = await repository.getByIsbn('9789750718533');
        expect(book, isNotNull);
        expect(book!.id, 'b1');
      });

      test('returns null when ISBN not found', () async {
        final book = await repository.getByIsbn('0000000000000');
        expect(book, isNull);
      });

      test('returns null when searching for null ISBN', () async {
        // No book has ISBN matching empty string
        final book = await repository.getByIsbn('');
        expect(book, isNull);
      });
    });

    group('create', () {
      test('adds a new book to the repository', () async {
        final newBook = Book(
          id: 'b4',
          isbn: '9789750738609',
          title: 'Suç ve Ceza',
          authors: ['Fyodor Dostoyevski'],
          language: 'tr',
          source: BookSource.googleBooks,
          createdAt: DateTime.now(),
        );

        await repository.create(newBook);

        final books = await repository.getAll();
        expect(books, hasLength(4));

        final found = await repository.getById('b4');
        expect(found, isNotNull);
        expect(found!.title, 'Suç ve Ceza');
      });
    });

    group('searchByTitle', () {
      test('finds books with case-insensitive match', () async {
        final results = await repository.searchByTitle('kucuk');
        expect(results, hasLength(1));
        expect(results.first.id, 'b1');
      });

      test('finds books with partial match', () async {
        final results = await repository.searchByTitle('istanbul');
        expect(results, hasLength(1));
        expect(results.first.id, 'b3');
      });

      test('returns empty list when no match', () async {
        final results = await repository.searchByTitle('nonexistent');
        expect(results, isEmpty);
      });

      test('returns multiple matches', () async {
        // Both 'Kucuk Prens' and 'Istanbul Hatirasi' contain lowercase letter patterns
        // but let's search for something that matches none, then add one
        final newBook = Book(
          id: 'b5',
          isbn: '1234567890123',
          title: 'Kucuk Kadinlar',
          authors: ['Louisa May Alcott'],
          language: 'tr',
          source: BookSource.manual,
          createdAt: DateTime.now(),
        );
        await repository.create(newBook);

        final results = await repository.searchByTitle('kucuk');
        expect(results, hasLength(2));
      });
    });
  });
}
