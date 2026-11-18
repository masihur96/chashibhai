import 'dart:convert';
import 'dart:io';

import '../../../../configs/network/api_logger.dart';
import '../../../../core/constants/api_path.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/utils/storage_service.dart';
import '../models/create_demand_request_model.dart';

abstract class BuyerRemoteDataSource {
  Future<DemandPost> createDemand({
    required CreateDemandRequestModel request,
    String? token,
  });

  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  });
}

class BuyerRemoteDataSourceImpl implements BuyerRemoteDataSource {
  final HttpClient _client;
  final UploadService _uploadService;

  /// Default fallback token from curl specification
  static const String defaultFallbackToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5MmY2ODM5YS01ZDBjLTQwYTctYmQ5Mi1hNTA4MGNkOGIwNzAiLCJwaG9uZSI6Ijg4MDE3NDA3MTkyMDUiLCJlbWFpbCI6IiIsInJvbGUiOiJmYXJtZXIiLCJpYXQiOjE3OTUwMTgxNTMsImV4cCI6MTc5NTAxOTA1M30.RS_3yAvrKK79heeVSxEnF5qUprg0B1JVSudMO3zA5Yo';

  BuyerRemoteDataSourceImpl({HttpClient? client, UploadService? uploadService})
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
  Future<DemandPost> createDemand({
    required CreateDemandRequestModel request,
    String? token,
  }) async {
    final endpoint = ApiPath.demands;
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
      'accept': '*/*',
      'Authorization': 'Bearer $resolvedToken',
      'Content-Type': 'application/json',
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
          final demandMap = decodedJson['data'] is Map<String, dynamic>
              ? decodedJson['data'] as Map<String, dynamic>
              : (decodedJson['demand'] is Map<String, dynamic>
                  ? decodedJson['demand'] as Map<String, dynamic>
                  : decodedJson);

          return DemandPost.fromJson(demandMap);
        } else {
          return DemandPost(
            id: 'd_${DateTime.now().millisecondsSinceEpoch}',
            buyerId: 'buyer_current',
            productName: request.productName,
            quantity: request.quantity,
            callingPrice: request.callingPrice,
            deliveryLocation: request.deliveryLocation,
            expiryTime: request.expiryTime,
            status: DemandStatus.active,
            tradeType: _parseTradeType(request.tradeType),
            imageUrl: request.imageUrl,
          );
        }
      } else if (httpResponse.statusCode == 401) {
        // Attempt to refresh token if available in Hive
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await createDemand(
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
            'Failed to create demand (Status code ${httpResponse.statusCode})';
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

  Future<String?> _attemptRefreshToken(String refreshToken) async {
    try {
      final refreshUri = Uri.parse(ApiPath.refresh);
      final req = await _client.postUrl(refreshUri);
      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      req.headers.set('accept', '*/*');
      req.write(jsonEncode({'refreshToken': refreshToken}));
      final res = await req.close();
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body);
        if (json is Map<String, dynamic>) {
          final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
          final newAccess = data['accessToken'] ?? data['access_token'] ?? data['token'];
          final newRefresh = data['refreshToken'] ?? data['refresh_token'];
          if (newAccess != null) {
            await StorageService().saveAuthTokens(
              accessToken: newAccess.toString(),
              refreshToken: newRefresh?.toString(),
            );
            return newAccess.toString();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  TradeType _parseTradeType(String type) {
    switch (type.toLowerCase()) {
      case 'auction':
        return TradeType.auction;
      case 'both':
        return TradeType.both;
      case 'negotiation':
      default:
        return TradeType.negotiation;
    }
  }
}
