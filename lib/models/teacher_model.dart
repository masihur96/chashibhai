class TeacherModel {
  final String id;
  final String name;
  final String designation;
  final String subject;
  final String phone;
  final String? email;
  final String? avatarUrl;

  const TeacherModel({
    required this.id,
    required this.name,
    required this.designation,
    required this.subject,
    required this.phone,
    this.email,
    this.avatarUrl,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'] as String,
      name: json['name'] as String,
      designation: json['designation'] as String,
      subject: json['subject'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'designation': designation,
      'subject': subject,
      'phone': phone,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }
}
