import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/validation/auth_validators.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_primary_button.dart';
import '../../../shared/widgets/lunora_screen_shell.dart';
import '../../../shared/widgets/lunora_text_field.dart';
import 'auth_navigation.dart';
import 'providers/auth_providers.dart';
import 'widgets/social_auth_section.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
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
          .signIn(email: _email.text.trim(), password: _password.text);
      if (!mounted) return;
      navigateAfterAuthenticated(context, ref);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connexion impossible : $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Connexion',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
        starCount: 26,
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
                      label: 'Se connecter',
                      isLoading: _loading,
                      onPressed: _submit,
                    ),
                    TextButton(
                      onPressed: () => context.push('/signup'),
                      child: const Text('Créer un compte'),
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
