import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/mobile_api_config.dart';
import '../../../core/config/stripe_config.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../routing/safe_navigation.dart';
import '../../../shared/models/enums/subscription_plan.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/elunai_fade_in.dart';
import '../../../shared/widgets/elunai_primary_button.dart';
import '../../../shared/widgets/elunai_screen_shell.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../../services/firebase/app_check_token_provider.dart';

/// Écran de paiement Stripe : récapitulatif puis redirection vers Checkout.
class StripeCheckoutScreen extends ConsumerStatefulWidget {
  const StripeCheckoutScreen({super.key, required this.initialPlanId});

  final String initialPlanId;

  @override
  ConsumerState<StripeCheckoutScreen> createState() =>
      _StripeCheckoutScreenState();
}

class _StripeCheckoutScreenState extends ConsumerState<StripeCheckoutScreen> {
  late SubscriptionPlan _plan;
  var _payBusy = false;

  @override
  void initState() {
    super.initState();
    _plan = SubscriptionPlanX.fromPlanId(widget.initialPlanId);
  }

  Future<void> _onPayWithStripe() async {
    final user = ref.read(authSessionProvider);
    if (user == null) return;

    setState(() => _payBusy = true);
    try {
      final uri = await _checkoutUriFor(user.email);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir Stripe Checkout.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _payBusy = false);
    }
  }

  Future<Uri> _checkoutUriFor(String email) async {
    if (MobileApiConfig.isConfigured) {
      final token = await firebase_auth.FirebaseAuth.instance.currentUser
          ?.getIdToken();
      if (token == null || token.isEmpty) {
        throw StateError('Session Firebase requise pour ouvrir Stripe.');
      }
      final response = await ref
          .read(elunaiApiClientProvider)
          .postJson(
            '/stripe/checkout',
            bearerToken: token,
            appCheckToken: await AppCheckTokenProvider.getToken(),
            body: {'planId': _plan.planId, 'email': email},
          );
      final url = response['url']?.toString().trim() ?? '';
      if (url.isEmpty) {
        throw StateError('Le backend Stripe n’a pas renvoyé d’URL Checkout.');
      }
      return Uri.parse(url);
    }

    final baseUrl = StripeConfig.checkoutUrlForPlan(_plan);
    if (baseUrl == null) {
      throw StateError(
        'Checkout Stripe non configuré. Configure le backend de paiement, puis '
        'ELUNAI_API_BASE_URL côté app.',
      );
    }
    return Uri.parse(baseUrl).replace(
      queryParameters: {
        ...Uri.parse(baseUrl).queryParameters,
        'planId': _plan.planId,
        'email': email,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider);
    final stripeReady =
        MobileApiConfig.isConfigured || StripeConfig.isPublishableKeyConfigured;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Session requise')));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ElunaiAppBar(
        title: 'Paiement',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePopOrGo('/subscription'),
        ),
      ),
      body: ElunaiScreenShell(
        showStarfield: true,
        child: SafeArea(
          child: ListView(
            padding: ElunaiSpacing.screen,
            children: [
              ElunaiFadeIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Récapitulatif',
                      style: ElunaiTextStyles.sectionTitle(theme.textTheme),
                    ),
                    const SizedBox(height: ElunaiSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: ElunaiSpacing.radiusLg,
                        color: ElunaiColors.nightBlueLift.withValues(
                          alpha: 0.75,
                        ),
                        border: Border.all(
                          color: ElunaiColors.mist.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(ElunaiSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _plan.displayName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: ElunaiColors.warmBeige,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: ElunaiSpacing.xs),
                            Text(
                              '${_plan.dailyStoriesPerChild} histoire par jour par enfant · lecture texte',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: ElunaiColors.mist.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                            ),
                            const SizedBox(height: ElunaiSpacing.xs),
                            Text(
                              _plan.priceLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: ElunaiColors.starGoldSoft,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: ElunaiSpacing.sm),
                            Text(
                              'Compte : ${user.email}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: ElunaiColors.mist.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: ElunaiSpacing.xl),
                    Text(
                      'Paiement sécurisé',
                      style: ElunaiTextStyles.sectionTitle(theme.textTheme),
                    ),
                    const SizedBox(height: ElunaiSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: ElunaiSpacing.radiusMd,
                        color: ElunaiColors.nightBlueLift.withValues(
                          alpha: 0.55,
                        ),
                        border: Border.all(
                          color: ElunaiColors.mist.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(ElunaiSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stripeReady
                                  ? 'Tu vas être redirigé vers Stripe Checkout. '
                                        'Les informations bancaires sont saisies '
                                        'uniquement sur la page sécurisée de Stripe.'
                                  : 'Configure le backend de paiement et '
                                        'ELUNAI_API_BASE_URL côté app.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: ElunaiColors.mist.withValues(
                                  alpha: 0.82,
                                ),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: ElunaiSpacing.xl),
                    ElunaiPrimaryButton(
                      label: stripeReady
                          ? 'Payer avec Stripe'
                          : 'Payer avec Stripe (configurer la clé)',
                      isLoading: _payBusy,
                      onPressed: _payBusy ? null : _onPayWithStripe,
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
