import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/school.dart';
import '../repositories/school_repository.dart';

class SchoolProvider extends ChangeNotifier {
  final SchoolRepository schoolRepository;

  List<String> provinces = [];
  List<String> districts = [];
  List<School> schools = [];

  String? selectedProvince;
  String? selectedDistrict;
  School? selectedSchool;

  bool get hasSelectedSchool => selectedSchool != null;

  SchoolProvider({required this.schoolRepository});

  Future<void> loadProvinces() async {
    provinces = await schoolRepository.getProvinces();
    notifyListeners();
  }

  Future<void> selectProvince(String province) async {
    selectedProvince = province;
    selectedDistrict = null;
    selectedSchool = null;
    schools = [];
    districts = await schoolRepository.getDistricts(province);
    notifyListeners();
  }

  Future<void> selectDistrict(String district) async {
    selectedDistrict = district;
    selectedSchool = null;
    schools = await schoolRepository.getByDistrict(
      selectedProvince!,
      district,
    );
    notifyListeners();
  }

  void selectSchool(School school) {
    selectedSchool = school;
    notifyListeners();
  }

  Future<void> loadSavedSchool() async {
    final prefs = await SharedPreferences.getInstance();
    final schoolJson = prefs.getString('selected_school');
    if (schoolJson != null) {
      final map = jsonDecode(schoolJson) as Map<String, dynamic>;
      selectedSchool = School.fromJson(map);
      selectedProvince = selectedSchool!.province;
      selectedDistrict = selectedSchool!.district;
      notifyListeners();
    }
  }

  Future<void> saveSelectedSchool() async {
    if (selectedSchool == null) return;
    final prefs = await SharedPreferences.getInstance();
    final schoolJson = jsonEncode(selectedSchool!.toJson());
    await prefs.setString('selected_school', schoolJson);
  }
}
