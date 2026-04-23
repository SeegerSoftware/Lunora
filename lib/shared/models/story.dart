import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'enums/story_format.dart';
import 'enums/story_tone.dart';

class Story extends Equatable {
  const Story({
    required this.id,
    required this.childId,
    required this.userId,
    required this.dateKey,
    required this.title,
    required this.content,
    required this.summary,
    required this.theme,
    required this.tone,
    required this.estimatedReadingMinutes,
    required this.format,
    required this.chapterNumber,
    required this.totalChapters,
    this.seriesId,
    this.generationSource = 'unknown',
    required this.createdAt,
  });

  final String id;
  final String childId;
  final String userId;
  final String dateKey;
  final String title;
  final String content;
  final String summary;
  final String theme;
  final StoryTone tone;
  final int estimatedReadingMinutes;
  final StoryFormat format;
  final int chapterNumber;
  final int totalChapters;
  final String? seriesId;
  final String generationSource;
  final DateTime createdAt;

  bool get isSerialized => format == StoryFormat.serializedChapters;

  Story copyWith({
    String? id,
    String? childId,
    String? userId,
    String? dateKey,
    String? title,
    String? content,
    String? summary,
    String? theme,
    StoryTone? tone,
    int? estimatedReadingMinutes,
    StoryFormat? format,
    int? chapterNumber,
    int? totalChapters,
    String? seriesId,
    String? generationSource,
    DateTime? createdAt,
  }) {
    return Story(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      userId: userId ?? this.userId,
      dateKey: dateKey ?? this.dateKey,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      theme: theme ?? this.theme,
      tone: tone ?? this.tone,
      estimatedReadingMinutes:
          estimatedReadingMinutes ?? this.estimatedReadingMinutes,
      format: format ?? this.format,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      totalChapters: totalChapters ?? this.totalChapters,
      seriesId: seriesId ?? this.seriesId,
      generationSource: generationSource ?? this.generationSource,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'userId': userId,
      'dateKey': dateKey,
      'title': title,
      'content': content,
      'summary': summary,
      'theme': theme,
      'tone': tone.wireValue,
      'estimatedReadingMinutes': estimatedReadingMinutes,
      'format': format.wireValue,
      'chapterNumber': chapterNumber,
      'totalChapters': totalChapters,
      'seriesId': seriesId,
      'generationSource': generationSource,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Story.fromMap(Map<String, dynamic> map) {
    return Story(
      id: map['id'] as String,
      childId: map['childId'] as String,
      userId: map['userId'] as String,
      dateKey: map['dateKey'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      summary: map['summary'] as String,
      theme: map['theme'] as String,
      tone: StoryToneX.parse(map['tone'] as String?),
      estimatedReadingMinutes: (map['estimatedReadingMinutes'] as num).toInt(),
      format: StoryFormatFirestore.parse(map['format'] as String?),
      chapterNumber: (map['chapterNumber'] as num).toInt(),
      totalChapters: (map['totalChapters'] as num).toInt(),
      seriesId: map['seriesId'] as String?,
      generationSource: (map['generationSource'] as String?) ?? 'unknown',
      createdAt: _readDate(map['createdAt']),
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    throw FormatException('Unsupported date: $value');
  }

  @override
  List<Object?> get props => [
    id,
    childId,
    userId,
    dateKey,
    title,
    content,
    summary,
    theme,
    tone,
    estimatedReadingMinutes,
    format,
    chapterNumber,
    totalChapters,
    seriesId,
    generationSource,
    createdAt,
  ];
}
