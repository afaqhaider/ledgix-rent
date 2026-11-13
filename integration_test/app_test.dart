// On-device tests (demo mode, in-memory data, nothing sent to Firebase).
// Run: flutter test integration_test -d <device-id>
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Brightness;
import 'package:integration_test/integration_test.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/core/routing/app_router.dart';
import 'package:ledgix_rent/features/account/account_providers.dart';
import 'package:ledgix_rent/features/account/domain/app_user.dart';
import 'package:ledgix_rent/features/landlord/domain/landlord.dart';
import 'package:ledgix_rent/features/leases/domain/lease.dart';
import 'package:ledgix_rent/features/tenant_portal/data/tenant_portal.dart';
import 'package:ledgix_rent/features/tenants/domain/tenant.dart';
import 'package:ledgix_rent/features/maintenance/domain/maintenance_ticket.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';
import 'package:ledgix_rent/main.dart';

import '../test/widget_test.dart' as widget_flows;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The same end-to-end flows as test/widget_test.dart, on a real device.
  group('flows', widget_flows.main);

  for (final (brightness, locale) in [
    for (final b in Brightness.values)
      for (final l in ['en', 'ar']) (b, l),
  ]) {
    testWidgets('every screen renders without errors ($locale, ${brightness.name})', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(localeProvider.notifier).set(locale);
      container.listen(userIdProvider, (_, _) {});
      await tester.runAsync(() async {
        await container.read(authRepositoryProvider).signInWithEmail('device@test.local', 'x');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await container.read(landlordRepositoryProvider).save(const Landlord(id: 'demo', name: 'Device Test'));
        await container.read(propertyRepositoryProvider).save(const Property(id: 'p1', landlordId: 'demo', name: 'Marina 1203'));
        await container.read(maintenanceRepositoryProvider).save(const MaintenanceTicket(id: 't1', propertyId: 'p1', title: 'AC leak'));
      });
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const LedgixApp()));
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      const paths = [
        '/', '/portfolio', '/cheques', '/maintenance', '/settings', '/profile', '/utilities', '/service-charges',
        '/property/new', '/property/p1', '/property/p1/edit', '/property/p1/bills',
        '/tenants', '/tenants/new', '/leases', '/leases/new',
        '/debits', '/holds', '/tickets/new', '/tickets/t1',
        '/reports', '/vendors', '/vendors/new',
      ];
      for (final path in paths) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'error on $path');
        expect(router.routerDelegate.currentConfiguration.uri.path, path, reason: 'redirected away from $path');
      }
    });

    testWidgets('every tenant screen renders without errors ($locale, ${brightness.name})', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(localeProvider.notifier).set(locale);
      container.listen(userIdProvider, (_, _) {});
      await tester.runAsync(() async {
        // A landlord with one tenancy, and the demo tenant joined with its code.
        const ll = 'device-landlord';
        await demoRepo<Landlord>(ll, 'profile').save(const Landlord(id: ll, name: 'Device Landlord'));
        await demoRepo<Property>(ll, 'properties').save(const Property(id: 'tp1', landlordId: ll, name: 'Marina 1203'));
        await demoRepo<Tenant>(ll, 'tenants').save(Tenant(id: 'tt1', name: 'Device Tenant'));
        await demoRepo<Lease>(ll, 'leases').save(Lease(
            id: 'tl1', propertyId: 'tp1', tenantId: 'tt1', startDate: DateTime(2026), endDate: DateTime(2027, 12, 31), annualRent: 90000));
        final invite = await DemoTenantPortal().createInvite(landlordUid: ll, tenantId: 'tt1');
        await container.read(authRepositoryProvider).signInWithEmail('tenant@device.test', 'x');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final uid = container.read(authRepositoryProvider).currentUserId!;
        await DemoTenantPortal().redeem(tenantUid: uid, code: invite.code).catchError((_) {});
        await container.read(accountRepositoryProvider).save(AppUser(id: uid, role: UserRole.tenant, name: 'Device Tenant'));
      });
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const LedgixApp()));
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      const paths = [
        '/t', '/t/landlords', '/t/landlords/device-landlord', '/t/properties', '/t/payments',
        '/t/inspections', '/t/maintenance', '/t/maintenance/new', '/t/settings',
      ];
      for (final path in paths) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'error on $path');
        expect(router.routerDelegate.currentConfiguration.uri.path, path, reason: 'redirected away from $path');
      }
    });
  }
}
