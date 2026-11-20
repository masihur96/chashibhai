import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chashibhai/core/constants/api_path.dart';
import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/features/auth/presentation/state/auth_provider.dart';
import 'package:chashibhai/features/buyer/data/datasources/buyer_remote_data_source.dart';
import 'package:chashibhai/features/buyer/data/models/create_demand_offer_request_model.dart';
import 'package:chashibhai/features/buyer/data/repositories/buyer_repository_impl.dart';
import 'package:chashibhai/features/buyer/domain/usecases/submit_demand_offer_usecase.dart';
import 'package:chashibhai/features/buyer/presentation/state/demand_provider.dart';
import 'package:chashibhai/features/farmer/presentation/views/widgets/submit_demand_offer_sheet.dart';

class MockDemandOfferHttpClient implements HttpClient {
  String? lastMethod;
  Uri? lastUri;
  String? lastBody;
  Map<String, String> lastHeaders = {};
  int statusCodeToReturn = 200;
  String responseBodyToReturn = jsonEncode({
    'success': true,
    'data': {
      'id': 'd0e0278a-38a5-4fba-a478-f7a529e356b7',
      'demandId': '033615c2-e905-4789-a536-dc0c95d3cee2',
      'farmerId': '92f6839a-5d0c-40a7-bd92-a5080cd8b070',
      'offerPrice': 27.5,
      'note': 'Can deliver 1000kg grade-A Diamant potatoes by tomorrow.',
      'createdAt': '2026-11-20T18:41:26.690963+00:00',
    }
  });

  @override
  Duration? connectionTimeout;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #postUrl) {
      lastMethod = 'POST';
      lastUri = invocation.positionalArguments.first as Uri;
      return Future.value(_MockDemandOfferHttpClientRequest(this));
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockDemandOfferHttpClientRequest implements HttpClientRequest {
  final MockDemandOfferHttpClient parent;
  final List<int> _bodyBuffer = [];

  _MockDemandOfferHttpClientRequest(this.parent);

  @override
  HttpHeaders get headers => _MockDemandOfferHttpHeaders(parent.lastHeaders);

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
    return Future.value(_MockDemandOfferHttpClientResponse(
      parent.statusCodeToReturn,
      parent.responseBodyToReturn,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockDemandOfferHttpHeaders implements HttpHeaders {
  final Map<String, String> storage;
  _MockDemandOfferHttpHeaders(this.storage);

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    storage[name.toLowerCase()] = value.toString();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockDemandOfferHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  final int statusCode;
  final String responseBody;

  _MockDemandOfferHttpClientResponse(this.statusCode, this.responseBody);

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
  group('Submit Demand Offer cURL Tests', () {
    const testDemandId = '033615c2-e905-4789-a536-dc0c95d3cee2';

    final testDemand = DemandPost(
      id: testDemandId,
      buyerId: 'd51a5dec-5c96-4dcd-8f1a-01461ae605e9',
      productName: 'Potato',
      quantity: 1000,
      callingPrice: 28,
      deliveryLocation: 'Karwan Bazar, Dhaka',
      expiryTime: DateTime.now().add(const Duration(days: 4)),
      status: DemandStatus.active,
      tradeType: TradeType.both,
      imageUrl: '',
    );

    test('CreateDemandOfferRequestModel serializes with dual-cased keys matching user cURL', () {
      final model = CreateDemandOfferRequestModel(
        offerPrice: 27.5,
        note: 'Can deliver 1000kg grade-A Diamant potatoes by tomorrow.',
      );

      final json = model.toJson();
      expect(json['offerPrice'], equals(27.5));
      expect(json['offer_price'], equals(27.5));
      expect(json['note'], equals('Can deliver 1000kg grade-A Diamant potatoes by tomorrow.'));
    });

    test('BuyerRemoteDataSourceImpl submitDemandOffer sends exact POST cURL request', () async {
      final mockClient = MockDemandOfferHttpClient();
      final dataSource = BuyerRemoteDataSourceImpl(client: mockClient);

      final result = await dataSource.submitDemandOffer(
        demandId: testDemandId,
        request: CreateDemandOfferRequestModel(
          offerPrice: 27.5,
          note: 'Can deliver 1000kg grade-A Diamant potatoes by tomorrow.',
        ),
        token: BuyerRemoteDataSourceImpl.defaultDemandOfferToken,
      );

      expect(mockClient.lastMethod, 'POST');
      expect(
        mockClient.lastUri.toString(),
        'http://localhost:3000/api/v1/demands/$testDemandId/offer',
      );
      expect(mockClient.lastHeaders['authorization'],
          contains(BuyerRemoteDataSourceImpl.defaultDemandOfferToken));
      expect(mockClient.lastBody, contains('"offerPrice":27.5'));
      expect(mockClient.lastBody, contains('"offer_price":27.5'));
      expect(mockClient.lastBody, contains('Can deliver 1000kg grade-A Diamant potatoes'));

      expect(result.id, 'd0e0278a-38a5-4fba-a478-f7a529e356b7');
      expect(result.demandId, testDemandId);
      expect(result.farmerId, '92f6839a-5d0c-40a7-bd92-a5080cd8b070');
      expect(result.offerPrice, 27.5);
      expect(result.note, contains('grade-A Diamant potatoes'));
    });

    test('DemandProvider submitDemandOffer updates provider state and history', () async {
      final mockClient = MockDemandOfferHttpClient();
      final dataSource = BuyerRemoteDataSourceImpl(client: mockClient);
      final repo = BuyerRepositoryImpl(remoteDataSource: dataSource);
      final useCase = SubmitDemandOfferUseCase(repo);
      final provider = DemandProvider(
        buyerRepository: repo,
        submitDemandOfferUseCase: useCase,
      );

      expect(provider.isSubmittingOffer, isFalse);
      expect(provider.lastSubmittedOffer, isNull);

      final offer = await provider.submitDemandOffer(
        demandId: testDemandId,
        offerPrice: 27.5,
        note: 'Can deliver 1000kg grade-A Diamant potatoes by tomorrow.',
        token: BuyerRemoteDataSourceImpl.defaultDemandOfferToken,
      );

      expect(provider.isSubmittingOffer, isFalse);
      expect(provider.lastSubmittedOffer, isNotNull);
      expect(provider.lastSubmittedOffer!.offerPrice, equals(27.5));
      expect(provider.myOffers.length, 1);
      expect(provider.myOffers.first.id, offer.id);
    });

    testWidgets('SubmitDemandOfferSheet displays cURL defaults and submits successfully', (WidgetTester tester) async {
      final mockClient = MockDemandOfferHttpClient();
      final dataSource = BuyerRemoteDataSourceImpl(client: mockClient);
      final repo = BuyerRepositoryImpl(remoteDataSource: dataSource);
      final useCase = SubmitDemandOfferUseCase(repo);
      final demandProvider = DemandProvider(
        buyerRepository: repo,
        submitDemandOfferUseCase: useCase,
      );
      final authProvider = AuthProvider();

      bool callbackFired = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DemandProvider>.value(value: demandProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SubmitDemandOfferSheet(
                demand: testDemand,
                onOfferSubmitted: () {
                  callbackFired = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify endpoint pill matches curl
      expect(find.text('/api/v1/demands/$testDemandId/offer'), findsOneWidget);
      expect(find.text('POST'), findsOneWidget);

      // Verify default values from cURL
      expect(find.text('27.5'), findsOneWidget);
      expect(find.text('Can deliver 1000kg grade-A Diamant potatoes by tomorrow.'), findsOneWidget);
      expect(find.text('cURL Default: ৳27.5'), findsOneWidget);

      // Verify target price info
      expect(find.text('৳28 / KG'), findsOneWidget);

      // Tap Submit Offer
      await tester.ensureVisible(find.text('Submit Offer'));
      await tester.tap(find.text('Submit Offer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify submission request sent
      expect(mockClient.lastMethod, 'POST');
      expect(mockClient.lastUri.toString(), ApiPath.demandOffer(testDemandId));
      expect(callbackFired, isTrue);
    });
  });
}
