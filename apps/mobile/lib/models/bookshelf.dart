class Bookshelf {
  final String id;
  final String roomId;
  final String name;
  final int sortOrder;
  final DateTime createdAt;

  Bookshelf({
    required this.id,
    required this.roomId,
    required this.name,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'room_id': roomId,
        'name': name,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
      };

  factory Bookshelf.fromMap(Map<String, dynamic> map) => Bookshelf(
        id: map['id'] as String,
        roomId: map['room_id'] as String,
        name: map['name'] as String,
        sortOrder: (map['sort_order'] as int?) ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Bookshelf copyWith({String? name, int? sortOrder}) => Bookshelf(
        id: id,
        roomId: roomId,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
      );
}
