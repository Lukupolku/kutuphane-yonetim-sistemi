import '../models/book.dart';

abstract class BookRepository {
  Future<List<Book>> getAll();
  Future<Book?> getById(String id);
  Future<Book?> getByIsbn(String isbn);
  Future<void> create(Book book);
  Future<List<Book>> searchByTitle(String query);
}
