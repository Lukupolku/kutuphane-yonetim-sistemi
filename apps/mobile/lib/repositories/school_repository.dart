import '../models/school.dart';

abstract class SchoolRepository {
  Future<List<School>> getAll();
  Future<School?> getById(String id);
  Future<List<String>> getProvinces();
  Future<List<String>> getDistricts(String province);
  Future<List<School>> getByDistrict(String province, String district);
}
