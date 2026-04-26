import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/validation/auth_validators.dart';
import '../../../shared/widgets/elunai_layout.dart';
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
  static const _lastEmailKey = 'auth.last_email';
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _loading = false;
  var _resetBusy = false;

  @override
  void initState() {
    super.initState();
    _restoreLastEmail();
  }

  Future<void> _restoreLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString(_lastEmailKey)?.trim() ?? '';
    if (!mounted || lastEmail.isEmpty) return;
    setState(() => _email.text = lastEmail);
  }

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastEmailKey, _email.text.trim().toLowerCase());
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

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _email.text.trim());
    final dialogForm = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mot de passe oublié'),
        content: Form(
          key: dialogForm,
          child: TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'toi@email.com',
            ),
            validator: AuthValidators.emailError,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (!(dialogForm.currentState?.validate() ?? false)) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final targetEmail = emailCtrl.text.trim().toLowerCase();
    setState(() => _resetBusy = true);
    try {
      await ref
          .read(authSessionProvider.notifier)
          .sendPasswordResetEmail(email: targetEmail);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            Icons.mark_email_read_rounded,
            color: Theme.of(ctx).colorScheme.primary,
            size: 36,
          ),
          title: const Text('Lien demandé auprès de Firebase'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Si un compte existe pour :\n$targetEmail\n\n'
                  'un e-mail de réinitialisation part dans les prochaines minutes.',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu ne vois rien ?',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Regarde dans Indésirables / Promotions (surtout Gmail).\n'
                  '• Vérifie qu’il n’y a pas de faute dans l’adresse.\n'
                  '• Dans la console Firebase : Authentication → Sign-in method : '
                  '« E-mail / Mot de passe » doit être activé.\n'
                  '• Domaine d’expédition : vérifie les modèles d’e-mail Auth '
                  '(pas désactivés) et les quotas du projet.\n'
                  '• Option avancée : définis PASSWORD_RESET_CONTINUE_URL dans '
                  'dart_defines.json avec une URL https déjà autorisée dans '
                  'Firebase (souvent meilleure délivrabilité des liens).',
                  style: Theme.of(
                    ctx,
                  ).textTheme.bodySmall?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Envoi impossible : $e')));
    } finally {
      if (mounted) setState(() => _resetBusy = false);
      emailCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ElunaiAppBar(
        title: 'Connexion',
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
                      const SizedBox(height: AppSizes.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: (_loading || _resetBusy)
                              ? null
                              : _forgotPassword,
                          child: _resetBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Mot de passe oublié ?'),
                        ),
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
