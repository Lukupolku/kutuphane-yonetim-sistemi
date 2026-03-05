import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kutuphane_mobile/models/book.dart';
import 'package:kutuphane_mobile/models/holding.dart';
import 'package:kutuphane_mobile/models/school.dart';
import 'package:kutuphane_mobile/repositories/mock_book_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_holding_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_school_repository.dart';
import 'package:kutuphane_mobile/providers/inventory_provider.dart';
import 'package:kutuphane_mobile/providers/school_provider.dart';
import 'package:kutuphane_mobile/screens/inventory_screen.dart';

void main() {
  late MockBookRepository bookRepository;
  late MockHoldingRepository holdingRepository;
  late MockSchoolRepository schoolRepository;
  late InventoryProvider inventoryProvider;
  late SchoolProvider schoolProvider;

  setUp(() {
    final seedBooks = [
      Book(
        id: 'b1',
        isbn: '9789750719387',
        title: 'Tutunamayanlar',
        authors: ['Oguz Atay'],
        publisher: 'Iletisim',
        language: 'tr',
        source: BookSource.manual,
        createdAt: DateTime(2024, 1, 1),
      ),
    ];

    final seedHoldings = [
      Holding(
        id: 'h1',
        bookId: 'b1',
        schoolId: 'school1',
        quantity: 3,
        addedBy: 'teacher1',
        addedAt: DateTime(2024, 1, 10),
        source: HoldingSource.manual,
      ),
    ];

    final seedSchools = [
      School(
        id: 'school1',
        name: 'Ankara Ilkokulu',
        province: 'Ankara',
        district: 'Cankaya',
        schoolType: SchoolType.ilkokul,
        ministryCode: '06001',
      ),
    ];

    bookRepository = MockBookRepository(seedBooks);
    holdingRepository = MockHoldingRepository(seedHoldings);
    schoolRepository = MockSchoolRepository(seedSchools);

    inventoryProvider = InventoryProvider(
      bookRepository: bookRepository,
      holdingRepository: holdingRepository,
    );

    schoolProvider = SchoolProvider(schoolRepository: schoolRepository);
    schoolProvider.selectSchool(seedSchools.first);
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<InventoryProvider>.value(
          value: inventoryProvider,
        ),
        ChangeNotifierProvider<SchoolProvider>.value(
          value: schoolProvider,
        ),
      ],
      child: MaterialApp(
        routes: {
          '/': (context) => const InventoryScreen(),
          '/school-selection': (context) => const Scaffold(
                body: Center(child: Text('School Selection')),
              ),
          '/scan/barcode': (context) => const Scaffold(
                body: Center(child: Text('Barcode Scan')),
              ),
          '/scan/cover': (context) => const Scaffold(
                body: Center(child: Text('Cover Scan')),
              ),
          '/scan/shelf': (context) => const Scaffold(
                body: Center(child: Text('Shelf Scan')),
              ),
          '/book/confirm': (context) => const Scaffold(
                body: Center(child: Text('Book Confirm')),
              ),
        },
      ),
    );
  }

  group('InventoryScreen', () {
    testWidgets('shows FAB for adding books', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows school name in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ankara Ilkokulu'), findsOneWidget);
    });

    testWidgets('shows book list after loading', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tutunamayanlar'), findsOneWidget);
    });

    testWidgets('shows bottom sheet when FAB is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Kitap Ekle'), findsWidgets);
      expect(find.text('Barkod Tara'), findsOneWidget);
      expect(find.text('Manuel Giris'), findsOneWidget);
    });
  });
}
