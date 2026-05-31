import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../services/audio/audio_narration_provider.dart';

class AudioPlayerWidget extends ConsumerStatefulWidget {
  const AudioPlayerWidget({
    required this.title,
    required this.content,
    super.key,
  });

  final String title;
  final String content;

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  var _isPlaying = false;

  Future<void> _togglePlayback() async {
    final service = ref.read(audioNarrationServiceProvider);
    if (_isPlaying) {
      await service.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isPlaying = true);
    try {
      await service.speak(title: widget.title, content: widget.content);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Lecture audio indisponible : $error')),
        );
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  void dispose() {
    ref.read(audioNarrationServiceProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ElunaiSpacing.md,
        vertical: ElunaiSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: ElunaiSpacing.radiusLg,
        color: ElunaiColors.nightBlueLift.withValues(alpha: 0.9),
        border: Border.all(
          color: ElunaiColors.starGold.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: ElunaiColors.starGold.withValues(alpha: 0.22),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _togglePlayback,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 32,
                  color: ElunaiColors.warmBeige,
                ),
              ),
            ),
          ),
          const SizedBox(width: ElunaiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPlaying ? 'Lecture en cours' : 'Écouter l’histoire',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: ElunaiColors.warmBeige,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _isPlaying
                      ? 'Appuie pour arrêter'
                      : 'Lecture avec la voix de l’appareil',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ElunaiColors.mist.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
