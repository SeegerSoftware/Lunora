import 'package:equatable/equatable.dart';

import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/enums/story_tone.dart';
import '../../../shared/models/series_state.dart';

class StoryGenerationResult extends Equatable {
  const StoryGenerationResult({
    required this.title,
    required this.content,
    required this.summary,
    required this.themeLabel,
    required this.tone,
    required this.estimatedReadingMinutes,
    required this.format,
    required this.chapterNumber,
    required this.totalChapters,
    this.seriesId,
    this.continuityUpdate,
    this.generationSource = 'unknown',
    this.qualityScore = 0,
    this.qualityDetails = const {},
    this.qualityWarnings = const [],
    this.coverPrompt,
  });

  final String title;
  final String content;
  final String summary;
  final String themeLabel;
  final StoryTone tone;
  final int estimatedReadingMinutes;
  final StoryFormat format;
  final int chapterNumber;
  final int totalChapters;
  final String? seriesId;
  final ChapterContinuityUpdate? continuityUpdate;
  final String generationSource;
  final int qualityScore;
  final Map<String, int> qualityDetails;
  final List<String> qualityWarnings;
  final String? coverPrompt;

  StoryGenerationResult copyWith({
    String? title,
    String? content,
    String? summary,
    String? themeLabel,
    StoryTone? tone,
    int? estimatedReadingMinutes,
    StoryFormat? format,
    int? chapterNumber,
    int? totalChapters,
    String? seriesId,
    ChapterContinuityUpdate? continuityUpdate,
    String? generationSource,
    int? qualityScore,
    Map<String, int>? qualityDetails,
    List<String>? qualityWarnings,
    String? coverPrompt,
  }) {
    return StoryGenerationResult(
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      themeLabel: themeLabel ?? this.themeLabel,
      tone: tone ?? this.tone,
      estimatedReadingMinutes:
          estimatedReadingMinutes ?? this.estimatedReadingMinutes,
      format: format ?? this.format,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      totalChapters: totalChapters ?? this.totalChapters,
      seriesId: seriesId ?? this.seriesId,
      continuityUpdate: continuityUpdate ?? this.continuityUpdate,
      generationSource: generationSource ?? this.generationSource,
      qualityScore: qualityScore ?? this.qualityScore,
      qualityDetails: qualityDetails ?? this.qualityDetails,
      qualityWarnings: qualityWarnings ?? this.qualityWarnings,
      coverPrompt: coverPrompt ?? this.coverPrompt,
    );
  }

  @override
  List<Object?> get props => [
    title,
    content,
    summary,
    themeLabel,
    tone,
    estimatedReadingMinutes,
    format,
    chapterNumber,
    totalChapters,
    seriesId,
    continuityUpdate,
    generationSource,
    qualityScore,
    qualityDetails,
    qualityWarnings,
    coverPrompt,
  ];
}
