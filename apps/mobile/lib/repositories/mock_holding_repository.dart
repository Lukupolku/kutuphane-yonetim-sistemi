import 'package:uuid/uuid.dart';

import '../models/holding.dart';
import 'holding_repository.dart';

class MockHoldingRepository implements HoldingRepository {
  final List<Holding> _holdings;
  final Uuid _uuid = const Uuid();

  MockHoldingRepository(List<Holding> holdings)
      : _holdings = List<Holding>.from(holdings);

  @override
  Future<List<Holding>> getBySchoolId(String schoolId) async {
    return _holdings.where((h) => h.schoolId == schoolId).toList();
  }

  @override
  Future<void> create(Holding holding) async {
    _holdings.add(holding);
  }

  @override
  Future<void> addOrIncrement({
    required String bookId,
    required String schoolId,
    required String addedBy,
    required HoldingSource source,
  }) async {
    final existingIndex = _holdings.indexWhere(
      (h) => h.bookId == bookId && h.schoolId == schoolId,
    );

    if (existingIndex != -1) {
      final existing = _holdings[existingIndex];
      _holdings[existingIndex] = Holding(
        id: existing.id,
        bookId: existing.bookId,
        schoolId: existing.schoolId,
        quantity: existing.quantity + 1,
        addedBy: existing.addedBy,
        addedAt: existing.addedAt,
        source: existing.source,
      );
    } else {
      _holdings.add(Holding(
        id: _uuid.v4(),
        bookId: bookId,
        schoolId: schoolId,
        quantity: 1,
        addedBy: addedBy,
        addedAt: DateTime.now(),
        source: source,
      ));
    }
  }

  @override
  Future<void> updateQuantity(String holdingId, int newQuantity) async {
    final index = _holdings.indexWhere((h) => h.id == holdingId);
    if (index != -1) {
      final existing = _holdings[index];
      _holdings[index] = Holding(
        id: existing.id,
        bookId: existing.bookId,
        schoolId: existing.schoolId,
        quantity: newQuantity,
        addedBy: existing.addedBy,
        addedAt: existing.addedAt,
        source: existing.source,
      );
    }
  }

  @override
  Future<void> delete(String holdingId) async {
    _holdings.removeWhere((h) => h.id == holdingId);
  }
}
