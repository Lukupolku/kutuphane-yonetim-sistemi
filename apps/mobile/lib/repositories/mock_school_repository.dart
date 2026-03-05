import '../models/school.dart';
import 'school_repository.dart';

class MockSchoolRepository implements SchoolRepository {
  final List<School> _schools;

  MockSchoolRepository(List<School> schools)
      : _schools = List<School>.from(schools);

  @override
  Future<List<School>> getAll() async {
    return List<School>.from(_schools);
  }

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
    final provinces = _schools.map((s) => s.province).toSet().toList();
    provinces.sort();
    return provinces;
  }

  @override
  Future<List<String>> getDistricts(String province) async {
    final districts = _schools
        .where((s) => s.province == province)
        .map((s) => s.district)
        .toSet()
        .toList();
    districts.sort();
    return districts;
  }

  @override
  Future<List<School>> getByDistrict(String province, String district) async {
    return _schools
        .where((s) => s.province == province && s.district == district)
        .toList();
  }
}
