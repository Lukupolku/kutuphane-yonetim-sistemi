class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String schoolId;

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.schoolId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
        'schoolId': schoolId,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['fullName'] as String,
        role: json['role'] as String,
        schoolId: json['schoolId'] as String,
      );
}
