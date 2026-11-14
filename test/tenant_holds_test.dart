import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/core/routing/app_router.dart';
import 'package:ledgix_rent/features/account/data/account_repository.dart';
import 'package:ledgix_rent/features/holds/domain/hold_request.dart';
import 'package:ledgix_rent/features/landlord/domain/landlord.dart';
import 'package:ledgix_rent/features/leases/domain/lease.dart';
import 'package:ledgix_rent/features/payments/domain/payment.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';
import 'package:ledgix_rent/features/tenant_portal/data/tenant_portal.dart';
import 'package:ledgix_rent/features/tenant_portal/domain/tenant_view.dart';
import 'package:ledgix_rent/features/tenants/domain/tenant.dart';
import 'package:ledgix_rent/main.dart';
import 'package:material_ui/material_ui.dart';

// All data here is made up.

DateTime _day(int days) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day).add(Duration(days: days));
}

/// One landlord with a tenant, a lease and two cheques; returns an invite code.
Future<String> _seed(String ll) async {
  await demoRepo<Landlord>(ll, 'profile').save(Landlord(id: ll, name: 'Mr XYZ', email: '$ll@example.test'));
  await demoRepo<Property>(ll, 'properties').save(Property(id: '$ll-p1', landlordId: ll, name: 'Tower A', address: 'Example Street 1'));
  await demoRepo<Tenant>(ll, 'tenants').save(Tenant(id: '$ll-t1', firstName: 'Sam', lastName: 'Renter', phone: '0501111111'));
  await demoRepo<Lease>(ll, 'leases').save(Lease(
    id: '$ll-l1',
    propertyId: '$ll-p1',
    tenantId: '$ll-t1',
    startDate: _day(-60),
    endDate: _day(300),
    annualRent: 120000,
    numberOfCheques: 2,
  ));
  await demoRepo<Payment>(ll, 'payments').save(Payment(
      id: '$ll-pay1', leaseId: '$ll-l1', type: PaymentMethod.cheque, amount: 60000, dueDate: _day(20), chequeNo: '000123'));
  await demoRepo<Payment>(ll, 'payments').save(Payment(
      id: '$ll-pay2', leaseId: '$ll-l1', type: PaymentMethod.cheque, amount: 60000, dueDate: _day(200),
      status: PaymentStatus.cleared));
  return (await DemoTenantPortal().createInvite(landlordUid: ll, tenantId: '$ll-t1', leaseId: '$ll-l1')).code;
}

Future<void> _desktop(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    InMemoryAccountRepository.reset();
    DemoTenantPortal.reset();
  });

  group('checkTenantHoldRequest', () {
    HoldRequestError? check({
      PaymentStatus status = PaymentStatus.pending,
      int requestedIn = 10,
      String reason = 'Salary is late',
      List<HoldRequest> existing = const [],
    }) =>
        checkTenantHoldRequest(
          status: status,
          dueDate: DateTime(2026, 12, 1),
          requestedDate: DateTime(2026, 12, 1).add(Duration(days: requestedIn)),
          reason: reason,
          existing: existing,
          paymentId: 'p1',
        );

    test('a reason and a later date within 90 days are required', () {
      expect(check(), isNull);
      expect(check(reason: '  '), HoldRequestError.reasonRequired);
      expect(check(requestedIn: 0), HoldRequestError.dateNotAfterDue);
      expect(check(requestedIn: -3), HoldRequestError.dateNotAfterDue);
      expect(check(requestedIn: 90), isNull);
      expect(check(requestedIn: 91), HoldRequestError.dateTooFar);
    });

    test('only pending or on-hold payments, and one open request at a time', () {
      expect(check(status: PaymentStatus.cleared), HoldRequestError.notAllowed);
      expect(check(status: PaymentStatus.deposited), HoldRequestError.notAllowed);
      expect(check(status: PaymentStatus.onHold), isNull);
      final open = HoldRequest(id: 'h', paymentId: 'p1', originalDate: DateTime(2026, 12, 1), requestedDate: DateTime(2026, 12, 9));
      expect(check(existing: [open]), HoldRequestError.alreadyOpen);
      expect(check(existing: [open.copyWith(status: HoldStatus.rejected)]), isNull);
    });
  });

  test('the tenant view carries only their own payments\' hold requests', () {
    final v = buildTenantView(
      landlordUid: 'L',
      tenantUid: 'U',
      profile: const Landlord(id: 'L', name: 'Mr XYZ'),
      tenants: [Tenant(id: 't1', name: 'Me', appUid: 'U'), Tenant(id: 't2', name: 'Someone else')],
      leases: [
        Lease(id: 'l1', propertyId: 'p', tenantId: 't1', startDate: _day(-10), endDate: _day(300), annualRent: 1),
        Lease(id: 'l2', propertyId: 'p', tenantId: 't2', startDate: _day(-10), endDate: _day(300), annualRent: 1),
      ],
      properties: const [Property(id: 'p', landlordId: 'L', name: 'Tower')],
      payments: [
        Payment(id: 'mine', leaseId: 'l1', type: PaymentMethod.cheque, amount: 1, dueDate: _day(5)),
        Payment(id: 'theirs', leaseId: 'l2', type: PaymentMethod.cheque, amount: 1, dueDate: _day(5)),
      ],
      holdRequests: [
        HoldRequest(id: 'h1', paymentId: 'mine', originalDate: _day(5), requestedDate: _day(15), reason: 'late salary'),
        HoldRequest(id: 'h2', paymentId: 'theirs', originalDate: _day(5), requestedDate: _day(15)),
      ],
      today: _day(0),
    );
    expect(v.holdRequests.map((r) => r.id), ['h1']);
    expect(v.holdRequests.single.reason, 'late salary');
  });

  test('demo portal: validates, refuses duplicates, and records a tenant request', () async {
    final code = await _seed('llH');
    final portal = DemoTenantPortal();
    await portal.redeem(tenantUid: 'tenantU', code: code);
    final due = _day(20);

    Future<void> ask(DateTime date, String reason, {String pay = 'llH-pay1'}) => portal.createHoldRequest(
        tenantUid: 'tenantU', landlordUid: 'llH', paymentId: pay, requestedDate: date, reason: reason);
    Matcher fails(HoldRequestError e) => throwsA(isA<HoldRequestException>().having((x) => x.reason, 'reason', e));

    await expectLater(ask(due.add(const Duration(days: 5)), ''), fails(HoldRequestError.reasonRequired));
    await expectLater(ask(due, 'late salary'), fails(HoldRequestError.dateNotAfterDue));
    await expectLater(ask(due.add(const Duration(days: 5)), 'x', pay: 'llH-pay2'), fails(HoldRequestError.notAllowed));
    await ask(due.add(const Duration(days: 5)), 'late salary');
    await expectLater(ask(due.add(const Duration(days: 6)), 'again'), fails(HoldRequestError.alreadyOpen));
    // Someone who isn't linked can't ask.
    await expectLater(
      portal.createHoldRequest(tenantUid: 'stranger', landlordUid: 'llH', paymentId: 'llH-pay1', requestedDate: due.add(const Duration(days: 5)), reason: 'x'),
      fails(HoldRequestError.notAllowed),
    );

    final saved = demoRepo<HoldRequest>('llH', 'holdRequests').items.single;
    expect(saved.fromTenantApp, isTrue);
    expect(saved.tenantId, 'llH-t1');
    expect(saved.leaseId, 'llH-l1');
    expect(saved.requestedByUid, 'tenantU');
    expect(saved.status, HoldStatus.pending);
    // The payment isn't changed until the landlord decides.
    expect((await demoRepo<Payment>('llH', 'payments').get('llH-pay1'))!.dueDate, due);
  });

  testWidgets('tenant (desktop): open a payment, request a hold, then see the landlord\'s answer', (tester) async {
    await _desktop(tester);
    final code = (await tester.runAsync(() => _seed('llW')))!;
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const LedgixApp()));
    await tester.pumpAndSettle();

    // Sign up as a tenant with the code.
    await tester.tap(find.byKey(const Key('toggle-sign-up')));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'm a tenant"));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('email-submit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('onboarding-name')), 'Sam Renter');
    await tester.enterText(find.byKey(const Key('onboarding-code')), code);
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    c.read(routerProvider).go('/t/payments');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payment-tile-llW-pay1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tenant-payment-detail')).hitTestable(), findsOneWidget);

    // The cleared cheque can't be held: no button there (checked below via the first one).
    await tester.tap(find.byKey(const Key('request-hold')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hold-reason')).hitTestable(), findsOneWidget);

    // Reason is required.
    await tester.tap(find.byKey(const Key('hold-send')));
    await tester.pumpAndSettle();
    expect(find.text('Please give a reason.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('hold-reason')), 'Salary is paid late this month');
    await tester.tap(find.byKey(const Key('hold-send')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hold-status')), findsOneWidget);
    expect(find.textContaining('waiting for your landlord'), findsWidgets);
    expect(find.byKey(const Key('request-hold')), findsNothing); // no duplicate open request

    // Landlord declines with a response: the tenant sees it live.
    final req = demoRepo<HoldRequest>('llW', 'holdRequests').items.single;
    final pay = (await tester.runAsync(() => demoRepo<Payment>('llW', 'payments').get('llW-pay1')))!;
    final res = HoldService.reject(req, pay, response: 'Cheque must be deposited on time');
    await tester.runAsync(() async {
      await demoRepo<HoldRequest>('llW', 'holdRequests').save(res.request);
      await demoRepo<Payment>('llW', 'payments').save(res.payment);
    });
    await tester.pumpAndSettle();
    expect(find.text('Hold request declined'), findsWidgets);
    expect(find.textContaining('Cheque must be deposited on time'), findsOneWidget);
    // After a decline the tenant may ask again.
    expect(find.byKey(const Key('request-hold')), findsOneWidget);

    // The cleared cheque has no hold action.
    await tester.tapAt(const Offset(5, 5)); // close the dialog
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payment-tile-llW-pay2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tenant-payment-detail')).hitTestable(), findsOneWidget);
    expect(find.byKey(const Key('request-hold')), findsNothing);
  });

  testWidgets('landlord (desktop): dashboard lists tenant hold requests; approve moves the date, decline keeps it',
      (tester) async {
    await _desktop(tester);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.listen(userIdProvider, (_, _) {});
    final due = _day(20);
    await tester.runAsync(() async {
      await c.read(authRepositoryProvider).signInWithEmail('landlord@test.local', 'x');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      const ll = 'demo';
      await demoRepo<Landlord>(ll, 'profile').save(const Landlord(id: ll, name: 'Me Landlord'));
      await demoRepo<Property>(ll, 'properties').save(const Property(id: 'p1', landlordId: ll, name: 'Tower A'));
      await demoRepo<Tenant>(ll, 'tenants').save(Tenant(id: 't1', firstName: 'Sam', lastName: 'Renter', phone: '1'));
      await demoRepo<Lease>(ll, 'leases').save(
          Lease(id: 'l1', propertyId: 'p1', tenantId: 't1', startDate: _day(-30), endDate: _day(300), annualRent: 120000));
      for (final id in ['a', 'b']) {
        await demoRepo<Payment>(ll, 'payments').save(Payment(
            id: 'pay-$id', leaseId: 'l1', type: PaymentMethod.cheque, amount: 60000, dueDate: due, chequeNo: '00$id'));
        await demoRepo<HoldRequest>(ll, 'holdRequests').save(HoldRequest(
          id: 'h-$id',
          paymentId: 'pay-$id',
          originalDate: due,
          requestedDate: due.add(const Duration(days: 10)),
          reason: 'Salary late ($id)',
          source: 'tenant',
          tenantId: 't1',
          leaseId: 'l1',
        ));
      }
    });
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const LedgixApp()));
    await tester.pumpAndSettle();

    final panel = find.byKey(const Key('dashboard-holds'));
    expect(panel.hitTestable(), findsOneWidget);
    expect(find.descendant(of: panel, matching: find.textContaining('Sam Renter')), findsNWidgets(2));
    expect(find.descendant(of: panel, matching: find.text('2 pending')), findsOneWidget);

    // Approve the first: due date moves to the requested date.
    await tester.tap(find.byKey(const Key('hold-approve-h-a')));
    await tester.pumpAndSettle();
    final a = (await tester.runAsync(() => demoRepo<Payment>('demo', 'payments').get('pay-a')))!;
    expect(a.dueDate, due.add(const Duration(days: 10)));
    final ha = await tester.runAsync(() => demoRepo<HoldRequest>('demo', 'holdRequests').get('h-a'));
    expect(ha!.status, HoldStatus.approved);

    // Decline the second with a response: due date stays.
    await tester.tap(find.byKey(const Key('hold-decline-h-b')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('hold-decline-response')), 'Please deposit on time');
    await tester.tap(find.byKey(const Key('hold-decline-confirm')));
    await tester.pumpAndSettle();
    final b = (await tester.runAsync(() => demoRepo<HoldRequest>('demo', 'holdRequests').get('h-b')))!;
    expect(b.status, HoldStatus.rejected);
    expect(b.response, 'Please deposit on time');
    final pb = await tester.runAsync(() => demoRepo<Payment>('demo', 'payments').get('pay-b'));
    expect(pb!.dueDate, due);
    expect(find.descendant(of: panel, matching: find.text('No pending hold requests.')), findsOneWidget);
  });
}
