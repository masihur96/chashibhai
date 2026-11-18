class SchoolModel {
  final String id;
  final String name;
  final String code;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;

  const SchoolModel({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      logoUrl: json['logoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'email': email,
      'logoUrl': logoUrl,
    };
  }
}

class SchoolClassModel {
  final String id;
  final String name;
  final List<String> sections;

  const SchoolClassModel({
    required this.id,
    required this.name,
    required this.sections,
  });

  factory SchoolClassModel.fromJson(Map<String, dynamic> json) {
    return SchoolClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sections: List<String>.from(json['sections'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sections': sections,
    };
  }
}
