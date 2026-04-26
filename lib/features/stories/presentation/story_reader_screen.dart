import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../features/child_profile/presentation/providers/child_profile_providers.dart';
import '../../../services/story_generation/story_adaptation_engine.dart';
import '../../../services/story_generation/story_generation_exception.dart';
import '../../../shared/models/story.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/lunora_badge.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_glass_card.dart';
import '../../../shared/widgets/lunora_night_scaffold.dart';
import '../../../shared/widgets/lunora_primary_button.dart';
import '../../../shared/widgets/lunora_section_title.dart';
import '../../../shared/widgets/magical/lunora_progress_bar.dart';
import '../../../shared/widgets/story_ui_labels.dart';
import 'providers/story_providers.dart';

class StoryReaderScreen extends ConsumerStatefulWidget {
  const StoryReaderScreen({super.key, this.storyId});

  final String? storyId;

  @override
  ConsumerState<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends ConsumerState<StoryReaderScreen> {
  double _fontSize = 20;
  static const double _minReaderFontSize = 18;
  static const double _maxReaderFontSize = 24;
  static const StoryAdaptationEngine _adaptationEngine = StoryAdaptationEngine();
  var _feedbackBusy = false;

  Widget _storySurface({required Widget child}) {
    return LunoraGlassCard(child: child);
  }

  Future<void> _submitStoryFeedback(
    WidgetRef ref,
    Story story,
    int feedback,
  ) async {
    setState(() => _feedbackBusy = true);
    try {
      await ref.read(storyRepositoryProvider).setStoryUserFeedback(
            storyId: story.id,
            feedback: feedback,
          );
      ref.invalidate(todayStoryProvider);
      final sid = widget.storyId;
      if (sid != null) {
        ref.invalidate(storyByIdProvider(sid));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci, ton avis est enregistré.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enregistrement impossible : $e')),
      );
    } finally {
      if (mounted) setState(() => _feedbackBusy = false);
    }
  }

  Widget _storyFeedbackBand(
    BuildContext context,
    WidgetRef ref, {
    required Story story,
    required Color hi,
    required Color meta,
  }) {
    final theme = Theme.of(context);
    final sel = story.userFeedback;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LunoraColors.nightBlueLift.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: meta.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Cette histoire te plaît ?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hi.withValues(alpha: 0.96),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_feedbackBusy)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              FilledButton.tonalIcon(
                onPressed: () => _submitStoryFeedback(ref, story, -1),
                icon: const Icon(Icons.thumb_down_rounded, size: 18),
                label: const Text('Bof'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: sel == -1
                      ? theme.colorScheme.errorContainer
                          .withValues(alpha: 0.55)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => _submitStoryFeedback(ref, story, 1),
                icon: const Icon(Icons.thumb_up_rounded, size: 18),
                label: const Text('J’adore'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: sel == 1
                      ? LunoraColors.joyMint.withValues(alpha: 0.35)
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final childProfile = ref.watch(childProfileProvider);
    final adaptation = childProfile == null
        ? null
        : _adaptationEngine.fromChildProfile(childProfile);
    final readerScale = adaptation?.readerFontScale ?? 1.0;
    final effectiveFontSize = (_fontSize * readerScale).clamp(17.0, 28.0);
    final contentMaxWidth =
        ((adaptation?.preferPagination ?? false) ? 680.0 : 760.0);

    final id = widget.storyId;
    final asyncStory = id == null
        ? ref.watch(todayStoryProvider)
        : ref.watch(storyByIdProvider(id));
    final appBarFg = LunoraColors.warmBeige.withValues(alpha: 0.95);

    return LunoraNightScaffold(
      scrollable: false,
      joyfulBackdrop: true,
      showStarryOverlay: true,
      forceNightBackdrop: true,
      backgroundGradient: null,
      appBar: ElunaiAppBar(
        title: 'Lecture',
        titleColor: appBarFg,
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Mode liseuse (écran dédié)',
            icon: const Icon(Icons.nights_stay_rounded),
            onPressed: () async {
              final sid = id ??
                  await ref.read(todayStoryProvider.future).then((s) => s?.id);
              if (!context.mounted || sid == null) return;
              context.push('/story/bedtime?id=${Uri.encodeComponent(sid)}');
            },
          ),
        ],
      ),
      child: asyncStory.when(
            skipLoadingOnReload: true,
            data: (story) {
              if (story == null) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.readerMaxWidth,
                    ),
                    child: LunoraGlassCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Aucune histoire disponible pour le moment.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: LunoraColors.warmBeige,
                            ),
                          ),
                          const SizedBox(height: LunoraSpacing.lg),
                          if (id == null)
                            LunoraPrimaryButton(
                              label: 'Générer une histoire',
                              icon: Icons.auto_stories_outlined,
                              onPressed: () => ref.invalidate(todayStoryProvider),
                            )
                          else
                            LunoraPrimaryButton(
                              label: 'Ouvrir la dernière histoire',
                              icon: Icons.nights_stay_rounded,
                              onPressed: () => context.go('/story'),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              const hi = LunoraColors.warmBeige;
              const meta = LunoraColors.mist;

              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 100,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LunoraFadeIn(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LunoraSectionTitle('Histoire', foregroundColor: hi),
                                  const SizedBox(height: LunoraSpacing.sm),
                                  Text(
                                    'Générée avec ${storyModelLabel(story.generationSource)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: meta.withValues(alpha: 0.88),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: LunoraSpacing.xs),
                                  Text(
                                    story.title,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: hi,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: LunoraSpacing.sm),
                                  Wrap(
                                    spacing: LunoraSpacing.xs,
                                    runSpacing: LunoraSpacing.xs,
                                    children: [
                                      LunoraBadge(
                                        icon: Icons.timer_outlined,
                                        label: readingDurationLabel(
                                          story.estimatedReadingMinutes,
                                        ),
                                      ),
                                      LunoraBadge(
                                        icon: Icons.menu_book_rounded,
                                        label: storyFormatLabel(story),
                                      ),
                                      if (story.isSerialized)
                                        LunoraBadge(
                                          icon: Icons.bookmark_rounded,
                                          label: 'Chapitre ${story.chapterNumber}',
                                        ),
                                      LunoraBadge(
                                        icon: Icons.auto_awesome_rounded,
                                        label: storySourceLabel(
                                          story.generationSource,
                                        ),
                                      ),
                                      if (adaptation != null)
                                        LunoraBadge(
                                          icon: Icons.tune_rounded,
                                          label: 'Lecture ${adaptation.ageYears} ans',
                                        ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(999),
                                        onTap: () async {
                                          final plainText =
                                              '${story.title}\n\n${story.content}';
                                          await Clipboard.setData(
                                            ClipboardData(text: plainText),
                                          );
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                            ..hideCurrentSnackBar()
                                            ..showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Histoire copiée dans le presse-papiers',
                                                ),
                                              ),
                                            );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: LunoraSpacing.sm,
                                            vertical: LunoraSpacing.xxs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: LunoraColors.nightBlueLift
                                                .withValues(alpha: 0.42),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: meta.withValues(alpha: 0.25),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.content_copy_rounded,
                                                size: 14,
                                                color: hi.withValues(alpha: 0.94),
                                              ),
                                              const SizedBox(
                                                width: LunoraSpacing.xxs,
                                              ),
                                              Text(
                                                'Copier',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: hi,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: LunoraSpacing.md),
                                  _storyFeedbackBand(
                                    context,
                                    ref,
                                    story: story,
                                    hi: hi,
                                    meta: meta,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: LunoraSpacing.md),
                            LunoraFadeIn(
                              delay: const Duration(milliseconds: 120),
                              child: _storySurface(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        _fontAction(
                                          context,
                                          label: 'A-',
                                          onTap: () => setState(() {
                                            _fontSize = (_fontSize - 0.5).clamp(
                                              _minReaderFontSize,
                                              _maxReaderFontSize,
                                            );
                                          }),
                                        ),
                                        const SizedBox(width: LunoraSpacing.xs),
                                        _fontAction(
                                          context,
                                          label: 'A+',
                                          onTap: () => setState(() {
                                            _fontSize = (_fontSize + 0.5).clamp(
                                              _minReaderFontSize,
                                              _maxReaderFontSize,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: LunoraSpacing.sm),
                                    Text(
                                      'Bonne lecture',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                            color: meta.withValues(alpha: 0.82),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: LunoraSpacing.md),
                                    SelectionArea(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: _paragraphWidgets(
                                          context,
                                          story.content,
                                          effectiveFontSize:
                                              effectiveFontSize,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: LunoraSpacing.md),
                            LunoraFadeIn(
                              delay: const Duration(milliseconds: 160),
                              child: _storySurface(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Partager un extrait',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: hi,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: LunoraSpacing.xs),
                                    Text(
                                      'On partage uniquement 1/4 de l’histoire.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: meta.withValues(alpha: 0.84),
                                      ),
                                    ),
                                    const SizedBox(height: LunoraSpacing.sm),
                                    Wrap(
                                      spacing: LunoraSpacing.xs,
                                      runSpacing: LunoraSpacing.xs,
                                      children: [
                                        _socialShareButton(
                                          context,
                                          label: 'WhatsApp',
                                          icon: Icons.chat_bubble_outline_rounded,
                                          onTap: () => _shareOnWhatsApp(
                                            context,
                                            title: story.title,
                                            content: story.content,
                                          ),
                                        ),
                                        _socialShareButton(
                                          context,
                                          label: 'X',
                                          icon: Icons.alternate_email_rounded,
                                          onTap: () => _shareOnX(
                                            context,
                                            title: story.title,
                                            content: story.content,
                                          ),
                                        ),
                                        _socialShareButton(
                                          context,
                                          label: 'Facebook',
                                          icon: Icons.thumb_up_alt_outlined,
                                          onTap: () => _shareOnFacebook(
                                            context,
                                            title: story.title,
                                            content: story.content,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: LunoraSpacing.sm),
                                    Text(
                                      'Connecte-toi à Elunai pour plus d’histoires.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: LunoraColors.starGoldSoft
                                            .withValues(alpha: 0.94),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: LunoraSpacing.lg),
                            LunoraPrimaryButton(
                              label: 'Terminer l\'histoire',
                              icon: Icons.check_circle_outline_rounded,
                              onPressed: () => context.go('/home'),
                            ),
                            const SizedBox(height: LunoraSpacing.md),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: LunoraProgressBar()),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(LunoraSpacing.md),
              child: Center(
                child: LunoraFadeIn(
                  child: LunoraGlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Impossible d’afficher l’histoire.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: LunoraColors.warmBeige,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: LunoraSpacing.sm),
                        Text(
                          err is StoryGenerationException
                              ? err.message
                              : '$err',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: LunoraColors.mist.withValues(alpha: 0.86),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: LunoraSpacing.lg),
                        if (id == null)
                          LunoraPrimaryButton(
                            label: 'Réessayer',
                            icon: Icons.refresh_rounded,
                            onPressed: () => ref.invalidate(todayStoryProvider),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _fontAction(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    const fg = LunoraColors.warmBeige;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LunoraSpacing.sm + 2,
          vertical: LunoraSpacing.xxs + 3,
        ),
        decoration: BoxDecoration(
          color: LunoraColors.nightBlueLift.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: LunoraColors.starGoldSoft.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }

  List<Widget> _paragraphWidgets(
    BuildContext context,
    String content, {
    required double effectiveFontSize,
  }) {
    final paragraphs = content
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final lh = _lineHeightForFontSize(effectiveFontSize);
    final style = Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontSize: effectiveFontSize,
          height: lh,
          color: LunoraColors.warmBeige.withValues(alpha: 0.97),
        );
    final paragraphGap = _paragraphGapForFontSize(effectiveFontSize);
    return [
      for (var i = 0; i < paragraphs.length; i++) ...[
        Text(paragraphs[i], style: style),
        if (i != paragraphs.length - 1)
          SizedBox(height: paragraphGap),
      ],
    ];
  }

  Widget _socialShareButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LunoraSpacing.sm,
          vertical: LunoraSpacing.xxs + 2,
        ),
        decoration: BoxDecoration(
          color: LunoraColors.nightBlueLift.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: LunoraColors.mist.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: LunoraColors.warmBeige,
            ),
            const SizedBox(width: LunoraSpacing.xxs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: LunoraColors.warmBeige,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shareSnippet(String title, String content) {
    final words = content
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final targetCount = (words.length / 4).ceil().clamp(35, 240);
    final excerpt = words.take(targetCount).join(' ');
    return '✨ Extrait de "$title"\n\n$excerpt\n\nConnecte-toi à Elunai pour plus d’histoires.';
  }

  Future<void> _shareOnWhatsApp(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    final text = _shareSnippet(title, content);
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    await _launchShare(context, uri);
  }

  Future<void> _shareOnX(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    final text = _shareSnippet(title, content);
    final uri = Uri.parse('https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}');
    await _launchShare(context, uri);
  }

  Future<void> _shareOnFacebook(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    final quote = _shareSnippet(title, content);
    final uri = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent("https://lunora.app")}&quote=${Uri.encodeComponent(quote)}',
    );
    await _launchShare(context, uri);
  }

  Future<void> _launchShare(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Partage indisponible pour le moment.')),
        );
    }
  }

  double _lineHeightForFontSize(double fontSize) {
    final t = ((fontSize - _minReaderFontSize) /
            (_maxReaderFontSize - _minReaderFontSize))
        .clamp(0.0, 1.0);
    // Courbe de confort: texte petit => interligne plus ample.
    return 1.7 - (0.12 * t);
  }

  double _paragraphGapForFontSize(double fontSize) {
    final t = ((fontSize - _minReaderFontSize) /
            (_maxReaderFontSize - _minReaderFontSize))
        .clamp(0.0, 1.0);
    return 20 - (4 * t);
  }
}
