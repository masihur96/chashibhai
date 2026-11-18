class OnlineClassModel {
  final String id;
  final String title;
  final String subject;
  final String teacherName;
  final DateTime startTime;
  final int durationMinutes;
  final String meetingLink;
  final String? password;
  final String status;

  const OnlineClassModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.teacherName,
    required this.startTime,
    required this.durationMinutes,
    required this.meetingLink,
    this.password,
    this.status = 'scheduled',
  });

  factory OnlineClassModel.fromJson(Map<String, dynamic> json) {
    return OnlineClassModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      teacherName: json['teacherName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      durationMinutes: json['durationMinutes'] as int? ?? 45,
      meetingLink: json['meetingLink'] as String,
      password: json['password'] as String?,
      status: json['status'] as String? ?? 'scheduled',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'teacherName': teacherName,
      'startTime': startTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'meetingLink': meetingLink,
      'password': password,
      'status': status,
    };
  }
}
