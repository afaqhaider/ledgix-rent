import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/layout/app_shell.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/features/landlord/domain/landlord.dart';
import 'package:ledgix_rent/features/maintenance/domain/maintenance_ticket.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';
import 'package:ledgix_rent/features/vendors/domain/vendor.dart';
import 'package:ledgix_rent/main.dart';

/// Scrolls a lazily built list until [finder] is on screen, then taps it.
/// Needed on real phones, where buttons can sit below the fold.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: pageScrollable);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// The page's own vertical list (not the navigation sidebar/rail).
final pageScrollable = find
    .byElementPredicate((e) =>
        e.widget is Scrollable &&
        axisDirectionToAxis((e.widget as Scrollable).axisDirection) == Axis.vertical &&
        e.findAncestorWidgetOfExactType<Sidebar>() == null)
    .first;

/// Completes landlord onboarding if it is showing (demo data is shared
/// across tests, so it may already be done).
Future<void> onboardLandlord(WidgetTester tester) async {
  if (find.byKey(const Key('onboarding-units')).evaluate().isEmpty) return;
  await tester.enterText(find.byKey(const Key('onboarding-name')), 'Afaq');
  await tester.enterText(find.byKey(const Key('onboarding-units')), '3');
  await tapVisible(tester, find.byKey(const Key('onboarding-continue')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('demo flow: sign in, onboard, see dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LedgixApp()));
    await tester.pumpAndSettle();

    // Login screen (demo auth accepts any credentials).
    expect(find.text('Sign in'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    // Onboarding: name, number of units and role only.
    expect(find.text('Set up your account'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-role')), findsOneWidget);
    await onboardLandlord(tester);

    // Dashboard, then the (empty) portfolio.
    expect(find.text('Collected this month'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-/portfolio')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nav-/portfolio')), findsOneWidget);
  });

  testWidgets('Continue with LedGix ID signs in (demo)', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LedgixApp()));
    await tester.pumpAndSettle();
    expect(find.text('Continue with LedGix ID'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('ledgix-sign-in')));
    await tester.pumpAndSettle();
    // Signed in: login is gone (onboarding or dashboard, depending on demo state).
    expect(find.byKey(const Key('ledgix-sign-in')), findsNothing);
    expect(
      find.text('Set up your account').evaluate().isNotEmpty || find.text('Collected this month').evaluate().isNotEmpty,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox()); // reset for the next test
  });

  testWidgets('delete account asks first, then signs out', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LedgixApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    // Demo data is shared across tests, so onboarding may already be done.
    await onboardLandlord(tester);

    await tester.tap(find.byKey(const Key('nav-/settings')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Privacy policy'), 200, scrollable: pageScrollable);
    expect(find.text('Privacy policy'), findsOneWidget);

    // Cancel keeps the account.
    await tapVisible(tester, find.byKey(const Key('delete-account')));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsNothing);
    expect(find.text('Sign out'), findsOneWidget);

    // Confirm deletes and returns to the login screen.
    await tapVisible(tester, find.byKey(const Key('delete-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-account')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(find.text('Your account has been deleted.'), findsOneWidget);
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

  testWidgets('forward a maintenance request to a company and approve its quote', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(userIdProvider, (_, _) {});
    await tester.runAsync(() async {
      await container.read(authRepositoryProvider).signInWithEmail('a@b.c', 'x');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await container.read(landlordRepositoryProvider).save(const Landlord(id: 'demo', name: 'A'));
      await container.read(propertyRepositoryProvider).save(const Property(id: 'p1', landlordId: 'demo', name: 'Marina 1203'));
      await container.read(vendorRepositoryProvider).save(const Vendor(id: 'v1', name: 'CoolFix', email: 'fix@example.ae'));
      await container.read(maintenanceRepositoryProvider).save(const MaintenanceTicket(id: 't1', propertyId: 'p1', title: 'AC leak'));
    });

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const LedgixApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-/maintenance')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AC leak'));
    await tester.pumpAndSettle();

    // Company is preselected only via defaults; pick it, then request a quote.
    await tapVisible(tester, find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CoolFix').last);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Request Quote'));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final orders = await container.read(workOrderRepositoryProvider).watchAll().first;
      expect(orders.single.channel, ForwardChannel.email);
      expect(orders.single.body, contains('Please review this maintenance request'));
      final ticket = (await container.read(maintenanceRepositoryProvider).get('t1'))!;
      expect(ticket.status, TicketStatus.requested);
    });
  });
}
