import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/validation/auth_validators.dart';
import '../../../routing/safe_navigation.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_page_header.dart';
import '../../../shared/widgets/lunora_primary_button.dart';
import '../../../shared/widgets/lunora_screen_shell.dart';
import '../../../shared/widgets/lunora_text_field.dart';
import '../../legal/presentation/terms_screen.dart';
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
  var _acceptedTerms = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu dois accepter les CGU pour créer un compte.'),
        ),
      );
      return;
    }
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
          onPressed: () => context.safePopOrGo('/welcome'),
        ),
      ),
      body: LunoraScreenShell(
        showStarfield: true,
        child: SafeArea(
          child: Padding(
            padding: AppSizes.screenPadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: LunoraFadeIn(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSizes.lg),
                          const LunoraPageHeader(
                            compact: true,
                            icon: Icons.auto_awesome_rounded,
                            title: 'Créer ton espace',
                            subtitle:
                                'Deux informations suffisent pour commencer. Le profil enfant vient juste après.',
                          ),
                          const SizedBox(height: AppSizes.xl),
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
                          CheckboxListTile(
                            value: _acceptedTerms,
                            onChanged: _loading
                                ? null
                                : (value) {
                                    setState(
                                      () => _acceptedTerms = value ?? false,
                                    );
                                  },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            title: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text('J’accepte les '),
                                TextButton(
                                  onPressed: () =>
                                      context.push(TermsScreen.routePath),
                                  child: const Text('CGU'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          LunoraPrimaryButton(
                            label: 'Continuer',
                            isLoading: _loading,
                            onPressed: _submit,
                          ),
                          TextButton(
                            onPressed: () => context.safePopOrGo('/signin'),
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
        ),
      ),
    );
  }
}
