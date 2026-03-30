import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../models/book_note.dart';
import '../models/lending.dart';

/// Joined model for displaying a user's book with metadata.
class UserBookWithDetails {
  final UserBook userBook;
  final Book book;
  final List<BookNote> notes;
  final Lending? activeLending;

  UserBookWithDetails({
    required this.userBook,
    required this.book,
    this.notes = const [],
    this.activeLending,
  });
}

class BookProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  List<UserBookWithDetails> _userBooks = [];

  List<UserBookWithDetails> get userBooks => _userBooks;

  List<UserBookWithDetails> get currentlyReading =>
      _userBooks.where((ub) => ub.userBook.status == ReadingStatus.reading).toList();

  List<UserBookWithDetails> get favorites =>
      _userBooks.where((ub) => ub.userBook.isFavorite).toList();

  List<UserBookWithDetails> get readBooks =>
      _userBooks.where((ub) => ub.userBook.status == ReadingStatus.read).toList();

  List<UserBookWithDetails> get lentOut =>
      _userBooks.where((ub) => ub.activeLending != null).toList();

  List<UserBookWithDetails> booksOnShelf(String shelfId) =>
      _userBooks.where((ub) => ub.userBook.shelfId == shelfId).toList();

  int get totalBooks => _userBooks.length;

  int get totalReadThisYear {
    final now = DateTime.now();
    return _userBooks.where((ub) =>
        ub.userBook.status == ReadingStatus.read &&
        ub.userBook.finishDate != null &&
        ub.userBook.finishDate!.year == now.year).length;
  }

  Future<void> loadAll() async {
    final db = await _db.database;

    final bookMaps = await db.query('books');
    final books = {for (final m in bookMaps) m['id'] as String: Book.fromMap(m)};

    final ubMaps = await db.query('user_books', orderBy: 'created_at DESC');
    final userBooksList = ubMaps.map(UserBook.fromMap).toList();

    final noteMaps = await db.query('book_notes', orderBy: 'created_at DESC');
    final notesByUb = <String, List<BookNote>>{};
    for (final m in noteMaps) {
      final note = BookNote.fromMap(m);
      notesByUb.putIfAbsent(note.userBookId, () => []).add(note);
    }

    final lendingMaps = await db.query('lendings',
        where: 'returned_date IS NULL', orderBy: 'lent_date DESC');
    final activeLendings = <String, Lending>{};
    for (final m in lendingMaps) {
      final lending = Lending.fromMap(m);
      activeLendings.putIfAbsent(lending.userBookId, () => lending);
    }

    _userBooks = userBooksList
        .where((ub) => books.containsKey(ub.bookId))
        .map((ub) => UserBookWithDetails(
              userBook: ub,
              book: books[ub.bookId]!,
              notes: notesByUb[ub.id] ?? [],
              activeLending: activeLendings[ub.id],
            ))
        .toList();

    notifyListeners();
  }

  /// Add a book to the library. If a book with the same ISBN exists, reuses it.
  Future<UserBookWithDetails> addBook(
    Book book, {
    String? shelfId,
    ReadingStatus status = ReadingStatus.toRead,
  }) async {
    final db = await _db.database;

    // Check if book with same ISBN already exists
    String bookId = book.id;
    if (book.isbn != null) {
      final existing = await db.query('books',
          where: 'isbn = ?', whereArgs: [book.isbn], limit: 1);
      if (existing.isNotEmpty) {
        bookId = existing.first['id'] as String;
      } else {
        await db.insert('books', book.toMap());
      }
    } else {
      await db.insert('books', book.toMap());
    }

    final now = DateTime.now();
    final userBook = UserBook(
      id: _uuid.v4(),
      bookId: bookId,
      shelfId: shelfId,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('user_books', userBook.toMap());

    final savedBook = bookId == book.id
        ? book
        : Book.fromMap(
            (await db.query('books', where: 'id = ?', whereArgs: [bookId])).first);

    final detail = UserBookWithDetails(userBook: userBook, book: savedBook);
    _userBooks.insert(0, detail);
    notifyListeners();
    return detail;
  }

  Future<void> updateUserBook(UserBook updated) async {
    final db = await _db.database;
    await db.update('user_books', updated.toMap(),
        where: 'id = ?', whereArgs: [updated.id]);
    final i = _userBooks.indexWhere((ub) => ub.userBook.id == updated.id);
    if (i >= 0) {
      _userBooks[i] = UserBookWithDetails(
        userBook: updated,
        book: _userBooks[i].book,
        notes: _userBooks[i].notes,
        activeLending: _userBooks[i].activeLending,
      );
      notifyListeners();
    }
  }

  Future<void> removeUserBook(String userBookId) async {
    final db = await _db.database;
    await db.delete('user_books', where: 'id = ?', whereArgs: [userBookId]);
    _userBooks.removeWhere((ub) => ub.userBook.id == userBookId);
    notifyListeners();
  }

  // ─── Notes ───────────────────────────────────────────────

  Future<BookNote> addNote(String userBookId,
      {required String content, int? pageNumber, NoteType type = NoteType.note, String? imagePath}) async {
    final note = BookNote(
      id: _uuid.v4(),
      userBookId: userBookId,
      pageNumber: pageNumber,
      content: content,
      imagePath: imagePath,
      type: type,
      createdAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('book_notes', note.toMap());

    final i = _userBooks.indexWhere((ub) => ub.userBook.id == userBookId);
    if (i >= 0) {
      final updatedNotes = [note, ..._userBooks[i].notes];
      _userBooks[i] = UserBookWithDetails(
        userBook: _userBooks[i].userBook,
        book: _userBooks[i].book,
        notes: updatedNotes,
        activeLending: _userBooks[i].activeLending,
      );
      notifyListeners();
    }
    return note;
  }

  Future<void> deleteNote(String noteId) async {
    final db = await _db.database;
    await db.delete('book_notes', where: 'id = ?', whereArgs: [noteId]);
    for (int i = 0; i < _userBooks.length; i++) {
      final notes = _userBooks[i].notes;
      if (notes.any((n) => n.id == noteId)) {
        _userBooks[i] = UserBookWithDetails(
          userBook: _userBooks[i].userBook,
          book: _userBooks[i].book,
          notes: notes.where((n) => n.id != noteId).toList(),
          activeLending: _userBooks[i].activeLending,
        );
        notifyListeners();
        break;
      }
    }
  }

  // ─── Lending ─────────────────────────────────────────────

  Future<Lending> lendBook(String userBookId,
      {required String borrowerName, String? contact, DateTime? dueDate}) async {
    final lending = Lending(
      id: _uuid.v4(),
      userBookId: userBookId,
      borrowerName: borrowerName,
      borrowerContact: contact,
      lentDate: DateTime.now(),
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('lendings', lending.toMap());

    final i = _userBooks.indexWhere((ub) => ub.userBook.id == userBookId);
    if (i >= 0) {
      _userBooks[i] = UserBookWithDetails(
        userBook: _userBooks[i].userBook,
        book: _userBooks[i].book,
        notes: _userBooks[i].notes,
        activeLending: lending,
      );
      notifyListeners();
    }
    return lending;
  }

  Future<void> returnBook(String lendingId) async {
    final db = await _db.database;
    await db.update(
      'lendings',
      {'returned_date': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [lendingId],
    );
    for (int i = 0; i < _userBooks.length; i++) {
      if (_userBooks[i].activeLending?.id == lendingId) {
        _userBooks[i] = UserBookWithDetails(
          userBook: _userBooks[i].userBook,
          book: _userBooks[i].book,
          notes: _userBooks[i].notes,
          activeLending: null,
        );
        notifyListeners();
        break;
      }
    }
  }

  /// Get all lending history for a user book.
  Future<List<Lending>> getLendingHistory(String userBookId) async {
    final db = await _db.database;
    final maps = await db.query('lendings',
        where: 'user_book_id = ?',
        whereArgs: [userBookId],
        orderBy: 'lent_date DESC');
    return maps.map(Lending.fromMap).toList();
  }
}
