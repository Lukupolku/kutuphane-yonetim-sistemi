class Shelf {
  final String id;
  final String bookshelfId;
  final String name;
  final int sortOrder;
  final DateTime createdAt;

  Shelf({
    required this.id,
    required this.bookshelfId,
    required this.name,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'bookshelf_id': bookshelfId,
        'name': name,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
      };

  factory Shelf.fromMap(Map<String, dynamic> map) => Shelf(
        id: map['id'] as String,
        bookshelfId: map['bookshelf_id'] as String,
        name: map['name'] as String,
        sortOrder: (map['sort_order'] as int?) ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Shelf copyWith({String? name, int? sortOrder}) => Shelf(
        id: id,
        bookshelfId: bookshelfId,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
      );
}
