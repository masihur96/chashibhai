import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../constants/api_path.dart';
import '../utils/storage_service.dart';

/// Centralized manager for handling automatic access token refresh using the stored refresh token.
/// Prevents concurrent duplicate refresh requests and synchronizes new tokens across the app.
class TokenRefreshManager {
  static final TokenRefreshManager _instance = TokenRefreshManager._internal();
  factory TokenRefreshManager() => _instance;
  TokenRefreshManager._internal();

  HttpClient _client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  Future<String?>? _ongoingRefreshFuture;

  /// Visible for testing to inject a custom HttpClient
  @visibleForTesting
  set client(HttpClient client) {
    _client = client;
  }

  /// Listeners notified whenever tokens are refreshed
  final List<void Function(String newAccessToken, String? newRefreshToken)> _listeners = [];

  void addTokenListener(void Function(String newAccessToken, String? newRefreshToken) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeTokenListener(void Function(String newAccessToken, String? newRefreshToken) listener) {
    _listeners.remove(listener);
  }

  /// Refreshes the access token using the stored refresh token via POST /api/v1/auth/refresh.
  /// If a refresh is already in progress, subsequent callers await the same in-flight future.
  Future<String?> refresh({String? explicitRefreshToken, HttpClient? client}) async {
    if (_ongoingRefreshFuture != null) {
      debugPrint('⏳ [TOKEN_REFRESH] Refresh already in progress, awaiting existing request...');
      return await _ongoingRefreshFuture;
    }

    _ongoingRefreshFuture = _performRefresh(explicitRefreshToken: explicitRefreshToken, customClient: client);
    try {
      return await _ongoingRefreshFuture;
    } finally {
      _ongoingRefreshFuture = null;
    }
  }

  Future<String?> _performRefresh({String? explicitRefreshToken, HttpClient? customClient}) async {
    try {
      final refreshToken = explicitRefreshToken ?? await StorageService().getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('⚠️ [TOKEN_REFRESH] No refresh token available in storage.');
        return null;
      }

      final refreshUri = Uri.parse(ApiPath.refresh);
      debugPrint('🔄 [TOKEN_REFRESH] Refreshing access token via POST ${refreshUri.toString()}...');

      final effectiveClient = customClient ?? _client;
      final req = await effectiveClient.postUrl(refreshUri);
      req.encoding = utf8;
      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      req.headers.set('accept', '*/*');

      final bodyBytes = utf8.encode(jsonEncode({'refreshToken': refreshToken}));
      req.contentLength = bodyBytes.length;
      req.add(bodyBytes);

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();

      if (res.statusCode == 200 || res.statusCode == 201) {
        dynamic decoded;
        try {
          decoded = jsonDecode(body);
        } catch (_) {
          decoded = null;
        }

        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'] is Map<String, dynamic> ? decoded['data'] : decoded;
          final newAccess = data['accessToken'] ?? data['access_token'] ?? data['token'];
          final newRefresh = data['refreshToken'] ?? data['refresh_token'];

          if (newAccess != null && newAccess.toString().isNotEmpty) {
            final accessStr = newAccess.toString();
            final refreshStr = newRefresh?.toString();

            await StorageService().saveAuthTokens(
              accessToken: accessStr,
              refreshToken: refreshStr,
            );

            debugPrint('✅ [TOKEN_REFRESH] Access token refreshed and persisted to Hive successfully.');

            // Notify listeners (e.g. AuthProvider)
            for (final listener in List.from(_listeners)) {
              try {
                listener(accessStr, refreshStr);
              } catch (e) {
                debugPrint('⚠️ [TOKEN_REFRESH] Error notifying token listener: $e');
              }
            }

            return accessStr;
          }
        }
      } else {
        debugPrint('❌ [TOKEN_REFRESH] Token refresh failed with HTTP ${res.statusCode}: $body');
      }
    } catch (e) {
      debugPrint('⚠️ [TOKEN_REFRESH] Exception during token refresh: $e');
    }
    return null;
  }
}
