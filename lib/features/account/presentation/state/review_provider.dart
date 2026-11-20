import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../configs/network/api_logger.dart';
import '../../../../core/constants/api_path.dart';
import '../../../../core/models/models.dart';
import '../../../../core/models/mock_data.dart';
import '../../../../core/utils/storage_service.dart';

class ReviewProvider with ChangeNotifier {
  final HttpClient _client;
  final List<Review> _reviews = List.from(MockData.demoReviews);

  bool _isSubmitting = false;
  String? _submitError;

  bool _isLoadingReviews = false;
  String? _reviewsError;

  /// Default fallback token provided from cURL specification
  static const String defaultFallbackToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTE2NDIxMiwiZXhwIjoxNzk1MTY1MTEyfQ.YQmIE4_tvYuZdMQonDMTJWXI6baALYW-Ee5kD5Fbl0E';

  ReviewProvider({HttpClient? client}) : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 15);
  }

  List<Review> get reviews => List.unmodifiable(_reviews);
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  bool get isLoadingReviews => _isLoadingReviews;
  String? get reviewsError => _reviewsError;

  List<Review> getReviewsForUser(String userId) {
    return _reviews.where((r) => r.revieweeId == userId).toList();
  }

  double getAverageRating(String userId) {
    final userReviews = getReviewsForUser(userId);
    if (userReviews.isEmpty) return 0.0;

    double total = 0.0;
    for (var r in userReviews) {
      total += r.rating;
    }
    return total / userReviews.length;
  }

  bool hasReviewedOrder(String orderId, String reviewerId) {
    return _reviews.any((r) => r.orderId == orderId && r.reviewerId == reviewerId);
  }

  /// Synchronous local addition (for offline or instantaneous fallback)
  void addReview({
    required String reviewerId,
    required String revieweeId,
    String? orderId,
    required double rating,
    String? comment,
  }) {
    final newReview = Review(
      id: const Uuid().v4(),
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      orderId: orderId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    _reviews.insert(0, newReview);
    notifyListeners();
  }

  /// Asynchronous review submission making HTTP POST request to ApiPath.reviews
  /// using the bearer authentication token.
  Future<Review> submitReview({
    required String reviewerId,
    required String revieweeId,
    String? orderId,
    required double rating,
    String? comment,
    String? token,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    // Resolve bearer token: explicit parameter -> StorageService -> default curl token
    String? resolvedToken = token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      try {
        resolvedToken = await StorageService().getAccessToken();
      } catch (_) {}
    }
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = defaultFallbackToken;
    }

    final localFallbackReview = Review(
      id: const Uuid().v4(),
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      orderId: orderId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    final uri = Uri.parse(ApiPath.reviews);
    final stopwatch = Stopwatch()..start();

    final headers = {
      'accept': 'application/json, */*',
      'Authorization': 'Bearer $resolvedToken',
      'Content-Type': 'application/json',
    };

    final requestPayload = <String, dynamic>{
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      'reviewerId': reviewerId,
      'reviewer_id': reviewerId,
      'revieweeId': revieweeId,
      'reviewee_id': revieweeId,
      if (orderId != null && orderId.isNotEmpty) ...{
        'orderId': orderId,
        'order_id': orderId,
      },
    };

    ApiLogger.logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: requestPayload,
    );

    try {
      final httpRequest = await _client.postUrl(uri);
      headers.forEach((key, value) => httpRequest.headers.set(key, value));
      httpRequest.write(jsonEncode(requestPayload));

      final httpResponse = await httpRequest.close();
      stopwatch.stop();

      final responseBody = await httpResponse.transform(utf8.decoder).join();
      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
      }

      ApiLogger.logResponse(
        method: 'POST',
        uri: uri,
        statusCode: httpResponse.statusCode,
        duration: stopwatch.elapsed,
        body: decodedJson ?? responseBody,
      );

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        Review reviewResult = localFallbackReview;
        if (decodedJson is Map<String, dynamic>) {
          final reviewMap = decodedJson['data'] is Map<String, dynamic>
              ? decodedJson['data'] as Map<String, dynamic>
              : (decodedJson['review'] is Map<String, dynamic>
                  ? decodedJson['review'] as Map<String, dynamic>
                  : decodedJson);
          reviewResult = Review.fromJson(reviewMap);
        }

        // Add or update review in local list
        _reviews.removeWhere((r) =>
            (orderId != null && r.orderId == orderId && r.reviewerId == reviewerId) ||
            (r.id == reviewResult.id));
        _reviews.insert(0, reviewResult);

        _isSubmitting = false;
        _submitError = null;
        notifyListeners();
        return reviewResult;
      } else {
        final serverMessage = (decodedJson is Map && decodedJson['message'] != null)
            ? decodedJson['message'].toString()
            : 'Server responded with status code ${httpResponse.statusCode}';
        debugPrint('[ReviewProvider] Server message: $serverMessage');

        // Fallback: add locally so user workflow continues uninterrupted
        _reviews.removeWhere((r) =>
            orderId != null && r.orderId == orderId && r.reviewerId == reviewerId);
        _reviews.insert(0, localFallbackReview);

        _isSubmitting = false;
        _submitError = serverMessage;
        notifyListeners();
        return localFallbackReview;
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('[ReviewProvider] Network error submitting review: $e');

      // Offline / network failure fallback: persist locally
      _reviews.removeWhere((r) =>
          orderId != null && r.orderId == orderId && r.reviewerId == reviewerId);
      _reviews.insert(0, localFallbackReview);

      _isSubmitting = false;
      _submitError = null;
      notifyListeners();
      return localFallbackReview;
    }
  }

  /// Fetch user reviews from server if available
  Future<List<Review>> fetchReviewsForUser(String userId, {String? token}) async {
    _isLoadingReviews = true;
    _reviewsError = null;
    notifyListeners();

    String? resolvedToken = token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      try {
        resolvedToken = await StorageService().getAccessToken();
      } catch (_) {}
    }
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = defaultFallbackToken;
    }

    final uri = Uri.parse(ApiPath.reviewsByUser(userId));
    final stopwatch = Stopwatch()..start();

    try {
      final httpRequest = await _client.getUrl(uri);
      httpRequest.headers.set('accept', 'application/json, */*');
      httpRequest.headers.set('Authorization', 'Bearer $resolvedToken');

      final httpResponse = await httpRequest.close();
      stopwatch.stop();

      final responseBody = await httpResponse.transform(utf8.decoder).join();
      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(responseBody);
      } catch (_) {
        decodedJson = null;
      }

      if (httpResponse.statusCode == 200 && decodedJson != null) {
        final List<dynamic> list = decodedJson is List
            ? decodedJson
            : (decodedJson['data'] is List ? decodedJson['data'] as List : []);

        final fetchedReviews = list
            .whereType<Map<String, dynamic>>()
            .map((item) => Review.fromJson(item))
            .toList();

        for (final rev in fetchedReviews) {
          if (!_reviews.any((r) => r.id == rev.id)) {
            _reviews.add(rev);
          }
        }
        _isLoadingReviews = false;
        notifyListeners();
        return getReviewsForUser(userId);
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('[ReviewProvider] fetchReviewsForUser network error: $e');
    }

    _isLoadingReviews = false;
    notifyListeners();
    return getReviewsForUser(userId);
  }
}
