enum HoldingSource {
  barcodeScan,
  coverOcr,
  shelfOcr,
  manual;

  static HoldingSource fromString(String value) {
    switch (value) {
      case 'BARCODE_SCAN': return HoldingSource.barcodeScan;
      case 'COVER_OCR': return HoldingSource.coverOcr;
      case 'SHELF_OCR': return HoldingSource.shelfOcr;
      case 'MANUAL': return HoldingSource.manual;
      default: throw ArgumentError('Unknown HoldingSource: $value');
    }
  }

  String toJsonString() {
    switch (this) {
      case HoldingSource.barcodeScan: return 'BARCODE_SCAN';
      case HoldingSource.coverOcr: return 'COVER_OCR';
      case HoldingSource.shelfOcr: return 'SHELF_OCR';
      case HoldingSource.manual: return 'MANUAL';
    }
  }
}

class Holding {
  final String id;
  final String bookId;
  final String schoolId;
  final int quantity;
  final String addedBy;
  final DateTime addedAt;
  final HoldingSource source;

  Holding({
    required this.id,
    required this.bookId,
    required this.schoolId,
    required this.quantity,
    required this.addedBy,
    required this.addedAt,
    required this.source,
  });

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      schoolId: json['schoolId'] as String,
      quantity: json['quantity'] as int,
      addedBy: json['addedBy'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
      source: HoldingSource.fromString(json['source'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'schoolId': schoolId,
      'quantity': quantity,
      'addedBy': addedBy,
      'addedAt': addedAt.toIso8601String(),
      'source': source.toJsonString(),
    };
  }
}
