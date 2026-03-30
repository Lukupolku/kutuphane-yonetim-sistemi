class ReadingList {
  final String id;
  final String name;
  final String? description;
  final String source; // 'user' or 'api'
  final DateTime createdAt;

  ReadingList({
    required this.id,
    required this.name,
    this.description,
    this.source = 'user',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'source': source,
        'created_at': createdAt.toIso8601String(),
      };

  factory ReadingList.fromMap(Map<String, dynamic> map) => ReadingList(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        source: (map['source'] as String?) ?? 'user',
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class ReadingListItem {
  final String id;
  final String readingListId;
  final String bookId;
  final int sortOrder;
  final DateTime addedAt;

  ReadingListItem({
    required this.id,
    required this.readingListId,
    required this.bookId,
    this.sortOrder = 0,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'reading_list_id': readingListId,
        'book_id': bookId,
        'sort_order': sortOrder,
        'added_at': addedAt.toIso8601String(),
      };

  factory ReadingListItem.fromMap(Map<String, dynamic> map) => ReadingListItem(
        id: map['id'] as String,
        readingListId: map['reading_list_id'] as String,
        bookId: map['book_id'] as String,
        sortOrder: (map['sort_order'] as int?) ?? 0,
        addedAt: DateTime.parse(map['added_at'] as String),
      );
}
