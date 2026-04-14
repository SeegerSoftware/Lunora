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
  ];
}
