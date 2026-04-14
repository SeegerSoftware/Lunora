import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lunora_v00/app.dart';

void main() {
  testWidgets('Affiche l’écran d’accueil Lunora', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LunoraApp()));
    await tester.pumpAndSettle();

    expect(find.text('lunora.v00'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
  });
}
