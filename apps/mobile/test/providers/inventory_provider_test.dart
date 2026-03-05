import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/book.dart';
import 'package:kutuphane_mobile/models/holding.dart';
import 'package:kutuphane_mobile/repositories/mock_book_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_holding_repository.dart';
import 'package:kutuphane_mobile/providers/inventory_provider.dart';

void main() {
  late MockBookRepository bookRepository;
  late MockHoldingRepository holdingRepository;
  late InventoryProvider provider;
  late List<Book> seedBooks;
  late List<Holding> seedHoldings;

  setUp(() {
    seedBooks = [
      Book(
        id: 'b1',
        isbn: '9789750719387',
        title: 'Tutunamayanlar',
        authors: ['Oguz Atay'],
        publisher: 'Iletisim',
        language: 'tr',
        source: BookSource.manual,
        createdAt: DateTime(2024, 1, 1),
      ),
      Book(
        id: 'b2',
        isbn: '9789750738609',
        title: 'Ince Memed',
        authors: ['Yasar Kemal'],
        publisher: 'YKY',
        language: 'tr',
        source: BookSource.manual,
        createdAt: DateTime(2024, 1, 2),
      ),
    ];

    seedHoldings = [
      Holding(
        id: 'h1',
        bookId: 'b1',
        schoolId: 'school1',
        quantity: 3,
        addedBy: 'teacher1',
        addedAt: DateTime(2024, 1, 10),
        source: HoldingSource.manual,
      ),
      Holding(
        id: 'h2',
        bookId: 'b2',
        schoolId: 'school1',
        quantity: 1,
        addedBy: 'teacher1',
        addedAt: DateTime(2024, 1, 11),
        source: HoldingSource.barcodeScan,
      ),
      Holding(
        id: 'h3',
        bookId: 'b1',
        schoolId: 'school2',
        quantity: 2,
        addedBy: 'teacher2',
        addedAt: DateTime(2024, 1, 12),
        source: HoldingSource.manual,
      ),
    ];

    bookRepository = MockBookRepository(seedBooks);
    holdingRepository = MockHoldingRepository(seedHoldings);
    provider = InventoryProvider(
      bookRepository: bookRepository,
      holdingRepository: holdingRepository,
    );
  });

  group('InventoryProvider', () {
    test('items and loading have correct initial values', () {
      expect(provider.items, isEmpty);
      expect(provider.loading, isFalse);
    });

    group('loadInventory', () {
      test('loads holdings with books for a school', () async {
        await provider.loadInventory('school1');

        expect(provider.items, hasLength(2));
        expect(provider.items[0].book.title, 'Tutunamayanlar');
        expect(provider.items[0].holding.quantity, 3);
        expect(provider.items[1].book.title, 'Ince Memed');
        expect(provider.items[1].holding.quantity, 1);
      });

      test('returns empty for unknown school', () async {
        await provider.loadInventory('unknown-school');

        expect(provider.items, isEmpty);
      });

      test('notifies listeners', () async {
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);
        await provider.loadInventory('school1');
        expect(notifyCount, greaterThan(0));
      });

      test('sets loading to false after completion', () async {
        await provider.loadInventory('school1');
        expect(provider.loading, isFalse);
      });
    });

    group('addBook', () {
      test('creates book and holding, inventory updates', () async {
        await provider.loadInventory('school1');
        expect(provider.items, hasLength(2));

        final newBook = Book(
          id: 'b3',
          isbn: '9789750000000',
          title: 'Yeni Kitap',
          authors: ['Yazar'],
          language: 'tr',
          source: BookSource.manual,
          createdAt: DateTime(2024, 2, 1),
        );

        await provider.addBook(
          book: newBook,
          schoolId: 'school1',
          addedBy: 'teacher1',
          source: HoldingSource.manual,
        );

        expect(provider.items, hasLength(3));
        final addedItem = provider.items.firstWhere(
          (item) => item.book.id == 'b3',
        );
        expect(addedItem.book.title, 'Yeni Kitap');
        expect(addedItem.holding.quantity, 1);
      });

      test('increments holding if book already exists at school', () async {
        await provider.loadInventory('school1');

        // Add a book that already exists at school1 (b1)
        final existingBook = seedBooks[0];
        await provider.addBook(
          book: existingBook,
          schoolId: 'school1',
          addedBy: 'teacher1',
          source: HoldingSource.barcodeScan,
        );

        final item = provider.items.firstWhere(
          (item) => item.book.id == 'b1',
        );
        expect(item.holding.quantity, 4); // was 3, now 4
      });

      test('notifies listeners', () async {
        await provider.loadInventory('school1');
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        final newBook = Book(
          id: 'b4',
          isbn: '9789750000001',
          title: 'Baska Kitap',
          authors: ['Yazar 2'],
          language: 'tr',
          source: BookSource.manual,
          createdAt: DateTime(2024, 2, 2),
        );

        await provider.addBook(
          book: newBook,
          schoolId: 'school1',
          addedBy: 'teacher1',
          source: HoldingSource.manual,
        );

        expect(notifyCount, greaterThan(0));
      });
    });
  });
}
