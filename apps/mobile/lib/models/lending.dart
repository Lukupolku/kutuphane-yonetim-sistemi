class Lending {
  final String id;
  final String userBookId;
  final String borrowerName;
  final String? borrowerContact;
  final DateTime lentDate;
  final DateTime? dueDate;
  final DateTime? returnedDate;
  final String? notes;
  final DateTime createdAt;

  Lending({
    required this.id,
    required this.userBookId,
    required this.borrowerName,
    this.borrowerContact,
    required this.lentDate,
    this.dueDate,
    this.returnedDate,
    this.notes,
    required this.createdAt,
  });

  bool get isReturned => returnedDate != null;

  bool get isOverdue =>
      !isReturned && dueDate != null && DateTime.now().isAfter(dueDate!);

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_book_id': userBookId,
        'borrower_name': borrowerName,
        'borrower_contact': borrowerContact,
        'lent_date': lentDate.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
        'returned_date': returnedDate?.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory Lending.fromMap(Map<String, dynamic> map) => Lending(
        id: map['id'] as String,
        userBookId: map['user_book_id'] as String,
        borrowerName: map['borrower_name'] as String,
        borrowerContact: map['borrower_contact'] as String?,
        lentDate: DateTime.parse(map['lent_date'] as String),
        dueDate: map['due_date'] != null
            ? DateTime.parse(map['due_date'] as String)
            : null,
        returnedDate: map['returned_date'] != null
            ? DateTime.parse(map['returned_date'] as String)
            : null,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Lending copyWith({
    String? borrowerName,
    String? borrowerContact,
    DateTime? dueDate,
    DateTime? returnedDate,
    String? notes,
  }) =>
      Lending(
        id: id,
        userBookId: userBookId,
        borrowerName: borrowerName ?? this.borrowerName,
        borrowerContact: borrowerContact ?? this.borrowerContact,
        lentDate: lentDate,
        dueDate: dueDate ?? this.dueDate,
        returnedDate: returnedDate ?? this.returnedDate,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}
