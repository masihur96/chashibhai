import 'dart:convert';
import 'dart:io';
import '../../../../configs/network/api_logger.dart';
import '../../../../core/constants/api_path.dart';
import '../models/login_request_model.dart';
import '../models/refresh_token_request_model.dart';
import '../models/register_request_model.dart';
import '../models/token_model.dart';
import '../models/user_model.dart';

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException([this.message = 'Access token expired or unauthorized']);
  @override
  String toString() => message;
}

abstract class AuthRemoteDataSource {
  Future<UserModel> register(RegisterRequestModel request);
  Future<UserModel> login(LoginRequestModel request);
  Future<UserModel> getMe(String token);
  Future<TokenModel> refreshToken(RefreshTokenRequestModel request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final HttpClient _client;

  AuthRemoteDataSourceImpl({HttpClient? client})
      : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 15);
  }

  @override
  Future<UserModel> register(RegisterRequestModel request) async {
    final endpoint = ApiPath.register;
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    final headers = {
      'accept': '*/*',
      'Content-Type': 'application/json; charset=utf-8',
    };

    ApiLogger.logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: request.toJson(),
    );

    try {
      final httpRequest = await _client.postUrl(uri);
      headers.forEach((key, value) => httpRequest.headers.set(key, value));

      final bodyString = jsonEncode(request.toJson());
      httpRequest.write(bodyString);

      final httpResponse = await httpRequest.close();
      stopwatch.stop();

      final responseBody = await httpResponse.transform(utf8.decoder).join();

      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
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
          return UserModel.fromJson(decodedJson);
        } else {
          return UserModel(
            name: request.name,
            phone: request.phone,
            role: request.role,
          );
        }
      } else {
        String errorMessage =
            'Registration failed with status code ${httpResponse.statusCode}';
        if (decodedJson is Map<String, dynamic>) {
          errorMessage = decodedJson['message']?.toString() ??
              decodedJson['error']?.toString() ??
              decodedJson['detail']?.toString() ??
              errorMessage;
        } else if (responseBody.isNotEmpty) {
          errorMessage = responseBody;
        }

        ApiLogger.logError(
          method: 'POST',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          error: errorMessage,
          body: decodedJson ?? responseBody,
        );

        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      final err = 'Cannot connect to server at ${uri.host}:${uri.port} ($e). Please check if backend is running on localhost:3000.';
      ApiLogger.logError(method: 'POST', uri: uri, duration: stopwatch.elapsed, error: err);
      throw Exception(err);
    } catch (e) {
      stopwatch.stop();
      if (e is! Exception) {
        ApiLogger.logError(method: 'POST', uri: uri, duration: stopwatch.elapsed, error: e);
      }
      rethrow;
    }
  }

  @override
  Future<UserModel> login(LoginRequestModel request) async {
    final endpoint = ApiPath.login;
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    final headers = {
      'accept': '*/*',
      'Content-Type': 'application/json; charset=utf-8',
    };

    ApiLogger.logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: request.toJson(),
    );

    try {
      final httpRequest = await _client.postUrl(uri);
      headers.forEach((key, value) => httpRequest.headers.set(key, value));

      final bodyString = jsonEncode(request.toJson());
      httpRequest.write(bodyString);

      final httpResponse = await httpRequest.close();
      stopwatch.stop();

      final responseBody = await httpResponse.transform(utf8.decoder).join();

      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
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
          return UserModel.fromJson(decodedJson);
        } else {
          return UserModel(
            name: 'User',
            phone: request.phone,
            role: 'BUYER',
          );
        }
      } else {
        String errorMessage =
            'Login failed with status code ${httpResponse.statusCode}';
        if (decodedJson is Map<String, dynamic>) {
          errorMessage = decodedJson['message']?.toString() ??
              decodedJson['error']?.toString() ??
              decodedJson['detail']?.toString() ??
              errorMessage;
        } else if (responseBody.isNotEmpty) {
          errorMessage = responseBody;
        }

        ApiLogger.logError(
          method: 'POST',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          error: errorMessage,
          body: decodedJson ?? responseBody,
        );

        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      final err = 'Cannot connect to server at ${uri.host}:${uri.port} ($e). Please check if backend is running on localhost:3000.';
      ApiLogger.logError(method: 'POST', uri: uri, duration: stopwatch.elapsed, error: err);
      throw Exception(err);
    } catch (e) {
      stopwatch.stop();
      if (e is! Exception) {
        ApiLogger.logError(method: 'POST', uri: uri, duration: stopwatch.elapsed, error: e);
      }
      rethrow;
    }
  }

  @override
  Future<UserModel> getMe(String token) async {
    final endpoint = ApiPath.me;
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    final headers = {
      'accept': '*/*',
      'Authorization': 'Bearer $token',
    };

    ApiLogger.logRequest(
      method: 'GET',
      uri: uri,
      headers: headers,
    );

    try {
      final httpRequest = await _client.getUrl(uri);
      headers.forEach((key, value) => httpRequest.headers.set(key, value));

      final httpResponse = await httpRequest.close();
      stopwatch.stop();

      final responseBody = await httpResponse.transform(utf8.decoder).join();

      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
      }

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        ApiLogger.logResponse(
          method: 'GET',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );

        if (decodedJson is Map<String, dynamic>) {
          return UserModel.fromJson(decodedJson, token);
        } else {
          throw Exception('Invalid response format from /auth/me');
        }
      } else if (httpResponse.statusCode == 401) {
        ApiLogger.logError(
          method: 'GET',
          uri: uri,
          statusCode: 401,
          duration: stopwatch.elapsed,
          error: 'Access token expired or unauthorized (HTTP 401)',
          body: decodedJson ?? responseBody,
        );
        throw TokenExpiredException('Access token expired or unauthorized (HTTP 401)');
      } else {
        String errorMessage =
            'Failed to fetch user with status ${httpResponse.statusCode}';
        if (decodedJson is Map<String, dynamic>) {
          errorMessage = decodedJson['message']?.toString() ??
              decodedJson['error']?.toString() ??
              decodedJson['detail']?.toString() ??
              errorMessage;
        } else if (responseBody.isNotEmpty) {
          errorMessage = responseBody;
        }

        ApiLogger.logError(
          method: 'GET',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          error: errorMessage,
          body: decodedJson ?? responseBody,
        );

        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      final err = 'Cannot connect to server at ${uri.host}:${uri.port} ($e). Please check if backend is running on localhost:3000.';
      ApiLogger.logError(method: 'GET', uri: uri, duration: stopwatch.elapsed, error: err);
      throw Exception(err);
    } catch (e) {
      stopwatch.stop();
      if (e is! Exception) {
        ApiLogger.logError(method: 'GET', uri: uri, duration: stopwatch.elapsed, error: e);
      }
      rethrow;
    }
  }

  @override
  Future<TokenModel> refreshToken(RefreshTokenRequestModel request) async {
    final endpoint = ApiPath.refresh;
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    final headers = {
      'accept': '*/*',
      'Content-Type': 'application/json; charset=utf-8',
    };

    ApiLogger.logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: request.toJson(),
    );

    try {
      final httpRequest = await _client.postUrl(uri);
      headers.forEach((key, value) => httpRequest.headers.set(key, value));

      final bodyString = jsonEncode(request.toJson());
      httpRequest.write(bodyString);

      final httpResponse = await httpRequest.close();
      stopwatch.stop();

      final responseBody = await httpResponse.transform(utf8.decoder).join();

      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
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
          return TokenModel.fromJson(decodedJson, request.refreshToken);
        } else {
          throw Exception('Invalid response format from /auth/refresh');
        }
      } else {
        String errorMessage =
            'Token refresh failed with status code ${httpResponse.statusCode}';
        if (decodedJson is Map<String, dynamic>) {
          errorMessage = decodedJson['message']?.toString() ??
              decodedJson['error']?.toString() ??
              decodedJson['detail']?.toString() ??
              errorMessage;
        } else if (responseBody.isNotEmpty) {
          errorMessage = responseBody;
        }

        ApiLogger.logError(
          method: 'POST',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          error: errorMessage,
          body: decodedJson ?? responseBody,
        );

        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      final err = 'Cannot connect to server at ${uri.host}:${uri.port} ($e). Please check if backend is running on localhost:3000.';
      ApiLogger.logError(method: 'POST', uri: uri, duration: stopwatch.elapsed, error: err);
      throw Exception(err);
    } catch (e) {
      stopwatch.stop();
      if (e is! Exception) {
        ApiLogger.logError(method: 'POST', uri: uri, duration: stopwatch.elapsed, error: e);
      }
      rethrow;
    }
  }
}
