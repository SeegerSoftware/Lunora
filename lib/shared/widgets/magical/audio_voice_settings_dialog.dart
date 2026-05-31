import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/audio/audio_narration_provider.dart';
import '../../../services/audio/audio_narration_service.dart';

class AudioVoiceSettingsDialog extends ConsumerStatefulWidget {
  const AudioVoiceSettingsDialog({super.key});

  @override
  ConsumerState<AudioVoiceSettingsDialog> createState() =>
      _AudioVoiceSettingsDialogState();
}

class _AudioVoiceSettingsDialogState
    extends ConsumerState<AudioVoiceSettingsDialog> {
  late Future<_AudioVoiceOptions> _options;
  var _selectedVoiceId = '';
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _options = _loadOptions();
  }

  Future<_AudioVoiceOptions> _loadOptions() async {
    final service = ref.read(audioNarrationServiceProvider);
    final voices = await service.availableFrenchVoices();
    final preferred = await service.preferredVoice();
    if (mounted) {
      setState(() => _selectedVoiceId = preferred?.id ?? '');
    }
    return _AudioVoiceOptions(voices);
  }

  Future<void> _save(List<NarrationVoice> voices) async {
    setState(() => _saving = true);
    NarrationVoice? selected;
    for (final voice in voices) {
      if (voice.id == _selectedVoiceId) selected = voice;
    }
    await ref.read(audioNarrationServiceProvider).savePreferredVoice(selected);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Voix de lecture audio'),
      content: FutureBuilder<_AudioVoiceOptions>(
        future: _options,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Text(
              'Impossible de charger les voix de cet appareil.\n\n'
              '${snapshot.error}',
            );
          }

          final voices = snapshot.requireData.voices;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Elunai utilise la synthèse vocale de cet appareil. '
                'L’histoire n’est pas envoyée vers un service audio externe.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue:
                    voices.any((voice) => voice.id == _selectedVoiceId)
                    ? _selectedVoiceId
                    : '',
                decoration: const InputDecoration(labelText: 'Voix'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Voix française par défaut'),
                  ),
                  ...voices.map(
                    (voice) => DropdownMenuItem(
                      value: voice.id,
                      child: Text(voice.label, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _selectedVoiceId = value ?? ''),
              ),
              if (voices.isEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Aucune voix française supplémentaire n’est installée. '
                  'La voix système sera utilisée.',
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FutureBuilder<_AudioVoiceOptions>(
          future: _options,
          builder: (context, snapshot) => FilledButton(
            onPressed: _saving || !snapshot.hasData
                ? null
                : () => _save(snapshot.requireData.voices),
            child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ),
      ],
    );
  }
}

class _AudioVoiceOptions {
  const _AudioVoiceOptions(this.voices);

  final List<NarrationVoice> voices;
}
