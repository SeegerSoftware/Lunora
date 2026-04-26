import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
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

  /// Libellé lisible pour logs (mini vs 4o vs autre).
  static String modelKindLabel(String model) {
    final m = model.trim().toLowerCase();
    if (m.contains('mini')) return 'mini (économique)';
    if (m.contains('gpt-4o')) return 'gpt-4o (premium / famille)';
    if (m.startsWith('gpt-4')) return 'gpt-4 ($model)';
    if (m.startsWith('o1') || m.startsWith('o3')) return 'reasoning ($model)';
    return 'autre ($model)';
  }

  static void _logOutgoingCall({
    required String resolvedModel,
    required int systemChars,
    required int userChars,
  }) {
    final kind = modelKindLabel(resolvedModel);
    final msg =
        'OpenAI chat/completions → ce prompt part sur le modèle '
        '"$resolvedModel" ($kind) | system $systemChars car., user $userChars car.';
    developer.log(msg, name: 'elunai.openai');
    debugPrint('[elunai.openai] $msg');
  }

  /// Corps brut du message assistant (JSON attendu).
  ///
  /// [modelOverride] permet d’appeler un autre modèle sans dupliquer le client.
  Future<String> completeJsonChat({
    required String systemMessage,
    required String userMessage,
    String? modelOverride,
    double temperature = 0.55,
    int maxTokens = 4500,
  }) async {
    final resolvedModel = (modelOverride ?? _model).trim();
    if (kDebugMode || AiGenerationConfig.logOpenAiCalls) {
      _logOutgoingCall(
        resolvedModel: resolvedModel,
        systemChars: systemMessage.length,
        userChars: userMessage.length,
      );
    }

    final payload = <String, dynamic>{
      'model': resolvedModel,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'response_format': const {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': systemMessage},
        {'role': 'user', 'content': userMessage},
      ],
    };

    if (AiGenerationConfig.logOpenAiPrompts) {
      debugPrint(
        '\n════════ Elunai OpenAI (avant envoi) ════════\n'
        'model: $resolvedModel (${modelKindLabel(resolvedModel)})\n'
        '--- system ---\n$systemMessage\n'
        '--- user ---\n$userMessage\n'
        '════════════════════════════════════════════\n',
      );
    }

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
