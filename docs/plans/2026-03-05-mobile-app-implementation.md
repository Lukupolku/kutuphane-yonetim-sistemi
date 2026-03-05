# Mobile App MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the Flutter mobile app with ISBN barcode scanning, cover OCR, shelf OCR, book registration, and inventory list — all backed by shared mock data.

**Architecture:** Single-flow navigation (inventory list → FAB → bottom sheet → scan/OCR → confirm → save). Provider for state management. Abstract repositories with mock implementations. Shared JSON mock data loaded as Flutter assets.

**Tech Stack:** Flutter 3.41, Dart 3.11, Provider, mobile_scanner, google_mlkit_text_recognition, image_picker, shared_preferences, uuid

---

### Task 1: Project Setup — Dependencies and Asset Configuration

**Files:**
- Modify: `apps/mobile/pubspec.yaml`
- Create: `apps/mobile/lib/services/mock_data_service.dart`
- Test: `apps/mobile/test/services/mock_data_service_test.dart`

**Step 1: Add shared_preferences dependency and configure assets in pubspec.yaml**

Add `shared_preferences: ^2.3.0` to dependencies. Add asset paths under `flutter:` section:

```yaml
dependencies:
  flutter:
    sdk: flutter
  mobile_scanner: ^6.0.0
  google_mlkit_text_recognition: ^0.14.0
  http: ^1.2.0
  uuid: ^4.5.0
  provider: ^6.1.0
  cached_network_image: ^3.4.0
  image_picker: ^1.1.0
  shared_preferences: ^2.3.0

# ... dev_dependencies stays same ...

flutter:
  uses-material-design: true
  assets:
    - packages/shared/mock-data/books.json
    - packages/shared/mock-data/schools.json
    - packages/shared/mock-data/holdings.json
```

Note: Flutter asset paths are relative to the project root. Since mock data lives in `packages/shared/`, we need to symlink or copy. Simpler approach: reference with a relative path from `apps/mobile/`. Create a symlink or just copy the JSON files to `apps/mobile/assets/mock-data/`.

**Revised approach — copy mock data as assets:**

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/mock-data/
```

Create directory `apps/mobile/assets/mock-data/` and copy the three JSON files there.

**Step 2: Run `flutter pub get`**

```bash
cd apps/mobile && flutter pub get
```

Expected: Dependencies resolved successfully.

**Step 3: Write the failing test for MockDataService**

```dart
// test/services/mock_data_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/services/mock_data_service.dart';
import 'package:kutuphane_mobile/models/book.dart';
import 'package:kutuphane_mobile/models/school.dart';
import 'package:kutuphane_mobile/models/holding.dart';

void main() {
  group('MockDataService', () {
    test('parseBooks parses JSON string to List<Book>', () {
      const json = '[{"id":"b1","isbn":"9789750718533","title":"Küçük Prens","authors":["Antoine de Saint-Exupéry"],"publisher":"Can Yayınları","publishedDate":"2020","pageCount":96,"coverImageUrl":null,"language":"tr","source":"GOOGLE_BOOKS","createdAt":"2026-01-15T10:00:00Z"}]';
      final books = MockDataService.parseBooks(json);
      expect(books.length, 1);
      expect(books[0].title, 'Küçük Prens');
      expect(books[0].isbn, '9789750718533');
    });

    test('parseSchools parses JSON string to List<School>', () {
      const json = '[{"id":"s1-ankara-cankaya-ataturk-ilk","name":"Atatürk İlkokulu","province":"Ankara","district":"Çankaya","schoolType":"ILKOKUL","ministryCode":"06001001"}]';
      final schools = MockDataService.parseSchools(json);
      expect(schools.length, 1);
      expect(schools[0].name, 'Atatürk İlkokulu');
    });

    test('parseHoldings parses JSON string to List<Holding>', () {
      const json = '[{"id":"h1","bookId":"b1","schoolId":"s1-ankara-cankaya-ataturk-ilk","quantity":5,"addedBy":"Ayşe Öğretmen","addedAt":"2026-02-01T10:00:00Z","source":"BARCODE_SCAN"}]';
      final holdings = MockDataService.parseHoldings(json);
      expect(holdings.length, 1);
      expect(holdings[0].quantity, 5);
    });
  });
}
```

**Step 4: Run test to verify it fails**

```bash
cd apps/mobile && flutter test test/services/mock_data_service_test.dart
```

Expected: FAIL — `mock_data_service.dart` not found.

**Step 5: Implement MockDataService**

```dart
// lib/services/mock_data_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/book.dart';
import '../models/school.dart';
import '../models/holding.dart';

class MockDataService {
  static List<Book> parseBooks(String jsonString) {
    final List<dynamic> list = json.decode(jsonString);
    return list.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  static List<School> parseSchools(String jsonString) {
    final List<dynamic> list = json.decode(jsonString);
    return list.map((e) => School.fromJson(e as Map<String, dynamic>)).toList();
  }

  static List<Holding> parseHoldings(String jsonString) {
    final List<dynamic> list = json.decode(jsonString);
    return list.map((e) => Holding.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Book>> loadBooks() async {
    final jsonString = await rootBundle.loadString('assets/mock-data/books.json');
    return parseBooks(jsonString);
  }

  static Future<List<School>> loadSchools() async {
    final jsonString = await rootBundle.loadString('assets/mock-data/schools.json');
    return parseSchools(jsonString);
  }

  static Future<List<Holding>> loadHoldings() async {
    final jsonString = await rootBundle.loadString('assets/mock-data/holdings.json');
    return parseHoldings(jsonString);
  }
}
```

**Step 6: Run tests**

```bash
cd apps/mobile && flutter test test/services/mock_data_service_test.dart
```

Expected: ALL PASS

**Step 7: Commit**

```bash
git add apps/mobile/pubspec.yaml apps/mobile/assets/ apps/mobile/lib/services/mock_data_service.dart apps/mobile/test/services/mock_data_service_test.dart
git commit -m "feat(mobile): add MockDataService and asset configuration"
```

---

### Task 2: Abstract Repositories and Mock Implementations

**Files:**
- Create: `apps/mobile/lib/repositories/book_repository.dart`
- Create: `apps/mobile/lib/repositories/mock_book_repository.dart`
- Create: `apps/mobile/lib/repositories/school_repository.dart`
- Create: `apps/mobile/lib/repositories/mock_school_repository.dart`
- Create: `apps/mobile/lib/repositories/holding_repository.dart`
- Create: `apps/mobile/lib/repositories/mock_holding_repository.dart`
- Test: `apps/mobile/test/repositories/mock_book_repository_test.dart`
- Test: `apps/mobile/test/repositories/mock_holding_repository_test.dart`

**Step 1: Write failing tests for MockBookRepository**

```dart
// test/repositories/mock_book_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/book.dart';
import 'package:kutuphane_mobile/repositories/book_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_book_repository.dart';

void main() {
  late MockBookRepository repo;

  setUp(() {
    repo = MockBookRepository([
      Book(id: 'b1', isbn: '9789750718533', title: 'Küçük Prens',
        authors: ['Antoine de Saint-Exupéry'], language: 'tr',
        source: BookSource.googleBooks, createdAt: DateTime.parse('2026-01-15T10:00:00Z')),
      Book(id: 'b2', isbn: '9789750726439', title: 'Sefiller',
        authors: ['Victor Hugo'], language: 'tr',
        source: BookSource.googleBooks, createdAt: DateTime.parse('2026-01-15T10:05:00Z')),
    ]);
  });

  group('MockBookRepository', () {
    test('getAll returns all books', () async {
      final books = await repo.getAll();
      expect(books.length, 2);
    });

    test('getById returns book when found', () async {
      final book = await repo.getById('b1');
      expect(book?.title, 'Küçük Prens');
    });

    test('getById returns null when not found', () async {
      final book = await repo.getById('b999');
      expect(book, isNull);
    });

    test('getByIsbn returns book when found', () async {
      final book = await repo.getByIsbn('9789750718533');
      expect(book?.title, 'Küçük Prens');
    });

    test('create adds new book', () async {
      final newBook = Book(id: 'b3', title: 'Yeni Kitap',
        authors: ['Yazar'], language: 'tr',
        source: BookSource.manual, createdAt: DateTime.now());
      await repo.create(newBook);
      final all = await repo.getAll();
      expect(all.length, 3);
    });

    test('searchByTitle finds matching books', () async {
      final results = await repo.searchByTitle('prens');
      expect(results.length, 1);
      expect(results[0].title, 'Küçük Prens');
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
cd apps/mobile && flutter test test/repositories/mock_book_repository_test.dart
```

**Step 3: Implement abstract BookRepository and MockBookRepository**

```dart
// lib/repositories/book_repository.dart
import '../models/book.dart';

abstract class BookRepository {
  Future<List<Book>> getAll();
  Future<Book?> getById(String id);
  Future<Book?> getByIsbn(String isbn);
  Future<void> create(Book book);
  Future<List<Book>> searchByTitle(String query);
}
```

```dart
// lib/repositories/mock_book_repository.dart
import '../models/book.dart';
import 'book_repository.dart';

class MockBookRepository implements BookRepository {
  final List<Book> _books;

  MockBookRepository(List<Book> initialBooks) : _books = List.from(initialBooks);

  @override
  Future<List<Book>> getAll() async => List.unmodifiable(_books);

  @override
  Future<Book?> getById(String id) async {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Book?> getByIsbn(String isbn) async {
    try {
      return _books.firstWhere((b) => b.isbn == isbn);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> create(Book book) async {
    _books.add(book);
  }

  @override
  Future<List<Book>> searchByTitle(String query) async {
    final lower = query.toLowerCase();
    return _books.where((b) => b.title.toLowerCase().contains(lower)).toList();
  }
}
```

**Step 4: Run tests**

```bash
cd apps/mobile && flutter test test/repositories/mock_book_repository_test.dart
```

Expected: ALL PASS

**Step 5: Write failing tests for MockHoldingRepository**

```dart
// test/repositories/mock_holding_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/holding.dart';
import 'package:kutuphane_mobile/repositories/holding_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_holding_repository.dart';

void main() {
  late MockHoldingRepository repo;

  setUp(() {
    repo = MockHoldingRepository([
      Holding(id: 'h1', bookId: 'b1', schoolId: 's1', quantity: 5,
        addedBy: 'Ayşe', addedAt: DateTime.parse('2026-02-01T10:00:00Z'),
        source: HoldingSource.barcodeScan),
      Holding(id: 'h2', bookId: 'b2', schoolId: 's1', quantity: 3,
        addedBy: 'Mehmet', addedAt: DateTime.parse('2026-02-02T11:00:00Z'),
        source: HoldingSource.barcodeScan),
    ]);
  });

  group('MockHoldingRepository', () {
    test('getBySchoolId returns holdings for school', () async {
      final holdings = await repo.getBySchoolId('s1');
      expect(holdings.length, 2);
    });

    test('getBySchoolId returns empty for unknown school', () async {
      final holdings = await repo.getBySchoolId('s999');
      expect(holdings, isEmpty);
    });

    test('create adds new holding', () async {
      final h = Holding(id: 'h3', bookId: 'b3', schoolId: 's1', quantity: 1,
        addedBy: 'Test', addedAt: DateTime.now(), source: HoldingSource.manual);
      await repo.create(h);
      final holdings = await repo.getBySchoolId('s1');
      expect(holdings.length, 3);
    });

    test('addOrIncrement increments quantity for existing book+school', () async {
      await repo.addOrIncrement(bookId: 'b1', schoolId: 's1', addedBy: 'Test', source: HoldingSource.barcodeScan);
      final holdings = await repo.getBySchoolId('s1');
      final h = holdings.firstWhere((h) => h.bookId == 'b1');
      expect(h.quantity, 6);
    });

    test('addOrIncrement creates new holding for new book+school', () async {
      await repo.addOrIncrement(bookId: 'b5', schoolId: 's1', addedBy: 'Test', source: HoldingSource.coverOcr);
      final holdings = await repo.getBySchoolId('s1');
      expect(holdings.length, 3);
    });
  });
}
```

**Step 6: Implement SchoolRepository, HoldingRepository, and their mocks**

```dart
// lib/repositories/school_repository.dart
import '../models/school.dart';

abstract class SchoolRepository {
  Future<List<School>> getAll();
  Future<School?> getById(String id);
  Future<List<String>> getProvinces();
  Future<List<String>> getDistricts(String province);
  Future<List<School>> getByDistrict(String province, String district);
}
```

```dart
// lib/repositories/mock_school_repository.dart
import '../models/school.dart';
import 'school_repository.dart';

class MockSchoolRepository implements SchoolRepository {
  final List<School> _schools;

  MockSchoolRepository(List<School> initialSchools) : _schools = List.from(initialSchools);

  @override
  Future<List<School>> getAll() async => List.unmodifiable(_schools);

  @override
  Future<School?> getById(String id) async {
    try {
      return _schools.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> getProvinces() async {
    return _schools.map((s) => s.province).toSet().toList()..sort();
  }

  @override
  Future<List<String>> getDistricts(String province) async {
    return _schools
        .where((s) => s.province == province)
        .map((s) => s.district)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  Future<List<School>> getByDistrict(String province, String district) async {
    return _schools
        .where((s) => s.province == province && s.district == district)
        .toList();
  }
}
```

```dart
// lib/repositories/holding_repository.dart
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
}
```

```dart
// lib/repositories/mock_holding_repository.dart
import 'package:uuid/uuid.dart';
import '../models/holding.dart';
import 'holding_repository.dart';

class MockHoldingRepository implements HoldingRepository {
  final List<Holding> _holdings;
  final _uuid = const Uuid();

  MockHoldingRepository(List<Holding> initialHoldings) : _holdings = List.from(initialHoldings);

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
    final index = _holdings.indexWhere(
      (h) => h.bookId == bookId && h.schoolId == schoolId,
    );
    if (index >= 0) {
      final existing = _holdings[index];
      _holdings[index] = Holding(
        id: existing.id,
        bookId: existing.bookId,
        schoolId: existing.schoolId,
        quantity: existing.quantity + 1,
        addedBy: addedBy,
        addedAt: DateTime.now(),
        source: source,
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
}
```

**Step 7: Run all repository tests**

```bash
cd apps/mobile && flutter test test/repositories/
```

Expected: ALL PASS

**Step 8: Commit**

```bash
git add apps/mobile/lib/repositories/ apps/mobile/test/repositories/
git commit -m "feat(mobile): add abstract repositories with mock implementations"
```

---

### Task 3: IsbnLookupService

**Files:**
- Create: `apps/mobile/lib/services/isbn_lookup_service.dart`
- Test: `apps/mobile/test/services/isbn_lookup_service_test.dart`

**Step 1: Write failing test**

```dart
// test/services/isbn_lookup_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/book.dart';
import 'package:kutuphane_mobile/repositories/mock_book_repository.dart';
import 'package:kutuphane_mobile/services/isbn_lookup_service.dart';

void main() {
  late IsbnLookupService service;
  late MockBookRepository bookRepo;

  setUp(() {
    bookRepo = MockBookRepository([
      Book(id: 'b1', isbn: '9789750718533', title: 'Küçük Prens',
        authors: ['Antoine de Saint-Exupéry'], language: 'tr',
        source: BookSource.googleBooks, createdAt: DateTime.parse('2026-01-15T10:00:00Z')),
    ]);
    service = IsbnLookupService(bookRepository: bookRepo);
  });

  group('IsbnLookupService', () {
    test('lookupByIsbn returns book from repository if exists', () async {
      final result = await service.lookupByIsbn('9789750718533');
      expect(result?.title, 'Küçük Prens');
    });

    test('lookupByIsbn returns null for unknown ISBN (mock mode)', () async {
      final result = await service.lookupByIsbn('0000000000000');
      expect(result, isNull);
    });

    test('searchByTitle returns matches from repository', () async {
      final results = await service.searchByTitle('prens');
      expect(results.length, 1);
    });

    test('searchByTitle returns empty for no matches', () async {
      final results = await service.searchByTitle('xyz');
      expect(results, isEmpty);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
cd apps/mobile && flutter test test/services/isbn_lookup_service_test.dart
```

**Step 3: Implement IsbnLookupService**

```dart
// lib/services/isbn_lookup_service.dart
import '../models/book.dart';
import '../repositories/book_repository.dart';

/// ISBN lookup with fallback chain.
/// MVP: only checks local repository.
/// Faz 1: Google Books API → Open Library API → null
class IsbnLookupService {
  final BookRepository bookRepository;

  IsbnLookupService({required this.bookRepository});

  /// Look up a book by ISBN.
  /// Returns existing Book from repo, or null if not found.
  Future<Book?> lookupByIsbn(String isbn) async {
    // Step 1: Check local repository
    final local = await bookRepository.getByIsbn(isbn);
    if (local != null) return local;

    // Step 2: Google Books API (Faz 1'de implemente edilecek)
    // Step 3: Open Library API (Faz 1'de implemente edilecek)

    return null;
  }

  /// Search books by title.
  Future<List<Book>> searchByTitle(String query) async {
    return bookRepository.searchByTitle(query);
  }
}
```

**Step 4: Run tests**

```bash
cd apps/mobile && flutter test test/services/isbn_lookup_service_test.dart
```

Expected: ALL PASS

**Step 5: Commit**

```bash
git add apps/mobile/lib/services/isbn_lookup_service.dart apps/mobile/test/services/isbn_lookup_service_test.dart
git commit -m "feat(mobile): add IsbnLookupService with repository fallback"
```

---

### Task 4: OcrService

**Files:**
- Create: `apps/mobile/lib/services/ocr_service.dart`
- Test: `apps/mobile/test/services/ocr_service_test.dart`

**Step 1: Write failing test**

```dart
// test/services/ocr_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/services/ocr_service.dart';

void main() {
  group('OcrService text parsing', () {
    test('parseBookTitle extracts clean title from OCR text', () {
      final result = OcrService.parseBookTitle('KÜÇÜK PRENS\nAntoine de Saint-Exupéry\nCan Yayınları');
      expect(result.title, 'Küçük Prens');
      expect(result.author, 'Antoine de Saint-Exupéry');
    });

    test('parseBookTitle handles single line', () {
      final result = OcrService.parseBookTitle('Suç ve Ceza');
      expect(result.title, 'Suç Ve Ceza');
      expect(result.author, isNull);
    });

    test('parseShelfTexts splits multi-line text into book candidates', () {
      final text = 'Küçük Prens\nSefiller\nSuç ve Ceza';
      final results = OcrService.parseShelfTexts(text);
      expect(results.length, 3);
      expect(results[0], 'Küçük Prens');
    });

    test('parseShelfTexts filters out short/empty lines', () {
      final text = 'Küçük Prens\n\na\nSefiller';
      final results = OcrService.parseShelfTexts(text);
      expect(results.length, 2);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
cd apps/mobile && flutter test test/services/ocr_service_test.dart
```

**Step 3: Implement OcrService**

```dart
// lib/services/ocr_service.dart
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ParsedBookText {
  final String title;
  final String? author;

  ParsedBookText({required this.title, this.author});
}

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from an image file using ML Kit.
  Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  /// Parse a single book's title and author from OCR text.
  /// Assumes first line is title, second line is author.
  static ParsedBookText parseBookTitle(String ocrText) {
    final lines = ocrText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return ParsedBookText(title: '');

    final title = _titleCase(lines[0].trim());
    final author = lines.length > 1 ? lines[1].trim() : null;
    return ParsedBookText(title: title, author: author);
  }

  /// Parse shelf photo text into individual book title candidates.
  /// Each non-empty line with 3+ characters is a candidate.
  static List<String> parseShelfTexts(String ocrText) {
    return ocrText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length >= 3)
        .toList();
  }

  static String _titleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void dispose() {
    _textRecognizer.close();
  }
}
```

**Step 4: Run tests**

```bash
cd apps/mobile && flutter test test/services/ocr_service_test.dart
```

Expected: ALL PASS

**Step 5: Commit**

```bash
git add apps/mobile/lib/services/ocr_service.dart apps/mobile/test/services/ocr_service_test.dart
git commit -m "feat(mobile): add OcrService with ML Kit text recognition"
```

---

### Task 5: SchoolProvider and SchoolSelectionScreen

**Files:**
- Create: `apps/mobile/lib/providers/school_provider.dart`
- Create: `apps/mobile/lib/screens/school_selection_screen.dart`
- Test: `apps/mobile/test/providers/school_provider_test.dart`
- Test: `apps/mobile/test/screens/school_selection_screen_test.dart`

**Step 1: Write failing test for SchoolProvider**

```dart
// test/providers/school_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/school.dart';
import 'package:kutuphane_mobile/providers/school_provider.dart';
import 'package:kutuphane_mobile/repositories/mock_school_repository.dart';

void main() {
  late SchoolProvider provider;
  late MockSchoolRepository repo;

  setUp(() {
    repo = MockSchoolRepository([
      School(id: 's1', name: 'Atatürk İlkokulu', province: 'Ankara',
        district: 'Çankaya', schoolType: SchoolType.ilkokul, ministryCode: '06001001'),
      School(id: 's2', name: 'İnönü Ortaokulu', province: 'Ankara',
        district: 'Keçiören', schoolType: SchoolType.ortaokul, ministryCode: '06002001'),
      School(id: 's3', name: 'Moda Lisesi', province: 'İstanbul',
        district: 'Kadıköy', schoolType: SchoolType.lise, ministryCode: '34001001'),
    ]);
    provider = SchoolProvider(schoolRepository: repo);
  });

  group('SchoolProvider', () {
    test('loadProvinces returns sorted provinces', () async {
      await provider.loadProvinces();
      expect(provider.provinces, ['Ankara', 'İstanbul']);
    });

    test('selectProvince loads districts', () async {
      await provider.loadProvinces();
      await provider.selectProvince('Ankara');
      expect(provider.districts, ['Keçiören', 'Çankaya']);
      expect(provider.selectedProvince, 'Ankara');
    });

    test('selectDistrict loads schools', () async {
      await provider.loadProvinces();
      await provider.selectProvince('Ankara');
      await provider.selectDistrict('Çankaya');
      expect(provider.schools.length, 1);
      expect(provider.schools[0].name, 'Atatürk İlkokulu');
    });

    test('selectSchool sets selected school', () async {
      await provider.loadProvinces();
      await provider.selectProvince('Ankara');
      await provider.selectDistrict('Çankaya');
      provider.selectSchool(provider.schools[0]);
      expect(provider.selectedSchool?.id, 's1');
    });

    test('hasSelectedSchool returns false initially', () {
      expect(provider.hasSelectedSchool, false);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
cd apps/mobile && flutter test test/providers/school_provider_test.dart
```

**Step 3: Implement SchoolProvider**

```dart
// lib/providers/school_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/school.dart';
import '../repositories/school_repository.dart';

class SchoolProvider extends ChangeNotifier {
  final SchoolRepository schoolRepository;

  List<String> _provinces = [];
  List<String> _districts = [];
  List<School> _schools = [];
  String? _selectedProvince;
  String? _selectedDistrict;
  School? _selectedSchool;

  SchoolProvider({required this.schoolRepository});

  List<String> get provinces => _provinces;
  List<String> get districts => _districts;
  List<School> get schools => _schools;
  String? get selectedProvince => _selectedProvince;
  String? get selectedDistrict => _selectedDistrict;
  School? get selectedSchool => _selectedSchool;
  bool get hasSelectedSchool => _selectedSchool != null;

  Future<void> loadProvinces() async {
    _provinces = await schoolRepository.getProvinces();
    notifyListeners();
  }

  Future<void> selectProvince(String province) async {
    _selectedProvince = province;
    _selectedDistrict = null;
    _schools = [];
    _selectedSchool = null;
    _districts = await schoolRepository.getDistricts(province);
    notifyListeners();
  }

  Future<void> selectDistrict(String district) async {
    _selectedDistrict = district;
    _selectedSchool = null;
    _schools = await schoolRepository.getByDistrict(_selectedProvince!, district);
    notifyListeners();
  }

  void selectSchool(School school) {
    _selectedSchool = school;
    notifyListeners();
  }

  Future<void> loadSavedSchool() async {
    final prefs = await SharedPreferences.getInstance();
    final schoolId = prefs.getString('selectedSchoolId');
    if (schoolId != null) {
      _selectedSchool = await schoolRepository.getById(schoolId);
      notifyListeners();
    }
  }

  Future<void> saveSelectedSchool() async {
    if (_selectedSchool == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedSchoolId', _selectedSchool!.id);
  }
}
```

**Step 4: Run tests**

```bash
cd apps/mobile && flutter test test/providers/school_provider_test.dart
```

Expected: ALL PASS

**Step 5: Write SchoolSelectionScreen widget test**

```dart
// test/screens/school_selection_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kutuphane_mobile/models/school.dart';
import 'package:kutuphane_mobile/providers/school_provider.dart';
import 'package:kutuphane_mobile/repositories/mock_school_repository.dart';
import 'package:kutuphane_mobile/screens/school_selection_screen.dart';

void main() {
  late MockSchoolRepository repo;

  setUp(() {
    repo = MockSchoolRepository([
      School(id: 's1', name: 'Atatürk İlkokulu', province: 'Ankara',
        district: 'Çankaya', schoolType: SchoolType.ilkokul, ministryCode: '06001001'),
      School(id: 's2', name: 'İnönü Ortaokulu', province: 'Ankara',
        district: 'Keçiören', schoolType: SchoolType.ortaokul, ministryCode: '06002001'),
    ]);
  });

  testWidgets('shows province dropdown on load', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => SchoolProvider(schoolRepository: repo)..loadProvinces(),
          child: const SchoolSelectionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('İl Seçin'), findsOneWidget);
  });
}
```

**Step 6: Implement SchoolSelectionScreen**

```dart
// lib/screens/school_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/school_provider.dart';

class SchoolSelectionScreen extends StatelessWidget {
  const SchoolSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Okul Seçimi')),
      body: Consumer<SchoolProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school, size: 64, color: Colors.deepPurple),
                const SizedBox(height: 16),
                const Text(
                  'Okulunuzu Seçin',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Province dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'İl Seçin',
                    border: OutlineInputBorder(),
                  ),
                  value: provider.selectedProvince,
                  items: provider.provinces
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) provider.selectProvince(value);
                  },
                ),
                const SizedBox(height: 16),

                // District dropdown
                if (provider.districts.isNotEmpty)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'İlçe Seçin',
                      border: OutlineInputBorder(),
                    ),
                    value: provider.selectedDistrict,
                    items: provider.districts
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) provider.selectDistrict(value);
                    },
                  ),
                const SizedBox(height: 16),

                // School dropdown
                if (provider.schools.isNotEmpty)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Okul Seçin',
                      border: OutlineInputBorder(),
                    ),
                    value: provider.selectedSchool?.id,
                    items: provider.schools
                        .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final school = provider.schools.firstWhere((s) => s.id == value);
                        provider.selectSchool(school);
                      }
                    },
                  ),

                const Spacer(),

                // Continue button
                ElevatedButton(
                  onPressed: provider.hasSelectedSchool
                      ? () async {
                          await provider.saveSelectedSchool();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/inventory');
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Devam Et', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

**Step 7: Run all tests**

```bash
cd apps/mobile && flutter test test/providers/ test/screens/
```

Expected: ALL PASS

**Step 8: Commit**

```bash
git add apps/mobile/lib/providers/ apps/mobile/lib/screens/school_selection_screen.dart apps/mobile/test/providers/ apps/mobile/test/screens/
git commit -m "feat(mobile): add SchoolProvider and SchoolSelectionScreen"
```

---

### Task 6: InventoryProvider and InventoryScreen

**Files:**
- Create: `apps/mobile/lib/providers/inventory_provider.dart`
- Create: `apps/mobile/lib/screens/inventory_screen.dart`
- Test: `apps/mobile/test/providers/inventory_provider_test.dart`
- Test: `apps/mobile/test/screens/inventory_screen_test.dart`

**Step 1: Write failing test for InventoryProvider**

```dart
// test/providers/inventory_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/book.dart';
import 'package:kutuphane_mobile/models/holding.dart';
import 'package:kutuphane_mobile/providers/inventory_provider.dart';
import 'package:kutuphane_mobile/repositories/mock_book_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_holding_repository.dart';

void main() {
  late InventoryProvider provider;

  setUp(() {
    final bookRepo = MockBookRepository([
      Book(id: 'b1', isbn: '9789750718533', title: 'Küçük Prens',
        authors: ['Antoine de Saint-Exupéry'], language: 'tr',
        source: BookSource.googleBooks, createdAt: DateTime.parse('2026-01-15T10:00:00Z')),
    ]);
    final holdingRepo = MockHoldingRepository([
      Holding(id: 'h1', bookId: 'b1', schoolId: 's1', quantity: 5,
        addedBy: 'Ayşe', addedAt: DateTime.parse('2026-02-01T10:00:00Z'),
        source: HoldingSource.barcodeScan),
    ]);
    provider = InventoryProvider(
      bookRepository: bookRepo,
      holdingRepository: holdingRepo,
    );
  });

  group('InventoryProvider', () {
    test('loadInventory loads holdings with books for a school', () async {
      await provider.loadInventory('s1');
      expect(provider.items.length, 1);
      expect(provider.items[0].book.title, 'Küçük Prens');
      expect(provider.items[0].holding.quantity, 5);
    });

    test('loadInventory returns empty for unknown school', () async {
      await provider.loadInventory('s999');
      expect(provider.items, isEmpty);
    });

    test('addBook creates book and holding', () async {
      await provider.loadInventory('s1');
      final newBook = Book(id: 'b2', title: 'Yeni Kitap',
        authors: ['Yazar'], language: 'tr',
        source: BookSource.manual, createdAt: DateTime.now());
      await provider.addBook(book: newBook, schoolId: 's1',
        addedBy: 'Test', source: HoldingSource.manual);
      expect(provider.items.length, 2);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
cd apps/mobile && flutter test test/providers/inventory_provider_test.dart
```

**Step 3: Implement InventoryProvider**

```dart
// lib/providers/inventory_provider.dart
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/holding.dart';
import '../repositories/book_repository.dart';
import '../repositories/holding_repository.dart';

class InventoryItem {
  final Book book;
  final Holding holding;

  InventoryItem({required this.book, required this.holding});
}

class InventoryProvider extends ChangeNotifier {
  final BookRepository bookRepository;
  final HoldingRepository holdingRepository;

  List<InventoryItem> _items = [];
  bool _loading = false;
  String? _currentSchoolId;

  InventoryProvider({
    required this.bookRepository,
    required this.holdingRepository,
  });

  List<InventoryItem> get items => _items;
  bool get loading => _loading;

  Future<void> loadInventory(String schoolId) async {
    _loading = true;
    _currentSchoolId = schoolId;
    notifyListeners();

    final holdings = await holdingRepository.getBySchoolId(schoolId);
    final List<InventoryItem> loaded = [];
    for (final h in holdings) {
      final book = await bookRepository.getById(h.bookId);
      if (book != null) {
        loaded.add(InventoryItem(book: book, holding: h));
      }
    }
    _items = loaded;
    _loading = false;
    notifyListeners();
  }

  Future<void> addBook({
    required Book book,
    required String schoolId,
    required String addedBy,
    required HoldingSource source,
  }) async {
    // Create book if not exists
    final existing = await bookRepository.getById(book.id);
    if (existing == null) {
      await bookRepository.create(book);
    }

    // Add or increment holding
    await holdingRepository.addOrIncrement(
      bookId: book.id,
      schoolId: schoolId,
      addedBy: addedBy,
      source: source,
    );

    // Reload inventory
    await loadInventory(schoolId);
  }
}
```

**Step 4: Run provider tests**

```bash
cd apps/mobile && flutter test test/providers/inventory_provider_test.dart
```

Expected: ALL PASS

**Step 5: Write InventoryScreen widget test**

```dart
// test/screens/inventory_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kutuphane_mobile/models/book.dart';
import 'package:kutuphane_mobile/models/holding.dart';
import 'package:kutuphane_mobile/models/school.dart';
import 'package:kutuphane_mobile/providers/inventory_provider.dart';
import 'package:kutuphane_mobile/providers/school_provider.dart';
import 'package:kutuphane_mobile/repositories/mock_book_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_holding_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_school_repository.dart';
import 'package:kutuphane_mobile/screens/inventory_screen.dart';

void main() {
  testWidgets('shows FAB for adding books', (tester) async {
    final bookRepo = MockBookRepository([]);
    final holdingRepo = MockHoldingRepository([]);
    final schoolRepo = MockSchoolRepository([
      School(id: 's1', name: 'Test Okulu', province: 'Ankara',
        district: 'Çankaya', schoolType: SchoolType.ilkokul, ministryCode: '06001001'),
    ]);
    final schoolProvider = SchoolProvider(schoolRepository: schoolRepo);
    schoolProvider.selectSchool(
      School(id: 's1', name: 'Test Okulu', province: 'Ankara',
        district: 'Çankaya', schoolType: SchoolType.ilkokul, ministryCode: '06001001'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: schoolProvider),
            ChangeNotifierProvider(
              create: (_) => InventoryProvider(
                bookRepository: bookRepo, holdingRepository: holdingRepo,
              ),
            ),
          ],
          child: const InventoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
```

**Step 6: Implement InventoryScreen**

```dart
// lib/screens/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/school_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final school = context.read<SchoolProvider>().selectedSchool;
      if (school != null) {
        context.read<InventoryProvider>().loadInventory(school.id);
      }
    });
  }

  void _showAddBookSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Kitap Ekle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Barkod Tara'),
              subtitle: const Text('ISBN barkodunu okut'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/scan/barcode');
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kapak Fotoğrafla'),
              subtitle: const Text('Kitap kapağını çek'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/scan/cover');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shelves),
              title: const Text('Raf Fotoğrafla'),
              subtitle: const Text('Kitap rafını çek'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/scan/shelf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Manuel Giriş'),
              subtitle: const Text('Bilgileri elle gir'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/book/confirm');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final school = context.watch<SchoolProvider>().selectedSchool;
    final inventory = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(school?.name ?? 'Envanter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/school-selection'),
          ),
        ],
      ),
      body: inventory.loading
          ? const Center(child: CircularProgressIndicator())
          : inventory.items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.library_books, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Henüz kitap eklenmemiş',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Kitap eklemek için + butonuna dokunun',
                        style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: inventory.items.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final item = inventory.items[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.book),
                        title: Text(item.book.title),
                        subtitle: Text(item.book.authors.join(', ')),
                        trailing: Chip(
                          label: Text('${item.holding.quantity} adet'),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBookSheet,
        icon: const Icon(Icons.add),
        label: const Text('Kitap Ekle'),
      ),
    );
  }
}
```

**Step 7: Run all tests**

```bash
cd apps/mobile && flutter test
```

Expected: ALL PASS

**Step 8: Commit**

```bash
git add apps/mobile/lib/providers/inventory_provider.dart apps/mobile/lib/screens/inventory_screen.dart apps/mobile/test/providers/inventory_provider_test.dart apps/mobile/test/screens/inventory_screen_test.dart
git commit -m "feat(mobile): add InventoryProvider and InventoryScreen with FAB"
```

---

### Task 7: BarcodeScanScreen

**Files:**
- Create: `apps/mobile/lib/screens/barcode_scan_screen.dart`

**Step 1: Implement BarcodeScanScreen**

Note: mobile_scanner requires a real device/emulator camera. Widget tests cannot test actual scanning. We test the navigation flow instead.

```dart
// lib/screens/barcode_scan_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/isbn_lookup_service.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final isbn = barcode!.rawValue!;
    // Only accept 13-digit ISBNs
    if (!RegExp(r'^\d{13}$').hasMatch(isbn)) return;

    setState(() => _processing = true);

    final lookupService = context.read<IsbnLookupService>();
    final book = await lookupService.lookupByIsbn(isbn);

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/book/confirm',
        arguments: {'book': book, 'isbn': isbn, 'source': 'BARCODE_SCAN'},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barkod Tara')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),
          if (_processing)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('ISBN aranıyor...'),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Kitabın ISBN barkodunu kameraya gösterin',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add apps/mobile/lib/screens/barcode_scan_screen.dart
git commit -m "feat(mobile): add BarcodeScanScreen with mobile_scanner"
```

---

### Task 8: BookConfirmScreen

**Files:**
- Create: `apps/mobile/lib/screens/book_confirm_screen.dart`
- Test: `apps/mobile/test/screens/book_confirm_screen_test.dart`

**Step 1: Write failing widget test**

```dart
// test/screens/book_confirm_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kutuphane_mobile/models/book.dart';
import 'package:kutuphane_mobile/models/school.dart';
import 'package:kutuphane_mobile/providers/inventory_provider.dart';
import 'package:kutuphane_mobile/providers/school_provider.dart';
import 'package:kutuphane_mobile/repositories/mock_book_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_holding_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_school_repository.dart';
import 'package:kutuphane_mobile/screens/book_confirm_screen.dart';

void main() {
  testWidgets('shows book info when book is provided', (tester) async {
    final book = Book(id: 'b1', isbn: '9789750718533', title: 'Küçük Prens',
      authors: ['Antoine de Saint-Exupéry'], publisher: 'Can Yayınları',
      language: 'tr', source: BookSource.googleBooks,
      createdAt: DateTime.parse('2026-01-15T10:00:00Z'));
    final schoolProvider = SchoolProvider(
      schoolRepository: MockSchoolRepository([
        School(id: 's1', name: 'Test', province: 'Ankara', district: 'Çankaya',
          schoolType: SchoolType.ilkokul, ministryCode: '06001001'),
      ]),
    )..selectSchool(
        School(id: 's1', name: 'Test', province: 'Ankara', district: 'Çankaya',
          schoolType: SchoolType.ilkokul, ministryCode: '06001001'));

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: schoolProvider),
            ChangeNotifierProvider(
              create: (_) => InventoryProvider(
                bookRepository: MockBookRepository([]),
                holdingRepository: MockHoldingRepository([]),
              ),
            ),
          ],
          child: BookConfirmScreen(
            book: book,
            isbn: '9789750718533',
            sourceType: 'BARCODE_SCAN',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Küçük Prens'), findsOneWidget);
    expect(find.text('Kaydet'), findsOneWidget);
  });

  testWidgets('shows empty form when no book provided', (tester) async {
    final schoolProvider = SchoolProvider(
      schoolRepository: MockSchoolRepository([
        School(id: 's1', name: 'Test', province: 'Ankara', district: 'Çankaya',
          schoolType: SchoolType.ilkokul, ministryCode: '06001001'),
      ]),
    )..selectSchool(
        School(id: 's1', name: 'Test', province: 'Ankara', district: 'Çankaya',
          schoolType: SchoolType.ilkokul, ministryCode: '06001001'));

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: schoolProvider),
            ChangeNotifierProvider(
              create: (_) => InventoryProvider(
                bookRepository: MockBookRepository([]),
                holdingRepository: MockHoldingRepository([]),
              ),
            ),
          ],
          child: const BookConfirmScreen(
            isbn: null,
            sourceType: 'MANUAL',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Başlık'), findsOneWidget);
    expect(find.text('Yazar'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

```bash
cd apps/mobile && flutter test test/screens/book_confirm_screen_test.dart
```

**Step 3: Implement BookConfirmScreen**

```dart
// lib/screens/book_confirm_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../models/holding.dart';
import '../providers/inventory_provider.dart';
import '../providers/school_provider.dart';

class BookConfirmScreen extends StatefulWidget {
  final Book? book;
  final String? isbn;
  final String sourceType;

  const BookConfirmScreen({
    super.key,
    this.book,
    this.isbn,
    required this.sourceType,
  });

  @override
  State<BookConfirmScreen> createState() => _BookConfirmScreenState();
}

class _BookConfirmScreenState extends State<BookConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _publisherController;
  late TextEditingController _isbnController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book?.title ?? '');
    _authorController = TextEditingController(
      text: widget.book?.authors.join(', ') ?? '',
    );
    _publisherController = TextEditingController(
      text: widget.book?.publisher ?? '',
    );
    _isbnController = TextEditingController(
      text: widget.book?.isbn ?? widget.isbn ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _isbnController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final school = context.read<SchoolProvider>().selectedSchool!;
    final isbn = _isbnController.text.trim();

    final book = widget.book ?? Book(
      id: const Uuid().v4(),
      isbn: isbn.isEmpty ? null : isbn,
      title: _titleController.text.trim(),
      authors: _authorController.text.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList(),
      publisher: _publisherController.text.trim().isEmpty ? null : _publisherController.text.trim(),
      language: 'tr',
      source: BookSource.fromString(widget.sourceType),
      createdAt: DateTime.now(),
    );

    final source = HoldingSource.fromString(widget.sourceType);
    await context.read<InventoryProvider>().addBook(
      book: book,
      schoolId: school.id,
      addedBy: 'Kütüphaneci',
      source: source,
    );

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNewBook = widget.book == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewBook ? 'Kitap Bilgileri' : 'Kitap Onayı'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isNewBook) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.book!.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(widget.book!.authors.join(', '),
                          style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                        if (widget.book!.publisher != null) ...[
                          const SizedBox(height: 4),
                          Text(widget.book!.publisher!,
                            style: TextStyle(color: Colors.grey[600])),
                        ],
                        if (widget.book!.isbn != null) ...[
                          const SizedBox(height: 4),
                          Text('ISBN: ${widget.book!.isbn}',
                            style: const TextStyle(fontFamily: 'monospace')),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (isNewBook) ...[
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Başlık gerekli' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: 'Yazar',
                    helperText: 'Birden fazla yazar virgülle ayırın',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Yazar gerekli' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _publisherController,
                  decoration: const InputDecoration(
                    labelText: 'Yayınevi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _isbnController,
                  decoration: const InputDecoration(
                    labelText: 'ISBN',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
              ],

              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Kaydet', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Run tests**

```bash
cd apps/mobile && flutter test test/screens/book_confirm_screen_test.dart
```

Expected: ALL PASS

**Step 5: Commit**

```bash
git add apps/mobile/lib/screens/book_confirm_screen.dart apps/mobile/test/screens/book_confirm_screen_test.dart
git commit -m "feat(mobile): add BookConfirmScreen with form validation"
```

---

### Task 9: CoverOcrScreen

**Files:**
- Create: `apps/mobile/lib/screens/cover_ocr_screen.dart`

**Step 1: Implement CoverOcrScreen**

Note: image_picker and ML Kit require real device. Navigation logic tested indirectly via integration.

```dart
// lib/screens/cover_ocr_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/isbn_lookup_service.dart';
import '../services/ocr_service.dart';

class CoverOcrScreen extends StatefulWidget {
  const CoverOcrScreen({super.key});

  @override
  State<CoverOcrScreen> createState() => _CoverOcrScreenState();
}

class _CoverOcrScreenState extends State<CoverOcrScreen> {
  final OcrService _ocrService = OcrService();
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureAndProcess());
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);

    if (photo == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final text = await _ocrService.extractText(File(photo.path));
      if (text.trim().isEmpty) {
        setState(() {
          _processing = false;
          _error = 'Metin tanınamadı. Lütfen tekrar deneyin.';
        });
        return;
      }

      final parsed = OcrService.parseBookTitle(text);
      final lookupService = context.read<IsbnLookupService>();
      final results = await lookupService.searchByTitle(parsed.title);
      final book = results.isNotEmpty ? results.first : null;

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/book/confirm',
          arguments: {
            'book': book,
            'isbn': null,
            'source': 'COVER_OCR',
            'parsedTitle': parsed.title,
            'parsedAuthor': parsed.author,
          },
        );
      }
    } catch (e) {
      setState(() {
        _processing = false;
        _error = 'Hata oluştu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kapak OCR')),
      body: Center(
        child: _processing
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Kapak metni tanınıyor...'),
                ],
              )
            : _error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _captureAndProcess,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tekrar Dene'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context, '/book/confirm',
                          arguments: {'source': 'COVER_OCR'},
                        ),
                        child: const Text('Manuel Giriş'),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add apps/mobile/lib/screens/cover_ocr_screen.dart
git commit -m "feat(mobile): add CoverOcrScreen with ML Kit text recognition"
```

---

### Task 10: ShelfOcrScreen and ShelfResultsScreen

**Files:**
- Create: `apps/mobile/lib/screens/shelf_ocr_screen.dart`
- Create: `apps/mobile/lib/screens/shelf_results_screen.dart`
- Test: `apps/mobile/test/screens/shelf_results_screen_test.dart`

**Step 1: Write failing test for ShelfResultsScreen**

```dart
// test/screens/shelf_results_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kutuphane_mobile/models/school.dart';
import 'package:kutuphane_mobile/providers/inventory_provider.dart';
import 'package:kutuphane_mobile/providers/school_provider.dart';
import 'package:kutuphane_mobile/repositories/mock_book_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_holding_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_school_repository.dart';
import 'package:kutuphane_mobile/screens/shelf_results_screen.dart';
import 'package:kutuphane_mobile/services/isbn_lookup_service.dart';

void main() {
  testWidgets('shows detected book titles with checkboxes', (tester) async {
    final bookRepo = MockBookRepository([]);
    final schoolProvider = SchoolProvider(
      schoolRepository: MockSchoolRepository([
        School(id: 's1', name: 'Test', province: 'Ankara', district: 'Çankaya',
          schoolType: SchoolType.ilkokul, ministryCode: '06001001'),
      ]),
    )..selectSchool(
        School(id: 's1', name: 'Test', province: 'Ankara', district: 'Çankaya',
          schoolType: SchoolType.ilkokul, ministryCode: '06001001'));

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: schoolProvider),
            ChangeNotifierProvider(
              create: (_) => InventoryProvider(
                bookRepository: bookRepo,
                holdingRepository: MockHoldingRepository([]),
              ),
            ),
            Provider(create: (_) => IsbnLookupService(bookRepository: bookRepo)),
          ],
          child: const ShelfResultsScreen(
            detectedTitles: ['Küçük Prens', 'Sefiller', 'Suç ve Ceza'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Küçük Prens'), findsOneWidget);
    expect(find.text('Sefiller'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(3));
  });
}
```

**Step 2: Run test to verify it fails**

```bash
cd apps/mobile && flutter test test/screens/shelf_results_screen_test.dart
```

**Step 3: Implement ShelfOcrScreen**

```dart
// lib/screens/shelf_ocr_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import 'shelf_results_screen.dart';

class ShelfOcrScreen extends StatefulWidget {
  const ShelfOcrScreen({super.key});

  @override
  State<ShelfOcrScreen> createState() => _ShelfOcrScreenState();
}

class _ShelfOcrScreenState extends State<ShelfOcrScreen> {
  final OcrService _ocrService = OcrService();
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureAndProcess());
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);

    if (photo == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final text = await _ocrService.extractText(File(photo.path));
      final titles = OcrService.parseShelfTexts(text);

      if (titles.isEmpty) {
        setState(() {
          _processing = false;
          _error = 'Kitap sırtı algılanamadı. Lütfen tekrar deneyin.';
        });
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ShelfResultsScreen(detectedTitles: titles),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _processing = false;
        _error = 'Hata oluştu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raf OCR')),
      body: Center(
        child: _processing
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Raf metni tanınıyor...'),
                ],
              )
            : _error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _captureAndProcess,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
```

**Step 4: Implement ShelfResultsScreen**

```dart
// lib/screens/shelf_results_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../models/holding.dart';
import '../providers/inventory_provider.dart';
import '../providers/school_provider.dart';
import '../services/isbn_lookup_service.dart';

class ShelfResultsScreen extends StatefulWidget {
  final List<String> detectedTitles;

  const ShelfResultsScreen({super.key, required this.detectedTitles});

  @override
  State<ShelfResultsScreen> createState() => _ShelfResultsScreenState();
}

class _ShelfResultsScreenState extends State<ShelfResultsScreen> {
  late List<bool> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.detectedTitles.length, true);
  }

  void _toggleAll(bool? value) {
    setState(() {
      _selected = List.filled(widget.detectedTitles.length, value ?? false);
    });
  }

  Future<void> _saveSelected() async {
    setState(() => _saving = true);

    final school = context.read<SchoolProvider>().selectedSchool!;
    final inventory = context.read<InventoryProvider>();
    final lookupService = context.read<IsbnLookupService>();
    const uuid = Uuid();

    for (int i = 0; i < widget.detectedTitles.length; i++) {
      if (!_selected[i]) continue;

      final title = widget.detectedTitles[i];
      final results = await lookupService.searchByTitle(title);
      final book = results.isNotEmpty
          ? results.first
          : Book(
              id: uuid.v4(),
              title: title,
              authors: ['Bilinmiyor'],
              language: 'tr',
              source: BookSource.ocr,
              createdAt: DateTime.now(),
            );

      await inventory.addBook(
        book: book,
        schoolId: school.id,
        addedBy: 'Kütüphaneci',
        source: HoldingSource.shelfOcr,
      );
    }

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.where((s) => s).length;
    final allSelected = _selected.every((s) => s);

    return Scaffold(
      appBar: AppBar(
        title: Text('Raf Sonuçları (${widget.detectedTitles.length})'),
      ),
      body: Column(
        children: [
          CheckboxListTile(
            title: Text(allSelected ? 'Tümünü Kaldır' : 'Tümünü Seç'),
            value: allSelected,
            onChanged: _toggleAll,
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: widget.detectedTitles.length,
              itemBuilder: (context, index) {
                return CheckboxListTile(
                  title: Text(widget.detectedTitles[index]),
                  value: _selected[index],
                  onChanged: (value) {
                    setState(() => _selected[index] = value ?? false);
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: (selectedCount == 0 || _saving) ? null : _saveSelected,
                icon: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text('$selectedCount Kitap Kaydet'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 5: Run tests**

```bash
cd apps/mobile && flutter test test/screens/shelf_results_screen_test.dart
```

Expected: ALL PASS

**Step 6: Commit**

```bash
git add apps/mobile/lib/screens/shelf_ocr_screen.dart apps/mobile/lib/screens/shelf_results_screen.dart apps/mobile/test/screens/shelf_results_screen_test.dart
git commit -m "feat(mobile): add ShelfOcrScreen and ShelfResultsScreen"
```

---

### Task 11: Wire main.dart with Providers and Navigation

**Files:**
- Modify: `apps/mobile/lib/main.dart`

**Step 1: Rewrite main.dart with full app wiring**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/book.dart';
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

class KutuphaneApp extends StatelessWidget {
  const KutuphaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final data = snapshot.data!;
        final bookRepo = MockBookRepository(data.books);
        final schoolRepo = MockSchoolRepository(data.schools);
        final holdingRepo = MockHoldingRepository(data.holdings);

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => SchoolProvider(schoolRepository: schoolRepo)..loadProvinces(),
            ),
            ChangeNotifierProvider(
              create: (_) => InventoryProvider(
                bookRepository: bookRepo,
                holdingRepository: holdingRepo,
              ),
            ),
            Provider(
              create: (_) => IsbnLookupService(bookRepository: bookRepo),
            ),
          ],
          child: Consumer<SchoolProvider>(
            builder: (context, schoolProvider, _) {
              return MaterialApp(
                title: 'Kütüphane Yönetim Sistemi',
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                  useMaterial3: true,
                ),
                home: schoolProvider.hasSelectedSchool
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
                    final args = settings.arguments as Map<String, dynamic>?;
                    return MaterialPageRoute(
                      builder: (_) => BookConfirmScreen(
                        book: args?['book'] as Book?,
                        isbn: args?['isbn'] as String?,
                        sourceType: args?['source'] as String? ?? 'MANUAL',
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

  Future<_MockData> _loadData() async {
    // In test/dev, load from assets. These will be available after asset bundle init.
    try {
      final books = await MockDataService.loadBooks();
      final schools = await MockDataService.loadSchools();
      final holdings = await MockDataService.loadHoldings();
      return _MockData(books: books, schools: schools, holdings: holdings);
    } catch (_) {
      // Fallback: empty data (e.g., during tests without asset bundle)
      return _MockData(books: [], schools: [], holdings: []);
    }
  }
}

class _MockData {
  final List books;
  final List schools;
  final List holdings;

  _MockData({required this.books, required this.schools, required this.holdings});
}
```

**Step 2: Run all tests**

```bash
cd apps/mobile && flutter test
```

Expected: ALL PASS

**Step 3: Run the app (smoke test on Chrome)**

```bash
cd apps/mobile && flutter run -d chrome
```

Expected: App loads, shows SchoolSelectionScreen.

**Step 4: Commit**

```bash
git add apps/mobile/lib/main.dart
git commit -m "feat(mobile): wire main.dart with providers, navigation, and mock data"
```

---

### Task 12: Update Roadmap and Final Cleanup

**Files:**
- Modify: `docs/plans/roadmap.md` — Check off Faz 0 items

**Step 1: Update roadmap checkboxes**

Mark the following as complete in `docs/plans/roadmap.md`:
- [x] Monorepo yapısı kurulumu
- [x] Shared paket: modeller, mock data, API kontratları
- [x] Flutter mobil uygulama
- [x] React web dashboard
- [x] Mock data layer

**Step 2: Run all tests one final time**

```bash
cd apps/mobile && flutter test
cd apps/web && npx vitest run
```

Expected: ALL PASS in both apps.

**Step 3: Commit and push**

```bash
git add docs/plans/roadmap.md
git commit -m "docs: mark Faz 0 MVP as complete in roadmap"
git push
```
