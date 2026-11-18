class SmsModel {
  final String id;
  final String recipient;
  final String message;
  final DateTime sentAt;
  final String status;
  final String? type;

  const SmsModel({
    required this.id,
    required this.recipient,
    required this.message,
    required this.sentAt,
    this.status = 'sent',
    this.type,
  });

  factory SmsModel.fromJson(Map<String, dynamic> json) {
    return SmsModel(
      id: json['id'] as String,
      recipient: json['recipient'] as String,
      message: json['message'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      status: json['status'] as String? ?? 'sent',
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient': recipient,
      'message': message,
      'sentAt': sentAt.toIso8601String(),
      'status': status,
      'type': type,
    };
  }
}
