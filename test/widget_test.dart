import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/main.dart';

void main() {
  testWidgets('demo flow: sign in, onboard, see dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LedgixApp()));
    await tester.pumpAndSettle();

    // Login screen (demo auth accepts any credentials).
    expect(find.text('Sign in'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    // Onboarding.
    expect(find.text('Welcome, landlord!'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Afaq');
    await tester.enterText(find.byType(TextFormField).at(1), 'Marina Studio');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    // Dashboard, then portfolio lists the first property.
    expect(find.text('Collected this month'), findsOneWidget);
    await tester.tap(find.text('Portfolio'));
    await tester.pumpAndSettle();
    expect(find.text('Marina Studio'), findsOneWidget);
  });

  testWidgets('Arabic locale is right-to-left', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(localeProvider.notifier).set('ar');
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const LedgixApp()));
    await tester.pumpAndSettle();
    final dir = Directionality.of(tester.element(find.byType(Scaffold).first));
    expect(dir.name, 'rtl');
  });
}
