import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'theme.dart';
import 'providers/library_provider.dart';
import 'providers/book_provider.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/search_screen.dart';
import 'screens/barcode_scan_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/note_capture_screen.dart';
import 'widgets/error_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Use web-compatible sqflite factory when running on web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: ErrorView(
        title: 'Bir Hata Olustu',
        message: details.exceptionAsString(),
        icon: Icons.warning_amber_rounded,
      ),
    );
  };

  runApp(const RaftaApp());
}

class RaftaApp extends StatelessWidget {
  const RaftaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
      ],
      child: MaterialApp(
        title: 'Rafta',
        theme: buildMebTheme(),
        debugShowCheckedModeBanner: false,
        home: const _AppLoader(),
        routes: {
          '/scan': (_) => const BarcodeScanScreen(),
          '/search': (_) => const SearchScreen(),
          '/book-detail': (_) => const BookDetailScreen(),
          '/note-capture': (_) => const NoteCaptureScreen(),
        },
      ),
    );
  }
}

/// Loads database data before showing the main shell.
class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final libProv = context.read<LibraryProvider>();
    final bookProv = context.read<BookProvider>();

    await Future.wait([
      libProv.loadAll(),
      bookProv.loadAll(),
    ]);

    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded, size: 64, color: MebColors.primary),
              const SizedBox(height: 16),
              Text('Rafta',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: MebColors.primary,
                  )),
              const SizedBox(height: 4),
              Text('Kisisel Kutuphane Yoneticin',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: MebColors.textTertiary,
                  )),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return const _MainShell();
  }
}

/// Bottom navigation shell with Home and Library tabs.
class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          const NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Kitapligim',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'mainFab',
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kitap Ekle',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: MebColors.primaryLight,
                  child: const Icon(Icons.qr_code_scanner_rounded, color: MebColors.primary),
                ),
                title: const Text('Barkod Tara'),
                subtitle: const Text('Kitabin barkodunu tarayin'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/scan');
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: MebColors.primaryLight,
                  child: const Icon(Icons.search_rounded, color: MebColors.primary),
                ),
                title: const Text('Kitap Ara'),
                subtitle: const Text('Isim, yazar veya ISBN ile arayin'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/search');
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: MebColors.primaryLight,
                  child: const Icon(Icons.edit_note_rounded, color: MebColors.primary),
                ),
                title: const Text('Manuel Ekle'),
                subtitle: const Text('Bilgileri kendiniz girin'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/add-manual');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
