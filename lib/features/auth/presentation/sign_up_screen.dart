import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/validation/auth_validators.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_primary_button.dart';
import '../../../shared/widgets/lunora_screen_shell.dart';
import '../../../shared/widgets/lunora_text_field.dart';
import 'auth_navigation.dart';
import 'providers/auth_providers.dart';
import 'widgets/social_auth_section.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authSessionProvider.notifier)
          .signUp(email: _email.text.trim(), password: _password.text);
      if (!mounted) return;
      navigateAfterAuthenticated(context, ref);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Inscription impossible : $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ElunaiAppBar(
        title: 'Créer un compte',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: LunoraScreenShell(
        showStarfield: true,
        child: SafeArea(
          child: Padding(
            padding: AppSizes.screenPadding,
            child: LunoraFadeIn(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      'Rejoins la constellation Elunai ✨',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: LunoraColors.joySun.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    LunoraTextField(
                      controller: _email,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: AuthValidators.emailError,
                    ),
                    const SizedBox(height: AppSizes.md),
                    LunoraTextField(
                      controller: _password,
                      label: 'Mot de passe',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: AuthValidators.passwordError,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    LunoraPrimaryButton(
                      label: 'Continuer',
                      isLoading: _loading,
                      onPressed: _submit,
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Déjà un compte ? Se connecter'),
                    ),
                    const SizedBox(height: AppSizes.xl),
                    const SocialAuthSection(),
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
