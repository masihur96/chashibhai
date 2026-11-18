import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiLogger {
  ApiLogger._();

  static bool isEnabled = kDebugMode;

  static void logRequest({
    required String method,
    required Uri uri,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    if (!isEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('\n┌── [API REQUEST] ─────────────────────────────────────────');
    buffer.writeln('│ Method : ${method.toUpperCase()}');
    buffer.writeln('│ URL    : $uri');

    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('├┄┄ Headers ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄');
      headers.forEach((key, value) {
        // Redact full token for security if too long, or display
        if (key.toLowerCase() == 'authorization' && value is String && value.length > 30) {
          buffer.writeln('│   $key: ${value.substring(0, 20)}...[truncated]');
        } else {
          buffer.writeln('│   $key: $value');
        }
      });
    }

    if (body != null) {
      buffer.writeln('├┄┄ Request Body ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄');
      buffer.writeln('│ ${_formatBody(body)}');
    }

    buffer.write('└──────────────────────────────────────────────────────────');
    debugPrint(buffer.toString());
  }

  static void logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    Duration? duration,
    dynamic body,
  }) {
    if (!isEnabled) return;

    final isSuccess = statusCode >= 200 && statusCode < 300;
    final statusSymbol = isSuccess ? '✅' : '❌';
    final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';

    final buffer = StringBuffer();
    buffer.writeln('\n┌── [API RESPONSE $statusSymbol] ────────────────────────────────────────');
    buffer.writeln('│ Method : ${method.toUpperCase()}');
    buffer.writeln('│ URL    : $uri');
    buffer.writeln('│ Status : $statusCode$durationStr');

    if (body != null) {
      buffer.writeln('├┄┄ Response Body ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄');
      buffer.writeln('│ ${_formatBody(body)}');
    }

    buffer.write('└──────────────────────────────────────────────────────────');
    debugPrint(buffer.toString());
  }

  static void logError({
    required String method,
    required Uri uri,
    int? statusCode,
    Duration? duration,
    dynamic error,
    dynamic body,
  }) {
    if (!isEnabled) return;

    final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';

    final buffer = StringBuffer();
    buffer.writeln('\n┌── [API ERROR ⚠️] ────────────────────────────────────────');
    buffer.writeln('│ Method : ${method.toUpperCase()}');
    buffer.writeln('│ URL    : $uri');
    if (statusCode != null) {
      buffer.writeln('│ Status : $statusCode$durationStr');
    }

    if (error != null) {
      buffer.writeln('├┄┄ Error ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄');
      buffer.writeln('│ $error');
    }

    if (body != null) {
      buffer.writeln('├┄┄ Response Body ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄');
      buffer.writeln('│ ${_formatBody(body)}');
    }

    buffer.write('└──────────────────────────────────────────────────────────');
    debugPrint(buffer.toString());
  }

  static String _formatBody(dynamic body) {
    try {
      if (body is Map || body is List) {
        return const JsonEncoder.withIndent('  ')
            .convert(body)
            .replaceAll('\n', '\n│ ');
      } else if (body is String && body.trim().startsWith('{') || (body is String && body.trim().startsWith('['))) {
        final decoded = jsonDecode(body);
        return const JsonEncoder.withIndent('  ')
            .convert(decoded)
            .replaceAll('\n', '\n│ ');
      } else {
        return body.toString().replaceAll('\n', '\n│ ');
      }
    } catch (_) {
      return body.toString().replaceAll('\n', '\n│ ');
    }
  }
}
