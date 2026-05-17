import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lunora_v00/app.dart';
import 'package:lunora_v00/services/firebase/firebase_bootstrap.dart';

const _runBackendIntegration = bool.fromEnvironment(
  'RUN_BACKEND_INTEGRATION',
  defaultValue: false,
);

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 12),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Widget not visible before timeout: $finder');
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await _pumpUntilVisible(tester, find.text(text));
  await tester.ensureVisible(find.text(text).first);
  await tester.tap(find.text(text).first);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'auth -> profil -> génération -> lecture',
    (tester) async {
      await FirebaseBootstrap.ensureInitialized();
      final unique = DateTime.now().millisecondsSinceEpoch;
      final email = 'qa_$unique@lunora.test';

      await tester.pumpWidget(const ProviderScope(child: LunoraApp()));
      await _pumpUntilVisible(tester, find.text('Créer un compte'));

      await _tapText(tester, 'Créer un compte');
      await tester.enterText(find.byType(TextFormField).at(0), email);
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await _tapText(tester, 'Continuer');

      await _pumpUntilVisible(tester, find.text('Profil enfant'));
      await tester.enterText(find.byType(TextFormField).first, 'Lina');
      await _tapText(tester, 'Continuer');
      await _tapText(tester, 'Continuer');
      await _tapText(tester, 'Enregistrer');

      await _pumpUntilVisible(tester, find.text('Histoire du jour'));
      await _tapText(tester, 'Lire l’histoire');

      await _pumpUntilVisible(tester, find.text('Lecture'));
      expect(find.textContaining('Lina'), findsWidgets);
    },
    skip: !_runBackendIntegration
        ? 'Run with --dart-define=RUN_BACKEND_INTEGRATION=true, Firebase Emulator, and backend mock.'
        : false,
  );
}
