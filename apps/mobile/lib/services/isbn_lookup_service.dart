import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/book.dart';
import '../repositories/book_repository.dart';

class IsbnLookupService {
  final BookRepository bookRepository;

  IsbnLookupService({required this.bookRepository});

  /// Looks up a book by ISBN using fallback chain:
  /// 1. Local repository (mock data)
  /// 2. Google Books API
  /// 3. Open Library API
  /// Returns null if not found anywhere.
  Future<Book?> lookupByIsbn(String isbn) async {
    // 1. Check local repository first
    final localBook = await bookRepository.getByIsbn(isbn);
    if (localBook != null) return localBook;

    // 2. Try Google Books API
    final googleBook = await _lookupGoogleBooks(isbn);
    if (googleBook != null) return googleBook;

    // 3. Try Open Library API
    final openLibBook = await _lookupOpenLibrary(isbn);
    if (openLibBook != null) return openLibBook;

    return null;
  }

  /// Searches books by title in local repository.
  Future<List<Book>> searchByTitle(String query) async {
    return await bookRepository.searchByTitle(query);
  }

  /// Google Books API lookup.
  /// https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn}
  Future<Book?> _lookupGoogleBooks(String isbn) async {
    try {
      final uri = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn',
      );
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final totalItems = data['totalItems'] as int? ?? 0;
      if (totalItems == 0) return null;

      final items = data['items'] as List<dynamic>;
      if (items.isEmpty) return null;

      final volumeInfo =
          items[0]['volumeInfo'] as Map<String, dynamic>? ?? {};

      final title = volumeInfo['title'] as String? ?? '';
      if (title.isEmpty) return null;

      final authors = (volumeInfo['authors'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
          [];
      final publisher = volumeInfo['publisher'] as String?;
      final publishedDate = volumeInfo['publishedDate'] as String?;
      final pageCount = volumeInfo['pageCount'] as int?;

      // Try to get cover image
      final imageLinks =
          volumeInfo['imageLinks'] as Map<String, dynamic>?;
      final coverUrl = imageLinks?['thumbnail'] as String? ??
          imageLinks?['smallThumbnail'] as String?;

      return Book(
        id: 'google-$isbn',
        isbn: isbn,
        title: title,
        authors: authors.isEmpty ? ['Bilinmiyor'] : authors,
        publisher: publisher,
        publishedDate: publishedDate,
        pageCount: pageCount,
        coverImageUrl: coverUrl,
        language: volumeInfo['language'] as String? ?? 'tr',
        source: BookSource.googleBooks,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Open Library API lookup.
  /// https://openlibrary.org/isbn/{isbn}.json
  Future<Book?> _lookupOpenLibrary(String isbn) async {
    try {
      final uri = Uri.parse('https://openlibrary.org/isbn/$isbn.json');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;

      final title = data['title'] as String? ?? '';
      if (title.isEmpty) return null;

      // Open Library stores authors as references, try to get them
      final authorRefs = data['authors'] as List<dynamic>? ?? [];
      final authors = <String>[];
      for (final ref in authorRefs) {
        final key = (ref as Map<String, dynamic>?)?['key'] as String?;
        if (key != null) {
          final authorName = await _fetchOpenLibraryAuthor(key);
          if (authorName != null) authors.add(authorName);
        }
      }

      final publishers = data['publishers'] as List<dynamic>? ?? [];
      final publisher =
          publishers.isNotEmpty ? publishers[0].toString() : null;

      final publishDate = data['publish_date'] as String?;
      final pageCount = data['number_of_pages'] as int?;

      // Cover image
      final covers = data['covers'] as List<dynamic>? ?? [];
      String? coverUrl;
      if (covers.isNotEmpty) {
        coverUrl =
            'https://covers.openlibrary.org/b/id/${covers[0]}-M.jpg';
      }

      return Book(
        id: 'openlibrary-$isbn',
        isbn: isbn,
        title: title,
        authors: authors.isEmpty ? ['Bilinmiyor'] : authors,
        publisher: publisher,
        publishedDate: publishDate,
        pageCount: pageCount,
        coverImageUrl: coverUrl,
        language: 'tr',
        source: BookSource.openLibrary,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetch author name from Open Library author key.
  Future<String?> _fetchOpenLibraryAuthor(String authorKey) async {
    try {
      final uri = Uri.parse('https://openlibrary.org$authorKey.json');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
