import 'models/story_generation_request.dart';
import 'models/story_generation_result.dart';
import '../../shared/models/series_state.dart';

abstract class StoryGenerationService {
  Future<StoryGenerationResult> generate(StoryGenerationRequest request);

  Future<SeriesBible> generateSeriesBible(StoryGenerationRequest request);
}
