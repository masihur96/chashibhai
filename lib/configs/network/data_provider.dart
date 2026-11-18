import 'package:flutter/foundation.dart';

abstract class DataProvider {
  Future<dynamic> get(String endpoint, {Map<String, String>? headers, Map<String, dynamic>? queryParameters});
  Future<dynamic> post(String endpoint, {dynamic body, Map<String, String>? headers});
  Future<dynamic> put(String endpoint, {dynamic body, Map<String, String>? headers});
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers});
}

class DefaultDataProvider implements DataProvider {
  final String baseUrl;

  DefaultDataProvider({this.baseUrl = ''});

  @override
  Future<dynamic> get(String endpoint, {Map<String, String>? headers, Map<String, dynamic>? queryParameters}) async {
    debugPrint('GET: $baseUrl$endpoint with query: $queryParameters');
    return null;
  }

  @override
  Future<dynamic> post(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    debugPrint('POST: $baseUrl$endpoint with body: $body');
    return null;
  }

  @override
  Future<dynamic> put(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    debugPrint('PUT: $baseUrl$endpoint with body: $body');
    return null;
  }

  @override
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    debugPrint('DELETE: $baseUrl$endpoint');
    return null;
  }
}
