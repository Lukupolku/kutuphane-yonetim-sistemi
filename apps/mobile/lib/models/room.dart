class Room {
  final String id;
  final String name;
  final String? icon;
  final int sortOrder;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.name,
    this.icon,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
      };

  factory Room.fromMap(Map<String, dynamic> map) => Room(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String?,
        sortOrder: (map['sort_order'] as int?) ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Room copyWith({String? name, String? icon, int? sortOrder}) => Room(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
      );
}
