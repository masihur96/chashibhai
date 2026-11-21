import 'dart:convert';
import 'dart:io';

import '../../../../configs/network/api_logger.dart';
import '../../../../core/constants/api_path.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/token_refresh_service.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/utils/storage_service.dart';
import '../models/create_product_request_model.dart';
import '../models/update_product_request_model.dart';

abstract class FarmerRemoteDataSource {
  Future<Product> addProduct({
    required CreateProductRequestModel request,
    String? token,
  });

  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  });

  Future<List<Product>> getMyProducts({
    int page = 1,
    int limit = 10,
    String? status,
    String? category,
    String? tradeType,
    double? minPrice,
    double? maxPrice,
    String? search,
    String? token,
  });

  Future<Product> getProductById({
    required String id,
    String? token,
  });

  Future<Product> updateProduct({
    required String id,
    required UpdateProductRequestModel request,
    String? token,
  });

  Future<bool> deleteProduct({
    required String id,
    String? token,
  });
}

class FarmerRemoteDataSourceImpl implements FarmerRemoteDataSource {
  final HttpClient _client;
  final UploadService _uploadService;

  /// Default fallback token from user curl specification
  static const String defaultFallbackToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5MmY2ODM5YS01ZDBjLTQwYTctYmQ5Mi1hNTA4MGNkOGIwNzAiLCJwaG9uZSI6Ijg4MDE3NDA3MTkyMDUiLCJlbWFpbCI6IiIsInJvbGUiOiJmYXJtZXIiLCJpYXQiOjE3OTUwMTgxNTMsImV4cCI6MTc5NTAxOTA1M30.RS_3yAvrKK79heeVSxEnF5qUprg0B1JVSudMO3zA5Yo';

  FarmerRemoteDataSourceImpl({HttpClient? client, UploadService? uploadService})
      : _client = client ?? HttpClient(),
        _uploadService = uploadService ?? UploadService(client: client) {
    _client.connectionTimeout = const Duration(seconds: 15);
  }

  @override
  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  }) async {
    return await _uploadService.uploadFiles(
      items: files,
      token: token,
    );
  }

  @override
  Future<Product> addProduct({
    required CreateProductRequestModel request,
    String? token,
  }) async {
    final endpoint = ApiPath.products;
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    // Resolve bearer token: explicit param -> StorageService -> default fallback token
    String? resolvedToken = token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = await StorageService().getAccessToken();
    }
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = defaultFallbackToken;
    }

    final headers = {
      'accept': 'application/json',
      'Authorization': 'Bearer $resolvedToken',
      'Content-Type': 'application/json; charset=utf-8',
    };

    final requestPayload = request.toJson();

    ApiLogger.logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: requestPayload,
    );

    try {
      final httpRequest = await _client.postUrl(uri);
      httpRequest.encoding = utf8;
      headers.forEach((key, value) => httpRequest.headers.set(key, value));

      final bodyBytes = utf8.encode(jsonEncode(requestPayload));
      httpRequest.contentLength = bodyBytes.length;
      httpRequest.add(bodyBytes);

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
          final productMap = decodedJson['data'] is Map<String, dynamic>
              ? decodedJson['data'] as Map<String, dynamic>
              : (decodedJson['product'] is Map<String, dynamic>
                  ? decodedJson['product'] as Map<String, dynamic>
                  : decodedJson);

          return Product.fromJson(productMap);
        } else {
          return Product(
            id: 'p_${DateTime.now().millisecondsSinceEpoch}',
            farmerId: 'farmer_current',
            productName: request.productName,
            imageUrl: request.imageUrl,
            quantity: request.quantity,
            unit: request.unit,
            minimumPrice: request.minimumPrice,
            tradeType: _parseTradeType(request.tradeType),
            startTime: request.startTime,
            endTime: request.endTime,
            category: request.category,
            status: 'active',
          );
        }
      } else if (httpResponse.statusCode == 401) {
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await addProduct(
              request: request,
              token: refreshedToken,
            );
          }
        }

        String errorMessage = 'Unauthorized or token expired';
        if (decodedJson is Map<String, dynamic>) {
          errorMessage = decodedJson['error']?.toString() ??
              decodedJson['message']?.toString() ??
              errorMessage;
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
      } else {
        String errorMessage =
            'Failed to add product (Status code ${httpResponse.statusCode})';
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
      final err =
          'Cannot connect to server at ${uri.host}:${uri.port} ($e). Please check if backend is running.';
      ApiLogger.logError(
        method: 'POST',
        uri: uri,
        duration: stopwatch.elapsed,
        error: err,
      );
      throw Exception(err);
    } catch (e) {
      stopwatch.stop();
      if (e is! Exception) {
        ApiLogger.logError(
          method: 'POST',
          uri: uri,
          duration: stopwatch.elapsed,
          error: e,
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<Product>> getMyProducts({
    int page = 1,
    int limit = 10,
    String? status,
    String? category,
    String? tradeType,
    double? minPrice,
    double? maxPrice,
    String? search,
    String? token,
  }) async {
    final endpoint = ApiPath.myProducts;
    final baseUri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    final queryParameters = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (category != null && category.isNotEmpty) {
      queryParameters['category'] = category;
    }
    if (tradeType != null && tradeType.isNotEmpty) {
      queryParameters['tradeType'] = tradeType;
      queryParameters['trade_type'] = tradeType;
    }
    if (minPrice != null) {
      queryParameters['minPrice'] = minPrice.toString();
      queryParameters['min_price'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParameters['maxPrice'] = maxPrice.toString();
      queryParameters['max_price'] = maxPrice.toString();
    }
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    final uri = baseUri.replace(queryParameters: queryParameters);

    // Resolve bearer token: explicit param -> StorageService -> default fallback token
    String? resolvedToken = token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = await StorageService().getAccessToken();
    }
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = defaultFallbackToken;
    }

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

        final List<Product> products = [];
        if (decodedJson is Map<String, dynamic>) {
          final data = decodedJson['data'];
          if (data is List) {
            for (final item in data) {
              if (item is Map<String, dynamic>) {
                products.add(Product.fromJson(item));
              }
            }
          } else if (decodedJson['products'] is List) {
            for (final item in decodedJson['products']) {
              if (item is Map<String, dynamic>) {
                products.add(Product.fromJson(item));
              }
            }
          }
        } else if (decodedJson is List) {
          for (final item in decodedJson) {
            if (item is Map<String, dynamic>) {
              products.add(Product.fromJson(item));
            }
          }
        }
        return products;
      } else if (httpResponse.statusCode == 401) {
        // Attempt to refresh token if a refresh token is saved in Hive
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await getMyProducts(
              page: page,
              limit: limit,
              status: status,
              category: category,
              tradeType: tradeType,
              minPrice: minPrice,
              maxPrice: maxPrice,
              search: search,
              token: refreshedToken,
            );
          }
        }

        String errorMessage = 'Unauthorized or token expired';
        if (decodedJson is Map<String, dynamic>) {
          errorMessage = decodedJson['error']?.toString() ??
              decodedJson['message']?.toString() ??
              errorMessage;
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
      } else {
        String errorMessage =
            'Failed to fetch products (Status code ${httpResponse.statusCode})';
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
      final err =
          'Cannot connect to server at ${uri.host}:${uri.port} ($e). Please check if backend is running.';
      ApiLogger.logError(
        method: 'GET',
        uri: uri,
        duration: stopwatch.elapsed,
        error: err,
      );
      throw Exception(err);
    } catch (e) {
      stopwatch.stop();
      if (e is! Exception) {
        ApiLogger.logError(
          method: 'GET',
          uri: uri,
          duration: stopwatch.elapsed,
          error: e,
        );
      }
      rethrow;
    }
  }

  @override
  Future<Product> getProductById({
    required String id,
    String? token,
  }) async {
    final endpoint = ApiPath.productById(id);
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    String? resolvedToken = token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = await StorageService().getAccessToken();
    }

    final headers = <String, String>{
      'accept': '*/*',
    };
    if (resolvedToken != null && resolvedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $resolvedToken';
    }

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
          final productMap = decodedJson['data'] is Map<String, dynamic>
              ? decodedJson['data'] as Map<String, dynamic>
              : (decodedJson['product'] is Map<String, dynamic>
                  ? decodedJson['product'] as Map<String, dynamic>
                  : decodedJson);
          return Product.fromJson(productMap);
        } else {
          throw Exception('Invalid product data response');
        }
      } else if (httpResponse.statusCode == 401) {
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await getProductById(
              id: id,
              token: refreshedToken,
            );
          }
        }

        String errorMessage = 'Unauthorized or token expired';
        if (decodedJson is Map<String, dynamic>) {
          errorMessage = decodedJson['error']?.toString() ??
              decodedJson['message']?.toString() ??
              errorMessage;
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
      } else {
        String errorMessage =
            'Failed to fetch product (Status code ${httpResponse.statusCode})';
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
      final err =
          'Cannot connect to server at ${uri.host}:${uri.port} ($e). Please check if backend is running.';
      ApiLogger.logError(
        method: 'GET',
        uri: uri,
        duration: stopwatch.elapsed,
        error: err,
      );
      throw Exception(err);
    } catch (e) {
      stopwatch.stop();
      if (e is! Exception) {
        ApiLogger.logError(
          method: 'GET',
          uri: uri,
          duration: stopwatch.elapsed,
          error: e,
        );
      }
      rethrow;
    }
  }

  @override
  Future<Product> updateProduct({
    required String id,
    required UpdateProductRequestModel request,
    String? token,
  }) async {
    final endpoint = ApiPath.productById(id);
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    String? resolvedToken = token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = await StorageService().getAccessToken();
    }
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = defaultFallbackToken;
    }

    final headers = {
      'accept': '*/*',
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (resolvedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $resolvedToken';
    }

    final requestPayload = request.toJson();

    ApiLogger.logRequest(
      method: 'PATCH',
      uri: uri,
      headers: headers,
      body: requestPayload,
    );

    try {
      final httpRequest = await _client.openUrl('PATCH', uri);
      httpRequest.encoding = utf8;
      headers.forEach((key, value) => httpRequest.headers.set(key, value));

      final bodyBytes = utf8.encode(jsonEncode(requestPayload));
      httpRequest.contentLength = bodyBytes.length;
      httpRequest.add(bodyBytes);

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
          method: 'PATCH',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );

        if (decodedJson is Map<String, dynamic>) {
          final productMap = decodedJson['data'] is Map<String, dynamic>
              ? decodedJson['data'] as Map<String, dynamic>
              : (decodedJson['product'] is Map<String, dynamic>
                  ? decodedJson['product'] as Map<String, dynamic>
                  : decodedJson);

          return Product.fromJson(productMap);
        } else {
          return Product(
            id: id,
            farmerId: 'farmer_current',
            productName: request.productName,
            imageUrl: request.imageUrl,
            imageUrls: request.imageUrls ?? [request.imageUrl],
            quantity: request.quantity,
            unit: request.unit,
            minimumPrice: request.minimumPrice,
            tradeType: _parseTradeType(request.tradeType),
            startTime: request.startTime,
            endTime: request.endTime,
            category: request.category,
            status: request.status,
          );
        }
      } else if (httpResponse.statusCode == 401) {
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await updateProduct(
              id: id,
              request: request,
              token: refreshedToken,
            );
          }
        }

        String errorMessage = 'Unauthorized or token expired';
        if (decodedJson is Map<String, dynamic>) {
          errorMessage = decodedJson['error']?.toString() ??
              decodedJson['message']?.toString() ??
              errorMessage;
        }

        ApiLogger.logError(
          method: 'PATCH',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          error: errorMessage,
          body: decodedJson ?? responseBody,
        );

        throw Exception(errorMessage);
      } else {
        String errorMessage =
            'Failed to update product (Status code ${httpResponse.statusCode})';
        if (decodedJson is Map<String, dynamic>) {
          errorMessage = decodedJson['message']?.toString() ??
              decodedJson['error']?.toString() ??
              decodedJson['detail']?.toString() ??
              errorMessage;
        } else if (responseBody.isNotEmpty) {
          errorMessage = responseBody;
        }

        ApiLogger.logError(
          method: 'PATCH',
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
      final err =
          'Cannot connect to server at ${uri.host}:${uri.port} ($e). Please check if backend is running.';
      ApiLogger.logError(
        method: 'PATCH',
        uri: uri,
        duration: stopwatch.elapsed,
        error: err,
      );
      throw Exception(err);
    } catch (e) {
      stopwatch.stop();
      if (e is! Exception) {
        ApiLogger.logError(
          method: 'PATCH',
          uri: uri,
          duration: stopwatch.elapsed,
          error: e,
        );
      }
      rethrow;
    }
  }

  @override
  Future<bool> deleteProduct({
    required String id,
    String? token,
  }) async {
    final endpoint = ApiPath.productById(id);
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    String? resolvedToken = token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = await StorageService().getAccessToken();
    }
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = defaultFallbackToken;
    }

    final headers = {
      'accept': '*/*',
    };
    if (resolvedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $resolvedToken';
    }

    ApiLogger.logRequest(
      method: 'DELETE',
      uri: uri,
      headers: headers,
    );

    try {
      final httpRequest = await _client.deleteUrl(uri);
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

      if (httpResponse.statusCode == 200 ||
          httpResponse.statusCode == 201 ||
          httpResponse.statusCode == 204) {
        ApiLogger.logResponse(
          method: 'DELETE',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );
        return true;
      } else if (httpResponse.statusCode == 401) {
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await deleteProduct(
              id: id,
              token: refreshedToken,
            );
          }
        }

        String errorMessage = 'Unauthorized or token expired';
        if (decodedJson is Map<String, dynamic>) {
          errorMessage = decodedJson['error']?.toString() ??
              decodedJson['message']?.toString() ??
              errorMessage;
        }

        ApiLogger.logError(
          method: 'DELETE',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          error: errorMessage,
          body: decodedJson ?? responseBody,
        );

        throw Exception(errorMessage);
      } else {
        String errorMessage =
            'Failed to delete product (Status code ${httpResponse.statusCode})';
        if (decodedJson is Map<String, dynamic>) {
          errorMessage = decodedJson['message']?.toString() ??
              decodedJson['error']?.toString() ??
              decodedJson['detail']?.toString() ??
              errorMessage;
        } else if (responseBody.isNotEmpty) {
          errorMessage = responseBody;
        }

        ApiLogger.logError(
          method: 'DELETE',
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
      final err =
          'Cannot connect to server at ${uri.host}:${uri.port} ($e). Please check if backend is running.';
      ApiLogger.logError(
        method: 'DELETE',
        uri: uri,
        duration: stopwatch.elapsed,
        error: err,
      );
      throw Exception(err);
    } catch (e) {
      stopwatch.stop();
      if (e is! Exception) {
        ApiLogger.logError(
          method: 'DELETE',
          uri: uri,
          duration: stopwatch.elapsed,
          error: e,
        );
      }
      rethrow;
    }
  }

  Future<String?> _attemptRefreshToken(String refreshToken) async {
    try {
      return await TokenRefreshManager().refresh(
        explicitRefreshToken: refreshToken,
        client: _client,
      );
    } catch (_) {}
    return null;
  }

  TradeType _parseTradeType(String type) {
    switch (type.toLowerCase()) {
      case 'auction':
        return TradeType.auction;
      case 'negotiation':
        return TradeType.negotiation;
      case 'both':
      default:
        return TradeType.both;
    }
  }
}
