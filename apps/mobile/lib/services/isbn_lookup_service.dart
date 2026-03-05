import '../models/book.dart';
import '../repositories/book_repository.dart';

class IsbnLookupService {
  final BookRepository bookRepository;

  IsbnLookupService({required this.bookRepository});

  /// Looks up a book by ISBN.
  ///
  /// Checks local repository first.
  /// MVP: only checks local repo. Phase 1 will add
  /// Google Books -> Open Library fallback chain.
  /// Returns null if not found.
  Future<Book?> lookupByIsbn(String isbn) async {
    return await bookRepository.getByIsbn(isbn);
  }

  /// Searches books by title.
  ///
  /// Delegates to [bookRepository.searchByTitle].
  Future<List<Book>> searchByTitle(String query) async {
    return await bookRepository.searchByTitle(query);
  }
}
