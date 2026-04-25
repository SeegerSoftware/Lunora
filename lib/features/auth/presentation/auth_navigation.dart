import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Après email / social : aller à l’accueil. Le routeur redirige vers
/// /setup-child uniquement si le profil enfant est réellement absent.
void navigateAfterAuthenticated(BuildContext context, WidgetRef ref) {
  if (!context.mounted) return;
  context.go('/home');
}
