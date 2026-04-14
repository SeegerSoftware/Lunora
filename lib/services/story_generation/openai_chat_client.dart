import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/ai_generation_config.dart';

/// Erreur HTTP / API OpenAI (ou compatible).
class OpenAiChatException implements Exception {
  OpenAiChatException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'OpenAiChatException($statusCode): $body';
}

/// Client minimal : Chat Completions + `response_format: json_object`.
class OpenAiChatClient {
  OpenAiChatClient({
    http.Client? httpClient,
    String? apiKey,
    String? model,
    String? baseUrl,
    Duration? timeout,
  })  : _http = httpClient ?? http.Client(),
        _apiKey = apiKey ?? AiGenerationConfig.openaiApiKey,
        _model = model ?? AiGenerationConfig.openaiModel,
        _baseUrl = (baseUrl ?? AiGenerationConfig.openaiBaseUrl).replaceAll(RegExp(r'/$'), ''),
        _timeout = timeout ?? AiGenerationConfig.requestTimeout;

  final http.Client _http;
  final String _apiKey;
  final String _model;
  final String _baseUrl;
  final Duration _timeout;

  Uri get _completionsUri => Uri.parse('$_baseUrl/v1/chat/completions');

  /// Corps brut du message assistant (JSON attendu).
  Future<String> completeJsonChat({
    required String systemMessage,
    required String userMessage,
    double temperature = 0.82,
    int maxTokens = 4500,
  }) async {
    final payload = <String, dynamic>{
      'model': _model,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'response_format': const {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': systemMessage},
        {'role': 'user', 'content': userMessage},
      ],
    };

    final response = await _http
        .post(
          _completionsUri,
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw OpenAiChatException(response.statusCode, response.body);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('OpenAI: réponse sans choices');
    }
    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw const FormatException('OpenAI: choice invalide');
    }
    final message = first['message'];
    if (message is! Map<String, dynamic>) {
      throw const FormatException('OpenAI: message manquant');
    }
    final content = message['content'];
    if (content is! String || content.trim().isEmpty) {
      throw const FormatException('OpenAI: contenu vide');
    }
    return content.trim();
  }

  void close() {
    _http.close();
  }
}
