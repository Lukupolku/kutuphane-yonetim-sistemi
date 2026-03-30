import 'dart:convert';

enum BookSource { googleBooks, openLibrary, manual }

class Book {
  final String id;
  final String? isbn;
  final String title;
  final List<String> authors;
  final String? publisher;
  final String? publishedDate;
  final int? pageCount;
  final String? coverImageUrl;
  final String? description;
  final List<String> categories;
  final String language;
  final BookSource source;
  final DateTime createdAt;

  Book({
    required this.id,
    this.isbn,
    required this.title,
    required this.authors,
    this.publisher,
    this.publishedDate,
    this.pageCount,
    this.coverImageUrl,
    this.description,
    this.categories = const [],
    this.language = 'tr',
    required this.source,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'isbn': isbn,
        'title': title,
        'authors': jsonEncode(authors),
        'publisher': publisher,
        'published_date': publishedDate,
        'page_count': pageCount,
        'cover_image_url': coverImageUrl,
        'description': description,
        'categories': jsonEncode(categories),
        'language': language,
        'source': source.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory Book.fromMap(Map<String, dynamic> map) => Book(
        id: map['id'] as String,
        isbn: map['isbn'] as String?,
        title: map['title'] as String,
        authors: _decodeList(map['authors']),
        publisher: map['publisher'] as String?,
        publishedDate: map['published_date'] as String?,
        pageCount: map['page_count'] as int?,
        coverImageUrl: map['cover_image_url'] as String?,
        description: map['description'] as String?,
        categories: _decodeList(map['categories']),
        language: (map['language'] as String?) ?? 'tr',
        source: BookSource.values.firstWhere(
          (e) => e.name == map['source'],
          orElse: () => BookSource.manual,
        ),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  static List<String> _decodeList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    if (value is String) {
      try {
        return (jsonDecode(value) as List).cast<String>();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  Book copyWith({
    String? isbn,
    String? title,
    List<String>? authors,
    String? publisher,
    String? publishedDate,
    int? pageCount,
    String? coverImageUrl,
    String? description,
    List<String>? categories,
  }) =>
      Book(
        id: id,
        isbn: isbn ?? this.isbn,
        title: title ?? this.title,
        authors: authors ?? this.authors,
        publisher: publisher ?? this.publisher,
        publishedDate: publishedDate ?? this.publishedDate,
        pageCount: pageCount ?? this.pageCount,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        description: description ?? this.description,
        categories: categories ?? this.categories,
        language: language,
        source: source,
        createdAt: createdAt,
      );
}
