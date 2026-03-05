import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/holding.dart';
import '../repositories/book_repository.dart';
import '../repositories/holding_repository.dart';

class InventoryItem {
  final Book book;
  final Holding holding;
  InventoryItem({required this.book, required this.holding});
}

class InventoryProvider extends ChangeNotifier {
  final BookRepository bookRepository;
  final HoldingRepository holdingRepository;

  List<InventoryItem> items = [];
  bool loading = false;

  InventoryProvider({
    required this.bookRepository,
    required this.holdingRepository,
  });

  Future<void> loadInventory(String schoolId) async {
    loading = true;
    notifyListeners();

    try {
      final holdings = await holdingRepository.getBySchoolId(schoolId);
      final loadedItems = <InventoryItem>[];

      for (final holding in holdings) {
        final book = await bookRepository.getById(holding.bookId);
        if (book != null) {
          loadedItems.add(InventoryItem(book: book, holding: holding));
        }
      }

      items = loadedItems;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addBook({
    required Book book,
    required String schoolId,
    required String addedBy,
    required HoldingSource source,
  }) async {
    // Create book if it doesn't already exist
    final existingBook = await bookRepository.getById(book.id);
    if (existingBook == null) {
      await bookRepository.create(book);
    }

    // Add or increment holding
    await holdingRepository.addOrIncrement(
      bookId: book.id,
      schoolId: schoolId,
      addedBy: addedBy,
      source: source,
    );

    // Reload inventory
    await loadInventory(schoolId);
  }
}
