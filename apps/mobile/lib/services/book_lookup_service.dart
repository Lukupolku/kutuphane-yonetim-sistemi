import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import 'package:uuid/uuid.dart';

/// Searches Google Books API and Open Library for book metadata.
/// Fallback chain: Google Books → Open Library → null (manual entry).
class BookLookupService {
  static const _googleBooksBase = 'https://www.googleapis.com/books/v1';
  static const _openLibraryBase = 'https://openlibrary.org';
  static const _timeout = Duration(seconds: 10);
  static const _uuid = Uuid();

  /// Look up a book by ISBN. Tries Google Books first, then Open Library.
  Future<Book?> lookupByIsbn(String isbn) async {
    final cleaned = isbn.replaceAll(RegExp(r'[^0-9X]'), '');
    return await _googleBooksIsbn(cleaned) ??
        await _openLibraryIsbn(cleaned);
  }

  /// Search books by title/author query. Returns up to [maxResults] results.
  Future<List<Book>> search(String query, {int maxResults = 20}) async {
    if (query.trim().isEmpty) return [];

    final results = <Book>[];

    // Try Google Books first
    final googleResults = await _googleBooksSearch(query, maxResults);
    results.addAll(googleResults);

    // If Google returned few results, supplement with Open Library
    if (results.length < 5) {
      final olResults = await _openLibrarySearch(query, maxResults - results.length);
      // Deduplicate by ISBN
      final existingIsbns = results.map((b) => b.isbn).whereType<String>().toSet();
      for (final book in olResults) {
        if (book.isbn == null || !existingIsbns.contains(book.isbn)) {
          results.add(book);
        }
      }
    }

    return results.take(maxResults).toList();
  }

  /// Fetch related books by subject/category from Open Library.
  Future<List<Book>> getRelatedBooks(Book book, {int limit = 10}) async {
    if (book.categories.isEmpty) return [];

    final subject = book.categories.first
        .toLowerCase()
        .replaceAll(' ', '_');

    try {
      final uri = Uri.parse(
        '$_openLibraryBase/subjects/$subject.json?limit=$limit',
      );
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final works = data['works'] as List? ?? [];

      return works.map((w) {
        final authors = w['authors'] as List? ?? [];
        return Book(
          id: _uuid.v4(),
          title: w['title'] as String? ?? '',
          authors: authors.map((a) => (a['name'] as String?) ?? '').toList(),
          coverImageUrl: w['cover_id'] != null
              ? 'https://covers.openlibrary.org/b/id/${w['cover_id']}-M.jpg'
              : null,
          source: BookSource.openLibrary,
          createdAt: DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Google Books ────────────────────────────────────────

  Future<Book?> _googleBooksIsbn(String isbn) async {
    try {
      final uri = Uri.parse(
        '$_googleBooksBase/volumes?q=isbn:$isbn&langRestrict=tr&maxResults=1',
      );
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List?;
      if (items == null || items.isEmpty) return null;

      return _parseGoogleBook(items.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<Book>> _googleBooksSearch(String query, int max) async {
    try {
      final uri = Uri.parse(
        '$_googleBooksBase/volumes?q=${Uri.encodeComponent(query)}'
        '&langRestrict=tr&maxResults=$max&orderBy=relevance',
      );
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];

      return items
          .map((item) => _parseGoogleBook(item as Map<String, dynamic>))
          .whereType<Book>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Book? _parseGoogleBook(Map<String, dynamic> item) {
    final info = item['volumeInfo'] as Map<String, dynamic>?;
    if (info == null) return null;

    final identifiers = info['industryIdentifiers'] as List? ?? [];
    String? isbn;
    for (final id in identifiers) {
      final type = id['type'] as String?;
      if (type == 'ISBN_13' || type == 'ISBN_10') {
        isbn = id['identifier'] as String?;
        if (type == 'ISBN_13') break;
      }
    }

    final imageLinks = info['imageLinks'] as Map<String, dynamic>?;
    String? coverUrl;
    if (imageLinks != null) {
      coverUrl = (imageLinks['medium'] ??
              imageLinks['small'] ??
              imageLinks['thumbnail'] ??
              imageLinks['smallThumbnail']) as String?;
      // Google returns http URLs; upgrade to https
      coverUrl = coverUrl?.replaceFirst('http://', 'https://');
    }

    return Book(
      id: _uuid.v4(),
      isbn: isbn,
      title: info['title'] as String? ?? '',
      authors: ((info['authors'] as List?) ?? []).cast<String>(),
      publisher: info['publisher'] as String?,
      publishedDate: info['publishedDate'] as String?,
      pageCount: info['pageCount'] as int?,
      coverImageUrl: coverUrl,
      description: info['description'] as String?,
      categories: ((info['categories'] as List?) ?? []).cast<String>(),
      language: (info['language'] as String?) ?? 'tr',
      source: BookSource.googleBooks,
      createdAt: DateTime.now(),
    );
  }

  // ─── Open Library ────────────────────────────────────────

  Future<Book?> _openLibraryIsbn(String isbn) async {
    try {
      final uri = Uri.parse('$_openLibraryBase/isbn/$isbn.json');
      final response = await http.get(uri, headers: {
        'User-Agent': 'RaftaApp/1.0 (rafta-kutuphane@app.com)',
      }).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final covers = data['covers'] as List?;
      String? coverUrl;
      if (covers != null && covers.isNotEmpty) {
        coverUrl =
            'https://covers.openlibrary.org/b/id/${covers.first}-M.jpg';
      }

      // Fetch author names from author references
      final authorRefs = data['authors'] as List? ?? [];
      final authors = <String>[];
      for (final ref in authorRefs) {
        final key = ref['key'] as String?;
        if (key != null) {
          try {
            final authorResp =
                await http.get(Uri.parse('$_openLibraryBase$key.json'),
                    headers: {
                      'User-Agent': 'RaftaApp/1.0 (rafta-kutuphane@app.com)',
                    }).timeout(_timeout);
            if (authorResp.statusCode == 200) {
              final authorData =
                  jsonDecode(authorResp.body) as Map<String, dynamic>;
              final name = authorData['name'] as String?;
              if (name != null) authors.add(name);
            }
          } catch (_) {}
        }
      }

      return Book(
        id: _uuid.v4(),
        isbn: isbn,
        title: data['title'] as String? ?? '',
        authors: authors,
        publisher: ((data['publishers'] as List?) ?? []).isNotEmpty
            ? (data['publishers'] as List).first as String
            : null,
        publishedDate: data['publish_date'] as String?,
        pageCount: data['number_of_pages'] as int?,
        coverImageUrl: coverUrl,
        description: data['description'] is String
            ? data['description'] as String
            : (data['description'] as Map<String, dynamic>?)?['value']
                as String?,
        categories: ((data['subjects'] as List?) ?? [])
            .take(5)
            .map((s) => s is String ? s : (s['name'] as String? ?? ''))
            .toList(),
        language: 'tr',
        source: BookSource.openLibrary,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<Book>> _openLibrarySearch(String query, int max) async {
    try {
      final uri = Uri.parse(
        '$_openLibraryBase/search.json?q=${Uri.encodeComponent(query)}'
        '&limit=$max&language=tur',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'RaftaApp/1.0 (rafta-kutuphane@app.com)',
      }).timeout(_timeout);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = data['docs'] as List? ?? [];

      return docs.map((doc) {
        final isbn13 = (doc['isbn'] as List?)?.firstWhere(
          (i) => (i as String).length == 13,
          orElse: () => null,
        ) as String?;
        final isbn10 = (doc['isbn'] as List?)?.firstWhere(
          (i) => (i as String).length == 10,
          orElse: () => null,
        ) as String?;

        final coverId = doc['cover_i'] as int?;

        return Book(
          id: _uuid.v4(),
          isbn: isbn13 ?? isbn10,
          title: doc['title'] as String? ?? '',
          authors: ((doc['author_name'] as List?) ?? []).cast<String>(),
          publisher: ((doc['publisher'] as List?) ?? []).isNotEmpty
              ? (doc['publisher'] as List).first as String
              : null,
          publishedDate: doc['first_publish_year']?.toString(),
          pageCount: doc['number_of_pages_median'] as int?,
          coverImageUrl: coverId != null
              ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
              : null,
          categories:
              ((doc['subject'] as List?) ?? []).take(5).cast<String>().toList(),
          source: BookSource.openLibrary,
          createdAt: DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
