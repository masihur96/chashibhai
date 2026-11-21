import 'dart:convert';
import 'dart:io';

import '../../../../configs/network/api_logger.dart';
import '../../../../core/constants/api_path.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/token_refresh_service.dart';
import '../../../../core/utils/storage_service.dart';

abstract class NotificationRemoteDataSource {
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
    String? token,
  });

  Future<bool> markAsRead({
    required String notificationId,
    String? token,
  });

  Future<bool> markAllAsRead({
    String? token,
  });
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final HttpClient _client;

  /// Default fallback token from user cURL specification
  static const String defaultFallbackToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTI2MzQwMiwiZXhwIjoxNzk1MjY0MzAyfQ.bBzXkK-A8EKBmCnQytF6bCoDBKdcIGIHrtU5Pey6Yqw';

  NotificationRemoteDataSourceImpl({HttpClient? client})
      : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 15);
  }

  Future<String> _resolveToken(String? explicitToken) async {
    if (explicitToken != null && explicitToken.isNotEmpty) {
      return explicitToken;
    }
    try {
      final stored = await StorageService().getAccessToken();
      if (stored != null && stored.isNotEmpty) {
        return stored;
      }
    } catch (_) {}
    return defaultFallbackToken;
  }

  Future<String?> _attemptRefreshToken() async {
    try {
      return await TokenRefreshManager().refresh(client: _client);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
    String? token,
  }) async {
    final queryParams = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (isRead != null) {
      queryParams['isRead'] = isRead.toString();
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    final baseUri = Uri.parse(ApiPath.notifications);
    final uri = baseUri.replace(queryParameters: queryParams);
    final stopwatch = Stopwatch()..start();

    String resolvedToken = await _resolveToken(token);
    final headers = {
      'accept': 'application/json',
      'Authorization': 'Bearer $resolvedToken',
    };

    ApiLogger.logRequest(
      method: 'GET',
      uri: uri,
      headers: headers,
    );

    try {
      var httpRequest = await _client.getUrl(uri);
      headers.forEach((key, value) => httpRequest.headers.set(key, value));

      var httpResponse = await httpRequest.close();
      stopwatch.stop();

      var responseBody = await httpResponse.transform(utf8.decoder).join();
      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
      }

      // Handle 401 auto refresh
      if (httpResponse.statusCode == 401) {
        final newToken = await _attemptRefreshToken();
        if (newToken != null && newToken.isNotEmpty) {
          resolvedToken = newToken;
          headers['Authorization'] = 'Bearer $resolvedToken';
          stopwatch.reset();
          stopwatch.start();

          httpRequest = await _client.getUrl(uri);
          headers.forEach((key, value) => httpRequest.headers.set(key, value));
          httpResponse = await httpRequest.close();
          stopwatch.stop();
          responseBody = await httpResponse.transform(utf8.decoder).join();
          try {
            decodedJson = jsonDecode(responseBody);
          } catch (_) {
            decodedJson = null;
          }
        }
      }

      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        ApiLogger.logResponse(
          method: 'GET',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );

        return _parseNotificationsList(decodedJson);
      } else {
        final errorMsg = decodedJson is Map && decodedJson['error'] != null
            ? decodedJson['error'].toString()
            : decodedJson is Map && decodedJson['message'] != null
                ? decodedJson['message'].toString()
                : 'Failed to fetch notifications (Status: ${httpResponse.statusCode})';

        ApiLogger.logError(
          method: 'GET',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          error: errorMsg,
          body: responseBody,
        );
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (stopwatch.isRunning) stopwatch.stop();
      rethrow;
    }
  }

  @override
  Future<bool> markAsRead({
    required String notificationId,
    String? token,
  }) async {
    final uri = Uri.parse(ApiPath.markNotificationRead(notificationId));
    final stopwatch = Stopwatch()..start();

    String resolvedToken = await _resolveToken(token);
    final headers = {
      'accept': 'application/json',
      'Authorization': 'Bearer $resolvedToken',
      'Content-Type': 'application/json',
    };

    ApiLogger.logRequest(
      method: 'PATCH',
      uri: uri,
      headers: headers,
    );

    try {
      var httpRequest = await _client.patchUrl(uri);
      headers.forEach((key, value) => httpRequest.headers.set(key, value));

      var httpResponse = await httpRequest.close();
      stopwatch.stop();

      var responseBody = await httpResponse.transform(utf8.decoder).join();
      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
      }

      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        ApiLogger.logResponse(
          method: 'PATCH',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );
        return true;
      }
      return false;
    } catch (_) {
      if (stopwatch.isRunning) stopwatch.stop();
      return false;
    }
  }

  @override
  Future<bool> markAllAsRead({
    String? token,
  }) async {
    final uri = Uri.parse(ApiPath.markAllNotificationsRead);
    final stopwatch = Stopwatch()..start();

    String resolvedToken = await _resolveToken(token);
    final headers = {
      'accept': 'application/json',
      'Authorization': 'Bearer $resolvedToken',
      'Content-Type': 'application/json',
    };

    ApiLogger.logRequest(
      method: 'PATCH',
      uri: uri,
      headers: headers,
    );

    try {
      var httpRequest = await _client.patchUrl(uri);
      headers.forEach((key, value) => httpRequest.headers.set(key, value));

      var httpResponse = await httpRequest.close();
      stopwatch.stop();

      var responseBody = await httpResponse.transform(utf8.decoder).join();
      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
      }

      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        ApiLogger.logResponse(
          method: 'PATCH',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );
        return true;
      }
      return false;
    } catch (_) {
      if (stopwatch.isRunning) stopwatch.stop();
      return false;
    }
  }

  List<AppNotification> _parseNotificationsList(dynamic decodedJson) {
    if (decodedJson == null) return [];
    if (decodedJson is List) {
      return decodedJson
          .map((e) => e is Map<String, dynamic> ? AppNotification.fromJson(e) : null)
          .whereType<AppNotification>()
          .toList();
    }
    if (decodedJson is Map<String, dynamic>) {
      if (decodedJson['data'] is List) {
        return (decodedJson['data'] as List)
            .map((e) => e is Map<String, dynamic> ? AppNotification.fromJson(e) : null)
            .whereType<AppNotification>()
            .toList();
      }
      if (decodedJson['notifications'] is List) {
        return (decodedJson['notifications'] as List)
            .map((e) => e is Map<String, dynamic> ? AppNotification.fromJson(e) : null)
            .whereType<AppNotification>()
            .toList();
      }
      if (decodedJson['data'] is Map && decodedJson['data']['notifications'] is List) {
        return (decodedJson['data']['notifications'] as List)
            .map((e) => e is Map<String, dynamic> ? AppNotification.fromJson(e) : null)
            .whereType<AppNotification>()
            .toList();
      }
      if (decodedJson['data'] is Map<String, dynamic>) {
        return [AppNotification.fromJson(decodedJson['data'] as Map<String, dynamic>)];
      }
      if (decodedJson.containsKey('id') || decodedJson.containsKey('title')) {
        return [AppNotification.fromJson(decodedJson)];
      }
    }
    return [];
  }
}
