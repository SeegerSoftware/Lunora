import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elunai_v00/app.dart';
import 'package:elunai_v00/features/auth/presentation/providers/auth_providers.dart';
import 'package:elunai_v00/features/child_profile/presentation/child_profile_setup_screen.dart';
import 'package:elunai_v00/features/child_profile/presentation/providers/child_profile_providers.dart';
import 'package:elunai_v00/shared/models/child_profile.dart';
import 'package:elunai_v00/shared/models/enums/story_format.dart';
import 'package:elunai_v00/shared/models/enums/story_tone.dart';
import 'package:elunai_v00/shared/models/enums/subscription_status.dart';
import 'package:elunai_v00/shared/models/story_universe.dart';
import 'package:elunai_v00/shared/models/user_model.dart';

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

Future<void> _tapVisibleText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.pumpAndSettle();
  for (var attempt = 0; attempt < 12 && finder.evaluate().isEmpty; attempt++) {
    final lists = find.byType(ListView);
    if (lists.evaluate().isEmpty) break;
    await tester.drag(lists.last, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('Parcours auth/navigation en mode mock', (
    WidgetTester tester,
  ) async {
    final unique = DateTime.now().millisecondsSinceEpoch;
    final email = 'qa_$unique@elunai.test';
    const password = 'password123';

    await tester.pumpWidget(
      ProviderScope(overrides: testAppOverrides(), child: const ElunaiApp()),
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

  testWidgets('Modifier un profil propose les trois choix de série', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(overrides: testAppOverrides());
    addTearDown(container.dispose);
    await container
        .read(authSessionProvider.notifier)
        .hydrateFromRestoredUser(_user());
    container.read(childProfileProvider.notifier).hydrate(_profile());

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChildProfileSetupScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await _pumpUntilVisible(tester, find.text('Profil enfant'));
    await tester.scrollUntilVisible(
      find.text('Ce que l’histoire doit prendre en compte'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.text('Ce que l’histoire doit prendre en compte'),
      findsOneWidget,
    );
    await _tapVisibleText(tester, 'Continuer');
    await _tapVisibleText(tester, 'Continuer');
    await _tapVisibleText(tester, 'Continuer');
    await _tapVisibleText(tester, 'Enregistrer');

    expect(find.text('Comment appliquer ces réglages ?'), findsOneWidget);
    expect(find.text('Enregistrer pour la prochaine série'), findsOneWidget);
    expect(find.text('Recommencer une nouvelle série'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Comment appliquer ces réglages ?'), findsNothing);
  });
}

UserModel _user() {
  return UserModel(
    id: 'test-user',
    email: 'parent@elunai.test',
    createdAt: DateTime(2026),
    subscriptionStatus: SubscriptionStatus.none,
  );
}

ChildProfile _profile() {
  final now = DateTime(2026);
  return ChildProfile(
    id: 'child-1',
    userId: 'test-user',
    firstName: 'Lina',
    birthMonth: 6,
    birthYear: 2019,
    preferredThemes: const ['nature'],
    avoidThemes: const [],
    personalityTraits: const ['curieuse'],
    fearsToAddress: const [],
    valuesToTeach: const [],
    storyUniverse: StoryUniverse.enchantedNature,
    preferredTone: StoryTone.reassuring,
    storyFormat: StoryFormat.serializedChapters,
    seriesDurationDays: 7,
    storyLengthMinutes: 10,
    createdAt: now,
    updatedAt: now,
  );
}
