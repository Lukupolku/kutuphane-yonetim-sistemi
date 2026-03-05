import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/holding.dart';
import 'package:kutuphane_mobile/repositories/holding_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_holding_repository.dart';

void main() {
  late HoldingRepository repository;
  late List<Holding> seedHoldings;

  setUp(() {
    seedHoldings = [
      Holding(
        id: 'h1',
        bookId: 'b1',
        schoolId: 's1',
        quantity: 3,
        addedBy: 'teacher1',
        addedAt: DateTime.parse('2026-01-15T10:00:00Z'),
        source: HoldingSource.barcodeScan,
      ),
      Holding(
        id: 'h2',
        bookId: 'b2',
        schoolId: 's1',
        quantity: 1,
        addedBy: 'teacher1',
        addedAt: DateTime.parse('2026-01-16T10:00:00Z'),
        source: HoldingSource.manual,
      ),
      Holding(
        id: 'h3',
        bookId: 'b1',
        schoolId: 's2',
        quantity: 2,
        addedBy: 'teacher2',
        addedAt: DateTime.parse('2026-01-17T10:00:00Z'),
        source: HoldingSource.coverOcr,
      ),
    ];
    repository = MockHoldingRepository(seedHoldings);
  });

  group('MockHoldingRepository', () {
    group('getBySchoolId', () {
      test('returns holdings for a specific school', () async {
        final holdings = await repository.getBySchoolId('s1');
        expect(holdings, hasLength(2));
        expect(holdings.every((h) => h.schoolId == 's1'), isTrue);
      });

      test('returns empty list when no holdings for school', () async {
        final holdings = await repository.getBySchoolId('nonexistent');
        expect(holdings, isEmpty);
      });
    });

    group('create', () {
      test('adds a new holding', () async {
        final newHolding = Holding(
          id: 'h4',
          bookId: 'b3',
          schoolId: 's1',
          quantity: 1,
          addedBy: 'teacher1',
          addedAt: DateTime.now(),
          source: HoldingSource.manual,
        );

        await repository.create(newHolding);

        final holdings = await repository.getBySchoolId('s1');
        expect(holdings, hasLength(3));
        expect(holdings.any((h) => h.id == 'h4'), isTrue);
      });
    });

    group('addOrIncrement', () {
      test('increments quantity when book+school combo exists', () async {
        // h1 is bookId='b1', schoolId='s1', quantity=3
        await repository.addOrIncrement(
          bookId: 'b1',
          schoolId: 's1',
          addedBy: 'teacher1',
          source: HoldingSource.barcodeScan,
        );

        final holdings = await repository.getBySchoolId('s1');
        final holding = holdings.firstWhere(
          (h) => h.bookId == 'b1' && h.schoolId == 's1',
        );
        expect(holding.quantity, 4); // was 3, now 4
      });

      test('creates new holding when book+school combo does not exist',
          () async {
        await repository.addOrIncrement(
          bookId: 'b3',
          schoolId: 's3',
          addedBy: 'teacher3',
          source: HoldingSource.shelfOcr,
        );

        final holdings = await repository.getBySchoolId('s3');
        expect(holdings, hasLength(1));
        expect(holdings.first.bookId, 'b3');
        expect(holdings.first.schoolId, 's3');
        expect(holdings.first.quantity, 1);
        expect(holdings.first.addedBy, 'teacher3');
        expect(holdings.first.source, HoldingSource.shelfOcr);
        // ID should be a UUID (non-empty, different from seed IDs)
        expect(holdings.first.id, isNotEmpty);
        expect(holdings.first.id, isNot('h1'));
        expect(holdings.first.id, isNot('h2'));
        expect(holdings.first.id, isNot('h3'));
      });

      test('increments preserve the existing holding id', () async {
        await repository.addOrIncrement(
          bookId: 'b1',
          schoolId: 's1',
          addedBy: 'teacher1',
          source: HoldingSource.barcodeScan,
        );

        final holdings = await repository.getBySchoolId('s1');
        final holding = holdings.firstWhere(
          (h) => h.bookId == 'b1' && h.schoolId == 's1',
        );
        expect(holding.id, 'h1'); // preserves original ID
      });
    });
  });
}
