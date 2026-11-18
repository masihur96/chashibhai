class PeriodAttendanceModel {
  final String id;
  final String periodId;
  final int periodNumber;
  final String subject;
  final DateTime date;
  final String classId;
  final String sectionId;
  final Map<String, String> studentStatus; // studentId -> 'present' / 'absent' / 'late'

  const PeriodAttendanceModel({
    required this.id,
    required this.periodId,
    required this.periodNumber,
    required this.subject,
    required this.date,
    required this.classId,
    required this.sectionId,
    required this.studentStatus,
  });

  factory PeriodAttendanceModel.fromJson(Map<String, dynamic> json) {
    return PeriodAttendanceModel(
      id: json['id'] as String,
      periodId: json['periodId'] as String,
      periodNumber: json['periodNumber'] as int,
      subject: json['subject'] as String,
      date: DateTime.parse(json['date'] as String),
      classId: json['classId'] as String,
      sectionId: json['sectionId'] as String,
      studentStatus: Map<String, String>.from(json['studentStatus'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'periodId': periodId,
      'periodNumber': periodNumber,
      'subject': subject,
      'date': date.toIso8601String(),
      'classId': classId,
      'sectionId': sectionId,
      'studentStatus': studentStatus,
    };
  }
}
