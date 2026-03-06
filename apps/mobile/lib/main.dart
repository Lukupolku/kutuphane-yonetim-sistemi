import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/book.dart';
import 'models/holding.dart';
import 'models/school.dart';
import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/school_provider.dart';
import 'repositories/mock_book_repository.dart';
import 'repositories/mock_holding_repository.dart';
import 'repositories/mock_school_repository.dart';
import 'screens/barcode_scan_screen.dart';
import 'screens/book_confirm_screen.dart';
import 'screens/cover_ocr_screen.dart';
import 'screens/excel_import_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/login_screen.dart';
import 'screens/shelf_ocr_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/isbn_lookup_service.dart';
import 'services/mock_data_service.dart';
import 'theme.dart';
import 'widgets/error_view.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Override default red error screen with user-friendly widget
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: ErrorView(
        title: 'Bir Hata Oluştu',
        message: details.exceptionAsString(),
        icon: Icons.warning_amber_rounded,
      ),
    );
  };

  runApp(const KutuphaneApp());
}

class KutuphaneApp extends StatefulWidget {
  const KutuphaneApp({super.key});

  @override
  State<KutuphaneApp> createState() => _KutuphaneAppState();
}

class _KutuphaneAppState extends State<KutuphaneApp> {
  final _authProvider = AuthProvider();

  // Created once after data loads — stable across rebuilds
  bool _ready = false;
  bool _showWelcome = false;
  bool _skipWelcomePref = false;
  late final List<School> _schools;
  late final SchoolProvider _schoolProvider;
  late final InventoryProvider _inventoryProvider;
  late final IsbnLookupService _isbnLookupService;

  Future<void> _loadAll() async {
    final results = await Future.wait([
      _loadMockData(),
      _authProvider.restoreSession(),
      SharedPreferences.getInstance(),
    ]);
    final data = results[0] as _MockData;
    final prefs = results[2] as SharedPreferences;
    _skipWelcomePref = prefs.getBool('skip_welcome') ?? false;
    _schools = data.schools;

    final bookRepo = MockBookRepository(data.books);
    final schoolRepo = MockSchoolRepository(data.schools);
    final holdingRepo = MockHoldingRepository(data.holdings);

    _schoolProvider = SchoolProvider(schoolRepository: schoolRepo);
    _schoolProvider.loadProvinces();

    _inventoryProvider = InventoryProvider(
      bookRepository: bookRepo,
      holdingRepository: holdingRepo,
    );

    _isbnLookupService = IsbnLookupService(bookRepository: bookRepo);

    // If already logged in, set school + load inventory
    _syncSchoolFromAuth();

    setState(() => _ready = true);
    FlutterNativeSplash.remove();

    // Listen for auth changes to sync school
    _authProvider.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    _syncSchoolFromAuth();
    // Show welcome on fresh login (not on session restore)
    if (_authProvider.isLoggedIn && !_skipWelcomePref) {
      setState(() => _showWelcome = true);
    }
    if (!_authProvider.isLoggedIn) {
      setState(() => _showWelcome = false);
    }
  }

  void _syncSchoolFromAuth() {
    if (_authProvider.isLoggedIn) {
      final userSchoolId = _authProvider.user!.schoolId;
      final school = _schools.cast<School?>().firstWhere(
            (s) => s!.id == userSchoolId,
            orElse: () => null,
          );
      if (school != null) {
        _schoolProvider.selectSchoolDirectly(school);
        _inventoryProvider.loadInventory(school.id);
      }
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MEB Okul Kütüphaneleri Yönetim Sistemi',
        theme: buildMebTheme(),
        home: SplashScreen(
          loadData: _loadAll,
          onReady: () {},
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<SchoolProvider>.value(value: _schoolProvider),
        ChangeNotifierProvider<InventoryProvider>.value(
            value: _inventoryProvider),
        Provider<IsbnLookupService>.value(value: _isbnLookupService),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'MEB Okul Kütüphaneleri Yönetim Sistemi',
            theme: buildMebTheme(),
            home: !auth.isLoggedIn
                ? const LoginScreen()
                : _showWelcome
                    ? WelcomeScreen(
                        onContinue: () =>
                            setState(() => _showWelcome = false),
                      )
                    : const InventoryScreen(),
            routes: {
              '/inventory': (_) => const InventoryScreen(),
              '/scan/barcode': (_) => const BarcodeScanScreen(),
              '/scan/cover': (_) => const CoverOcrScreen(),
              '/scan/shelf': (_) => const ShelfOcrScreen(),
              '/import/excel': (_) => const ExcelImportScreen(),
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
                    parsedTitle: args?['parsedTitle'] as String?,
                    parsedAuthor: args?['parsedAuthor'] as String?,
                  ),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class _MockData {
  final List<Book> books;
  final List<School> schools;
  final List<Holding> holdings;
  _MockData({required this.books, required this.schools, required this.holdings});
}

Future<_MockData> _loadMockData() async {
  try {
    final books = await MockDataService.loadBooks();
    final schools = await MockDataService.loadSchools();
    final holdings = await MockDataService.loadHoldings();
    return _MockData(books: books, schools: schools, holdings: holdings);
  } catch (_) {
    return _MockData(books: [], schools: [], holdings: []);
  }
}
