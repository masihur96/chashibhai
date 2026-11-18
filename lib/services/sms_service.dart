import 'package:flutter/foundation.dart';
import '../models/sms_models.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  Future<bool> sendSms({
    required String recipientPhone,
    required String message,
  }) async {
    try {
      debugPrint('Sending SMS to $recipientPhone: $message');
      return true;
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return false;
    }
  }

  Future<bool> sendOtp({
    required String phone,
    required String otp,
  }) async {
    return sendSms(
      recipientPhone: phone,
      message: 'Your verification OTP is $otp. Valid for 5 minutes.',
    );
  }
}
