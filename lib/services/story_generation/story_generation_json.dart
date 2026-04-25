import 'dart:convert';

import '../../core/utils/age_calculator.dart';
import '../../shared/models/enums/story_format.dart';
import '../../shared/models/enums/story_tone.dart';
import '../../shared/models/series_state.dart';
import 'models/story_generation_request.dart';
import 'models/story_generation_result.dart';
import 'story_adaptation_engine.dart';

/// Données brutes extraites du JSON modèle (champs optionnels pour robustesse).
class ParsedStoryJson {
  const ParsedStoryJson({
    this.title,
    this.content,
    this.summary,
    this.estimatedReadingMinutes,
    this.theme,
    this.toneRaw,
    this.chapterNumber,
    this.totalChapters,
    this.continuityUpdate,
  });

  final String? title;
  final String? content;
  final String? summary;
  final int? estimatedReadingMinutes;
  final String? theme;
  final String? toneRaw;
  final int? chapterNumber;
  final int? totalChapters;
  final ChapterContinuityUpdate? continuityUpdate;
}

abstract final class StoryGenerationJsonParser {
  /// Extrait un objet JSON même si le modèle a ajouté du texte autour ou des fences ```.
  static Map<String, dynamic> extractObject(String raw) {
    var s = raw.trim();
    if (s.startsWith('\uFEFF')) {
      s = s.substring(1).trim();
    }
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
    final m = fence.firstMatch(s);
    if (m != null) {
      s = (m.group(1) ?? '').trim();
    }
    final start = s.indexOf('{');
    if (start == -1) {
      throw const FormatException('JSON objet introuvable dans la réponse');
    }
    final end = _lastClosingBraceIndex(s, start);
    if (end == null || end <= start) {
      throw const FormatException('JSON objet incomplet dans la réponse');
    }
    var slice = s.substring(start, end + 1).trim();
    if (slice.startsWith('\uFEFF')) {
      slice = slice.substring(1).trim();
    }
    try {
      final decoded = jsonDecode(slice);
      if (decoded is! Map) {
        throw const FormatException('Racine JSON attendue : objet');
      }
      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw FormatException('JSON invalide après extraction : ${slice.length} car.');
    }
  }

  /// Dernière accolade fermante alignée sur la première `{` (texte narratif peut contenir `}`).
  static int? _lastClosingBraceIndex(String s, int openIndex) {
    var depth = 0;
    var inString = false;
    var escape = false;
    for (var i = openIndex; i < s.length; i++) {
      final ch = s[i];
      if (inString) {
        if (escape) {
          escape = false;
          continue;
        }
        if (ch == r'\') {
          escape = true;
          continue;
        }
        if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
        continue;
      }
      if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return null;
  }

  static String? _readTrimmedString(dynamic v) {
    if (v == null) return null;
    final t = v.toString().trim();
    return t.isEmpty ? null : t;
  }

  static ParsedStoryJson parseMap(Map<String, dynamic> m) {
    int? readInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.round();
      if (v is String) return int.tryParse(v.trim());
      return null;
    }

    return ParsedStoryJson(
      title: _readTrimmedString(m['title']),
      content: _readTrimmedString(m['content']),
      summary: _readTrimmedString(m['summary']),
      estimatedReadingMinutes: readInt(m['estimatedReadingMinutes']),
      theme: _readTrimmedString(m['theme']),
      toneRaw: _readTrimmedString(m['tone']),
      chapterNumber: readInt(m['chapterNumber']),
      totalChapters: readInt(m['totalChapters']),
      continuityUpdate: m['continuityUpdate'] is Map
          ? ChapterContinuityUpdate.fromMap(
              Map<String, dynamic>.from(m['continuityUpdate'] as Map),
            )
          : null,
    );
  }
}

abstract final class StoryGenerationResultNormalizer {
  static const int _minContentLength = 220;
  static const StoryAdaptationEngine _adaptationEngine = StoryAdaptationEngine();

  /// Valeurs de chapitre / série : la source de vérité est la requête produit (pas le modèle).
  static StoryGenerationResult normalize({
    required ParsedStoryJson parsed,
    required StoryGenerationRequest request,
  }) {
    final child = request.child;
    final displayName =
        child.firstName.trim().isEmpty ? 'toi' : child.firstName.trim();

    final title = (parsed.title != null && parsed.title!.isNotEmpty)
        ? parsed.title!
        : 'Une histoire pour $displayName';

    final rawContent = parsed.content;
    if (rawContent == null || rawContent.isEmpty) {
      throw const FormatException('content manquant');
    }
    if (rawContent.length < _minContentLength) {
      throw FormatException(
        'content trop court (${rawContent.length} car., min $_minContentLength)',
      );
    }
    final ageYears = AgeCalculator.ageInYears(
      birthMonth: child.birthMonth,
      birthYear: child.birthYear,
    );
    final minWords = _adaptationEngine.minWordsForValidation(
      ageYears: ageYears,
      requestedMinutes: child.storyLengthMinutes,
    );
    final words = _wordCount(rawContent);
    // Politique qualité: pour coller a la promesse de duree, on impose un minimum
    // plus exigeant avant d'accepter la reponse.
    final hardMinWords = (minWords * 0.85).round();
    if (words < hardMinWords) {
      throw FormatException(
        'content trop court ($words mots, min dur $hardMinWords)',
      );
    }
    final content = rawContent;

    final summary = (parsed.summary != null && parsed.summary!.isNotEmpty)
        ? parsed.summary!
        : 'Une histoire douce pour le coucher.';

    final themeLabel = (parsed.theme != null && parsed.theme!.isNotEmpty)
        ? parsed.theme!
        : (child.preferredThemes.isNotEmpty
            ? child.preferredThemes.first.trim()
            : 'Rituel du soir');

    final tone = _parseTone(parsed.toneRaw, fallback: child.preferredTone);

    var minutes = parsed.estimatedReadingMinutes ?? child.storyLengthMinutes;
    minutes = _nearestAllowedMinutes(minutes, child.storyLengthMinutes);

    final String? seriesId = child.storyFormat == StoryFormat.serializedChapters
        ? (request.seriesId ?? 'series_${child.id}')
        : null;

    return StoryGenerationResult(
      title: title,
      content: content,
      summary: summary,
      themeLabel: themeLabel,
      tone: tone,
      estimatedReadingMinutes: minutes,
      format: child.storyFormat,
      chapterNumber: request.chapterIndex,
      totalChapters: request.totalChapters,
      seriesId: seriesId,
      continuityUpdate: parsed.continuityUpdate,
      generationSource: 'remote-ai',
    );
  }

  static int _wordCount(String content) {
    return content
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
  }

  static int _nearestAllowedMinutes(int value, int preferred) {
    const allowed = {5, 10, 15};
    if (allowed.contains(value)) return value;
    if (allowed.contains(preferred)) return preferred;
    var best = 10;
    var bestDist = 1 << 30;
    for (final a in allowed) {
      final d = (value - a).abs();
      if (d < bestDist) {
        bestDist = d;
        best = a;
      }
    }
    return best;
  }

  static StoryTone _parseTone(String? raw, {required StoryTone fallback}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final t = raw.trim();
    for (final e in StoryTone.values) {
      if (e.name == t || e.wireValue == t) return e;
      if (e.displayLabel.toLowerCase() == t.toLowerCase()) return e;
    }
    return fallback;
  }
}
