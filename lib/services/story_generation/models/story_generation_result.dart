import 'package:equatable/equatable.dart';

import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/enums/story_tone.dart';

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
    this.generationSource = 'unknown',
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
  final String generationSource;

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
    String? generationSource,
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
      generationSource: generationSource ?? this.generationSource,
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
    generationSource,
  ];
}
