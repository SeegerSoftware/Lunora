import 'package:elunai_v00/services/audio/audio_narration_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioNarrationService.splitIntoChunks', () {
    test('keeps short content in one chunk', () {
      expect(
        AudioNarrationService.splitIntoChunks('Une phrase. Une autre phrase.'),
        ['Une phrase. Une autre phrase.'],
      );
    });

    test('splits content without exceeding the requested limit', () {
      final chunks = AudioNarrationService.splitIntoChunks(
        'Première phrase assez longue. Deuxième phrase assez longue. '
        'Troisième phrase assez longue.',
        maxLength: 42,
      );

      expect(chunks.length, greaterThan(1));
      expect(chunks.every((chunk) => chunk.length <= 42), isTrue);
      expect(chunks.join(' '), contains('Troisième phrase'));
    });

    test('splits a sentence that exceeds the limit', () {
      final chunks = AudioNarrationService.splitIntoChunks(
        'un deux trois quatre cinq six sept huit neuf dix',
        maxLength: 16,
      );

      expect(chunks.every((chunk) => chunk.length <= 16), isTrue);
      expect(
        chunks.join(' '),
        'un deux trois quatre cinq six sept huit neuf dix',
      );
    });
  });
}
