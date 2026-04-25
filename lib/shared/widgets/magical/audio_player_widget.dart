import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

/// Lecteur audio visuel (MVP : pas de lecture réelle — UX prête).
class AudioPlayerWidget extends StatelessWidget {
  const AudioPlayerWidget({super.key, this.enabled = false, this.onPlay});

  final bool enabled;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: enabled ? 'Lecture audio' : 'Lecture audio bientôt disponible',
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LunoraSpacing.md,
            vertical: LunoraSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: LunoraSpacing.radiusLg,
            color: LunoraColors.nightBlueLift.withValues(alpha: 0.9),
            border: Border.all(
              color: LunoraColors.starGold.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              Material(
                color: LunoraColors.starGold.withValues(alpha: 0.22),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: enabled ? onPlay : null,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 32,
                      color: LunoraColors.warmBeige.withValues(
                        alpha: enabled ? 1 : 0.65,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: LunoraSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Écouter l’histoire',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: LunoraColors.warmBeige,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      enabled ? 'Appuie pour lancer' : 'Bientôt dans Elunai',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: LunoraColors.mist.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
