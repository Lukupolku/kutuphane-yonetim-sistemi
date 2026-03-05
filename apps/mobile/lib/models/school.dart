enum SchoolType {
  ilkokul,
  ortaokul,
  lise;

  static SchoolType fromString(String value) {
    switch (value) {
      case 'ILKOKUL': return SchoolType.ilkokul;
      case 'ORTAOKUL': return SchoolType.ortaokul;
      case 'LISE': return SchoolType.lise;
      default: throw ArgumentError('Unknown SchoolType: $value');
    }
  }

  String toJsonString() {
    switch (this) {
      case SchoolType.ilkokul: return 'ILKOKUL';
      case SchoolType.ortaokul: return 'ORTAOKUL';
      case SchoolType.lise: return 'LISE';
    }
  }
}

class School {
  final String id;
  final String name;
  final String province;
  final String district;
  final SchoolType schoolType;
  final String ministryCode;

  School({
    required this.id,
    required this.name,
    required this.province,
    required this.district,
    required this.schoolType,
    required this.ministryCode,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] as String,
      name: json['name'] as String,
      province: json['province'] as String,
      district: json['district'] as String,
      schoolType: SchoolType.fromString(json['schoolType'] as String),
      ministryCode: json['ministryCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'province': province,
      'district': district,
      'schoolType': schoolType.toJsonString(),
      'ministryCode': ministryCode,
    };
  }
}
