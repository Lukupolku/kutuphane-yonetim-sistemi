import '../models/book.dart';
import 'book_repository.dart';

class MockBookRepository implements BookRepository {
  final List<Book> _books;

  MockBookRepository(List<Book> books) : _books = List<Book>.from(books);

  @override
  Future<List<Book>> getAll() async {
    return List<Book>.from(_books);
  }

  @override
  Future<Book?> getById(String id) async {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Book?> getByIsbn(String isbn) async {
    try {
      return _books.firstWhere((b) => b.isbn == isbn);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> create(Book book) async {
    _books.add(book);
  }

  @override
  Future<List<Book>> searchByTitle(String query) async {
    final lowerQuery = query.toLowerCase();
    return _books.where((b) => b.title.toLowerCase().contains(lowerQuery)).toList();
  }
}
