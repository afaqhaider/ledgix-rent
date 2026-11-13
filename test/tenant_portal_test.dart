import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/layout/navigation.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/core/routing/app_router.dart';
import 'package:ledgix_rent/core/utils/dates.dart';
import 'package:ledgix_rent/features/account/account_providers.dart';
import 'package:ledgix_rent/features/account/data/account_repository.dart';
import 'package:ledgix_rent/features/account/domain/app_user.dart';
import 'package:ledgix_rent/features/landlord/domain/landlord.dart';
import 'package:ledgix_rent/features/leases/domain/lease.dart';
import 'package:ledgix_rent/features/maintenance/domain/maintenance_ticket.dart';
import 'package:ledgix_rent/features/payments/domain/payment.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';
import 'package:ledgix_rent/features/tenant_portal/data/tenant_portal.dart';
import 'package:ledgix_rent/features/tenant_portal/domain/tenant_view.dart';
import 'package:ledgix_rent/features/tenants/domain/tenant.dart';
import 'package:ledgix_rent/main.dart';
import 'package:material_ui/material_ui.dart';

final _today = DateTime(2026, 11, 14);

/// Seeds one landlord's data in the demo store. [ended] makes the lease a past one.
Future<String> _seedLandlord(String ll, {required String name, required String property, bool ended = false}) async {
  await demoRepo<Landlord>(ll, 'profile').save(Landlord(id: ll, name: name, email: '$ll@example.test', phone: '0500000000', emiratesIdNo: '784-1970-1111111-1'));
  await demoRepo<Property>(ll, 'properties').save(Property(
    id: '$ll-p1',
    landlordId: ll,
    name: property,
    address: 'Example Street 1',
    dewaPremiseNo: '123456789',
    documents: const [
      AppDocument(name: 'Title deed', url: 'https://example.test/deed.pdf', kind: DocumentKinds.titleDeed, sharedWithTenant: true),
      AppDocument(name: 'Owner passport', url: 'https://example.test/pp.jpg', kind: DocumentKinds.ownerPassport),
    ],
  ));
  await demoRepo<Tenant>(ll, 'tenants').save(Tenant(id: '$ll-t1', firstName: 'Sam', lastName: 'Renter', phone: '0501111111', emiratesIdNo: '784-1990-2222222-2'));
  final start = ended ? DateTime(2024, 1, 1) : DateTime(2026, 1, 1);
  final end = ended ? DateTime(2024, 12, 31) : DateTime(2027, 12, 31);
  await demoRepo<Lease>(ll, 'leases').save(Lease(
    id: '$ll-l1',
    propertyId: '$ll-p1',
    tenantId: '$ll-t1',
    startDate: start,
    endDate: end,
    annualRent: 120000,
    numberOfCheques: 2,
  ));
  await demoRepo<Payment>(ll, 'payments').save(Payment(
    id: '$ll-pay1',
    leaseId: '$ll-l1',
    type: PaymentMethod.cheque,
    amount: 60000,
    dueDate: DateTime.now().add(const Duration(days: 20)),
    chequeNo: '000123',
    imageUrl: 'https://example.test/cheque1.jpg',
  ));
  await demoRepo<Payment>(ll, 'payments').save(Payment(
    id: '$ll-pay2',
    leaseId: '$ll-l1',
    type: PaymentMethod.cheque,
    amount: 60000,
    dueDate: DateTime.now().add(const Duration(days: 200)),
    imageUrl: 'https://example.test/cheque2.jpg',
    shareImageWithTenant: false,
  ));
  final invite = await DemoTenantPortal().createInvite(landlordUid: ll, tenantId: '$ll-t1', leaseId: '$ll-l1');
  return invite.code;
}

Future<void> _desktop(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    InMemoryAccountRepository.reset();
    DemoTenantPortal.reset();
  });

  group('buildTenantView', () {
    Lease lease(String id, String tenantId, {DateTime? end, List<AppDocument> docs = const []}) => Lease(
          id: id,
          propertyId: 'p1',
          tenantId: tenantId,
          startDate: DateTime(2026, 1, 1),
          endDate: end ?? DateTime(2027, 1, 1),
          annualRent: 90000,
          documents: docs,
        );

    test('only the tenant\'s own leases, payments, shared documents and shared cheque copies', () {
      final v = buildTenantView(
        landlordUid: 'L',
        tenantUid: 'U',
        profile: const Landlord(id: 'L', name: 'Mr XYZ', emiratesIdNo: '784-1970-1111111-1'),
        tenants: [Tenant(id: 't1', name: 'Me', appUid: 'U'), Tenant(id: 't2', name: 'Someone else')],
        leases: [
          lease('l1', 't1', docs: const [AppDocument(name: 'Ejari', url: 'https://x/e.pdf', kind: DocumentKinds.ejari, sharedWithTenant: true)]),
          lease('l2', 't2'),
        ],
        properties: const [
          Property(id: 'p1', landlordId: 'L', name: 'Tower A', documents: [
            AppDocument(name: 'Deed', url: 'https://x/d.pdf', kind: DocumentKinds.titleDeed, sharedWithTenant: true),
            AppDocument(name: 'Private', url: 'https://x/p.pdf'),
          ]),
        ],
        payments: [
          Payment(id: 'a', leaseId: 'l1', type: PaymentMethod.cheque, amount: 1, dueDate: _today, imageUrl: 'https://x/c.jpg'),
          Payment(id: 'b', leaseId: 'l1', type: PaymentMethod.cheque, amount: 1, dueDate: _today, imageUrl: 'https://x/h.jpg', shareImageWithTenant: false),
          Payment(id: 'c', leaseId: 'l2', type: PaymentMethod.cheque, amount: 1, dueDate: _today),
        ],
        inspections: const [
          {'id': 'i1', 'leaseId': 'l1', 'type': 'moveIn'},
          {'id': 'i2', 'leaseId': 'l2', 'type': 'moveIn'},
        ],
        today: _today,
      );
      expect(v.landlord.name, 'Mr XYZ');
      expect(v.landlord.emiratesIdNo, '784-1970-1111111-1');
      expect(v.status, LinkStatus.active);
      expect(v.leases.map((x) => x.id), ['l1']);
      expect(v.payments.map((x) => x.id), ['a', 'b']);
      expect(v.payments.firstWhere((p) => p.id == 'a').imageUrl, isNotNull);
      expect(v.payments.firstWhere((p) => p.id == 'b').imageUrl, isNull);
      expect(v.documents.map((d) => d.kind).toSet(), {DocumentKinds.titleDeed, DocumentKinds.ejari});
      expect(v.inspections.map((i) => i['id']), ['i1']);
      expect(v.inspections.single['landlordUid'], 'L');
      expect(v.properties.single.agreementAmount, 90000);
      expect(tenantPropertyTitle(v.properties.single, formatAed, 'Agreement'), 'Tower A · Agreement AED 90,000.00');
    });

    test('the link becomes former once every lease has ended', () {
      final v = buildTenantView(
        landlordUid: 'L',
        tenantUid: 'U',
        profile: null,
        tenants: [Tenant(id: 't1', name: 'Me', appUid: 'U')],
        leases: [lease('l1', 't1', end: DateTime(2025, 6, 30))],
        properties: const [Property(id: 'p1', landlordId: 'L', name: 'Old flat')],
        payments: const [],
        today: _today,
      );
      expect(v.status, LinkStatus.former);
    });
  });

  group('invite codes', () {
    test('redeem links the tenant once; reused, unknown and own codes are refused', () async {
      final code = await _seedLandlord('llX', name: 'Mr X', property: 'X Tower');
      final portal = DemoTenantPortal();
      expect(code, hasLength(8));
      expect(code, matches(RegExp('^[${TenantPortal.alphabet}]{8}\$')));
      await expectLater(portal.redeem(tenantUid: 'llX', code: code),
          throwsA(isA<RedeemException>().having((e) => e.reason, 'reason', RedeemError.ownCode)));
      await expectLater(portal.redeem(tenantUid: 'u1', code: 'NOPE2345'),
          throwsA(isA<RedeemException>().having((e) => e.reason, 'reason', RedeemError.invalid)));
      await portal.redeem(tenantUid: 'u1', code: code.toLowerCase());
      expect((await demoRepo<Tenant>('llX', 'tenants').get('llX-t1'))!.appUid, 'u1');
      await expectLater(portal.redeem(tenantUid: 'u2', code: code),
          throwsA(isA<RedeemException>().having((e) => e.reason, 'reason', RedeemError.used)));
      final links = await portal.watchLinks('u1').first;
      expect(links.single.landlordUid, 'llX');
    });

    test('maintenance requests reach the landlord as tenant-raised tickets', () async {
      final code = await _seedLandlord('llM', name: 'Mr M', property: 'M Tower');
      final portal = DemoTenantPortal();
      await portal.redeem(tenantUid: 'u9', code: code);
      await portal.createMaintenanceRequest(tenantUid: 'u9', landlordUid: 'llM', propertyId: 'llM-p1', title: 'AC not cooling');
      final ticket = demoRepo<MaintenanceTicket>('llM', 'maintenanceTickets').items.single;
      expect(ticket.raisedBy, 'tenant');
      expect(ticket.title, 'AC not cooling');
    });
  });

  testWidgets('landlord onboarding asks only name, units and role', (tester) async {
    await _desktop(tester);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const LedgixApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('email-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Set up your account'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // name + units, no property step
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number (1 or more)'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('onboarding-name')), 'Pat Manager');
    await tester.enterText(find.byKey(const Key('onboarding-units')), '12');
    await tester.tap(find.text('Property manager'));
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();
    final user = c.read(appUserProvider).value!;
    expect(user.role, UserRole.propertyManager);
    expect(user.unitCount, 12);
    expect(find.text('Collected this month'), findsOneWidget); // landlord dashboard
    await c.read(authRepositoryProvider).signOut();
    await tester.pumpAndSettle();
  });

  testWidgets('tenant signs up with a code, sees properties, cheque copies and documents; manages landlords',
      (tester) async {
    await _desktop(tester);
    final codeA = (await tester.runAsync(() => _seedLandlord('llA', name: 'Mr XYZ', property: 'Tower A')))!;
    final codeB = (await tester.runAsync(() => _seedLandlord('llB', name: 'Ms Former', property: 'Old Villa', ended: true)))!;

    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const LedgixApp()));
    await tester.pumpAndSettle();

    // Sign up as a tenant.
    await tester.tap(find.byKey(const Key('toggle-sign-up')));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'm a tenant"));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('email-submit')));
    await tester.pumpAndSettle();

    // Tenant onboarding: name + invite code.
    expect(find.text('Welcome to LedGix Rent'), findsWidgets);
    await tester.enterText(find.byKey(const Key('onboarding-name')), 'Sam Renter');
    await tester.enterText(find.byKey(const Key('onboarding-code')), 'WRONG234');
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();
    expect(find.text("That code isn't valid. Check it and try again."), findsOneWidget);
    await tester.enterText(find.byKey(const Key('onboarding-code')), codeA);
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();
    expect(c.read(appUserProvider).value!.role, UserRole.tenant);

    // Tenant home.
    expect(find.byKey(const Key('nav-/t')), findsOneWidget);
    expect(find.byKey(const Key('nav-/portfolio')), findsNothing); // no landlord menu
    expect(find.byKey(const Key('next-payment-amount')), findsOneWidget);

    // Properties: "{name} · Agreement AED x", details and only shared documents.
    await tester.tap(find.byKey(const Key('nav-/t/properties')));
    await tester.pumpAndSettle();
    expect(find.text('Tower A · Agreement AED 120,000.00'), findsOneWidget);
    await tester.tap(find.text('Tower A · Agreement AED 120,000.00'));
    await tester.pumpAndSettle();
    expect(find.text('123456789'), findsOneWidget); // DEWA premise no.
    expect(find.text('Title deed'), findsOneWidget);
    expect(find.text('Owner passport'), findsNothing);

    // Payments: the shared cheque copy only.
    await tester.tap(find.byKey(const Key('nav-/t/payments')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cheque-copy-llA-pay1')), findsOneWidget);
    expect(find.byKey(const Key('cheque-copy-llA-pay2')), findsNothing);

    // Landlord details include the Emirates ID.
    await tester.tap(find.byKey(const Key('nav-/t/landlords')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('landlord-llA')));
    await tester.pumpAndSettle();
    expect(find.text('784-1970-1111111-1'), findsOneWidget);
    expect(find.text('llA@example.test'), findsOneWidget);

    // Add a second landlord with a code: the ended lease shows under Former and can be removed.
    await tester.tap(find.byKey(const Key('nav-/t/landlords')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-landlord')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('add-landlord-code')), codeB);
    await tester.tap(find.byKey(const Key('add-landlord-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Former'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    await tester.tap(find.byKey(const Key('remove-landlord-llB')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-remove-landlord')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('landlord-llB')), findsNothing);
    expect(find.byKey(const Key('landlord-llA')), findsOneWidget);

    // Landlord routes are closed to tenants.
    c.read(routerProvider).go('/portfolio');
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).routerDelegate.currentConfiguration.uri.path, '/t');

    await c.read(authRepositoryProvider).signOut();
    await tester.pumpAndSettle();
  });

  test('document share switch is stored with the document', () {
    const d = AppDocument(name: 'Ejari', url: 'u', kind: DocumentKinds.ejari);
    expect(d.sharedWithTenant, isFalse);
    expect(AppDocument.fromMap(d.withShared(true).toMap()).sharedWithTenant, isTrue);
    final p = Payment(id: 'p', leaseId: 'l', type: PaymentMethod.cheque, amount: 1, dueDate: _today);
    expect(p.shareImageWithTenant, isTrue); // cheque copies are shared by default
    expect(Payment.fromMap(p.copyWith(shareImageWithTenant: false).toMap()).shareImageWithTenant, isFalse);
  });

  test('tenant nav: home matches exactly, sections own their pages', () {
    expect(navItemFor('/t/properties')?.path, '/t/properties');
    expect(navItemFor('/t')?.path, '/t');
    expect(navItemFor('/t/landlords/abc')?.path, '/t/landlords');
    expect(navItemFor('/portfolio')?.path, '/portfolio');
  });

  test('tenant edits keep the app link', () {
    final t = Tenant(id: 't', name: 'A B', appUid: 'U', inviteCode: 'ABCD2345', inviteExpiresAt: DateTime(2030));
    final e = t.copyDetails(
        firstName: 'A', middleName: '', lastName: 'C', email: '', phone: '', emiratesIdNo: '', passportNo: '', documents: const []);
    expect(e.appUid, 'U');
    expect(Tenant.fromMap(e.toMap()).inviteCode, 'ABCD2345');
    expect(e.inviteStatus(DateTime(2026)), TenantInviteStatus.joined);
  });
}
