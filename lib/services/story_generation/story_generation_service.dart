import 'models/story_generation_request.dart';
import 'models/story_generation_result.dart';

abstract class StoryGenerationService {
  Future<StoryGenerationResult> generate(StoryGenerationRequest request);
}
