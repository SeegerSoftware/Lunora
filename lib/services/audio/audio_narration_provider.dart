import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_narration_service.dart';

final audioNarrationServiceProvider = Provider<AudioNarrationService>((ref) {
  final service = AudioNarrationService();
  ref.onDispose(service.dispose);
  return service;
});
