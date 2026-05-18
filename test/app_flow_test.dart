import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunora_v00/app.dart';

import 'test_app_overrides.dart';

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

    await tester.pumpWidget(
      ProviderScope(overrides: testAppOverrides(), child: const LunoraApp()),
    );
    await _pumpUntilVisible(tester, find.textContaining('compte'));

    expect(find.textContaining('compte'), findsWidgets);

    await tester.tap(find.textContaining('compte').first);
    await _pumpUntilVisible(tester, find.text('Continuer'));
    expect(find.text('Continuer'), findsOneWidget);

    await tester.enterText(_activeFormFields().at(0), email);
    await tester.enterText(_activeFormFields().at(1), password);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Continuer'));
    await _pumpUntilVisible(tester, find.text('Profil enfant'));

    expect(find.text('Profil enfant'), findsWidgets);
  });
}
