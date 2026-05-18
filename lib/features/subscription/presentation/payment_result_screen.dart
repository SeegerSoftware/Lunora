import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/lunora_primary_button.dart';
import '../../../shared/widgets/lunora_screen_shell.dart';

class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({super.key, required this.success});

  final bool success;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ElunaiAppBar(title: 'Paiement'),
      body: LunoraScreenShell(
        showStarfield: true,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: LunoraSpacing.screen,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      success
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      size: 64,
                      color: success
                          ? LunoraColors.joyMint
                          : LunoraColors.starGoldSoft,
                    ),
                    const SizedBox(height: LunoraSpacing.lg),
                    Text(
                      success
                          ? 'Paiement confirmé'
                          : 'Paiement non finalisé',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: LunoraColors.warmBeige,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.sm),
                    Text(
                      success
                          ? 'Ton abonnement sera mis à jour automatiquement dès réception du webhook Stripe.'
                          : 'Tu peux reprendre le paiement quand tu veux depuis l’écran abonnement.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: LunoraColors.mist.withValues(alpha: 0.82),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.xl),
                    LunoraPrimaryButton(
                      label: 'Retour à l’abonnement',
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
    );
  }
}
