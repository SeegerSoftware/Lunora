import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/magical/magical_app_button.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_screen_shell.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: LunoraScreenShell(
        showStarfield: true,
        starCount: 32,
        child: SafeArea(
          child: Padding(
            padding: AppSizes.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                LunoraFadeIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Elunai',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: LunoraColors.warmBeige,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: LunoraSpacing.sm),
                      Text(
                        'La plateforme d’histoires intelligentes 0-12 ans qui s’adapte à chaque enfant.',
                        style: LunoraTextStyles.greetingSub(theme.textTheme)
                            .copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                LunoraFadeIn(
                  delay: const Duration(milliseconds: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LunoraCustomButton(
                        label: 'Créer un compte',
                        icon: Icons.mail_outline_rounded,
                        onPressed: () => context.push('/signup'),
                      ),
                      const SizedBox(height: LunoraSpacing.md),
                      LunoraCustomButton(
                        label: 'J’ai déjà un compte',
                        variant: MagicalButtonVariant.secondary,
                        icon: Icons.login_rounded,
                        onPressed: () => context.push('/signin'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: LunoraSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
