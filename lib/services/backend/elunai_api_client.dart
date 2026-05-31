import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/mobile_api_config.dart';

class ElunaiApiException implements Exception {
  ElunaiApiException({
    required this.statusCode,
    required this.body,
    required this.path,
  });

  final int statusCode;
  final String body;
  final String path;

  @override
  String toString() => 'ElunaiApiException($statusCode @ $path): $body';
}

/// Client HTTP minimal pour commencer la migration mobile -> backend Elunai.
class ElunaiApiClient {
  ElunaiApiClient({http.Client? httpClient, String? baseUrl, Duration? timeout})
    : _http = httpClient ?? http.Client(),
      _baseUrl = (baseUrl ?? MobileApiConfig.baseUrl).replaceAll(
        RegExp(r'/$'),
        '',
      ),
      _timeout = timeout ?? MobileApiConfig.requestTimeout;

  final http.Client _http;
  final String _baseUrl;
  final Duration _timeout;

  bool get isConfigured => _baseUrl.isNotEmpty;

  Uri _uri(String path, [Map<String, String>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$cleanPath').replace(queryParameters: query);
  }

  Map<String, String> _headers({String? bearerToken, String? appCheckToken}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (bearerToken != null && bearerToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${bearerToken.trim()}';
    }
    if (appCheckToken != null && appCheckToken.trim().isNotEmpty) {
      headers['X-Firebase-AppCheck'] = appCheckToken.trim();
    }
    return headers;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    String? bearerToken,
    String? appCheckToken,
  }) async {
    final response = await withTimeoutMessage(
      _http.get(
        _uri(path, query),
        headers: _headers(
          bearerToken: bearerToken,
          appCheckToken: appCheckToken,
        ),
      ),
      path,
    );
    return _decodeJson(response, path);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
    String? appCheckToken,
  }) async {
    final response = await withTimeoutMessage(
      _http.post(
        _uri(path),
        headers: _headers(
          bearerToken: bearerToken,
          appCheckToken: appCheckToken,
        ),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
      path,
    );
    return _decodeJson(response, path);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, String>? query,
    String? bearerToken,
    String? appCheckToken,
  }) async {
    final response = await withTimeoutMessage(
      _http.delete(
        _uri(path, query),
        headers: _headers(
          bearerToken: bearerToken,
          appCheckToken: appCheckToken,
        ),
      ),
      path,
    );
    return _decodeJson(response, path);
  }

  Map<String, dynamic> _decodeJson(http.Response response, String path) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ElunaiApiException(
        statusCode: response.statusCode,
        body: response.body,
        path: path,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('API backend: réponse JSON objet attendue');
    }
    return decoded;
  }

  Future<T> withTimeoutMessage<T>(Future<T> request, String path) async {
    try {
      return await request.timeout(_timeout);
    } on TimeoutException {
      throw ElunaiApiException(
        statusCode: 408,
        body:
            'Le serveur met trop de temps a repondre. Reessaie dans un instant.',
        path: path,
      );
    }
  }

  void close() => _http.close();
}
