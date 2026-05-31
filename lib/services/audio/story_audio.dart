class StoryAudio {
  const StoryAudio({
    this.audioStatus = 'unavailable',
    this.audioUrl,
    this.audioVoice,
    this.audioDuration,
  });

  final String audioStatus;
  final String? audioUrl;
  final String? audioVoice;
  final int? audioDuration;
}

abstract interface class TtsProvider {
  Future<StoryAudio> generate({
    required String storyId,
    required String text,
    String? voice,
  });
}

abstract interface class AudioGenerationService {
  Future<void> enqueue(String storyId);

  Future<void> regenerate(String storyId);
}
