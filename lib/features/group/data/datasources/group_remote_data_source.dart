import 'dart:convert';
import 'dart:io';

import '../../../../configs/network/api_logger.dart';
import '../../../../core/constants/api_path.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/token_refresh_service.dart';
import '../../../../core/utils/storage_service.dart';
import '../models/create_group_request_model.dart';
import '../models/join_group_request_model.dart';

abstract class GroupRemoteDataSource {
  Future<BuyingGroup> createGroup({
    required CreateGroupRequestModel request,
    String? token,
  });

  Future<List<BuyingGroup>> getMyGroups({
    String? token,
  });

  Future<List<BuyingGroup>> getGroups({
    String? category,
    String? status,
    String? token,
  });

  Future<BuyingGroup> getGroupById({
    required String groupId,
    String? token,
  });

  Future<BuyingGroup> joinGroup({
    required String groupId,
    required JoinGroupRequestModel request,
    String? token,
  });

  Future<bool> leaveGroup({
    required String groupId,
    String? token,
  });

  Future<List<GroupMessage>> getGroupMessages({
    required String groupId,
    int page = 1,
    int limit = 50,
    String? token,
  });

  Future<GroupMessage> sendGroupMessage({
    required String groupId,
    required String message,
    String? token,
  });

  Future<Map<String, dynamic>> postDemandFromGroup({
    required String groupId,
    String? token,
  });
}

class GroupRemoteDataSourceImpl implements GroupRemoteDataSource {
  final HttpClient _client;

  /// Default fallback token from user cURL specification
  static const String defaultFallbackToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTI2MzQwMiwiZXhwIjoxNzk1MjY0MzAyfQ.bBzXkK-A8EKBmCnQytF6bCoDBKdcIGIHrtU5Pey6Yqw';

  GroupRemoteDataSourceImpl({HttpClient? client})
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
  Future<BuyingGroup> createGroup({
    required CreateGroupRequestModel request,
    String? token,
  }) async {
    final endpoint = ApiPath.groups;
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    String resolvedToken = await _resolveToken(token);
    final requestPayload = request.toJson();

    final headers = {
      'accept': '*/*',
      'Authorization': 'Bearer $resolvedToken',
      'Content-Type': 'application/json',
    };

    ApiLogger.logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: requestPayload,
    );

    try {
      var httpRequest = await _client.postUrl(uri);
      headers.forEach((key, value) => httpRequest.headers.set(key, value));

      final bodyBytes = utf8.encode(jsonEncode(requestPayload));
      httpRequest.contentLength = bodyBytes.length;
      httpRequest.add(bodyBytes);

      var httpResponse = await httpRequest.close();
      stopwatch.stop();

      var responseBody = await httpResponse.transform(utf8.decoder).join();
      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
      }

      // Handle 401 Token Expiry: auto-refresh and retry once
      if (httpResponse.statusCode == 401) {
        ApiLogger.logError(
          method: 'POST',
          uri: uri,
          statusCode: 401,
          duration: stopwatch.elapsed,
          error: 'Token has expired. Attempting automatic refresh...',
          body: responseBody,
        );

        final newToken = await _attemptRefreshToken();
        if (newToken != null && newToken.isNotEmpty) {
          resolvedToken = newToken;
          headers['Authorization'] = 'Bearer $resolvedToken';
          stopwatch.reset();
          stopwatch.start();

          httpRequest = await _client.postUrl(uri);
          headers.forEach((key, value) => httpRequest.headers.set(key, value));
          httpRequest.contentLength = bodyBytes.length;
          httpRequest.add(bodyBytes);

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

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        ApiLogger.logResponse(
          method: 'POST',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );

        if (decodedJson is Map<String, dynamic>) {
          if (decodedJson['data'] is Map<String, dynamic>) {
            return BuyingGroup.fromJson(decodedJson['data'] as Map<String, dynamic>);
          }
          if (decodedJson['group'] is Map<String, dynamic>) {
            return BuyingGroup.fromJson(decodedJson['group'] as Map<String, dynamic>);
          }
          return BuyingGroup.fromJson(decodedJson);
        }
        throw Exception('Unexpected response format when creating group: $responseBody');
      } else {
        final errorMsg = decodedJson is Map && decodedJson['error'] != null
            ? decodedJson['error'].toString()
            : decodedJson is Map && decodedJson['message'] != null
                ? decodedJson['message'].toString()
                : 'Failed to create group (Status: ${httpResponse.statusCode})';

        ApiLogger.logError(
          method: 'POST',
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
      if (e is! Exception || !e.toString().contains('Failed to create group')) {
        ApiLogger.logError(
          method: 'POST',
          uri: uri,
          statusCode: 0,
          duration: stopwatch.elapsed,
          error: e,
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<BuyingGroup>> getMyGroups({
    String? token,
  }) async {
    final endpoint = ApiPath.myGroups;
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    String resolvedToken = await _resolveToken(token);
    final headers = {
      'accept': '*/*',
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

      // Handle 401 Token Expiry
      if (httpResponse.statusCode == 401) {
        ApiLogger.logError(
          method: 'GET',
          uri: uri,
          statusCode: 401,
          duration: stopwatch.elapsed,
          error: 'Token has expired. Attempting automatic refresh...',
          body: responseBody,
        );

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

      if (httpResponse.statusCode == 200) {
        ApiLogger.logResponse(
          method: 'GET',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );

        return _parseGroupsList(decodedJson);
      } else {
        final errorMsg = decodedJson is Map && decodedJson['error'] != null
            ? decodedJson['error'].toString()
            : decodedJson is Map && decodedJson['message'] != null
                ? decodedJson['message'].toString()
                : 'Failed to fetch my groups (Status: ${httpResponse.statusCode})';

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
      if (e is! Exception || !e.toString().contains('Failed to fetch my groups')) {
        ApiLogger.logError(
          method: 'GET',
          uri: uri,
          statusCode: 0,
          duration: stopwatch.elapsed,
          error: e,
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<BuyingGroup>> getGroups({
    String? category,
    String? status,
    String? token,
  }) async {
    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty && category != 'All') {
      queryParams['category'] = category.toLowerCase();
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status.toLowerCase();
    }

    final baseUri = Uri.parse(ApiPath.groups);
    final uri = queryParams.isEmpty
        ? baseUri
        : baseUri.replace(queryParameters: queryParams);

    final stopwatch = Stopwatch()..start();
    String resolvedToken = await _resolveToken(token);

    final headers = {
      'accept': '*/*',
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

      if (httpResponse.statusCode == 200) {
        ApiLogger.logResponse(
          method: 'GET',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );

        return _parseGroupsList(decodedJson);
      } else {
        final errorMsg = decodedJson is Map && decodedJson['error'] != null
            ? decodedJson['error'].toString()
            : decodedJson is Map && decodedJson['message'] != null
                ? decodedJson['message'].toString()
                : 'Failed to fetch groups (Status: ${httpResponse.statusCode})';

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
  Future<BuyingGroup> getGroupById({
    required String groupId,
    String? token,
  }) async {
    final endpoint = ApiPath.groupById(groupId);
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    String resolvedToken = await _resolveToken(token);
    final headers = {
      'accept': '*/*',
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

      if (httpResponse.statusCode == 200) {
        ApiLogger.logResponse(
          method: 'GET',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );

        if (decodedJson is Map<String, dynamic>) {
          if (decodedJson['data'] is Map<String, dynamic>) {
            return BuyingGroup.fromJson(decodedJson['data'] as Map<String, dynamic>);
          }
          if (decodedJson['group'] is Map<String, dynamic>) {
            return BuyingGroup.fromJson(decodedJson['group'] as Map<String, dynamic>);
          }
          return BuyingGroup.fromJson(decodedJson);
        }
        throw Exception('Unexpected response format for group details: $responseBody');
      } else {
        final errorMsg = decodedJson is Map && decodedJson['error'] != null
            ? decodedJson['error'].toString()
            : 'Failed to fetch group details (Status: ${httpResponse.statusCode})';

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
  Future<BuyingGroup> joinGroup({
    required String groupId,
    required JoinGroupRequestModel request,
    String? token,
  }) async {
    final endpoint = ApiPath.joinGroup(groupId);
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    String resolvedToken = await _resolveToken(token);
    final requestPayload = request.toJson();

    final headers = {
      'accept': '*/*',
      'Authorization': 'Bearer $resolvedToken',
      'Content-Type': 'application/json',
    };

    ApiLogger.logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: requestPayload,
    );

    try {
      var httpRequest = await _client.postUrl(uri);
      headers.forEach((key, value) => httpRequest.headers.set(key, value));

      final bodyBytes = utf8.encode(jsonEncode(requestPayload));
      httpRequest.contentLength = bodyBytes.length;
      httpRequest.add(bodyBytes);

      var httpResponse = await httpRequest.close();
      stopwatch.stop();

      var responseBody = await httpResponse.transform(utf8.decoder).join();
      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
      }

      if (httpResponse.statusCode == 401) {
        final newToken = await _attemptRefreshToken();
        if (newToken != null && newToken.isNotEmpty) {
          resolvedToken = newToken;
          headers['Authorization'] = 'Bearer $resolvedToken';
          stopwatch.reset();
          stopwatch.start();

          httpRequest = await _client.postUrl(uri);
          headers.forEach((key, value) => httpRequest.headers.set(key, value));
          httpRequest.contentLength = bodyBytes.length;
          httpRequest.add(bodyBytes);

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

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        ApiLogger.logResponse(
          method: 'POST',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );

        if (decodedJson is Map<String, dynamic>) {
          if (decodedJson['data'] is Map<String, dynamic>) {
            return BuyingGroup.fromJson(decodedJson['data'] as Map<String, dynamic>);
          }
          if (decodedJson['group'] is Map<String, dynamic>) {
            return BuyingGroup.fromJson(decodedJson['group'] as Map<String, dynamic>);
          }
          if (decodedJson.containsKey('id') || decodedJson.containsKey('name')) {
            return BuyingGroup.fromJson(decodedJson);
          }
        }
        // If response is just a success message or membership, re-fetch group
        return await getGroupById(groupId: groupId, token: resolvedToken);
      } else {
        final errorMsg = decodedJson is Map && decodedJson['error'] != null
            ? decodedJson['error'].toString()
            : decodedJson is Map && decodedJson['message'] != null
                ? decodedJson['message'].toString()
                : 'Failed to join group (Status: ${httpResponse.statusCode})';

        ApiLogger.logError(
          method: 'POST',
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
  Future<bool> leaveGroup({
    required String groupId,
    String? token,
  }) async {
    final endpoint = ApiPath.leaveGroup(groupId);
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    String resolvedToken = await _resolveToken(token);
    final headers = {
      'accept': '*/*',
      'Authorization': 'Bearer $resolvedToken',
    };

    ApiLogger.logRequest(
      method: 'DELETE',
      uri: uri,
      headers: headers,
    );

    try {
      var httpRequest = await _client.deleteUrl(uri);
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

      if (httpResponse.statusCode == 401) {
        final newToken = await _attemptRefreshToken();
        if (newToken != null && newToken.isNotEmpty) {
          resolvedToken = newToken;
          headers['Authorization'] = 'Bearer $resolvedToken';
          stopwatch.reset();
          stopwatch.start();

          httpRequest = await _client.deleteUrl(uri);
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

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 204) {
        ApiLogger.logResponse(
          method: 'DELETE',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );
        return true;
      } else {
        final errorMsg = decodedJson is Map && decodedJson['error'] != null
            ? decodedJson['error'].toString()
            : decodedJson is Map && decodedJson['message'] != null
                ? decodedJson['message'].toString()
                : 'Failed to leave group (Status: ${httpResponse.statusCode})';

        ApiLogger.logError(
          method: 'DELETE',
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
  Future<List<GroupMessage>> getGroupMessages({
    required String groupId,
    int page = 1,
    int limit = 50,
    String? token,
  }) async {
    final baseUri = Uri.parse(ApiPath.groupMessages(groupId));
    final uri = baseUri.replace(queryParameters: {
      'page': '$page',
      'limit': '$limit',
    });
    final stopwatch = Stopwatch()..start();

    String resolvedToken = await _resolveToken(token);
    final headers = {
      'accept': '*/*',
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

      if (httpResponse.statusCode == 200) {
        ApiLogger.logResponse(
          method: 'GET',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );

        return _parseMessagesList(decodedJson, groupId);
      } else {
        final errorMsg = decodedJson is Map && decodedJson['error'] != null
            ? decodedJson['error'].toString()
            : decodedJson is Map && decodedJson['message'] != null
                ? decodedJson['message'].toString()
                : 'Failed to fetch messages (Status: ${httpResponse.statusCode})';

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
  Future<GroupMessage> sendGroupMessage({
    required String groupId,
    required String message,
    String? token,
  }) async {
    final endpoint = ApiPath.groupMessages(groupId);
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    String resolvedToken = await _resolveToken(token);
    final requestPayload = {
      'message': message.trim(),
    };

    final headers = {
      'accept': '*/*',
      'Authorization': 'Bearer $resolvedToken',
      'Content-Type': 'application/json',
    };

    ApiLogger.logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: requestPayload,
    );

    try {
      var httpRequest = await _client.postUrl(uri);
      headers.forEach((key, value) => httpRequest.headers.set(key, value));

      final bodyBytes = utf8.encode(jsonEncode(requestPayload));
      httpRequest.contentLength = bodyBytes.length;
      httpRequest.add(bodyBytes);

      var httpResponse = await httpRequest.close();
      stopwatch.stop();

      var responseBody = await httpResponse.transform(utf8.decoder).join();
      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
      }

      if (httpResponse.statusCode == 401) {
        final newToken = await _attemptRefreshToken();
        if (newToken != null && newToken.isNotEmpty) {
          resolvedToken = newToken;
          headers['Authorization'] = 'Bearer $resolvedToken';
          stopwatch.reset();
          stopwatch.start();

          httpRequest = await _client.postUrl(uri);
          headers.forEach((key, value) => httpRequest.headers.set(key, value));
          httpRequest.contentLength = bodyBytes.length;
          httpRequest.add(bodyBytes);

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

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        ApiLogger.logResponse(
          method: 'POST',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );

        if (decodedJson is Map<String, dynamic>) {
          if (decodedJson['data'] is Map<String, dynamic>) {
            return GroupMessage.fromJson(decodedJson['data'] as Map<String, dynamic>);
          }
          if (decodedJson['message'] is Map<String, dynamic>) {
            return GroupMessage.fromJson(decodedJson['message'] as Map<String, dynamic>);
          }
          if (decodedJson.containsKey('id') || decodedJson.containsKey('message')) {
            return GroupMessage.fromJson(decodedJson);
          }
        }

        return GroupMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          groupId: groupId,
          senderId: '',
          senderName: 'You',
          message: message,
          createdAt: DateTime.now(),
        );
      } else {
        final errorMsg = decodedJson is Map && decodedJson['error'] != null
            ? decodedJson['error'].toString()
            : decodedJson is Map && decodedJson['message'] != null
                ? decodedJson['message'].toString()
                : 'Failed to send message (Status: ${httpResponse.statusCode})';

        ApiLogger.logError(
          method: 'POST',
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
  Future<Map<String, dynamic>> postDemandFromGroup({
    required String groupId,
    String? token,
  }) async {
    final endpoint = ApiPath.postDemandFromGroup(groupId);
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    String resolvedToken = await _resolveToken(token);
    final headers = {
      'accept': '*/*',
      'Authorization': 'Bearer $resolvedToken',
      'Content-Type': 'application/json',
    };

    ApiLogger.logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: '',
    );

    try {
      var httpRequest = await _client.postUrl(uri);
      headers.forEach((key, value) => httpRequest.headers.set(key, value));
      httpRequest.write('');

      var httpResponse = await httpRequest.close();
      stopwatch.stop();

      var responseBody = await httpResponse.transform(utf8.decoder).join();
      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
      }

      if (httpResponse.statusCode == 401) {
        final newToken = await _attemptRefreshToken();
        if (newToken != null && newToken.isNotEmpty) {
          resolvedToken = newToken;
          headers['Authorization'] = 'Bearer $resolvedToken';
          stopwatch.reset();
          stopwatch.start();

          httpRequest = await _client.postUrl(uri);
          headers.forEach((key, value) => httpRequest.headers.set(key, value));
          httpRequest.write('');

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
          method: 'POST',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );

        if (decodedJson is Map<String, dynamic>) {
          return decodedJson;
        }

        return {
          'success': true,
          'message': 'Group successfully converted to demand post',
          'groupId': groupId,
        };
      } else {
        final errorMsg = decodedJson is Map && decodedJson['error'] != null
            ? decodedJson['error'].toString()
            : decodedJson is Map && decodedJson['message'] != null
                ? decodedJson['message'].toString()
                : 'Failed to convert group to demand post (Status: ${httpResponse.statusCode})';

        ApiLogger.logError(
          method: 'POST',
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

  List<GroupMessage> _parseMessagesList(dynamic decodedJson, String fallbackGroupId) {
    if (decodedJson == null) return [];
    if (decodedJson is List) {
      return decodedJson
          .map((e) => e is Map<String, dynamic> ? GroupMessage.fromJson(e) : null)
          .whereType<GroupMessage>()
          .toList();
    }
    if (decodedJson is Map<String, dynamic>) {
      if (decodedJson['data'] is List) {
        return (decodedJson['data'] as List)
            .map((e) => e is Map<String, dynamic> ? GroupMessage.fromJson(e) : null)
            .whereType<GroupMessage>()
            .toList();
      }
      if (decodedJson['messages'] is List) {
        return (decodedJson['messages'] as List)
            .map((e) => e is Map<String, dynamic> ? GroupMessage.fromJson(e) : null)
            .whereType<GroupMessage>()
            .toList();
      }
      if (decodedJson['data'] is Map && decodedJson['data']['messages'] is List) {
        return (decodedJson['data']['messages'] as List)
            .map((e) => e is Map<String, dynamic> ? GroupMessage.fromJson(e) : null)
            .whereType<GroupMessage>()
            .toList();
      }
      if (decodedJson['data'] is Map<String, dynamic>) {
        return [GroupMessage.fromJson(decodedJson['data'] as Map<String, dynamic>)];
      }
    }
    return [];
  }

  List<BuyingGroup> _parseGroupsList(dynamic decodedJson) {
    if (decodedJson == null) return [];
    if (decodedJson is List) {
      return decodedJson
          .map((e) => e is Map<String, dynamic> ? BuyingGroup.fromJson(e) : null)
          .whereType<BuyingGroup>()
          .toList();
    }
    if (decodedJson is Map<String, dynamic>) {
      if (decodedJson['data'] is List) {
        return (decodedJson['data'] as List)
            .map((e) => e is Map<String, dynamic> ? BuyingGroup.fromJson(e) : null)
            .whereType<BuyingGroup>()
            .toList();
      }
      if (decodedJson['groups'] is List) {
        return (decodedJson['groups'] as List)
            .map((e) => e is Map<String, dynamic> ? BuyingGroup.fromJson(e) : null)
            .whereType<BuyingGroup>()
            .toList();
      }
      if (decodedJson['data'] is Map && decodedJson['data']['groups'] is List) {
        return (decodedJson['data']['groups'] as List)
            .map((e) => e is Map<String, dynamic> ? BuyingGroup.fromJson(e) : null)
            .whereType<BuyingGroup>()
            .toList();
      }
      if (decodedJson['data'] is Map<String, dynamic>) {
        return [BuyingGroup.fromJson(decodedJson['data'] as Map<String, dynamic>)];
      }
    }
    return [];
  }
}
