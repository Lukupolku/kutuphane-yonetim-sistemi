import '../models/holding.dart';

abstract class HoldingRepository {
  Future<List<Holding>> getBySchoolId(String schoolId);
  Future<void> create(Holding holding);
  Future<void> addOrIncrement({
    required String bookId,
    required String schoolId,
    required String addedBy,
    required HoldingSource source,
  });
  Future<void> updateQuantity(String holdingId, int newQuantity);
  Future<void> delete(String holdingId);
}
