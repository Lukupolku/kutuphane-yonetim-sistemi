import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/book.dart';
import 'models/holding.dart';
import 'models/school.dart';
import 'providers/inventory_provider.dart';
import 'providers/school_provider.dart';
import 'repositories/mock_book_repository.dart';
import 'repositories/mock_holding_repository.dart';
import 'repositories/mock_school_repository.dart';
import 'screens/barcode_scan_screen.dart';
import 'screens/book_confirm_screen.dart';
import 'screens/cover_ocr_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/school_selection_screen.dart';
import 'screens/shelf_ocr_screen.dart';
import 'services/isbn_lookup_service.dart';
import 'services/mock_data_service.dart';

void main() {
  runApp(const KutuphaneApp());
}

class _MockData {
  final List<Book> books;
  final List<School> schools;
  final List<Holding> holdings;

  _MockData({
    required this.books,
    required this.schools,
    required this.holdings,
  });
}

Future<_MockData> _loadData() async {
  try {
    final books = await MockDataService.loadBooks();
    final schools = await MockDataService.loadSchools();
    final holdings = await MockDataService.loadHoldings();
    return _MockData(books: books, schools: schools, holdings: holdings);
  } catch (_) {
    return _MockData(books: [], schools: [], holdings: []);
  }
}

class KutuphaneApp extends StatelessWidget {
  const KutuphaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MockData>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            title: 'Kütüphane Yönetim Sistemi',
            theme: ThemeData(
              colorSchemeSeed: Colors.deepPurple,
              useMaterial3: true,
            ),
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final data = snapshot.data!;

        final bookRepo = MockBookRepository(data.books);
        final schoolRepo = MockSchoolRepository(data.schools);
        final holdingRepo = MockHoldingRepository(data.holdings);

        final schoolProvider = SchoolProvider(schoolRepository: schoolRepo);
        schoolProvider.loadProvinces();

        final inventoryProvider = InventoryProvider(
          bookRepository: bookRepo,
          holdingRepository: holdingRepo,
        );

        final isbnLookupService = IsbnLookupService(bookRepository: bookRepo);

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<SchoolProvider>.value(
              value: schoolProvider,
            ),
            ChangeNotifierProvider<InventoryProvider>.value(
              value: inventoryProvider,
            ),
            Provider<IsbnLookupService>.value(
              value: isbnLookupService,
            ),
          ],
          child: Consumer<SchoolProvider>(
            builder: (context, school, _) {
              return MaterialApp(
                title: 'Kütüphane Yönetim Sistemi',
                theme: ThemeData(
                  colorSchemeSeed: Colors.deepPurple,
                  useMaterial3: true,
                ),
                home: school.hasSelectedSchool
                    ? const InventoryScreen()
                    : const SchoolSelectionScreen(),
                routes: {
                  '/school-selection': (_) => const SchoolSelectionScreen(),
                  '/inventory': (_) => const InventoryScreen(),
                  '/scan/barcode': (_) => const BarcodeScanScreen(),
                  '/scan/cover': (_) => const CoverOcrScreen(),
                  '/scan/shelf': (_) => const ShelfOcrScreen(),
                },
                onGenerateRoute: (settings) {
                  if (settings.name == '/book/confirm') {
                    final args =
                        settings.arguments as Map<String, dynamic>?;
                    return MaterialPageRoute(
                      builder: (_) => BookConfirmScreen(
                        book: args?['book'] as Book?,
                        isbn: args?['isbn'] as String?,
                        sourceType:
                            args?['source'] as String? ?? 'MANUAL',
                      ),
                    );
                  }
                  return null;
                },
              );
            },
          ),
        );
      },
    );
  }
}
