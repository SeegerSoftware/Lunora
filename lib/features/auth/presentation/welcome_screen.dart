import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/lunora_primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSizes.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text('lunora.v00', style: theme.textTheme.headlineLarge),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Une histoire douce chaque soir, pensée pour votre rituel du coucher.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              LunoraPrimaryButton(
                label: 'Créer un compte',
                onPressed: () => context.push('/signup'),
              ),
              const SizedBox(height: AppSizes.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/signin'),
                  child: const Text('Se connecter'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
