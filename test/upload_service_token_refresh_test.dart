import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:chashibhai/core/constants/api_path.dart';
import 'package:chashibhai/core/services/token_refresh_service.dart';
import 'package:chashibhai/core/services/upload_service.dart';
import 'package:chashibhai/core/utils/storage_service.dart';

class MockUploadHttpClient implements HttpClient {
  int uploadCallCount = 0;
  int refreshCallCount = 0;
  String? lastUploadToken;
  String? lastRefreshTokenSent;

  bool return401OnFirstUpload = true;
  bool returnSuccessOnRefresh = true;

  @override
  Duration? connectionTimeout;

  @override
  bool autoUncompress = true;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}

  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}

  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {}

  @override
  void close({bool force = false}) {}

  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) {}

  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  set keyLog(Function(String line)? callback) {}

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    final path = url.path;

    if (path.contains('/auth/refresh')) {
      refreshCallCount++;
      return _MockRefreshHttpRequest(this);
    } else if (path.contains('/upload')) {
      uploadCallCount++;
      return _MockUploadHttpRequest(this);
    }

    throw UnsupportedError('Unexpected postUrl: $url');
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => throw UnimplementedError();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => throw UnimplementedError();

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async => throw UnimplementedError();

  @override
  Future<HttpClientRequest> patchUrl(Uri url) async => throw UnimplementedError();

  @override
  Future<HttpClientRequest> putUrl(Uri url) async => throw UnimplementedError();

  @override
  Future<HttpClientRequest> headUrl(Uri url) async => throw UnimplementedError();

  @override
  Future<HttpClientRequest> get(String host, int port, String path) async => throw UnimplementedError();

  @override
  Future<HttpClientRequest> post(String host, int port, String path) async => throw UnimplementedError();

  @override
  Future<HttpClientRequest> put(String host, int port, String path) async => throw UnimplementedError();

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) async => throw UnimplementedError();

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) async => throw UnimplementedError();

  @override
  Future<HttpClientRequest> head(String host, int port, String path) async => throw UnimplementedError();

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) async => throw UnimplementedError();
}

class _MockUploadHttpRequest implements HttpClientRequest {
  final MockUploadHttpClient parent;
  final _MockHttpHeaders _headers = _MockHttpHeaders();
  final List<int> _bodyBytes = [];

  _MockUploadHttpRequest(this.parent);

  @override
  HttpHeaders get headers => _headers;

  @override
  void add(List<int> data) {
    _bodyBytes.addAll(data);
  }

  @override
  void write(Object? obj) {
    if (obj != null) {
      _bodyBytes.addAll(utf8.encode(obj.toString()));
    }
  }

  @override
  Future<HttpClientResponse> close() async {
    final authHeader = _headers.getHeader('authorization') ?? _headers.getHeader('Authorization');
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      parent.lastUploadToken = authHeader.substring('Bearer '.length);
    }

    if (parent.return401OnFirstUpload && parent.uploadCallCount == 1) {
      final errorJson = jsonEncode({
        'success': false,
        'error': 'Token has expired. Please refresh your session.',
        'statusCode': 401,
        'path': '/api/v1/upload',
        'timestamp': '2026-11-21T03:35:59.538Z',
      });
      return _MockHttpResponse(401, errorJson);
    }

    final successJson = jsonEncode({
      'success': true,
      'urls': ['http://localhost:3000/uploads/chashibhai_test_image.jpg'],
    });
    return _MockHttpResponse(200, successJson);
  }

  @override
  bool bufferOutput = true;
  @override
  int contentLength = 0;
  @override
  Encoding encoding = utf8;
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) async => stream.forEach(add);
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  List<Cookie> get cookies => [];
  @override
  Future<HttpClientResponse> get done => close();
  @override
  Future flush() async {}
  @override
  String get method => 'POST';
  @override
  Uri get uri => Uri.parse('http://localhost:3000/api/v1/upload');
  @override
  void writeAll(Iterable objects, [String separator = ""]) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = ""]) {}
  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
}

class _MockRefreshHttpRequest implements HttpClientRequest {
  final MockUploadHttpClient parent;
  final _MockHttpHeaders _headers = _MockHttpHeaders();
  final List<int> _bodyBytes = [];

  _MockRefreshHttpRequest(this.parent);

  @override
  HttpHeaders get headers => _headers;

  @override
  void add(List<int> data) {
    _bodyBytes.addAll(data);
  }

  @override
  void write(Object? obj) {
    if (obj != null) {
      _bodyBytes.addAll(utf8.encode(obj.toString()));
    }
  }

  @override
  Future<HttpClientResponse> close() async {
    final bodyStr = utf8.decode(_bodyBytes);
    try {
      final decoded = jsonDecode(bodyStr);
      if (decoded is Map && decoded.containsKey('refreshToken')) {
        parent.lastRefreshTokenSent = decoded['refreshToken']?.toString();
      }
    } catch (_) {}

    if (parent.returnSuccessOnRefresh) {
      final successJson = jsonEncode({
        'success': true,
        'data': {
          'accessToken': 'new_valid_access_token_777',
          'refreshToken': 'new_valid_refresh_token_888',
        },
      });
      return _MockHttpResponse(200, successJson);
    } else {
      final errorJson = jsonEncode({
        'success': false,
        'error': 'Invalid or expired refresh token',
        'statusCode': 401,
      });
      return _MockHttpResponse(401, errorJson);
    }
  }

  @override
  bool bufferOutput = true;
  @override
  int contentLength = 0;
  @override
  Encoding encoding = utf8;
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) async => stream.forEach(add);
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  List<Cookie> get cookies => [];
  @override
  Future<HttpClientResponse> get done => close();
  @override
  Future flush() async {}
  @override
  String get method => 'POST';
  @override
  Uri get uri => Uri.parse('http://localhost:3000/api/v1/auth/refresh');
  @override
  void writeAll(Iterable objects, [String separator = ""]) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = ""]) {}
  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
}

class _MockHttpHeaders implements HttpHeaders {
  final Map<String, String> _map = {};

  String? getHeader(String name) => _map[name.toLowerCase()];

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _map[name.toLowerCase()] = value.toString();
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _map[name.toLowerCase()] = value.toString();
  }

  @override
  List<String>? operator [](String name) {
    final val = _map[name.toLowerCase()];
    return val != null ? [val] : null;
  }

  @override
  String? value(String name) => _map[name.toLowerCase()];

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _map.forEach((k, v) => action(k, [v]));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final int statusCode;
  final String responseBody;

  _MockHttpResponse(this.statusCode, this.responseBody);

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
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  int get contentLength => utf8.encode(responseBody).length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  String get reasonPhrase => statusCode == 200 ? 'OK' : 'Unauthorized';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('hive_upload_token_test_');

  setUpAll(() async {
    Hive.init(tempDir.path);
    await StorageService().init();
  });

  tearDownAll(() async {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    await StorageService().clearAuthData();
  });

  test('UploadService catches 401, refreshes access token and retries upload automatically', () async {
    // 1. Arrange: Store expired access token and valid refresh token
    const initialExpiredToken = 'expired_access_token_111';
    const initialRefreshToken = 'valid_refresh_token_222';

    await StorageService().saveAuthTokens(
      accessToken: initialExpiredToken,
      refreshToken: initialRefreshToken,
    );

    final mockClient = MockUploadHttpClient();
    mockClient.return401OnFirstUpload = true;
    mockClient.returnSuccessOnRefresh = true;

    final uploadService = UploadService(client: mockClient);

    final item = UploadFileItem.fromBytes(
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      name: 'test_product.jpg',
      mimeType: 'image/jpeg',
    );

    // 2. Act: Upload file with expired token
    final urls = await uploadService.uploadFiles(
      items: [item],
      token: initialExpiredToken,
    );

    // 3. Assert
    // - Should have uploaded twice (1st failed with 401, 2nd succeeded after refresh)
    expect(mockClient.uploadCallCount, equals(2));
    // - Should have called refresh once
    expect(mockClient.refreshCallCount, equals(1));
    expect(mockClient.lastRefreshTokenSent, equals(initialRefreshToken));
    // - 2nd upload used the new refreshed access token
    expect(mockClient.lastUploadToken, equals('new_valid_access_token_777'));
    // - Hive StorageService now has the new tokens
    final savedAccess = await StorageService().getAccessToken();
    final savedRefresh = await StorageService().getRefreshToken();
    expect(savedAccess, equals('new_valid_access_token_777'));
    expect(savedRefresh, equals('new_valid_refresh_token_888'));
    // - URLs returned correctly from the retried upload
    expect(urls, contains('http://localhost:3000/uploads/chashibhai_test_image.jpg'));
  });

  test('UploadService throws if refresh token is missing when 401 is received', () async {
    // No tokens saved in storage
    final mockClient = MockUploadHttpClient();
    mockClient.return401OnFirstUpload = true;

    final uploadService = UploadService(client: mockClient);
    final item = UploadFileItem.fromBytes(
      bytes: Uint8List.fromList([1, 2, 3]),
      name: 'file.jpg',
      mimeType: 'image/jpeg',
    );

    expect(
      () => uploadService.uploadFiles(items: [item], token: 'invalid_token'),
      throwsA(isA<Exception>()),
    );
  });

  test('UploadService throws if refresh endpoint returns 401', () async {
    await StorageService().saveAuthTokens(
      accessToken: 'old_access',
      refreshToken: 'bad_refresh',
    );

    final mockClient = MockUploadHttpClient();
    mockClient.return401OnFirstUpload = true;
    mockClient.returnSuccessOnRefresh = false; // Refresh fails with 401

    final uploadService = UploadService(client: mockClient);
    final item = UploadFileItem.fromBytes(
      bytes: Uint8List.fromList([1, 2, 3]),
      name: 'file.jpg',
      mimeType: 'image/jpeg',
    );

    expect(
      () => uploadService.uploadFiles(items: [item], token: 'old_access'),
      throwsA(isA<Exception>()),
    );
  });

  test('TokenRefreshManager notifies listeners when token is refreshed', () async {
    await StorageService().saveAuthTokens(
      accessToken: 'stale_token',
      refreshToken: 'refresh_xyz',
    );

    final mockClient = MockUploadHttpClient();
    mockClient.returnSuccessOnRefresh = true;

    String? notifiedAccess;
    String? notifiedRefresh;

    void listener(String access, String? refresh) {
      notifiedAccess = access;
      notifiedRefresh = refresh;
    }

    TokenRefreshManager().addTokenListener(listener);

    final refreshed = await TokenRefreshManager().refresh(client: mockClient);

    expect(refreshed, equals('new_valid_access_token_777'));
    expect(notifiedAccess, equals('new_valid_access_token_777'));
    expect(notifiedRefresh, equals('new_valid_refresh_token_888'));

    TokenRefreshManager().removeTokenListener(listener);
  });
}
