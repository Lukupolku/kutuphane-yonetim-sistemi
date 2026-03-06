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
  String? _currentSchoolId;

  InventoryProvider({
    required this.bookRepository,
    required this.holdingRepository,
  });

  Future<void> loadInventory(String schoolId) async {
    _currentSchoolId = schoolId;
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
    final existingBook = await bookRepository.getById(book.id);
    if (existingBook == null) {
      // Check if ISBN already exists in catalog
      if (book.isbn != null) {
        final byIsbn = await bookRepository.getByIsbn(book.isbn!);
        if (byIsbn != null) {
          // Use existing book from catalog
          await holdingRepository.addOrIncrement(
            bookId: byIsbn.id,
            schoolId: schoolId,
            addedBy: addedBy,
            source: source,
          );
          await loadInventory(schoolId);
          return;
        }
      }
      await bookRepository.create(book);
    }

    await holdingRepository.addOrIncrement(
      bookId: book.id,
      schoolId: schoolId,
      addedBy: addedBy,
      source: source,
    );

    await loadInventory(schoolId);
  }

  Future<void> updateBook(Book updatedBook) async {
    await bookRepository.update(updatedBook);
    if (_currentSchoolId != null) {
      await loadInventory(_currentSchoolId!);
    }
  }

  Future<void> updateQuantity(String holdingId, int newQuantity) async {
    if (newQuantity <= 0) {
      await holdingRepository.delete(holdingId);
    } else {
      await holdingRepository.updateQuantity(holdingId, newQuantity);
    }
    if (_currentSchoolId != null) {
      await loadInventory(_currentSchoolId!);
    }
  }

  Future<void> removeItem(String holdingId) async {
    await holdingRepository.delete(holdingId);
    if (_currentSchoolId != null) {
      await loadInventory(_currentSchoolId!);
    }
  }
}
