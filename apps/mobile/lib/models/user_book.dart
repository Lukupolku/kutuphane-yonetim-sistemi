enum ReadingStatus { toRead, reading, read, dropped }

class UserBook {
  final String id;
  final String bookId;
  final String? shelfId;
  final ReadingStatus status;
  final double? rating;
  final bool isFavorite;
  final DateTime? startDate;
  final DateTime? finishDate;
  final String? personalNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserBook({
    required this.id,
    required this.bookId,
    this.shelfId,
    this.status = ReadingStatus.toRead,
    this.rating,
    this.isFavorite = false,
    this.startDate,
    this.finishDate,
    this.personalNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'book_id': bookId,
        'shelf_id': shelfId,
        'status': status.name,
        'rating': rating,
        'is_favorite': isFavorite ? 1 : 0,
        'start_date': startDate?.toIso8601String(),
        'finish_date': finishDate?.toIso8601String(),
        'personal_notes': personalNotes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory UserBook.fromMap(Map<String, dynamic> map) => UserBook(
        id: map['id'] as String,
        bookId: map['book_id'] as String,
        shelfId: map['shelf_id'] as String?,
        status: ReadingStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => ReadingStatus.toRead,
        ),
        rating: (map['rating'] as num?)?.toDouble(),
        isFavorite: (map['is_favorite'] as int?) == 1,
        startDate: map['start_date'] != null
            ? DateTime.parse(map['start_date'] as String)
            : null,
        finishDate: map['finish_date'] != null
            ? DateTime.parse(map['finish_date'] as String)
            : null,
        personalNotes: map['personal_notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  UserBook copyWith({
    String? shelfId,
    ReadingStatus? status,
    double? rating,
    bool? isFavorite,
    DateTime? startDate,
    DateTime? finishDate,
    String? personalNotes,
  }) =>
      UserBook(
        id: id,
        bookId: bookId,
        shelfId: shelfId ?? this.shelfId,
        status: status ?? this.status,
        rating: rating ?? this.rating,
        isFavorite: isFavorite ?? this.isFavorite,
        startDate: startDate ?? this.startDate,
        finishDate: finishDate ?? this.finishDate,
        personalNotes: personalNotes ?? this.personalNotes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  String get statusLabel {
    switch (status) {
      case ReadingStatus.toRead:
        return 'Okunacak';
      case ReadingStatus.reading:
        return 'Okunuyor';
      case ReadingStatus.read:
        return 'Okundu';
      case ReadingStatus.dropped:
        return 'Birakildi';
    }
  }
}
