import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lunora_v00/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Parcours principal: auth, navigation, deconnexion', (
    WidgetTester tester,
  ) async {
    final unique = DateTime.now().millisecondsSinceEpoch;
    final email = 'qa_$unique@lunora.test';
    const password = 'password123';

    await tester.pumpWidget(const ProviderScope(child: LunoraApp()));
    await tester.pumpAndSettle();

    expect(find.text('lunora.v00'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);

    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    expect(find.text('Continuer'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Profil enfant'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Lina');
    await tester.scrollUntilVisible(find.text('Enregistrer'), 300);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.textContaining('Bonsoir'), findsOneWidget);
    expect(find.text('Espace parent'), findsOneWidget);

    await tester.tap(find.text('Tout voir'));
    await tester.pumpAndSettle();
    expect(find.text('Historique'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Créer un compte'), findsOneWidget);

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // En mode mock, la deconnexion vide le store; on revient donc au setup enfant.
    expect(find.text('Profil enfant'), findsOneWidget);
  });
}
