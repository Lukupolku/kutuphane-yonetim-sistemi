import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kutuphane_mobile/models/school.dart';
import 'package:kutuphane_mobile/repositories/mock_book_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_holding_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_school_repository.dart';
import 'package:kutuphane_mobile/providers/inventory_provider.dart';
import 'package:kutuphane_mobile/providers/school_provider.dart';
import 'package:kutuphane_mobile/services/isbn_lookup_service.dart';
import 'package:kutuphane_mobile/screens/shelf_results_screen.dart';

void main() {
  late MockBookRepository bookRepository;
  late MockHoldingRepository holdingRepository;
  late MockSchoolRepository schoolRepository;
  late InventoryProvider inventoryProvider;
  late SchoolProvider schoolProvider;
  late IsbnLookupService isbnLookupService;

  setUp(() {
    bookRepository = MockBookRepository([]);
    holdingRepository = MockHoldingRepository([]);
    schoolRepository = MockSchoolRepository([
      School(
        id: 'school1',
        name: 'Ankara Ilkokulu',
        province: 'Ankara',
        district: 'Cankaya',
        schoolType: SchoolType.ilkokul,
        ministryCode: '06001',
      ),
    ]);

    inventoryProvider = InventoryProvider(
      bookRepository: bookRepository,
      holdingRepository: holdingRepository,
    );

    schoolProvider = SchoolProvider(schoolRepository: schoolRepository);
    schoolProvider.selectSchool(School(
      id: 'school1',
      name: 'Ankara Ilkokulu',
      province: 'Ankara',
      district: 'Cankaya',
      schoolType: SchoolType.ilkokul,
      ministryCode: '06001',
    ));

    isbnLookupService = IsbnLookupService(bookRepository: bookRepository);
  });

  Widget createTestWidget({required List<String> detectedTitles}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<InventoryProvider>.value(
          value: inventoryProvider,
        ),
        ChangeNotifierProvider<SchoolProvider>.value(
          value: schoolProvider,
        ),
        Provider<IsbnLookupService>.value(
          value: isbnLookupService,
        ),
      ],
      child: MaterialApp(
        home: ShelfResultsScreen(detectedTitles: detectedTitles),
      ),
    );
  }

  group('ShelfResultsScreen', () {
    testWidgets('shows detected titles with checkboxes', (tester) async {
      final titles = ['Kucuk Prens', 'Sefiller', 'Suç ve Ceza'];

      await tester.pumpWidget(createTestWidget(detectedTitles: titles));
      await tester.pumpAndSettle();

      // 3 title CheckboxListTiles + 1 "Tümünü Seç" toggle = 4
      expect(find.byType(CheckboxListTile), findsNWidgets(4));
    });

    testWidgets('shows title count in app bar', (tester) async {
      final titles = ['Kucuk Prens', 'Sefiller', 'Suç ve Ceza'];

      await tester.pumpWidget(createTestWidget(detectedTitles: titles));
      await tester.pumpAndSettle();

      expect(find.text('Raf Sonuçları (3)'), findsOneWidget);
    });

    testWidgets('shows save button with selected count', (tester) async {
      final titles = ['Kucuk Prens', 'Sefiller'];

      await tester.pumpWidget(createTestWidget(detectedTitles: titles));
      await tester.pumpAndSettle();

      expect(find.text('2 Kitap Kaydet'), findsOneWidget);
    });

    testWidgets('toggling a title updates save button count', (tester) async {
      final titles = ['Kucuk Prens', 'Sefiller'];

      await tester.pumpWidget(createTestWidget(detectedTitles: titles));
      await tester.pumpAndSettle();

      // Uncheck the first title
      await tester.tap(find.text('Kucuk Prens'));
      await tester.pumpAndSettle();

      expect(find.text('1 Kitap Kaydet'), findsOneWidget);
    });
  });
}
