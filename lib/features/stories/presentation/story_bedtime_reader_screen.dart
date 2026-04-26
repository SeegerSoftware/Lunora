import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/widgets/magical/lunora_progress_bar.dart';
import 'providers/story_providers.dart';

/// Lecture minimale pour le coucher : texte seul, contraste doux, luminosité visuelle basse.
class StoryBedtimeReaderScreen extends ConsumerStatefulWidget {
  const StoryBedtimeReaderScreen({super.key, this.storyId});

  final String? storyId;

  @override
  ConsumerState<StoryBedtimeReaderScreen> createState() =>
      _StoryBedtimeReaderScreenState();
}

class _StoryBedtimeReaderScreenState extends ConsumerState<StoryBedtimeReaderScreen> {
  static const _bg = Color(0xFF0E1014);
  static const _ink = Color(0xFFE6D9C8);
  static const _inkMuted = Color(0xFFB8A99A);
  static const double _fontSize = 22;
  static const double _titleSize = 17;

  @override
  Widget build(BuildContext context) {
    final id = widget.storyId;
    final asyncStory = id == null
        ? ref.watch(todayStoryProvider)
        : ref.watch(storyByIdProvider(id));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Theme(
        data: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _bg,
        ),
        child: Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Retour',
                    icon: const Icon(Icons.arrow_back_rounded, color: _inkMuted),
                    onPressed: () => context.pop(),
                  ),
                ),
                Expanded(
                  child: asyncStory.when(
                    skipLoadingOnReload: true,
                    data: (story) {
                      if (story == null) {
                        return Center(
                          child: Text(
                            'Aucune histoire à afficher.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _ink.withValues(alpha: 0.85),
                              fontSize: 16,
                            ),
                          ),
                        );
                      }
                      final paras = story.content
                          .split(RegExp(r'\n\s*\n'))
                          .map((p) => p.trim())
                          .where((p) => p.isNotEmpty)
                          .toList();
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(
                          LunoraSpacing.lg,
                          0,
                          LunoraSpacing.lg,
                          LunoraSpacing.xl,
                        ),
                        children: [
                          Text(
                            story.title,
                            style: TextStyle(
                              fontSize: _titleSize,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              color: _inkMuted,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: LunoraSpacing.lg),
                          ...paras.expand((p) => [
                                Text(
                                  p,
                                  style: LunoraTextStyles.ereaderBody(
                                    _fontSize,
                                    1.65,
                                  ).copyWith(color: _ink),
                                ),
                                const SizedBox(height: LunoraSpacing.md),
                              ]),
                        ],
                      );
                    },
                    loading: () => const Center(child: LunoraProgressBar()),
                    error: (err, _) => Padding(
                      padding: LunoraSpacing.screen,
                      child: Center(
                        child: Text(
                          'Impossible de charger l’histoire.\n\n$err',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ink.withValues(alpha: 0.9),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
