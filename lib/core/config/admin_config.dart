import '../../shared/models/user_model.dart';

/// Accès admin : combinaison du champ Firestore `isAdmin` et d’e-mails passés au build.
///
/// Exemple :
/// `flutter run --dart-define=LUNORA_ADMIN_EMAILS=toi@example.com,autre@example.com`
abstract final class AdminConfig {
  static const String _envKey = 'LUNORA_ADMIN_EMAILS';

  static bool isAdminUser(UserModel user) {
    if (user.isAdmin) return true;
    return matchesAdminEmail(user.email);
  }

  static bool matchesAdminEmail(String email) {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return false;
    return _emailsFromEnvironment().contains(e);
  }

  static List<String> _emailsFromEnvironment() {
    const raw = String.fromEnvironment(_envKey, defaultValue: '');
    if (raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
