class StudentModel {
  final String id;
  final String name;
  final String rollNo;
  final String className;
  final String section;
  final String? guardianName;
  final String? guardianPhone;
  final String? avatarUrl;

  const StudentModel({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.className,
    required this.section,
    this.guardianName,
    this.guardianPhone,
    this.avatarUrl,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      rollNo: json['rollNo'] as String,
      className: json['className'] as String,
      section: json['section'] as String,
      guardianName: json['guardianName'] as String?,
      guardianPhone: json['guardianPhone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rollNo': rollNo,
      'className': className,
      'section': section,
      'guardianName': guardianName,
      'guardianPhone': guardianPhone,
      'avatarUrl': avatarUrl,
    };
  }
}
