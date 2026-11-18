import 'dart:convert';
import 'dart:io';
import '../../../../core/constants/api_path.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> register(RegisterRequestModel request);
  Future<UserModel> login(LoginRequestModel request);
  Future<UserModel> getMe(String token);
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

    try {
      final httpRequest = await _client.postUrl(uri);

      // Set request headers matching curl
      httpRequest.headers.set(HttpHeaders.acceptHeader, '*/*');
      httpRequest.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );

      // Write body
      final bodyString = jsonEncode(request.toJson());
      httpRequest.write(bodyString);

      final httpResponse = await httpRequest.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
      }

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
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
        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      throw Exception(
        'Cannot connect to server at ${uri.host}:${uri.port} ($e). Please check if your backend server is running on localhost:3000.',
      );
    } on HandshakeException catch (e) {
      throw Exception('SSL Handshake error: $e');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<UserModel> login(LoginRequestModel request) async {
    final endpoint = ApiPath.login;
    final uri = Uri.parse(endpoint);

    try {
      final httpRequest = await _client.postUrl(uri);

      // Set request headers matching curl
      httpRequest.headers.set(HttpHeaders.acceptHeader, '*/*');
      httpRequest.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );

      // Write body
      final bodyString = jsonEncode(request.toJson());
      httpRequest.write(bodyString);

      final httpResponse = await httpRequest.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
      }

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
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
        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      throw Exception(
        'Cannot connect to server at ${uri.host}:${uri.port} ($e). Please check if your backend server is running on localhost:3000.',
      );
    } on HandshakeException catch (e) {
      throw Exception('SSL Handshake error: $e');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<UserModel> getMe(String token) async {
    final endpoint = ApiPath.me;
    final uri = Uri.parse(endpoint);

    try {
      final httpRequest = await _client.getUrl(uri);

      // Set request headers matching curl
      httpRequest.headers.set(HttpHeaders.acceptHeader, '*/*');
      httpRequest.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');

      final httpResponse = await httpRequest.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
      }

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        if (decodedJson is Map<String, dynamic>) {
          return UserModel.fromJson(decodedJson, token);
        } else {
          throw Exception('Invalid response format from /auth/me');
        }
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
        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      throw Exception(
        'Cannot connect to server at ${uri.host}:${uri.port} ($e). Please check if your backend server is running on localhost:3000.',
      );
    } on HandshakeException catch (e) {
      throw Exception('SSL Handshake error: $e');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }
}
