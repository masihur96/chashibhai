import 'dart:convert';
import 'dart:io';

import '../../../../configs/network/api_logger.dart';
import '../../../../core/constants/api_path.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/storage_service.dart';
import '../models/create_product_request_model.dart';

abstract class FarmerRemoteDataSource {
  Future<Product> addProduct({
    required CreateProductRequestModel request,
    String? token,
  });
}

class FarmerRemoteDataSourceImpl implements FarmerRemoteDataSource {
  final HttpClient _client;

  /// Default fallback token from user curl specification
  static const String defaultFallbackToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5MmY2ODM5YS01ZDBjLTQwYTctYmQ5Mi1hNTA4MGNkOGIwNzAiLCJwaG9uZSI6Ijg4MDE3NDA3MTkyMDUiLCJlbWFpbCI6IiIsInJvbGUiOiJmYXJtZXIiLCJpYXQiOjE3OTUwMTYwNzMsImV4cCI6MTc5NTAxNjk3M30.R_asblBCluelVCEcIPveOiojYkgQawjzVfup2qyCMw4';

  FarmerRemoteDataSourceImpl({HttpClient? client})
      : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 15);
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
      headers.forEach((key, value) => httpRequest.headers.set(key, value));

      final bodyString = jsonEncode(requestPayload);
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
