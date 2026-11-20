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
      'id': 'rev_test_123',
      'reviewerId': '395e2439-099f-41da-a739-019f5a08e504',
      'revieweeId': 'f1_seller',
      'orderId': 'order_abc',
      'rating': 5.0,
      'comment': 'Exceptional fresh produce!',
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
  Future<HttpClientResponse> close() {
    return Future.value(_MockReviewHttpClientResponse(
      parent.statusCodeToReturn,
      parent.responseBodyToReturn,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockReviewHttpHeaders implements HttpHeaders {
  final Map<String, String> storage;
  _MockReviewHttpHeaders(this.storage);

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    storage[name.toLowerCase()] = value.toString();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockReviewHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Review Model & Provider Tests', () {
    test('Review fromJson and toJson serialization', () {
      final jsonMap = {
        'id': 'r_test_1',
        'reviewerId': '395e2439-099f-41da-a739-019f5a08e504',
        'revieweeId': 'farmer_99',
        'orderId': 'ord_88',
        'rating': 4.5,
        'comment': 'Good quality tomatoes',
        'createdAt': '2026-11-20T12:00:00.000Z',
      };

      final review = Review.fromJson(jsonMap);
      expect(review.id, 'r_test_1');
      expect(review.reviewerId, '395e2439-099f-41da-a739-019f5a08e504');
      expect(review.revieweeId, 'farmer_99');
      expect(review.orderId, 'ord_88');
      expect(review.rating, 4.5);
      expect(review.comment, 'Good quality tomatoes');

      final serialized = review.toJson();
      expect(serialized['id'], 'r_test_1');
      expect(serialized['rating'], 4.5);
      expect(serialized['orderId'], 'ord_88');
    });

    test('ReviewProvider submitReview sends POST request to ApiPath.reviews with Bearer auth', () async {
      final mockClient = MockReviewHttpClient();
      final provider = ReviewProvider(client: mockClient);

      const testToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTE2NDIxMiwiZXhwIjoxNzk1MTY1MTEyfQ.YQmIE4_tvYuZdMQonDMTJWXI6baALYW-Ee5kD5Fbl0E';

      final created = await provider.submitReview(
        reviewerId: '395e2439-099f-41da-a739-019f5a08e504',
        revieweeId: 'f1_seller',
        orderId: 'order_abc',
        rating: 5.0,
        comment: 'Exceptional fresh produce!',
        token: testToken,
      );

      expect(mockClient.lastMethod, 'POST');
      expect(mockClient.lastUri.toString(), ApiPath.reviews);
      expect(mockClient.lastHeaders['authorization'], 'Bearer $testToken');
      expect(created.id, 'rev_test_123');
      expect(created.rating, 5.0);
      expect(provider.reviews.first.id, 'rev_test_123');
      expect(provider.hasReviewedOrder('order_abc', '395e2439-099f-41da-a739-019f5a08e504'), true);
    });

    test('ReviewProvider submitReview falls back gracefully on network error', () async {
      final provider = ReviewProvider(); // Uses default client which will fail gracefully without real server

      final review = await provider.submitReview(
        reviewerId: 'u1',
        revieweeId: 'f1',
        orderId: 'offline_order',
        rating: 4.0,
        comment: 'Locally persisted test review',
      );

      expect(review.rating, 4.0);
      expect(review.orderId, 'offline_order');
      expect(provider.reviews.any((r) => r.orderId == 'offline_order'), true);
    });
  });

  group('RatingDialog Widget Tests', () {
    testWidgets('Displays title, star buttons, endpoint pill and submits review',
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
                orderId: 'order_widget_test',
                reviewerId: '395e2439-099f-41da-a739-019f5a08e504',
                revieweeId: 'farmer_01',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & subtitle
      expect(find.text('Rate your Experience'), findsOneWidget);
      expect(find.textContaining('Feedback for Order #order_wi'), findsOneWidget);

      // Verify endpoint pill
      expect(find.text('POST'), findsOneWidget);
      expect(find.text('Bearer Auth'), findsOneWidget);

      // Verify 5 star icons are present
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(5));
      expect(find.text('Tap a star to rate'), findsOneWidget);

      // Tap 5th star
      await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
      await tester.pumpAndSettle();

      // Verify mood tag changed to Excellent!
      expect(find.text('Excellent! 🌟'), findsOneWidget);

      // Verify quick tags are shown
      expect(find.text('Fresh Quality 🥦'), findsOneWidget);

      // Tap quick tag 'Fresh Quality 🥦'
      await tester.tap(find.text('Fresh Quality 🥦'));
      await tester.pumpAndSettle();

      // Verify text field contains quick tag
      expect(find.text('Fresh Quality 🥦'), findsWidgets);

      // Tap Submit Review button
      await tester.tap(find.text('Submit Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify HTTP request was sent
      expect(mockClient.lastMethod, 'POST');
      expect(mockClient.lastUri.toString(), ApiPath.reviews);
    });
  });
}
