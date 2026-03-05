import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kutuphane_mobile/models/book.dart';
import 'package:kutuphane_mobile/models/school.dart';
import 'package:kutuphane_mobile/repositories/mock_book_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_holding_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_school_repository.dart';
import 'package:kutuphane_mobile/providers/inventory_provider.dart';
import 'package:kutuphane_mobile/providers/school_provider.dart';
import 'package:kutuphane_mobile/screens/book_confirm_screen.dart';

void main() {
  late MockBookRepository bookRepository;
  late MockHoldingRepository holdingRepository;
  late MockSchoolRepository schoolRepository;
  late InventoryProvider inventoryProvider;
  late SchoolProvider schoolProvider;

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
  });

  Widget createTestWidget({Book? book, String? isbn, String sourceType = 'BARCODE_SCAN'}) {
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
        home: BookConfirmScreen(
          book: book,
          isbn: isbn,
          sourceType: sourceType,
        ),
      ),
    );
  }

  group('BookConfirmScreen', () {
    testWidgets('shows book info when book is provided', (tester) async {
      final book = Book(
        id: 'b1',
        isbn: '9789750719387',
        title: 'Tutunamayanlar',
        authors: ['Oguz Atay'],
        publisher: 'Iletisim',
        language: 'tr',
        source: BookSource.googleBooks,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(createTestWidget(
        book: book,
        isbn: '9789750719387',
        sourceType: 'BARCODE_SCAN',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tutunamayanlar'), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
    });

    testWidgets('shows empty form when no book provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        sourceType: 'MANUAL',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Baslik'), findsOneWidget);
      expect(find.text('Yazar'), findsOneWidget);
    });
  });
}
