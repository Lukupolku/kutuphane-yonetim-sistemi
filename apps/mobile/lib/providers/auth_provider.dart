import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Mock user database — email → {password, user data}.
const _mockUsers = <String, Map<String, dynamic>>{
  'demo@meb.k12.tr': {
    'password': '123456',
    'id': 'u13',
    'fullName': 'Ahmet Yıldız',
    'role': 'teacher',
    'schoolId': 's13-ankara-sincan-sdemirel-lise',
  },
  'ogretmen@ataturk.meb.k12.tr': {
    'password': '123456',
    'id': 'u1',
    'fullName': 'Ayşe Yılmaz',
    'role': 'teacher',
    'schoolId': 's1-ankara-cankaya-ataturk-ilk',
  },
  'ogretmen@inonu.meb.k12.tr': {
    'password': '123456',
    'id': 'u2',
    'fullName': 'Mehmet Kaya',
    'role': 'teacher',
    'schoolId': 's2-ankara-cankaya-inonu-orta',
  },
  'ogretmen@fatih.meb.k12.tr': {
    'password': '123456',
    'id': 'u3',
    'fullName': 'Fatma Demir',
    'role': 'teacher',
    'schoolId': 's3-ankara-kecioren-fatih-lise',
  },
  'ogretmen@moda.meb.k12.tr': {
    'password': '123456',
    'id': 'u5',
    'fullName': 'Ali Öztürk',
    'role': 'teacher',
    'schoolId': 's5-istanbul-kadikoy-moda-orta',
  },
  'ogretmen@fenerbahce.meb.k12.tr': {
    'password': '123456',
    'id': 'u6',
    'fullName': 'Zeynep Arslan',
    'role': 'teacher',
    'schoolId': 's6-istanbul-kadikoy-fenerbahce-lise',
  },
  'ogretmen@barbaros.meb.k12.tr': {
    'password': '123456',
    'id': 'u7',
    'fullName': 'Hasan Çelik',
    'role': 'teacher',
    'schoolId': 's7-istanbul-besiktas-barbaros-ilk',
  },
  'ogretmen@alsancak.meb.k12.tr': {
    'password': '123456',
    'id': 'u9',
    'fullName': 'Elif Koç',
    'role': 'teacher',
    'schoolId': 's9-izmir-konak-alsancak-lise',
  },
  'ogretmen@ege.meb.k12.tr': {
    'password': '123456',
    'id': 'u11',
    'fullName': 'Burak Şahin',
    'role': 'teacher',
    'schoolId': 's11-izmir-bornova-ege-orta',
  },
  'admin@meb.k12.tr': {
    'password': 'admin123',
    'id': 'u0',
    'fullName': 'Sistem Yöneticisi',
    'role': 'admin',
    'schoolId': 's1-ankara-cankaya-ataturk-ilk',
  },
};

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _loading = false;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;

  /// Try restoring a previously saved session.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('auth_user');
    if (userJson != null) {
      _user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      notifyListeners();
    }
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> login(String email, String password) async {
    _loading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final entry = _mockUsers[email.trim().toLowerCase()];

    if (entry == null || entry['password'] != password) {
      _loading = false;
      notifyListeners();
      return 'E-posta veya şifre hatalı';
    }

    _user = AppUser(
      id: entry['id'] as String,
      email: email.trim().toLowerCase(),
      fullName: entry['fullName'] as String,
      role: entry['role'] as String,
      schoolId: entry['schoolId'] as String,
    );

    // Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user', jsonEncode(_user!.toJson()));

    _loading = false;
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user');
    await prefs.remove('selected_school');
    notifyListeners();
  }
}
