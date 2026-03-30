enum NoteType { highlight, note, quote }

class BookNote {
  final String id;
  final String userBookId;
  final int? pageNumber;
  final String content;
  final String? imagePath;
  final NoteType type;
  final DateTime createdAt;

  BookNote({
    required this.id,
    required this.userBookId,
    this.pageNumber,
    required this.content,
    this.imagePath,
    this.type = NoteType.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_book_id': userBookId,
        'page_number': pageNumber,
        'content': content,
        'image_path': imagePath,
        'type': type.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory BookNote.fromMap(Map<String, dynamic> map) => BookNote(
        id: map['id'] as String,
        userBookId: map['user_book_id'] as String,
        pageNumber: map['page_number'] as int?,
        content: map['content'] as String,
        imagePath: map['image_path'] as String?,
        type: NoteType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => NoteType.note,
        ),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  BookNote copyWith({
    int? pageNumber,
    String? content,
    String? imagePath,
    NoteType? type,
  }) =>
      BookNote(
        id: id,
        userBookId: userBookId,
        pageNumber: pageNumber ?? this.pageNumber,
        content: content ?? this.content,
        imagePath: imagePath ?? this.imagePath,
        type: type ?? this.type,
        createdAt: createdAt,
      );

  String get typeLabel {
    switch (type) {
      case NoteType.highlight:
        return 'Alti Cizili';
      case NoteType.note:
        return 'Not';
      case NoteType.quote:
        return 'Alinti';
    }
  }
}
