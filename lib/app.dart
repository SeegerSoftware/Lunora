import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'core/config/security_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'routing/app_router.dart';

class LunoraApp extends ConsumerWidget {
  const LunoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(firebaseAuthSyncProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Elunai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) =>
          _MobileBiometricGate(child: child ?? const SizedBox.shrink()),
    );
  }
}

class _MobileBiometricGate extends ConsumerStatefulWidget {
  const _MobileBiometricGate({required this.child});

  final Widget child;

  @override
  ConsumerState<_MobileBiometricGate> createState() =>
      _MobileBiometricGateState();
}

class _MobileBiometricGateState extends ConsumerState<_MobileBiometricGate>
    with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = LocalAuthentication();
  ProviderSubscription<Object?>? _authSessionSub;
  var _initialized = false;
  var _biometricSupported = false;
  var _biometricEnabled = true;
  var _unlocked = true;
  var _authInProgress = false;
  String? _unlockError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSessionSub = ref.listenManual(authSessionProvider, (prev, next) {
      if (next == null) {
        if (mounted) {
          setState(() {
            _unlocked = true;
            _unlockError = null;
          });
        }
        return;
      }
      _prepareForSignedSession();
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _prepareForSignedSession(),
    );
  }

  @override
  void dispose() {
    _authSessionSub?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _handleResume();
  }

  Future<void> _handleResume() async {
    final user = ref.read(authSessionProvider);
    if (user == null) return;
    if (!_biometricSupported || _authInProgress) return;
    _biometricEnabled = await SecurityPreferences.isBiometricLockEnabled();
    if (!_biometricEnabled || !mounted) {
      if (mounted) setState(() => _unlocked = true);
      return;
    }
    setState(() => _unlocked = false);
    await _promptUnlock();
  }

  Future<void> _prepareForSignedSession() async {
    final user = ref.read(authSessionProvider);
    if (user == null || _authInProgress) return;

    if (!_initialized) {
      _biometricSupported = await _checkBiometricSupport();
      _initialized = true;
    }

    if (!_biometricSupported) {
      if (mounted) setState(() => _unlocked = true);
      return;
    }

    _biometricEnabled = await SecurityPreferences.isBiometricLockEnabled();
    if (!_biometricEnabled) {
      if (mounted) setState(() => _unlocked = true);
      return;
    }

    if (mounted) setState(() => _unlocked = false);
    await _promptUnlock();
  }

  Future<bool> _checkBiometricSupport() async {
    if (kIsWeb) return false;
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<void> _promptUnlock() async {
    if (_authInProgress) return;
    if (ref.read(authSessionProvider) == null) return;

    setState(() {
      _authInProgress = true;
      _unlockError = null;
    });

    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Déverrouille Elunai avec ton empreinte ou Face ID',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!mounted) return;
      setState(() {
        _unlocked = ok;
        if (!ok) {
          _unlockError = 'Déverrouillage annulé.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _unlocked = false;
        _unlockError = 'Impossible de lancer la biométrie: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _authInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider);
    if (user == null ||
        !_biometricSupported ||
        !_biometricEnabled ||
        _unlocked) {
      return widget.child;
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fingerprint_rounded,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'App verrouillée',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Utilise la biométrie pour continuer.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                if (_unlockError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _unlockError!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _authInProgress ? null : _promptUnlock,
                  icon: _authInProgress
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open_rounded),
                  label: const Text('Déverrouiller'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _authInProgress
                      ? null
                      : () => ref.read(authSessionProvider.notifier).signOut(),
                  child: const Text('Se déconnecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
