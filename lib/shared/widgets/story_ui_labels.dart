import '../models/story.dart';
import '../../core/config/ai_generation_config.dart';

String storyFormatLabel(Story story) {
  if (story.isSerialized) return 'Chapitre';
  return 'Histoire unique';
}

String storySourceLabel(String source) {
  final lower = source.toLowerCase();
  if (lower.contains('fallback')) return 'Mode secours';
  return 'Création personnalisée';
}

String readingDurationLabel(int minutes) => '$minutes min';

String storyModelLabel(String source) {
  final lower = source.toLowerCase();
  if (lower.contains('fallback')) return 'mode secours local';
  if (lower.contains('gpt-4o')) return AiGenerationConfig.openaiModelPremium;
  return AiGenerationConfig.openaiModel;
}
