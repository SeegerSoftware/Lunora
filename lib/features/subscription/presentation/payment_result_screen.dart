import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/lunora_glass_card.dart';
import '../../../shared/widgets/lunora_page_header.dart';
import '../../../shared/widgets/lunora_primary_button.dart';
import '../../../shared/widgets/lunora_screen_shell.dart';

class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({super.key, required this.success});

  final bool success;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = success ? Icons.check_circle_rounded : Icons.info_rounded;
    final title = success ? 'Paiement confirmé' : 'Paiement interrompu';
    final subtitle = success
        ? 'Stripe a accepté le paiement. L’abonnement sera synchronisé automatiquement dès réception du webhook.'
        : 'Aucun paiement n’a été finalisé. Tu peux reprendre tranquillement depuis l’écran abonnement.';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ElunaiAppBar(title: 'Paiement'),
      body: LunoraScreenShell(
        showStarfield: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: LunoraSpacing.screen,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: LunoraGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LunoraPageHeader(
                        compact: true,
                        icon: icon,
                        title: title,
                        subtitle: subtitle,
                        badge: success
                            ? 'Abonnement en cours d’activation'
                            : 'Aucune action requise',
                      ),
                      const SizedBox(height: LunoraSpacing.xl),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: LunoraSpacing.radiusLg,
                          color: LunoraColors.forestGreen.withValues(
                            alpha: 0.08,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(LunoraSpacing.md),
                          child: Text(
                            success
                                ? 'Si le statut n’apparaît pas immédiatement, patiente quelques secondes puis rouvre l’écran abonnement.'
                                : 'Tes données et ton profil restent inchangés.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: LunoraColors.storybookInkMuted,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: LunoraSpacing.xl),
                      LunoraPrimaryButton(
                        label: 'Voir mon abonnement',
                        icon: Icons.workspace_premium_rounded,
                        onPressed: () => context.go('/subscription'),
                      ),
                      const SizedBox(height: LunoraSpacing.sm),
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Retour à l’accueil'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
