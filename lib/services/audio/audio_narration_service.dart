import 'dart:convert';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NarrationVoice {
  const NarrationVoice({required this.name, required this.locale});

  final String name;
  final String locale;

  String get id => '$locale::$name';

  String get label {
    final language = locale.replaceAll('_', '-');
    return '$name ($language)';
  }

  Map<String, String> toMap() => {'name': name, 'locale': locale};

  factory NarrationVoice.fromMap(Map<String, dynamic> map) {
    return NarrationVoice(
      name: map['name']?.toString() ?? '',
      locale: map['locale']?.toString() ?? '',
    );
  }
}

class AudioNarrationService {
  AudioNarrationService({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();

  static const _preferredVoiceKey = 'audio_narration_preferred_voice';
  static const _defaultLocale = 'fr-FR';
  static const _maxChunkLength = 3500;

  final FlutterTts _flutterTts;
  var _playbackGeneration = 0;

  Future<List<NarrationVoice>> availableFrenchVoices() async {
    final rawVoices = await _flutterTts.getVoices;
    if (rawVoices is! List) return const [];

    final voices = rawVoices
        .whereType<Map>()
        .map(
          (raw) => NarrationVoice(
            name: raw['name']?.toString() ?? '',
            locale: raw['locale']?.toString() ?? '',
          ),
        )
        .where(
          (voice) =>
              voice.name.isNotEmpty &&
              voice.locale.toLowerCase().startsWith('fr'),
        )
        .toList();
    voices.sort((a, b) => a.label.compareTo(b.label));
    return voices;
  }

  Future<NarrationVoice?> preferredVoice() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_preferredVoiceKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final voice = NarrationVoice.fromMap(decoded);
      return voice.name.isEmpty || voice.locale.isEmpty ? null : voice;
    } on FormatException {
      return null;
    }
  }

  Future<void> savePreferredVoice(NarrationVoice? voice) async {
    final prefs = await SharedPreferences.getInstance();
    if (voice == null) {
      await prefs.remove(_preferredVoiceKey);
      return;
    }
    await prefs.setString(_preferredVoiceKey, jsonEncode(voice.toMap()));
  }

  Future<void> speak({required String title, required String content}) async {
    final generation = ++_playbackGeneration;
    await _flutterTts.stop();
    await _flutterTts.setLanguage(_defaultLocale);
    await _flutterTts.setSpeechRate(0.42);
    await _flutterTts.setPitch(0.96);
    await _flutterTts.awaitSpeakCompletion(true);

    final voice = await preferredVoice();
    if (voice != null) {
      try {
        await _flutterTts.setVoice(voice.toMap());
      } on Object {
        // Une voix peut disparaitre apres une mise a jour de l'appareil.
        // La langue francaise definie plus haut reste alors le repli systeme.
      }
    }

    for (final chunk in splitIntoChunks('$title.\n\n$content')) {
      if (generation != _playbackGeneration) return;
      await _flutterTts.speak(chunk);
    }
  }

  Future<void> stop() async {
    _playbackGeneration++;
    await _flutterTts.stop();
  }

  Future<void> dispose() => stop();

  static List<String> splitIntoChunks(
    String text, {
    int maxLength = _maxChunkLength,
  }) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return const [];
    if (maxLength < 1) {
      throw ArgumentError.value(maxLength, 'maxLength', 'Must be positive');
    }

    final sentences = normalized
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((sentence) => sentence.isNotEmpty);
    final chunks = <String>[];
    var current = '';

    void appendCurrent() {
      if (current.isEmpty) return;
      chunks.add(current);
      current = '';
    }

    for (final sentence in sentences) {
      if (sentence.length > maxLength) {
        appendCurrent();
        var remaining = sentence;
        while (remaining.length > maxLength) {
          final splitAt = remaining.lastIndexOf(' ', maxLength);
          final end = splitAt > 0 ? splitAt : maxLength;
          chunks.add(remaining.substring(0, end).trim());
          remaining = remaining.substring(end).trim();
        }
        current = remaining;
        continue;
      }

      final candidate = current.isEmpty ? sentence : '$current $sentence';
      if (candidate.length > maxLength) {
        appendCurrent();
        current = sentence;
      } else {
        current = candidate;
      }
    }
    appendCurrent();
    return chunks;
  }
}
