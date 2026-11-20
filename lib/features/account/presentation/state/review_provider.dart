import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/models.dart';
import '../../../../core/models/mock_data.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../order/data/datasources/review_remote_data_source.dart';
import '../../../order/data/models/create_review_request_model.dart';
import '../../../order/data/repositories/review_repository_impl.dart';
import '../../../order/domain/repositories/review_repository.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewRepository _reviewRepository;
  final HttpClient _client;
  final List<Review> _reviews = List.from(MockData.demoReviews);

  bool _isSubmitting = false;
  String? _submitError;

  bool _isLoadingReviews = false;
  String? _reviewsError;

  /// Default fallback token provided from cURL specification
  static const String defaultFallbackToken =
      ReviewRemoteDataSourceImpl.defaultFallbackToken;

  ReviewProvider({HttpClient? client, ReviewRepository? repository})
      : _client = client ?? HttpClient(),
        _reviewRepository = repository ??
            ReviewRepositoryImpl(
              remoteDataSource: ReviewRemoteDataSourceImpl(
                client: client,
              ),
            ) {
    _client.connectionTimeout = const Duration(seconds: 15);
  }

  List<Review> get reviews => List.unmodifiable(_reviews);
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  bool get isLoadingReviews => _isLoadingReviews;
  String? get reviewsError => _reviewsError;
  ReviewRepository get reviewRepository => _reviewRepository;

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
  /// using the bearer authentication token and supporting dual-casing cURL format.
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

    // Resolve bearer token
    String? resolvedToken = token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      try {
        resolvedToken = await StorageService().getAccessToken();
      } catch (_) {}
    }
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = defaultFallbackToken;
    }

    try {
      final request = CreateReviewRequestModel(
        revieweeId: revieweeId,
        orderId: orderId,
        rating: rating,
        comment: comment,
        reviewerId: reviewerId,
      );

      final reviewResult = await _reviewRepository.createReview(
        request: request,
        token: resolvedToken,
      );

      // Add or update review in local list
      _reviews.removeWhere((r) =>
          (orderId != null && r.orderId == orderId && r.reviewerId == reviewerId) ||
          (r.id == reviewResult.id));
      _reviews.insert(0, reviewResult);

      _isSubmitting = false;
      _submitError = null;
      notifyListeners();
      return reviewResult;
    } catch (e) {
      debugPrint('[ReviewProvider] Error submitting review: $e');

      final localFallbackReview = Review(
        id: const Uuid().v4(),
        reviewerId: reviewerId,
        revieweeId: revieweeId,
        orderId: orderId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      _reviews.removeWhere((r) =>
          orderId != null && r.orderId == orderId && r.reviewerId == reviewerId);
      _reviews.insert(0, localFallbackReview);

      _isSubmitting = false;
      _submitError = e.toString();
      notifyListeners();
      return localFallbackReview;
    }
  }

  /// Fetch user reviews from server if available
  Future<List<Review>> fetchReviewsForUser(String userId, {String? token}) async {
    _isLoadingReviews = true;
    _reviewsError = null;
    notifyListeners();

    try {
      final list = await _reviewRepository.getReviewsByUser(userId: userId, token: token);
      for (final r in list) {
        if (!_reviews.any((existing) => existing.id == r.id)) {
          _reviews.add(r);
        }
      }
      _isLoadingReviews = false;
      notifyListeners();
      return list;
    } catch (e) {
      _isLoadingReviews = false;
      _reviewsError = e.toString();
      notifyListeners();
      return getReviewsForUser(userId);
    }
  }
}
