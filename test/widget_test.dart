import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/features/landlord/domain/landlord.dart';
import 'package:ledgix_rent/features/maintenance/domain/maintenance_ticket.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';
import 'package:ledgix_rent/features/vendors/domain/vendor.dart';
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
    await tester.tap(find.text('Maintenance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AC leak'));
    await tester.pumpAndSettle();

    // Company is preselected only via defaults; pick it, then request a quote.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CoolFix').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request Quote'));
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
