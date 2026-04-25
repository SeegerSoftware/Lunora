import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/stripe_config.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/models/enums/story_plan.dart';
import '../../../shared/models/enums/subscription_status.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_primary_button.dart';
import '../../../shared/widgets/lunora_screen_shell.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'providers/subscription_providers.dart';

/// Écran de paiement préparé pour Stripe : récap plan + zone « carte ».
///
/// **Prod** : un backend doit créer un [PaymentIntent] (ou Checkout Session) ;
/// l’app appellera l’endpoint puis affichera PaymentSheet / redirect.
class StripeCheckoutScreen extends ConsumerStatefulWidget {
  const StripeCheckoutScreen({super.key, required this.initialPlanId});

  final String initialPlanId;

  @override
  ConsumerState<StripeCheckoutScreen> createState() =>
      _StripeCheckoutScreenState();
}

class _StripeCheckoutScreenState extends ConsumerState<StripeCheckoutScreen> {
  late StoryPlan _plan;
  var _testBusy = false;

  @override
  void initState() {
    super.initState();
    _plan = StoryPlanX.fromPlanId(widget.initialPlanId);
  }

  Future<void> _activateTestPlan() async {
    final user = ref.read(authSessionProvider);
    if (user == null) return;
    setState(() => _testBusy = true);
    try {
      await ref
          .read(subscriptionProvider.notifier)
          .selectMockPlanFor(user: user, plan: _plan);
      ref.read(authSessionProvider.notifier).applyPlanSelection(
            planId: _plan.planId,
            status: SubscriptionStatus.active,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan test : ${_plan.displayLabel}')),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _testBusy = false);
    }
  }

  void _onPayWithStripe() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Branchement Stripe : endpoint sécurisé (ex. Cloud Function) qui '
          'retourne clientSecret + activation PaymentSheet / Checkout.',
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider);
    final stripeReady = StripeConfig.isPublishableKeyConfigured;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Session requise')));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Paiement',
          style: theme.textTheme.titleLarge?.copyWith(
            color: LunoraColors.warmBeige,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: LunoraColors.warmBeige.withValues(alpha: 0.9),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: LunoraScreenShell(
        showStarfield: true,
        starCount: 20,
        child: SafeArea(
          child: ListView(
            padding: LunoraSpacing.screen,
            children: [
              LunoraFadeIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Récapitulatif',
                      style: LunoraTextStyles.sectionTitle(theme.textTheme),
                    ),
                    const SizedBox(height: LunoraSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: LunoraSpacing.radiusLg,
                        color: LunoraColors.nightBlueLift.withValues(alpha: 0.75),
                        border: Border.all(
                          color: LunoraColors.mist.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(LunoraSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _plan.displayLabel,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: LunoraColors.warmBeige,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: LunoraSpacing.xs),
                            Text(
                              'Durée cible ~${_plan.targetStoryMinutes} min / histoire',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: LunoraColors.mist.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: LunoraSpacing.sm),
                            Text(
                              'Compte : ${user.email}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: LunoraColors.mist.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.xl),
                    Text(
                      'Carte bancaire',
                      style: LunoraTextStyles.sectionTitle(theme.textTheme),
                    ),
                    const SizedBox(height: LunoraSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: LunoraSpacing.radiusMd,
                        color: LunoraColors.nightBlueLift.withValues(alpha: 0.55),
                        border: Border.all(
                          color: LunoraColors.mist.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(LunoraSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stripeReady
                                  ? 'Clé publique détectée (pk_…). Prochaine étape : '
                                      'flutter_stripe + PaymentSheet après clientSecret.'
                                  : 'Définis STRIPE_PUBLISHABLE_KEY (pk_test_…) en '
                                      'dart-define pour activer le SDK côté app.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: LunoraColors.mist.withValues(alpha: 0.82),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: LunoraSpacing.md),
                            _PlaceholderField(
                              label: 'Numéro de carte',
                              hint: '4242 4242 4242 4242',
                              icon: Icons.credit_card_rounded,
                            ),
                            const SizedBox(height: LunoraSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: _PlaceholderField(
                                    label: 'Expiration',
                                    hint: 'MM / AA',
                                    icon: Icons.calendar_month_rounded,
                                  ),
                                ),
                                const SizedBox(width: LunoraSpacing.sm),
                                Expanded(
                                  child: _PlaceholderField(
                                    label: 'CVC',
                                    hint: '123',
                                    icon: Icons.lock_outline_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.xl),
                    LunoraPrimaryButton(
                      label: stripeReady
                          ? 'Payer avec Stripe'
                          : 'Payer avec Stripe (configurer la clé)',
                      onPressed: _testBusy ? null : _onPayWithStripe,
                    ),
                    const SizedBox(height: LunoraSpacing.sm),
                    TextButton(
                      onPressed: _testBusy ? null : _activateTestPlan,
                      child: _testBusy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Mode test : activer le plan sans paiement',
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

class _PlaceholderField extends StatelessWidget {
  const _PlaceholderField({
    required this.label,
    required this.hint,
    required this.icon,
  });

  final String label;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: LunoraColors.mist.withValues(alpha: 0.5)),
        filled: true,
        fillColor: LunoraColors.nightBlueLift.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: LunoraSpacing.radiusSm,
          borderSide: BorderSide(
            color: LunoraColors.mist.withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: LunoraSpacing.radiusSm,
          borderSide: BorderSide(
            color: LunoraColors.mist.withValues(alpha: 0.12),
          ),
        ),
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color: LunoraColors.mist.withValues(alpha: 0.75),
        ),
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: LunoraColors.mist.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
