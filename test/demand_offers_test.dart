import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/features/buyer/data/datasources/buyer_remote_data_source.dart';
import 'package:chashibhai/features/buyer/data/repositories/buyer_repository_impl.dart';
import 'package:chashibhai/features/buyer/domain/usecases/get_demand_offers_usecase.dart';
import 'package:chashibhai/features/buyer/domain/usecases/get_demand_by_id_usecase.dart';
import 'package:chashibhai/features/buyer/domain/usecases/accept_demand_offer_usecase.dart';
import 'package:chashibhai/features/buyer/presentation/state/demand_provider.dart';
import 'package:chashibhai/features/buyer/presentation/views/demand_offers_screen.dart';

class MockDemandOffersHttpClient implements HttpClient {
  String? lastMethod;
  Uri? lastUri;
  Map<String, String> lastHeaders = {};

  final String demandJsonResponse = jsonEncode({
    'success': true,
    'data': {
      'id': 'b93b37c9-64b8-4844-a3a0-95390974aeab',
      'buyerId': '395e2439-099f-41da-a739-019f5a08e504',
      'productName': 'Potatoes vb(Diamant)',
      'quantity': 1000,
      'callingPrice': 28,
      'deliveryLocation': 'Karwan Bazar, Dhaka',
      'expiryTime': '2026-11-30T18:00:00+00:00',
      'status': 'active',
      'tradeType': 'both',
      'imageUrl': 'https://nimydnehbwyorkpefbgr.supabase.co/storage/v1/object/public/product-images/products/test.jpg',
      'createdAt': '2026-11-18T18:20:18.592381+00:00',
      'buyer': {
        'id': '395e2439-099f-41da-a739-019f5a08e504',
        'name': 'Buyer From App',
        'phone': '+8801407070311',
      },
      'offersCount': 2,
    }
  });

  final String offersJsonResponse = jsonEncode({
    'success': true,
    'data': [
      {
        'id': 'dfb71d92-a406-447c-8208-67c6bd6c73b3',
        'demandId': 'b93b37c9-64b8-4844-a3a0-95390974aeab',
        'farmerId': '92f6839a-5d0c-40a7-bd92-a5080cd8b070',
        'offerPrice': 27.5,
        'note': 'Can deliver 1000kg grade-A Diamant potatoes by tomorrow.',
        'createdAt': '2026-11-20T19:28:30.016524+00:00',
        'farmer': {
          'id': '92f6839a-5d0c-40a7-bd92-a5080cd8b070',
          'name': 'Rafiq Ahmed',
          'phone': '+8801740719205',
          'rating': 4.8,
          'avatarUrl': null,
          'district': 'Bogura',
        }
      },
      {
        'id': '0130a81e-2539-45ca-912e-89de6c6449ea',
        'demandId': 'b93b37c9-64b8-4844-a3a0-95390974aeab',
        'farmerId': '92f6839a-5d0c-40a7-bd92-a5080cd8b070',
        'offerPrice': 27.8,
        'note': 'Second batch ready for prompt dispatch.',
        'createdAt': '2026-11-21T02:36:02.179565+00:00',
        'farmer': {
          'id': '92f6839a-5d0c-40a7-bd92-a5080cd8b070',
          'name': 'Rafiq Ahmed',
          'phone': '+8801740719205',
          'rating': 4.8,
          'avatarUrl': null,
          'district': 'Bogura',
        }
      }
    ]
  });

  final String acceptOfferJsonResponse = jsonEncode({
    'success': true,
    'message': 'Offer accepted successfully. Demand fulfilled and order created.',
    'data': {
      'demandId': 'b93b37c9-64b8-4844-a3a0-95390974aeab',
      'offerId': 'dfb71d92-a406-447c-8208-67c6bd6c73b3',
      'status': 'fulfilled',
      'order': {
        'id': 'ord_accept_test_1',
        'status': 'confirmed',
      }
    }
  });

  @override
  Duration? connectionTimeout;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl) {
      lastMethod = 'GET';
      lastUri = invocation.positionalArguments.first as Uri;
      final isDemandDetails = !lastUri.toString().contains('/offers');
      final body = isDemandDetails ? demandJsonResponse : offersJsonResponse;
      return Future.value(_MockDemandOffersHttpClientRequest(this, body));
    }
    if (invocation.memberName == #postUrl) {
      lastMethod = 'POST';
      lastUri = invocation.positionalArguments.first as Uri;
      return Future.value(_MockDemandOffersHttpClientRequest(this, acceptOfferJsonResponse));
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockDemandOffersHttpClientRequest implements HttpClientRequest {
  final MockDemandOffersHttpClient parent;
  final String responseBody;

  _MockDemandOffersHttpClientRequest(this.parent, this.responseBody);

  @override
  HttpHeaders get headers => _MockDemandOffersHttpHeaders(parent.lastHeaders);

  @override
  void write(Object? obj) {}

  @override
  Future<HttpClientResponse> close() {
    return Future.value(_MockDemandOffersHttpClientResponse(responseBody));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockDemandOffersHttpHeaders implements HttpHeaders {
  final Map<String, String> headersMap;

  _MockDemandOffersHttpHeaders(this.headersMap);

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    headersMap[name] = value.toString();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockDemandOffersHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  final String body;

  _MockDemandOffersHttpClientResponse(this.body);

  @override
  int get statusCode => 200;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(utf8.encode(body)).listen(
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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Demand Offers Unit and Integration Tests', () {
    test('BuyerRemoteDataSourceImpl fetches demand offers and single demand correctly', () async {
      final mockClient = MockDemandOffersHttpClient();
      final remoteDataSource = BuyerRemoteDataSourceImpl(client: mockClient);

      final offers = await remoteDataSource.getDemandOffers(
        demandId: 'b93b37c9-64b8-4844-a3a0-95390974aeab',
      );

      expect(offers.length, 2);
      expect(offers.first.demandId, 'b93b37c9-64b8-4844-a3a0-95390974aeab');
      expect(offers.first.offerPrice, 27.5);
      expect(offers.first.note, contains('grade-A Diamant'));
      expect(offers.first.farmer?.name, 'Rafiq Ahmed');
      expect(offers.first.farmer?.district, 'Bogura');
      expect(offers.first.farmer?.phone, '+8801740719205');
      expect(offers.first.farmer?.rating, 4.8);

      final demand = await remoteDataSource.getDemandById(
        demandId: 'b93b37c9-64b8-4844-a3a0-95390974aeab',
      );

      expect(demand.id, 'b93b37c9-64b8-4844-a3a0-95390974aeab');
      expect(demand.productName, 'Potatoes vb(Diamant)');
      expect(demand.quantity, 1000.0);
      expect(demand.callingPrice, 28.0);
      expect(demand.deliveryLocation, 'Karwan Bazar, Dhaka');
      expect(demand.offersCount, 2);
    });

    test('DemandProvider manages demand offers state correctly', () async {
      final mockClient = MockDemandOffersHttpClient();
      final remoteDataSource = BuyerRemoteDataSourceImpl(client: mockClient);
      final repo = BuyerRepositoryImpl(remoteDataSource: remoteDataSource);
      final provider = DemandProvider(
        getDemandOffersUseCase: GetDemandOffersUseCase(repo),
        getDemandByIdUseCase: GetDemandByIdUseCase(repo),
        buyerRepository: repo,
      );

      expect(provider.isOffersLoading, false);

      final offers = await provider.fetchDemandOffers(
        demandId: 'b93b37c9-64b8-4844-a3a0-95390974aeab',
      );

      expect(offers.length, 2);
      expect(provider.getOffersForDemand('b93b37c9-64b8-4844-a3a0-95390974aeab').length, 2);
      expect(provider.isOffersLoading, false);

      final demand = await provider.fetchDemandById(
        demandId: 'b93b37c9-64b8-4844-a3a0-95390974aeab',
      );

      expect(demand.productName, 'Potatoes vb(Diamant)');
      expect(provider.getDemandDetail('b93b37c9-64b8-4844-a3a0-95390974aeab')?.productName, 'Potatoes vb(Diamant)');
    });

    test('BuyerRemoteDataSourceImpl accepts offer using cURL specs', () async {
      final mockClient = MockDemandOffersHttpClient();
      final remoteDataSource = BuyerRemoteDataSourceImpl(client: mockClient);

      final result = await remoteDataSource.acceptDemandOffer(
        demandId: 'b93b37c9-64b8-4844-a3a0-95390974aeab',
        offerId: 'dfb71d92-a406-447c-8208-67c6bd6c73b3',
      );

      expect(result.success, true);
      expect(result.status, 'fulfilled');
      expect(result.demandId, 'b93b37c9-64b8-4844-a3a0-95390974aeab');
      expect(result.offerId, 'dfb71d92-a406-447c-8208-67c6bd6c73b3');
      expect(mockClient.lastMethod, 'POST');
      expect(
        mockClient.lastUri.toString(),
        'http://localhost:3000/api/v1/demands/b93b37c9-64b8-4844-a3a0-95390974aeab/offers/dfb71d92-a406-447c-8208-67c6bd6c73b3/accept',
      );
    });

    test('DemandProvider accepts demand offer and updates status to fulfilled', () async {
      final mockClient = MockDemandOffersHttpClient();
      final remoteDataSource = BuyerRemoteDataSourceImpl(client: mockClient);
      final repo = BuyerRepositoryImpl(remoteDataSource: remoteDataSource);
      final provider = DemandProvider(
        getDemandOffersUseCase: GetDemandOffersUseCase(repo),
        getDemandByIdUseCase: GetDemandByIdUseCase(repo),
        acceptDemandOfferUseCase: AcceptDemandOfferUseCase(repo),
        buyerRepository: repo,
      );

      await provider.fetchDemandById(demandId: 'b93b37c9-64b8-4844-a3a0-95390974aeab');
      expect(provider.getDemandDetail('b93b37c9-64b8-4844-a3a0-95390974aeab')?.status, DemandStatus.active);

      final result = await provider.acceptDemandOffer(
        demandId: 'b93b37c9-64b8-4844-a3a0-95390974aeab',
        offerId: 'dfb71d92-a406-447c-8208-67c6bd6c73b3',
      );

      expect(result.success, true);
      expect(result.status, 'fulfilled');
      expect(provider.lastAcceptedOfferResult?.offerId, 'dfb71d92-a406-447c-8208-67c6bd6c73b3');
      expect(provider.getDemandDetail('b93b37c9-64b8-4844-a3a0-95390974aeab')?.status, DemandStatus.fulfilled);
    });

    testWidgets('DemandOffersScreen renders demand details, intelligence banner, and farmer offers', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockClient = MockDemandOffersHttpClient();
      final remoteDataSource = BuyerRemoteDataSourceImpl(client: mockClient);
      final repo = BuyerRepositoryImpl(remoteDataSource: remoteDataSource);
      final provider = DemandProvider(
        getDemandOffersUseCase: GetDemandOffersUseCase(repo),
        getDemandByIdUseCase: GetDemandByIdUseCase(repo),
        acceptDemandOfferUseCase: AcceptDemandOfferUseCase(repo),
        buyerRepository: repo,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DemandProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: DemandOffersScreen(
              demandId: 'b93b37c9-64b8-4844-a3a0-95390974aeab',
            ),
          ),
        ),
      );

      // Initial frame with loading
      await tester.pump();
      // Pump until futures complete
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify Demand Details
      expect(find.text('Demand Offers'), findsOneWidget);
      expect(find.text('Potatoes vb(Diamant)'), findsWidgets);
      expect(find.text('Karwan Bazar, Dhaka'), findsOneWidget);
      expect(find.text('Target Price'), findsOneWidget);
      expect(find.text('1,000 KG'), findsOneWidget);

      // Verify Market Intelligence banner
      expect(find.text('Market Intelligence'), findsOneWidget);
      expect(find.text('Best Offer'), findsOneWidget);
      expect(find.text('Average Offer'), findsOneWidget);
      expect(find.text('Max Savings'), findsOneWidget);

      // Verify Farmer Offers
      expect(find.text('Rafiq Ahmed'), findsWidgets);
      expect(find.text('Bogura'), findsWidgets);
      expect(find.text('Can deliver 1000kg grade-A Diamant potatoes by tomorrow.'), findsOneWidget);
      expect(find.text('Accept Offer'), findsWidgets);
      expect(find.text('Call'), findsWidgets);

      // Scroll to and tap Accept Offer button
      await tester.ensureVisible(find.text('Accept Offer').first);
      await tester.tap(find.text('Accept Offer').first);
      await tester.pumpAndSettle();

      // Verify confirmation sheet opens
      expect(find.text('Accept Farmer Offer'), findsOneWidget);
      expect(find.text('Total Escrow Deposit'), findsOneWidget);
      expect(find.text('Confirm & Proceed'), findsOneWidget);

      // Tap Confirm & Proceed
      await tester.tap(find.text('Confirm & Proceed'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify success snackbar appears
      expect(find.text('Offer accepted successfully. Demand fulfilled and order created.'), findsOneWidget);
    });
  });
}
