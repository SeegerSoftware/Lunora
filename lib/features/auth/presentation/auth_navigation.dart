import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../child_profile/presentation/providers/child_profile_providers.dart';

/// Après email / social : envoie vers le profil enfant ou l’accueil (le routeur
/// réagit aussi, mais ce `go` corrige les cas où la pile ne se rafraîchit pas).
void navigateAfterAuthenticated(BuildContext context, WidgetRef ref) {
  if (!context.mounted) return;
  final child = ref.read(childProfileProvider);
  context.go(child == null ? '/setup-child' : '/home');
}
