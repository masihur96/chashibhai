import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chashibhai/core/constants/api_path.dart';
import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/features/account/presentation/state/review_provider.dart';
import 'package:chashibhai/features/auth/presentation/providers/auth_provider.dart';
import 'package:chashibhai/features/order/data/datasources/review_remote_data_source.dart';
import 'package:chashibhai/core/presentation/widgets/reviews_list_sheet.dart';
import 'package:chashibhai/features/order/data/models/create_review_request_model.dart';
import 'package:chashibhai/features/order/data/repositories/review_repository_impl.dart';
import 'package:chashibhai/features/order/domain/usecases/get_order_reviews_usecase.dart';
import 'package:chashibhai/features/order/presentation/views/rating_dialog.dart';

class MockReviewHttpClient implements HttpClient {
  String? lastMethod;
  Uri? lastUri;
  String? lastBody;
  Map<String, String> lastHeaders = {};
  int statusCodeToReturn = 201;
  String responseBodyToReturn = jsonEncode({
    'statusCode': 201,
    'message': 'Review submitted successfully',
    'data': {
      'id': 'rev_test_curl_123',
      'reviewerId': '395e2439-099f-41da-a739-019f5a08e504',
      'revieweeId': 'd3b07384-d113-49fb-9400-ee481d6f5822',
      'orderId': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
      'rating': 4.5,
      'comment':
          'Fresh produce, arrived promptly as described. Highly recommended!',
      'createdAt': '2026-11-20T16:00:00.000Z',
    }
  });

  @override
  Duration? connectionTimeout;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #postUrl) {
      lastMethod = 'POST';
      lastUri = invocation.positionalArguments.first as Uri;
      return Future.value(_MockReviewHttpClientRequest(this));
    }
    if (invocation.memberName == #getUrl) {
      lastMethod = 'GET';
      lastUri = invocation.positionalArguments.first as Uri;
      return Future.value(_MockReviewHttpClientRequest(this));
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockReviewHttpClientRequest implements HttpClientRequest {
  final MockReviewHttpClient parent;
  final List<int> _bodyBuffer = [];

  _MockReviewHttpClientRequest(this.parent);

  @override
  HttpHeaders get headers => _MockReviewHttpHeaders(parent.lastHeaders);

  @override
  void write(Object? obj) {
    if (obj != null) {
      final str = obj.toString();
      parent.lastBody = str;
      _bodyBuffer.addAll(utf8.encode(str));
    }
  }

  @override
  void add(List<int> data) {
    _bodyBuffer.addAll(data);
    parent.lastBody = utf8.decode(data, allowMalformed: true);
  }

  @override
  Future<HttpClientResponse> close() {
    return Future.value(_MockReviewHttpClientResponse(
      parent.statusCodeToReturn,
      parent.responseBodyToReturn,
    ));
  }

  @override
  int contentLength = 0;

  Encoding encoding = utf8;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockReviewHttpHeaders implements HttpHeaders {
  final Map<String, String> storage;
  _MockReviewHttpHeaders(this.storage);

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    storage[name.toLowerCase()] = value.toString();
  }

  @override
  int contentLength = 0;

  Encoding encoding = utf8;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockReviewHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  final int statusCode;
  final String responseBody;

  _MockReviewHttpClientResponse(this.statusCode, this.responseBody);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(utf8.encode(responseBody)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  int contentLength = 0;

  Encoding encoding = utf8;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('CreateReviewRequestModel Tests', () {
    test('CreateReviewRequestModel serialization with cURL dual-cased keys', () {
      final model = CreateReviewRequestModel(
        revieweeId: 'd3b07384-d113-49fb-9400-ee481d6f5822',
        orderId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
        rating: 4.5,
        comment:
            'Fresh produce, arrived promptly as described. Highly recommended!',
      );

      final map = model.toJson();
      expect(map['revieweeId'], 'd3b07384-d113-49fb-9400-ee481d6f5822');
      expect(map['reviewee_id'], 'd3b07384-d113-49fb-9400-ee481d6f5822');
      expect(map['orderId'], 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
      expect(map['order_id'], 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
      expect(map['rating'], 4.5);
      expect(map['comment'],
          'Fresh produce, arrived promptly as described. Highly recommended!');
    });
  });

  group('Review Model & Provider Tests', () {
    test('Review fromJson and toJson serialization', () {
      final jsonMap = {
        'id': 'r_test_curl',
        'reviewerId': '395e2439-099f-41da-a739-019f5a08e504',
        'revieweeId': 'd3b07384-d113-49fb-9400-ee481d6f5822',
        'orderId': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
        'rating': 4.5,
        'comment':
            'Fresh produce, arrived promptly as described. Highly recommended!',
        'createdAt': '2026-11-20T12:00:00.000Z',
      };

      final review = Review.fromJson(jsonMap);
      expect(review.id, 'r_test_curl');
      expect(review.reviewerId, '395e2439-099f-41da-a739-019f5a08e504');
      expect(review.revieweeId, 'd3b07384-d113-49fb-9400-ee481d6f5822');
      expect(review.orderId, 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
      expect(review.rating, 4.5);
      expect(review.comment,
          'Fresh produce, arrived promptly as described. Highly recommended!');

      final serialized = review.toJson();
      expect(serialized['id'], 'r_test_curl');
      expect(serialized['rating'], 4.5);
      expect(serialized['orderId'], 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
    });

    test('ReviewRemoteDataSource submits review matching exact user cURL',
        () async {
      final mockClient = MockReviewHttpClient();
      final dataSource = ReviewRemoteDataSourceImpl(client: mockClient);
      final repo = ReviewRepositoryImpl(remoteDataSource: dataSource);

      final result = await repo.createReview(
        request: const CreateReviewRequestModel(
          revieweeId: 'd3b07384-d113-49fb-9400-ee481d6f5822',
          orderId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
          rating: 4.5,
          comment:
              'Fresh produce, arrived promptly as described. Highly recommended!',
        ),
      );

      expect(mockClient.lastMethod, 'POST');
      expect(mockClient.lastUri.toString(), ApiPath.reviews);
      expect(mockClient.lastHeaders['content-type'], 'application/json');
      expect(mockClient.lastHeaders['accept'], 'application/json');
      expect(result.id, 'rev_test_curl_123');
      expect(result.rating, 4.5);
      expect(result.revieweeId, 'd3b07384-d113-49fb-9400-ee481d6f5822');
    });

    test('ReviewProvider submitReview sends POST request to ApiPath.reviews',
        () async {
      final mockClient = MockReviewHttpClient();
      final provider = ReviewProvider(client: mockClient);

      const testToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTE2NDIxMiwiZXhwIjoxNzk1MTY1MTEyfQ.YQmIE4_tvYuZdMQonDMTJWXI6baALYW-Ee5kD5Fbl0E';

      final created = await provider.submitReview(
        reviewerId: '395e2439-099f-41da-a739-019f5a08e504',
        revieweeId: 'd3b07384-d113-49fb-9400-ee481d6f5822',
        orderId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
        rating: 4.5,
        comment:
            'Fresh produce, arrived promptly as described. Highly recommended!',
        token: testToken,
      );

      expect(mockClient.lastMethod, 'POST');
      expect(mockClient.lastUri.toString(), ApiPath.reviews);
      expect(mockClient.lastHeaders['authorization'], 'Bearer $testToken');
      expect(created.id, 'rev_test_curl_123');
      expect(created.rating, 4.5);
      expect(provider.reviews.first.id, 'rev_test_curl_123');
      expect(
          provider.hasReviewedOrder('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
              '395e2439-099f-41da-a739-019f5a08e504'),
          true);
    });

    test('ReviewRemoteDataSource submits review with emojis and Bangla unicode successfully',
        () async {
      final mockClient = MockReviewHttpClient();
      final dataSource = ReviewRemoteDataSourceImpl(client: mockClient);
      final repo = ReviewRepositoryImpl(remoteDataSource: dataSource);

      final result = await repo.createReview(
        request: const CreateReviewRequestModel(
          revieweeId: '395e2439-099f-41da-a739-019f5a08e504',
          orderId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
          rating: 5.0,
          comment:
              'Fresh produce, arrived promptly as described. Highly recommended!, Fair Price 💰 ভালো দাম',
        ),
      );

      expect(mockClient.lastMethod, 'POST');
      expect(mockClient.lastUri.toString(), ApiPath.reviews);
      expect(result.id, 'rev_test_curl_123');
      expect(mockClient.lastBody, contains('Fair Price 💰 ভালো দাম'));
    });

    test('ReviewProvider submitReview falls back gracefully on network error',
        () async {
      final provider = ReviewProvider();

      final review = await provider.submitReview(
        reviewerId: 'u1',
        revieweeId: 'd3b07384-d113-49fb-9400-ee481d6f5822',
        orderId: 'offline_order',
        rating: 4.5,
        comment: 'Locally persisted test review',
      );

      expect(review.rating, 4.5);
      expect(review.orderId, 'offline_order');
      expect(provider.reviews.any((r) => r.orderId == 'offline_order'), true);
    });
  });

  group('RatingDialog Widget Tests', () {
    testWidgets(
        'Displays 4.5 default rating, cURL comment, endpoint pill and submits review',
        (tester) async {
      final mockClient = MockReviewHttpClient();
      final reviewProvider = ReviewProvider(client: mockClient);
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ReviewProvider>.value(value: reviewProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RatingDialog(
                orderId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
                reviewerId: '395e2439-099f-41da-a739-019f5a08e504',
                revieweeId: 'd3b07384-d113-49fb-9400-ee481d6f5822',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & subtitle
      expect(find.text('Rate your Experience'), findsOneWidget);
      expect(find.textContaining('Feedback for Order #a1b2c3d4'),
          findsOneWidget);

      // Verify endpoint pill
      expect(find.text('POST'), findsOneWidget);
      expect(find.text('Bearer Auth'), findsOneWidget);

      // Verify 4.5 rating badge & default cURL chip
      expect(find.textContaining('4.5 ★'), findsWidgets);
      expect(find.text('4.5 (cURL Default) ★'), findsOneWidget);

      // Verify default comment text in TextField
      expect(
          find.text(
              'Fresh produce, arrived promptly as described. Highly recommended!'),
          findsOneWidget);

      // Scroll to and tap Submit Review button
      await tester.ensureVisible(find.text('Submit Review'));
      await tester.tap(find.text('Submit Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify HTTP request was sent
      expect(mockClient.lastMethod, 'POST');
      expect(mockClient.lastUri.toString(), ApiPath.reviews);
      expect(mockClient.lastBody, contains('"rating":4.5'));
      expect(mockClient.lastBody, contains('"revieweeId":"d3b07384-d113-49fb-9400-ee481d6f5822"'));
      expect(mockClient.lastBody, contains('"orderId":"a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d"'));
    });

    test('ReviewRemoteDataSourceImpl getReviewsByOrder sends GET to ApiPath.reviewsByOrder', () async {
      final mockClient = MockReviewHttpClient();
      mockClient.statusCodeToReturn = 200;
      mockClient.responseBodyToReturn = jsonEncode({
        'statusCode': 200,
        'data': [
          {
            'id': 'rev_order_curl_1',
            'reviewerId': 'u1',
            'revieweeId': 'f1',
            'orderId': ' rfs dfsd',
            'rating': 4.5,
            'comment': 'Fresh produce, arrived promptly as described. Highly recommended!',
            'createdAt': '2026-11-20T17:00:00.000Z',
          }
        ]
      });

      final dataSource = ReviewRemoteDataSourceImpl(client: mockClient);
      final reviews = await dataSource.getReviewsByOrder(
        orderId: ' rfs dfsd',
        token: ReviewRemoteDataSourceImpl.defaultOrderReviewsToken,
      );

      expect(mockClient.lastMethod, 'GET');
      expect(
        mockClient.lastUri.toString(),
        ApiPath.reviewsByOrder(' rfs dfsd'),
      );
      expect(reviews.length, 1);
      expect(reviews.first.id, 'rev_order_curl_1');
      expect(reviews.first.orderId, ' rfs dfsd');
      expect(reviews.first.rating, 4.5);
      expect(reviews.first.comment, contains('Fresh produce, arrived promptly'));
    });

    testWidgets('ReviewsListSheet displays reviews fetched via cURL endpoint', (WidgetTester tester) async {
      final mockClient = MockReviewHttpClient();
      mockClient.statusCodeToReturn = 200;
      mockClient.responseBodyToReturn = jsonEncode({
        'statusCode': 200,
        'data': [
          {
            'id': 'rev_order_curl_2',
            'reviewerId': 'u1',
            'revieweeId': 'f1',
            'orderId': ' rfs dfsd',
            'rating': 4.5,
            'comment': 'Fresh produce, arrived promptly as described. Highly recommended!',
            'createdAt': '2026-11-20T17:00:00.000Z',
          }
        ]
      });

      final dataSource = ReviewRemoteDataSourceImpl(client: mockClient);
      final repo = ReviewRepositoryImpl(remoteDataSource: dataSource);
      final useCase = GetOrderReviewsUseCase(repo);
      final reviewProvider = ReviewProvider(
        client: mockClient,
        repository: repo,
        getOrderReviewsUseCase: useCase,
      );
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ReviewProvider>.value(value: reviewProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ReviewsListSheet(
                orderId: ' rfs dfsd',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify endpoint pill matches curl
      expect(find.text('/api/v1/reviews/order/%20rfs%20dfsd'), findsOneWidget);
      expect(find.text('Order:  rfs dfsd'), findsOneWidget);

      // Verify review content rendered
      expect(find.text('Order Reviews'), findsOneWidget);
      expect(find.text('Masihur Rahman (Buyer)'), findsOneWidget);
      expect(find.text('Order # rfs dfsd'), findsOneWidget);
      expect(
        find.text('Fresh produce, arrived promptly as described. Highly recommended!'),
        findsOneWidget,
      );
    });
  });
}
