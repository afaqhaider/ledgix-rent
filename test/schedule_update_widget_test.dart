import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/core/routing/app_router.dart';
import 'package:ledgix_rent/features/landlord/domain/landlord.dart';
import 'package:ledgix_rent/features/leases/domain/lease.dart';
import 'package:ledgix_rent/features/payments/domain/payment.dart';
import 'package:ledgix_rent/features/payments/domain/payment_scheduler.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';
import 'package:ledgix_rent/features/tenants/domain/tenant.dart';
import 'package:ledgix_rent/main.dart';
import 'package:material_ui/material_ui.dart';

// Made-up data only.
// Demo data is shared between tests, so each test uses its own agreement id.
Future<ProviderContainer> _editAgreement(WidgetTester tester, String leaseId) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.listen(userIdProvider, (_, _) {});
  var n = 0;
  await tester.runAsync(() async {
    await c.read(authRepositoryProvider).signInWithEmail('su@test.local', 'x');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await c.read(landlordRepositoryProvider).save(const Landlord(id: 'demo', name: 'Test Landlord'));
    await c.read(propertyRepositoryProvider).save(const Property(id: 'P1', landlordId: 'demo', name: 'Test Unit 1', address: 'Test address'));
    await c.read(tenantRepositoryProvider).save(Tenant.fromMap(const {'id': 'T1', 'firstName': 'Test', 'lastName': 'Tenant', 'phone': '0500000000', 'emiratesIdNo': '784-0000-0000000-0'}));
    final lease = Lease(id: leaseId, propertyId: 'P1', tenantId: 'T1', startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 12, 31), annualRent: 60000, numberOfCheques: 4);
    await c.read(leaseRepositoryProvider).save(lease);
    final pays = PaymentScheduler.generate(lease, () => '$leaseId-p${n++}');
    await c.read(paymentRepositoryProvider).save(pays[0].copyWith(status: PaymentStatus.cleared));
    for (final p in pays.skip(1)) {
      await c.read(paymentRepositoryProvider).save(p);
    }
  });
  await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const LedgixApp()));
  await tester.pumpAndSettle();
  c.read(routerProvider).push('/leases/$leaseId/edit');
  await tester.pumpAndSettle();
  return c;
}

Future<List<Payment>> _payments(WidgetTester tester, ProviderContainer c, String leaseId) async =>
    [for (final p in (await tester.runAsync(() => c.read(paymentRepositoryProvider).watchAll().first))!) if (p.leaseId == leaseId) p];

void main() {
  testWidgets('editing the rent asks first, then rebuilds only untouched payments', (tester) async {
    final c = await _editAgreement(tester, 'SU1');
    final rent = find.byKey(const ValueKey('field-annualRent'));
    expect(rent.hitTestable(), findsOneWidget);
    await tester.enterText(rent, '72000');
    await tester.tap(find.byKey(const Key('form-save')));
    // The save spinner keeps animating behind the dialog, so pump frames.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byKey(const Key('schedule-update-dialog')), findsOneWidget);
    expect(find.byKey(const Key('schedule-update')).hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const Key('schedule-update')));
    await tester.pumpAndSettle();

    final pays = await _payments(tester, c, 'SU1');
    final cleared = pays.where((p) => p.status == PaymentStatus.cleared).toList();
    expect(cleared.single.amount, 15000); // untouched
    expect(pays.fold<double>(0, (s, p) => s + p.amount), 72000);
    expect(pays.length, 4);
  });

  testWidgets('"Keep current schedule" saves the agreement without touching payments', (tester) async {
    final c = await _editAgreement(tester, 'SU2');
    await tester.enterText(find.byKey(const ValueKey('field-annualRent')), '72000');
    await tester.tap(find.byKey(const Key('form-save')));
    // The save spinner keeps animating behind the dialog, so pump frames.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byKey(const Key('schedule-keep')));
    await tester.pumpAndSettle();

    final pays = await _payments(tester, c, 'SU2');
    expect(pays.fold<double>(0, (s, p) => s + p.amount), 60000);
    final lease = (await tester.runAsync(() => c.read(leaseRepositoryProvider).get('SU2')))!;
    expect(lease.annualRent, 72000);
  });
}
