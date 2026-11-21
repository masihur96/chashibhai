import 'dart:convert';
import 'dart:io';

import '../../../../configs/network/api_logger.dart';
import '../../../../core/constants/api_path.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/token_refresh_service.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/utils/storage_service.dart';
import '../models/create_demand_request_model.dart';
import '../models/create_bid_request_model.dart';
import '../models/create_demand_offer_request_model.dart';

abstract class BuyerRemoteDataSource {
  Future<DemandPost> createDemand({
    required CreateDemandRequestModel request,
    String? token,
  });

  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  });

  Future<List<DemandPost>> getMyDemands({
    int page = 1,
    int limit = 10,
    String? search,
    String? productName,
    double? minPrice,
    double? maxPrice,
    String? tradeType,
    String? status,
    String? token,
  });

  Future<List<DemandPost>> getDemands({
    int page = 1,
    int limit = 10,
    String? tradeType = 'both',
    String? status = 'active',
    String? search,
    String? token,
  });

  Future<Bid> createBid({
    required CreateBidRequestModel request,
    String? token,
  });

  Future<List<Product>> getAvailableProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? token,
  });

  Future<Product?> getProductById({
    required String id,
    String? token,
  });

  Future<List<Bid>> getBidsByProductId({
    required String productId,
    String? token,
  });

  Future<List<Bid>> getMyBids({
    String? token,
  });

  Future<List<Negotiation>> getMyNegotiations({
    String? token,
  });

  Future<DemandOffer> submitDemandOffer({
    required String demandId,
    required CreateDemandOfferRequestModel request,
    String? token,
  });

  Future<List<DemandOffer>> getDemandOffers({
    required String demandId,
    String? token,
  });

  Future<DemandPost> getDemandById({
    required String demandId,
    String? token,
  });

  Future<AcceptDemandOfferResult> acceptDemandOffer({
    required String demandId,
    required String offerId,
    String? token,
  });
}

class BuyerRemoteDataSourceImpl implements BuyerRemoteDataSource {
  final HttpClient _client;
  final UploadService _uploadService;

  /// Default fallback token from user curl specification
  static const String defaultFallbackToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTIzMDQ4OCwiZXhwIjoxNzk1MjMxMzg4fQ.Bz507CiQ8S1aVUftQiGHshCt7ShDNFTZ6osiVm4_Zcw';

  /// Default accept offer token from curl specification
  static const String defaultAcceptOfferToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTIzMDQ4OCwiZXhwIjoxNzk1MjMxMzg4fQ.Bz507CiQ8S1aVUftQiGHshCt7ShDNFTZ6osiVm4_Zcw';

  /// Default demand offers token from curl specification
  static const String defaultDemandOffersToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTIyODY4NSwiZXhwIjoxNzk1MjI5NTg1fQ.tOmmN802nMfarpXhPLyKzrG4lhDAlptRY_8m_yWpnfw';

  /// Default farmer demands token from curl specification
  static const String defaultFarmerDemandsToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5MmY2ODM5YS01ZDBjLTQwYTctYmQ5Mi1hNTA4MGNkOGIwNzAiLCJwaG9uZSI6Ijg4MDE3NDA3MTkyMDUiLCJlbWFpbCI6IiIsInJvbGUiOiJmYXJtZXIiLCJpYXQiOjE3OTUxODA4ODcsImV4cCI6MTc5NTE4MTc4N30.VUKDsD7Ihas2X2ANxB6-K89f-L1Rp5uWhTJGf4q_lFc';

  /// Default demand offer token from curl specification
  static const String defaultDemandOfferToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5MmY2ODM5YS01ZDBjLTQwYTctYmQ5Mi1hNTA4MGNkOGIwNzAiLCJwaG9uZSI6Ijg4MDE3NDA3MTkyMDUiLCJlbWFpbCI6IiIsInJvbGUiOiJmYXJtZXIiLCJpYXQiOjE3OTUxOTk1NjEsImV4cCI6MTc5NTIwMDQ2MX0.YIPpOSg4keK6Ck-FfnrQDXlyUh_zSd-LxpMHS7Vnp-s';

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

  @override
  Future<List<DemandPost>> getMyDemands({
    int page = 1,
    int limit = 10,
    String? search,
    String? productName,
    double? minPrice,
    double? maxPrice,
    String? tradeType,
    String? status,
    String? token,
  }) async {
    final endpoint = ApiPath.myDemands;
    final baseUri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    final queryParameters = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    if (productName != null && productName.isNotEmpty) {
      queryParameters['productName'] = productName;
      queryParameters['product_name'] = productName;
    }
    if (minPrice != null) {
      queryParameters['minPrice'] = minPrice.toString();
      queryParameters['min_price'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParameters['maxPrice'] = maxPrice.toString();
      queryParameters['max_price'] = maxPrice.toString();
    }
    if (tradeType != null && tradeType.isNotEmpty) {
      queryParameters['tradeType'] = tradeType;
      queryParameters['trade_type'] = tradeType;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
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

        final List<DemandPost> demands = [];
        if (decodedJson is Map<String, dynamic>) {
          final data = decodedJson['data'];
          if (data is List) {
            for (final item in data) {
              if (item is Map<String, dynamic>) {
                demands.add(DemandPost.fromJson(item));
              }
            }
          } else if (decodedJson['demands'] is List) {
            for (final item in decodedJson['demands']) {
              if (item is Map<String, dynamic>) {
                demands.add(DemandPost.fromJson(item));
              }
            }
          }
        } else if (decodedJson is List) {
          for (final item in decodedJson) {
            if (item is Map<String, dynamic>) {
              demands.add(DemandPost.fromJson(item));
            }
          }
        }
        return demands;
      } else if (httpResponse.statusCode == 401) {
        // Attempt to refresh token if a refresh token is saved in Hive
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await getMyDemands(
              page: page,
              limit: limit,
              search: search,
              productName: productName,
              minPrice: minPrice,
              maxPrice: maxPrice,
              tradeType: tradeType,
              status: status,
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
            'Failed to fetch demands (Status code ${httpResponse.statusCode})';
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
  Future<List<DemandPost>> getDemands({
    int page = 1,
    int limit = 10,
    String? tradeType = 'both',
    String? status = 'active',
    String? search,
    String? token,
  }) async {
    final endpoint = ApiPath.demands;
    final baseUri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    final queryParameters = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (tradeType != null && tradeType.isNotEmpty) {
      queryParameters['tradeType'] = tradeType;
      queryParameters['trade_type'] = tradeType;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    final uri = baseUri.replace(queryParameters: queryParameters);

    // Resolve bearer token: explicit parameter -> StorageService -> defaultFarmerDemandsToken
    String? resolvedToken = token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      try {
        resolvedToken = await StorageService().getAccessToken();
      } catch (_) {}
    }
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = defaultFarmerDemandsToken;
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

      if (httpResponse.statusCode == 200) {
        ApiLogger.logResponse(
          method: 'GET',
          uri: uri,
          statusCode: httpResponse.statusCode,
          duration: stopwatch.elapsed,
          body: decodedJson ?? responseBody,
        );

        final List<dynamic> items;
        if (decodedJson is Map<String, dynamic>) {
          if (decodedJson['data'] is List) {
            items = decodedJson['data'] as List<dynamic>;
          } else if (decodedJson['demands'] is List) {
            items = decodedJson['demands'] as List<dynamic>;
          } else {
            items = [];
          }
        } else if (decodedJson is List) {
          items = decodedJson;
        } else {
          items = [];
        }

        return items
            .map((item) => DemandPost.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (httpResponse.statusCode == 401) {
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await getDemands(
              page: page,
              limit: limit,
              tradeType: tradeType,
              status: status,
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
            'Failed to fetch demands (Status code ${httpResponse.statusCode})';
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

  Future<String?> _attemptRefreshToken(String refreshToken) async {
    try {
      return await TokenRefreshManager().refresh(
        explicitRefreshToken: refreshToken,
        client: _client,
      );
    } catch (_) {}
    return null;
  }

  @override
  Future<Bid> createBid({
    required CreateBidRequestModel request,
    String? token,
  }) async {
    final endpoint = ApiPath.bids;
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
          final bidMap = decodedJson['data'] is Map<String, dynamic>
              ? decodedJson['data'] as Map<String, dynamic>
              : (decodedJson['bid'] is Map<String, dynamic>
                  ? decodedJson['bid'] as Map<String, dynamic>
                  : decodedJson);
          return Bid.fromJson(bidMap);
        } else {
          return Bid(
            id: 'b_${DateTime.now().millisecondsSinceEpoch}',
            productId: request.productId,
            buyerId: '395e2439-099f-41da-a739-019f5a08e504',
            amount: request.amount,
            createdAt: DateTime.now(),
          );
        }
      } else if (httpResponse.statusCode == 401) {
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await createBid(
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
            'Failed to place bid (Status code ${httpResponse.statusCode})';
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
  Future<List<Product>> getAvailableProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? token,
  }) async {
    final endpoint = ApiPath.products;
    final baseUri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    final queryParameters = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null && category.isNotEmpty && category != 'All') {
      queryParameters['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    final uri = baseUri.replace(queryParameters: queryParameters);

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
          final data = decodedJson['data'] ?? decodedJson['products'];
          if (data is List) {
            for (final item in data) {
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
      } else {
        throw Exception('Failed to fetch available products (${httpResponse.statusCode})');
      }
    } catch (e) {
      stopwatch.stop();
      rethrow;
    }
  }

  @override
  Future<Product?> getProductById({
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
      'accept': 'application/json',
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

        if (decodedJson is Map<String, dynamic>) {
          final productMap = decodedJson['data'] is Map<String, dynamic>
              ? decodedJson['data'] as Map<String, dynamic>
              : (decodedJson['product'] is Map<String, dynamic>
                  ? decodedJson['product'] as Map<String, dynamic>
                  : decodedJson);
          return Product.fromJson(productMap);
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      stopwatch.stop();
      return null;
    }
  }

  @override
  Future<List<Bid>> getBidsByProductId({
    required String productId,
    String? token,
  }) async {
    final endpoint = ApiPath.bidsByProduct(productId);
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

        final List<Bid> bids = [];
        if (decodedJson is Map<String, dynamic>) {
          final data = decodedJson['data'] ?? decodedJson['bids'] ?? decodedJson['result'];
          if (data is List) {
            for (final item in data) {
              if (item is Map<String, dynamic>) {
                bids.add(Bid.fromJson(item));
              }
            }
          }
        } else if (decodedJson is List) {
          for (final item in decodedJson) {
            if (item is Map<String, dynamic>) {
              bids.add(Bid.fromJson(item));
            }
          }
        }
        return bids;
      } else if (httpResponse.statusCode == 401) {
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await getBidsByProductId(
              productId: productId,
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
            'Failed to fetch product bids (Status code ${httpResponse.statusCode})';
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
  Future<List<Negotiation>> getMyNegotiations({
    String? token,
  }) async {
    final endpoint = ApiPath.myNegotiations;
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

        final List<Negotiation> list = [];
        if (decodedJson is Map<String, dynamic>) {
          final data = decodedJson['data'] ?? decodedJson['negotiations'] ?? decodedJson['result'];
          if (data is List) {
            for (final item in data) {
              if (item is Map<String, dynamic>) {
                list.add(Negotiation.fromJson(item));
              }
            }
          }
        } else if (decodedJson is List) {
          for (final item in decodedJson) {
            if (item is Map<String, dynamic>) {
              list.add(Negotiation.fromJson(item));
            }
          }
        }
        return list;
      } else if (httpResponse.statusCode == 401) {
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await getMyNegotiations(token: refreshedToken);
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
            'Failed to fetch negotiations (Status code ${httpResponse.statusCode})';
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
  Future<List<Bid>> getMyBids({
    String? token,
  }) async {
    final endpoint = ApiPath.myBids;
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

        final List<Bid> bids = [];
        if (decodedJson is Map<String, dynamic>) {
          final data = decodedJson['data'] ?? decodedJson['bids'] ?? decodedJson['result'];
          if (data is List) {
            for (final item in data) {
              if (item is Map<String, dynamic>) {
                bids.add(Bid.fromJson(item));
              }
            }
          }
        } else if (decodedJson is List) {
          for (final item in decodedJson) {
            if (item is Map<String, dynamic>) {
              bids.add(Bid.fromJson(item));
            }
          }
        }
        return bids;
      } else if (httpResponse.statusCode == 401) {
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await getMyBids(token: refreshedToken);
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
            'Failed to fetch my bids (Status code ${httpResponse.statusCode})';
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

  /// Submits an offer on an active demand post using POST /api/v1/demands/{demandId}/offer
  @override
  Future<DemandOffer> submitDemandOffer({
    required String demandId,
    required CreateDemandOfferRequestModel request,
    String? token,
  }) async {
    final endpoint = ApiPath.demandOffer(demandId);
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    // Resolve bearer token: explicit param -> StorageService -> defaultDemandOfferToken
    String? resolvedToken = token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      try {
        resolvedToken = await StorageService().getAccessToken();
      } catch (_) {}
    }
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = defaultDemandOfferToken;
    }

    final headers = <String, String>{
      'accept': '*/*',
      'Content-Type': 'application/json',
    };
    if (resolvedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $resolvedToken';
    }

    final requestBody = request.toJson();

    ApiLogger.logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: requestBody,
    );

    try {
      final httpRequest = await _client.postUrl(uri);
      httpRequest.encoding = utf8;
      headers.forEach((key, value) {
        httpRequest.headers.set(key, value);
      });

      final bodyBytes = utf8.encode(jsonEncode(requestBody));
      httpRequest.contentLength = bodyBytes.length;
      httpRequest.add(bodyBytes);
      final httpResponse = await httpRequest.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();
      stopwatch.stop();

      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = responseBody;
      }

      // Handle 401 token refresh & retry
      if (httpResponse.statusCode == 401) {
        String? refreshToken;
        try {
          refreshToken = await StorageService().getRefreshToken();
        } catch (_) {}

        if (refreshToken != null && refreshToken.isNotEmpty) {
          final newAccessToken = await _attemptRefreshToken(refreshToken);
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            final retryHeaders = Map<String, String>.from(headers);
            retryHeaders['Authorization'] = 'Bearer $newAccessToken';

            ApiLogger.logRequest(
              method: 'POST',
              uri: uri,
              headers: retryHeaders,
              body: requestBody,
            );

            final retryRequest = await _client.postUrl(uri);
            retryRequest.encoding = utf8;
            retryHeaders.forEach((key, value) {
              retryRequest.headers.set(key, value);
            });
            retryRequest.contentLength = bodyBytes.length;
            retryRequest.add(bodyBytes);

            final retryResponse = await retryRequest.close();
            final retryBody =
                await retryResponse.transform(utf8.decoder).join();
            dynamic retryDecoded;
            try {
              retryDecoded = jsonDecode(retryBody);
            } catch (_) {
              retryDecoded = retryBody;
            }

            if (retryResponse.statusCode >= 200 &&
                retryResponse.statusCode < 300) {
              ApiLogger.logResponse(
                method: 'POST',
                uri: uri,
                statusCode: retryResponse.statusCode,
                duration: stopwatch.elapsed,
                body: retryDecoded ?? retryBody,
              );

              final data = retryDecoded is Map<String, dynamic> &&
                      retryDecoded.containsKey('data')
                  ? retryDecoded['data']
                  : retryDecoded;
              return DemandOffer.fromJson(data as Map<String, dynamic>);
            }
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

        final data = decodedJson is Map<String, dynamic> &&
                decodedJson.containsKey('data')
            ? decodedJson['data']
            : decodedJson;
        return DemandOffer.fromJson(data as Map<String, dynamic>);
      } else {
        String errorMessage =
            'Failed to submit demand offer (Status code ${httpResponse.statusCode})';
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
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      final err = 'Cannot connect to server at ${uri.host}:${uri.port} ($e)';
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

  /// Fetches offers submitted for a demand using GET /api/v1/demands/{demandId}/offers
  @override
  Future<List<DemandOffer>> getDemandOffers({
    required String demandId,
    String? token,
  }) async {
    final endpoint = ApiPath.demandOffers(demandId);
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    // Resolve bearer token: explicit param -> StorageService -> defaultDemandOffersToken -> defaultFallbackToken
    String? resolvedToken = token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      try {
        resolvedToken = await StorageService().getAccessToken();
      } catch (_) {}
    }
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = defaultDemandOffersToken;
    }

    final headers = <String, String>{
      'accept': '*/*',
    };
    if (resolvedToken.isNotEmpty) {
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

        final List<DemandOffer> offers = [];
        if (decodedJson is Map<String, dynamic>) {
          final data = decodedJson['data'] ?? decodedJson['offers'] ?? decodedJson['result'];
          if (data is List) {
            for (final item in data) {
              if (item is Map<String, dynamic>) {
                offers.add(DemandOffer.fromJson(item));
              }
            }
          }
        } else if (decodedJson is List) {
          for (final item in decodedJson) {
            if (item is Map<String, dynamic>) {
              offers.add(DemandOffer.fromJson(item));
            }
          }
        }
        return offers;
      } else if (httpResponse.statusCode == 401) {
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await getDemandOffers(
              demandId: demandId,
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
            'Failed to fetch demand offers (Status code ${httpResponse.statusCode})';
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
      final err = 'Cannot connect to server at ${uri.host}:${uri.port} ($e)';
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

  /// Fetches details for a single demand using GET /api/v1/demands/{demandId}
  @override
  Future<DemandPost> getDemandById({
    required String demandId,
    String? token,
  }) async {
    final endpoint = ApiPath.demandById(demandId);
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    // Resolve bearer token: explicit param -> StorageService -> defaultDemandOffersToken -> defaultFallbackToken
    String? resolvedToken = token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      try {
        resolvedToken = await StorageService().getAccessToken();
      } catch (_) {}
    }
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = defaultDemandOffersToken;
    }

    final headers = <String, String>{
      'accept': '*/*',
    };
    if (resolvedToken.isNotEmpty) {
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
          final data = decodedJson['data'] is Map<String, dynamic>
              ? decodedJson['data'] as Map<String, dynamic>
              : (decodedJson['demand'] is Map<String, dynamic>
                  ? decodedJson['demand'] as Map<String, dynamic>
                  : decodedJson);
          return DemandPost.fromJson(data);
        }
        throw Exception('Unexpected response format when fetching demand details');
      } else if (httpResponse.statusCode == 401) {
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await getDemandById(
              demandId: demandId,
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
            'Failed to fetch demand details (Status code ${httpResponse.statusCode})';
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
      final err = 'Cannot connect to server at ${uri.host}:${uri.port} ($e)';
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

  /// Accepts an offer on a demand post using POST /api/v1/demands/{demandId}/offers/{offerId}/accept
  @override
  Future<AcceptDemandOfferResult> acceptDemandOffer({
    required String demandId,
    required String offerId,
    String? token,
  }) async {
    final endpoint = ApiPath.acceptDemandOffer(demandId, offerId);
    final uri = Uri.parse(endpoint);
    final stopwatch = Stopwatch()..start();

    // Resolve bearer token: explicit param -> StorageService -> defaultAcceptOfferToken -> defaultFallbackToken
    String? resolvedToken = token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      try {
        resolvedToken = await StorageService().getAccessToken();
      } catch (_) {}
    }
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = defaultAcceptOfferToken;
    }

    final headers = <String, String>{
      'accept': '*/*',
    };
    if (resolvedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $resolvedToken';
    }

    ApiLogger.logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: '',
    );

    try {
      final httpRequest = await _client.postUrl(uri);
      headers.forEach((key, value) => httpRequest.headers.set(key, value));
      httpRequest.write('');

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
          return AcceptDemandOfferResult.fromJson(decodedJson);
        }
        return AcceptDemandOfferResult(
          success: true,
          message: 'Offer accepted successfully.',
          demandId: demandId,
          offerId: offerId,
          status: 'fulfilled',
        );
      } else if (httpResponse.statusCode == 401) {
        final refreshToken = await StorageService().getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedToken = await _attemptRefreshToken(refreshToken);
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            return await acceptDemandOffer(
              demandId: demandId,
              offerId: offerId,
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
            'Failed to accept demand offer (Status code ${httpResponse.statusCode})';
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
      final err = 'Cannot connect to server at ${uri.host}:${uri.port} ($e)';
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
}
