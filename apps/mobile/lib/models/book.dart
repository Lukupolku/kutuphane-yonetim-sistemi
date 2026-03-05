enum BookSource {
  googleBooks,
  openLibrary,
  manual,
  ocr;

  static BookSource fromString(String value) {
    switch (value) {
      case 'GOOGLE_BOOKS': return BookSource.googleBooks;
      case 'OPEN_LIBRARY': return BookSource.openLibrary;
      case 'MANUAL': return BookSource.manual;
      case 'OCR': return BookSource.ocr;
      default: throw ArgumentError('Unknown BookSource: $value');
    }
  }

  String toJsonString() {
    switch (this) {
      case BookSource.googleBooks: return 'GOOGLE_BOOKS';
      case BookSource.openLibrary: return 'OPEN_LIBRARY';
      case BookSource.manual: return 'MANUAL';
      case BookSource.ocr: return 'OCR';
    }
  }
}

class Book {
  final String id;
  final String? isbn;
  final String title;
  final List<String> authors;
  final String? publisher;
  final String? publishedDate;
  final int? pageCount;
  final String? coverImageUrl;
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
    required this.language,
    required this.source,
    required this.createdAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      isbn: json['isbn'] as String?,
      title: json['title'] as String,
      authors: List<String>.from(json['authors'] as List),
      publisher: json['publisher'] as String?,
      publishedDate: json['publishedDate'] as String?,
      pageCount: json['pageCount'] as int?,
      coverImageUrl: json['coverImageUrl'] as String?,
      language: json['language'] as String,
      source: BookSource.fromString(json['source'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isbn': isbn,
      'title': title,
      'authors': authors,
      'publisher': publisher,
      'publishedDate': publishedDate,
      'pageCount': pageCount,
      'coverImageUrl': coverImageUrl,
      'language': language,
      'source': source.toJsonString(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
