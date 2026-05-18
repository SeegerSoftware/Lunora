import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lunora_v00/app.dart';
import 'test_app_overrides.dart';

void main() {
  testWidgets('Affiche l’écran d’accueil Lunora', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: testAppOverrides(), child: const LunoraApp()),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Créer un compte'), findsOneWidget);
  });
}
