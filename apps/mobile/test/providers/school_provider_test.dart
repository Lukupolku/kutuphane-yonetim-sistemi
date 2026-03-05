import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/school.dart';
import 'package:kutuphane_mobile/repositories/mock_school_repository.dart';
import 'package:kutuphane_mobile/providers/school_provider.dart';

void main() {
  late MockSchoolRepository repository;
  late SchoolProvider provider;
  late List<School> seedSchools;

  setUp(() {
    seedSchools = [
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
        name: 'Ankara Ortaokulu',
        province: 'Ankara',
        district: 'Kecioren',
        schoolType: SchoolType.ortaokul,
        ministryCode: '06002',
      ),
      School(
        id: 's3',
        name: 'Istanbul Lisesi',
        province: 'Istanbul',
        district: 'Kadikoy',
        schoolType: SchoolType.lise,
        ministryCode: '34001',
      ),
      School(
        id: 's4',
        name: 'Istanbul Ilkokulu',
        province: 'Istanbul',
        district: 'Kadikoy',
        schoolType: SchoolType.ilkokul,
        ministryCode: '34002',
      ),
      School(
        id: 's5',
        name: 'Izmir Ortaokulu',
        province: 'Izmir',
        district: 'Konak',
        schoolType: SchoolType.ortaokul,
        ministryCode: '35001',
      ),
    ];
    repository = MockSchoolRepository(seedSchools);
    provider = SchoolProvider(schoolRepository: repository);
  });

  group('SchoolProvider', () {
    test('hasSelectedSchool returns false initially', () {
      expect(provider.hasSelectedSchool, isFalse);
    });

    test('provinces, districts, schools are empty initially', () {
      expect(provider.provinces, isEmpty);
      expect(provider.districts, isEmpty);
      expect(provider.schools, isEmpty);
    });

    test('selectedProvince, selectedDistrict, selectedSchool are null initially', () {
      expect(provider.selectedProvince, isNull);
      expect(provider.selectedDistrict, isNull);
      expect(provider.selectedSchool, isNull);
    });

    group('loadProvinces', () {
      test('returns sorted provinces', () async {
        await provider.loadProvinces();
        expect(provider.provinces, ['Ankara', 'Istanbul', 'Izmir']);
      });

      test('notifies listeners', () async {
        var notified = false;
        provider.addListener(() => notified = true);
        await provider.loadProvinces();
        expect(notified, isTrue);
      });
    });

    group('selectProvince', () {
      test('loads districts and sets selectedProvince', () async {
        await provider.loadProvinces();
        await provider.selectProvince('Ankara');

        expect(provider.selectedProvince, 'Ankara');
        expect(provider.districts, ['Cankaya', 'Kecioren']);
      });

      test('clears selectedDistrict and schools when province changes', () async {
        await provider.loadProvinces();
        await provider.selectProvince('Istanbul');
        await provider.selectDistrict('Kadikoy');
        expect(provider.schools, hasLength(2));

        await provider.selectProvince('Ankara');
        expect(provider.selectedDistrict, isNull);
        expect(provider.schools, isEmpty);
        expect(provider.selectedSchool, isNull);
      });

      test('notifies listeners', () async {
        await provider.loadProvinces();
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);
        await provider.selectProvince('Ankara');
        expect(notifyCount, greaterThan(0));
      });
    });

    group('selectDistrict', () {
      test('loads schools for that province and district', () async {
        await provider.loadProvinces();
        await provider.selectProvince('Istanbul');
        await provider.selectDistrict('Kadikoy');

        expect(provider.selectedDistrict, 'Kadikoy');
        expect(provider.schools, hasLength(2));
        expect(provider.schools.every((s) => s.district == 'Kadikoy'), isTrue);
      });

      test('clears selectedSchool when district changes', () async {
        await provider.loadProvinces();
        await provider.selectProvince('Istanbul');
        await provider.selectDistrict('Kadikoy');
        provider.selectSchool(provider.schools.first);
        expect(provider.hasSelectedSchool, isTrue);

        await provider.selectDistrict('Kadikoy');
        expect(provider.selectedSchool, isNull);
      });

      test('notifies listeners', () async {
        await provider.loadProvinces();
        await provider.selectProvince('Istanbul');
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);
        await provider.selectDistrict('Kadikoy');
        expect(notifyCount, greaterThan(0));
      });
    });

    group('selectSchool', () {
      test('sets selectedSchool', () async {
        await provider.loadProvinces();
        await provider.selectProvince('Ankara');
        await provider.selectDistrict('Cankaya');

        final school = provider.schools.first;
        provider.selectSchool(school);

        expect(provider.selectedSchool, school);
        expect(provider.hasSelectedSchool, isTrue);
      });

      test('notifies listeners', () async {
        await provider.loadProvinces();
        await provider.selectProvince('Ankara');
        await provider.selectDistrict('Cankaya');

        var notified = false;
        provider.addListener(() => notified = true);
        provider.selectSchool(provider.schools.first);
        expect(notified, isTrue);
      });
    });

    group('hasSelectedSchool', () {
      test('returns true when a school is selected', () async {
        await provider.loadProvinces();
        await provider.selectProvince('Ankara');
        await provider.selectDistrict('Cankaya');
        provider.selectSchool(provider.schools.first);

        expect(provider.hasSelectedSchool, isTrue);
      });

      test('returns false when no school is selected', () {
        expect(provider.hasSelectedSchool, isFalse);
      });
    });
  });
}
