import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunora_v00/app.dart';

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
  Duration step = const Duration(milliseconds: 150),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Widget not visible before timeout: $finder');
}

Future<void> _scrollDownUntilVisible(
  WidgetTester tester,
  Finder finder, {
  int maxScrolls = 8,
}) async {
  for (var i = 0; i < maxScrolls; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(find.byType(ListView).first, const Offset(0, -350));
    await tester.pump(const Duration(milliseconds: 200));
  }
  fail('Unable to scroll to widget: $finder');
}

Finder _activeFormFields() {
  return find.descendant(
    of: find.byType(Form).last,
    matching: find.byType(TextFormField),
  );
}

void main() {
  testWidgets('Parcours auth/navigation en mode mock', (
    WidgetTester tester,
  ) async {
    final unique = DateTime.now().millisecondsSinceEpoch;
    final email = 'qa_$unique@lunora.test';
    const password = 'password123';

    await tester.pumpWidget(const ProviderScope(child: LunoraApp()));
    await _pumpUntilVisible(tester, find.text('Créer un compte'));

    expect(find.text('Créer un compte'), findsOneWidget);

    await tester.tap(find.text('Créer un compte'));
    await _pumpUntilVisible(tester, find.text('Continuer'));
    expect(find.text('Continuer'), findsOneWidget);

    await tester.enterText(_activeFormFields().at(0), email);
    await tester.enterText(_activeFormFields().at(1), password);
    await tester.tap(find.text('Continuer'));
    await _pumpUntilVisible(tester, find.text('Profil enfant'));

    expect(find.text('Profil enfant'), findsOneWidget);

    await tester.enterText(_activeFormFields().first, 'Lina');
    await _scrollDownUntilVisible(tester, find.text('Enregistrer'));
    final saveButton = find.ancestor(
      of: find.text('Enregistrer'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(saveButton.first);
    await tester.tap(saveButton.first);
    await _pumpUntilVisible(tester, find.text('Ce soir'));

    expect(find.text('Ce soir'), findsOneWidget);
    await _pumpUntilVisible(tester, find.text('Tout voir'));
    await tester.tap(find.text('Tout voir'));
    await _pumpUntilVisible(tester, find.text('Historique'));
    expect(find.text('Historique'), findsOneWidget);
    await tester.pageBack();
    await _pumpUntilVisible(tester, find.text('Ce soir'));

    await tester.tap(find.byTooltip('Se déconnecter'));
    await _pumpUntilVisible(tester, find.text('Créer un compte'));
    expect(find.text('Créer un compte'), findsOneWidget);

    await tester.tap(find.text('Se connecter').first);
    await _pumpUntilVisible(tester, find.text('Connexion'));
    expect(find.text('Connexion'), findsOneWidget);

    await tester.enterText(_activeFormFields().at(0), email);
    await tester.enterText(_activeFormFields().at(1), password);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Se connecter').first);
    await _pumpUntilVisible(tester, find.text('Ce soir'));

    // Le même compte retrouve son profil et son historique.
    expect(find.text('Ce soir'), findsOneWidget);
    await _pumpUntilVisible(tester, find.text('Tout voir'));
    await tester.tap(find.text('Tout voir'));
    await _pumpUntilVisible(tester, find.text('Historique'));
    expect(
      find.text('Pas encore d’histoires enregistrées. Revenez après une première lecture.'),
      findsNothing,
    );
  });
}
