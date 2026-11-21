import 'dart:convert';
import 'dart:io';
import 'api_logger.dart';

abstract class DataProvider {
  Future<dynamic> get(String endpoint, {Map<String, String>? headers, Map<String, dynamic>? queryParameters});
  Future<dynamic> post(String endpoint, {dynamic body, Map<String, String>? headers});
  Future<dynamic> put(String endpoint, {dynamic body, Map<String, String>? headers});
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers});
}

class DefaultDataProvider implements DataProvider {
  final String baseUrl;
  final HttpClient _client;

  DefaultDataProvider({this.baseUrl = '', HttpClient? client})
      : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 15);
  }

  @override
  Future<dynamic> get(String endpoint, {Map<String, String>? headers, Map<String, dynamic>? queryParameters}) async {
    String url = '$baseUrl$endpoint';
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParameters).query;
      url = '$url?$queryString';
    }

    final uri = Uri.parse(url);
    final stopwatch = Stopwatch()..start();

    ApiLogger.logRequest(method: 'GET', uri: uri, headers: headers);

    try {
      final request = await _client.getUrl(uri);
      headers?.forEach((key, value) => request.headers.set(key, value));

      final response = await request.close();
      stopwatch.stop();

      final responseBody = await response.transform(utf8.decoder).join();
      dynamic decoded;
      try {
        decoded = jsonDecode(responseBody);
      } catch (_) {
        decoded = responseBody;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ApiLogger.logResponse(
          method: 'GET',
          uri: uri,
          statusCode: response.statusCode,
          duration: stopwatch.elapsed,
          body: decoded,
        );
        return decoded;
      } else {
        ApiLogger.logError(
          method: 'GET',
          uri: uri,
          statusCode: response.statusCode,
          duration: stopwatch.elapsed,
          body: decoded,
        );
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'GET', uri: uri, duration: stopwatch.elapsed, error: e);
      rethrow;
    }
  }

  @override
  Future<dynamic> post(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final stopwatch = Stopwatch()..start();

    ApiLogger.logRequest(method: 'POST', uri: uri, headers: headers, body: body);

    try {
      final request = await _client.postUrl(uri);
      headers?.forEach((key, value) => request.headers.set(key, value));
      if (!request.headers.value(HttpHeaders.contentTypeHeader)!.contains('application/json')) {
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      }

      if (body != null) {
        final bodyStr = body is String ? body : jsonEncode(body);
        final bodyBytes = utf8.encode(bodyStr);
        request.contentLength = bodyBytes.length;
        request.add(bodyBytes);
      }

      final response = await request.close();
      stopwatch.stop();

      final responseBody = await response.transform(utf8.decoder).join();
      dynamic decoded;
      try {
        decoded = jsonDecode(responseBody);
      } catch (_) {
        decoded = responseBody;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ApiLogger.logResponse(
          method: 'POST',
          uri: uri,
          statusCode: response.statusCode,
          duration: stopwatch.elapsed,
          body: decoded,
        );
        return decoded;
      } else {
        ApiLogger.logError(
          method: 'POST',
          uri: uri,
          statusCode: response.statusCode,
          duration: stopwatch.elapsed,
          body: decoded,
        );
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'POST', uri: uri, duration: stopwatch.elapsed, error: e);
      rethrow;
    }
  }

  @override
  Future<dynamic> put(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final stopwatch = Stopwatch()..start();

    ApiLogger.logRequest(method: 'PUT', uri: uri, headers: headers, body: body);

    try {
      final request = await _client.putUrl(uri);
      headers?.forEach((key, value) => request.headers.set(key, value));

      if (body != null) {
        final bodyStr = body is String ? body : jsonEncode(body);
        final bodyBytes = utf8.encode(bodyStr);
        request.contentLength = bodyBytes.length;
        request.add(bodyBytes);
      }

      final response = await request.close();
      stopwatch.stop();

      final responseBody = await response.transform(utf8.decoder).join();
      dynamic decoded;
      try {
        decoded = jsonDecode(responseBody);
      } catch (_) {
        decoded = responseBody;
      }

      ApiLogger.logResponse(
        method: 'PUT',
        uri: uri,
        statusCode: response.statusCode,
        duration: stopwatch.elapsed,
        body: decoded,
      );
      return decoded;
    } catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'PUT', uri: uri, duration: stopwatch.elapsed, error: e);
      rethrow;
    }
  }

  @override
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final stopwatch = Stopwatch()..start();

    ApiLogger.logRequest(method: 'DELETE', uri: uri, headers: headers);

    try {
      final request = await _client.deleteUrl(uri);
      headers?.forEach((key, value) => request.headers.set(key, value));

      final response = await request.close();
      stopwatch.stop();

      final responseBody = await response.transform(utf8.decoder).join();
      dynamic decoded;
      try {
        decoded = jsonDecode(responseBody);
      } catch (_) {
        decoded = responseBody;
      }

      ApiLogger.logResponse(
        method: 'DELETE',
        uri: uri,
        statusCode: response.statusCode,
        duration: stopwatch.elapsed,
        body: decoded,
      );
      return decoded;
    } catch (e) {
      stopwatch.stop();
      ApiLogger.logError(method: 'DELETE', uri: uri, duration: stopwatch.elapsed, error: e);
      rethrow;
    }
  }
}
