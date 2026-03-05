import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/school.dart';

void main() {
  group('School', () {
    test('fromJson creates School', () {
      final json = {
        'id': 's1-ankara-cankaya-ataturk-ilk',
        'name': 'Atatürk İlkokulu',
        'province': 'Ankara',
        'district': 'Çankaya',
        'schoolType': 'ILKOKUL',
        'ministryCode': '06001001',
      };
      final school = School.fromJson(json);
      expect(school.name, 'Atatürk İlkokulu');
      expect(school.schoolType, SchoolType.ilkokul);
    });

    test('toJson produces valid JSON', () {
      final school = School(
        id: 's1',
        name: 'Test Okulu',
        province: 'Ankara',
        district: 'Çankaya',
        schoolType: SchoolType.ilkokul,
        ministryCode: '06001001',
      );
      expect(school.toJson()['schoolType'], 'ILKOKUL');
    });
  });
}
