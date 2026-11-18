import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../configs/network/api_logger.dart';
import '../constants/api_path.dart';
import '../utils/storage_service.dart';

/// Represents a single file payload for multipart upload
class UploadFileItem {
  final String name;
  final Uint8List bytes;
  final String mimeType;
  final String? path;

  const UploadFileItem({
    required this.name,
    required this.bytes,
    required this.mimeType,
    this.path,
  });

  /// Factory from an [XFile] (from image_picker)
  static Future<UploadFileItem> fromXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final name = file.name.isNotEmpty ? file.name : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final mimeType = file.mimeType ?? _detectMimeType(name);
    return UploadFileItem(
      name: name,
      bytes: bytes,
      mimeType: mimeType,
      path: file.path,
    );
  }

  /// Factory from a dart:io [File]
  static Future<UploadFileItem> fromFile(File file) async {
    final bytes = await file.readAsBytes();
    final name = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'image.jpg';
    return UploadFileItem(
      name: name,
      bytes: bytes,
      mimeType: _detectMimeType(name),
      path: file.path,
    );
  }

  /// Factory from raw [Uint8List] bytes
  static UploadFileItem fromBytes({
    required Uint8List bytes,
    required String name,
    String? mimeType,
    String? path,
  }) {
    return UploadFileItem(
      name: name,
      bytes: bytes,
      mimeType: mimeType ?? _detectMimeType(name),
      path: path,
    );
  }

  static String _detectMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}

class UploadService {
  final HttpClient _client;

  /// Default fallback farmer token matching curl specification
  static const String defaultFallbackToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5MmY2ODM5YS01ZDBjLTQwYTctYmQ5Mi1hNTA4MGNkOGIwNzAiLCJwaG9uZSI6Ijg4MDE3NDA3MTkyMDUiLCJlbWFpbCI6IiIsInJvbGUiOiJmYXJtZXIiLCJpYXQiOjE3OTUwMTgxNTMsImV4cCI6MTc5NTAxOTA1M30.RS_3yAvrKK79heeVSxEnF5qUprg0B1JVSudMO3zA5Yo';

  UploadService({HttpClient? client})
      : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 30);
  }

  /// Uploads one or more files to `POST /api/v1/upload` using multipart/form-data.
  ///
  /// Field name used: `files` (matching `-F 'files=@...;type=image/jpeg'`).
  ///
  /// Returns a list of uploaded image URLs provided by the server.
  Future<List<String>> uploadFiles({
    required List<UploadFileItem> items,
    String? token,
    String? customUrl,
  }) async {
    if (items.isEmpty) {
      return [];
    }

    final endpointUrl = customUrl ?? ApiPath.upload;
    final uri = Uri.parse(endpointUrl);
    final stopwatch = Stopwatch()..start();

    // Resolve Authorization Token
    String? resolvedToken = token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = await StorageService().getAccessToken();
    }
    if (resolvedToken == null || resolvedToken.isEmpty) {
      resolvedToken = defaultFallbackToken;
    }

    final boundary = '----ChashiBhaiUpload${DateTime.now().millisecondsSinceEpoch}';

    final headers = {
      'accept': 'application/json',
      'Authorization': 'Bearer $resolvedToken',
      'Content-Type': 'multipart/form-data; boundary=$boundary',
    };

    ApiLogger.logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: {
        'files_count': items.length,
        'files': items.map((i) => '${i.name} (${i.bytes.length} bytes, ${i.mimeType})').toList(),
      },
    );

    try {
      final httpRequest = await _client.postUrl(uri);
      headers.forEach((key, value) => httpRequest.headers.set(key, value));

      // Build multipart body with calculated Content-Length for strict servers
      final List<List<int>> partHeaders = [];
      final List<List<int>> partFooters = [];
      int totalContentLength = 0;

      for (final item in items) {
        final headerString =
            '--$boundary\r\n'
            'Content-Disposition: form-data; name="files"; filename="${item.name}"\r\n'
            'Content-Type: ${item.mimeType}\r\n\r\n';
        final headerBytes = utf8.encode(headerString);
        final footerBytes = utf8.encode('\r\n');

        partHeaders.add(headerBytes);
        partFooters.add(footerBytes);
        totalContentLength += headerBytes.length + item.bytes.length + footerBytes.length;
      }

      final closingBytes = utf8.encode('--$boundary--\r\n');
      totalContentLength += closingBytes.length;

      httpRequest.contentLength = totalContentLength;

      // Stream the parts
      for (int i = 0; i < items.length; i++) {
        httpRequest.add(partHeaders[i]);
        httpRequest.add(items[i].bytes);
        httpRequest.add(partFooters[i]);
      }
      httpRequest.add(closingBytes);

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

        final urls = _extractUrlsFromResponse(decodedJson ?? responseBody, ApiPath.serverOrigin);
        if (urls.isEmpty && responseBody.isNotEmpty) {
          debugPrint('⚠️ [UPLOAD] Status 200/201 but no explicit URLs parsed. Response: $responseBody');
        }
        return urls;
      } else {
        String errorMessage = 'Failed to upload images (Status code ${httpResponse.statusCode})';
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
      final err = 'Cannot connect to upload server at ${uri.host}:${uri.port} ($e). Please check backend server.';
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

  /// Extracts image URLs from diverse backend JSON formats:
  /// - { "urls": ["http://..."] }
  /// - { "url": "http://..." }
  /// - { "data": { "urls": [...] } }
  /// - { "data": ["http://...", ...] }
  /// - { "files": [ { "url": "http://..." }, ... ] }
  /// - [ "http://...", ... ]
  /// - Relative paths like "/uploads/abc.jpg"
  static List<String> _extractUrlsFromResponse(dynamic decoded, String serverOrigin) {
    final List<String> results = [];

    void inspect(dynamic value) {
      if (value == null) return;

      if (value is String) {
        final str = value.trim();
        if (str.isEmpty || str == 'string') return;

        if (str.startsWith('http://') || str.startsWith('https://')) {
          results.add(str);
        } else if (str.startsWith('/') && serverOrigin.isNotEmpty) {
          results.add('$serverOrigin$str');
        } else if (str.contains('/') && (str.endsWith('.jpg') || str.endsWith('.jpeg') || str.endsWith('.png') || str.endsWith('.webp'))) {
          // Relative path like 'uploads/xyz.jpg'
          results.add('$serverOrigin/$str');
        }
      } else if (value is List) {
        for (final item in value) {
          inspect(item);
        }
      } else if (value is Map) {
        // Check standard keys first
        const priorityKeys = [
          'urls',
          'imageUrls',
          'images',
          'files',
          'data',
          'url',
          'imageUrl',
          'path',
          'location',
          'link',
          'secure_url'
        ];

        for (final key in priorityKeys) {
          if (value.containsKey(key)) {
            inspect(value[key]);
          }
        }

        // If nothing extracted yet, inspect all values in map
        if (results.isEmpty) {
          for (final entry in value.entries) {
            final k = entry.key.toString().toLowerCase();
            if (k.contains('url') || k.contains('file') || k.contains('image') || k.contains('path')) {
              inspect(entry.value);
            }
          }
        }
      }
    }

    inspect(decoded);
    return results.toSet().toList(); // unique
  }
}
