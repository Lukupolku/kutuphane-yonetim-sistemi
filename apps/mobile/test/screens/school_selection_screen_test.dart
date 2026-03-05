import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kutuphane_mobile/models/school.dart';
import 'package:kutuphane_mobile/repositories/mock_school_repository.dart';
import 'package:kutuphane_mobile/providers/school_provider.dart';
import 'package:kutuphane_mobile/screens/school_selection_screen.dart';

void main() {
  late MockSchoolRepository repository;
  late SchoolProvider schoolProvider;

  setUp(() {
    final seedSchools = [
      School(
        id: 's1',
        name: 'Ankara Ilkokulu',
        province: 'Ankara',
        district: 'Cankaya',
        schoolType: SchoolType.ilkokul,
        ministryCode: '06001',
      ),
      School(
        id: 's2',
        name: 'Istanbul Lisesi',
        province: 'Istanbul',
        district: 'Kadikoy',
        schoolType: SchoolType.lise,
        ministryCode: '34001',
      ),
    ];
    repository = MockSchoolRepository(seedSchools);
    schoolProvider = SchoolProvider(schoolRepository: repository);
  });

  Widget createTestWidget() {
    return ChangeNotifierProvider<SchoolProvider>.value(
      value: schoolProvider,
      child: MaterialApp(
        routes: {
          '/': (context) => const SchoolSelectionScreen(),
          '/inventory': (context) => const Scaffold(
                body: Center(child: Text('Inventory')),
              ),
        },
      ),
    );
  }

  group('SchoolSelectionScreen', () {
    testWidgets('shows province dropdown on load', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Il Secin'), findsOneWidget);
    });

    testWidgets('shows AppBar with correct title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Okul Secimi'), findsOneWidget);
    });

    testWidgets('shows school icon and title text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.school), findsOneWidget);
      expect(find.text('Okulunuzu Secin'), findsOneWidget);
    });

    testWidgets('shows Devam Et button disabled initially', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final button = find.text('Devam Et');
      expect(button, findsOneWidget);

      final elevatedButton = find.ancestor(
        of: button,
        matching: find.byType(ElevatedButton),
      );
      final widget = tester.widget<ElevatedButton>(elevatedButton);
      expect(widget.onPressed, isNull);
    });
  });
}
