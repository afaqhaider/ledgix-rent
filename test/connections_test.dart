import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/core/routing/app_router.dart';
import 'package:ledgix_rent/features/account/data/account_repository.dart';
import 'package:ledgix_rent/features/account/domain/app_user.dart';
import 'package:ledgix_rent/features/connections/data/connections_service.dart';
import 'package:ledgix_rent/features/connections/domain/connection.dart';
import 'package:ledgix_rent/features/landlord/domain/landlord.dart';
import 'package:ledgix_rent/features/leases/domain/lease.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';
import 'package:ledgix_rent/features/tenant_portal/data/tenant_portal.dart';
import 'package:ledgix_rent/features/tenants/domain/tenant.dart';
import 'package:ledgix_rent/main.dart';
import 'package:material_ui/material_ui.dart';

// All names, emails and numbers here are made up.

const _ll = 'demo'; // demo landlord uid (any non-"tenant" email)
const _tn = 'demo-tenant'; // demo tenant uid (emails starting with "tenant")

Future<void> _accounts() async {
  final repo = InMemoryAccountRepository();
  await repo.save(const AppUser(id: _ll, role: UserRole.landlord, name: 'Mr Owner', email: 'owner@example.test'));
  await repo.save(AppUser(
    id: _tn,
    role: UserRole.tenant,
    name: 'Sam Middle Renter',
    email: 'tenant.sam@example.test',
    phone: '0509999999',
    passportNo: 'P1234567',
    passportExpiry: DateTime(2030, 5, 1),
  ));
  await demoRepo<Landlord>(_ll, 'profile').save(const Landlord(id: _ll, name: 'Mr Owner', email: 'owner@example.test'));
}

/// A landlord tenant record (not linked) with a lease on a named property.
Future<void> _record(String id, {String email = '', String phone = '0501111111', String passport = ''}) async {
  await demoRepo<Property>(_ll, 'properties').save(const Property(id: 'p1', landlordId: _ll, name: 'Tower A'));
  await demoRepo<Tenant>(_ll, 'tenants')
      .save(Tenant(id: id, firstName: 'Sam', lastName: 'Renter', phone: phone, email: email, passportNo: passport, emiratesIdNo: '784-1990-2222222-2'));
  await demoRepo<Lease>(_ll, 'leases').save(Lease(
    id: 'l-$id',
    propertyId: 'p1',
    tenantId: id,
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2027, 1, 1),
    annualRent: 90000,
  ));
}

Future<void> _desktop(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Demo app signed in as [email] (landlord unless it starts with "tenant").
Future<ProviderContainer> _app(WidgetTester tester, String email) async {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.listen(userIdProvider, (_, _) {});
  await tester.runAsync(() async {
    await c.read(authRepositoryProvider).signInWithEmail(email, 'x');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });
  await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const LedgixApp()));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _go(WidgetTester tester, ProviderContainer c, String path) async {
  c.read(routerProvider).push(path);
  await tester.pumpAndSettle();
}

void main() {
  final svc = DemoConnectionsService();

  setUp(() async {
    InMemoryAccountRepository.reset();
    DemoTenantPortal.reset();
    DemoConnectionsService.reset();
    await _accounts();
  });

  group('domain', () {
    test('email or LedGix code input', () {
      expect(ConnectTarget.parse(' Sam@Example.TEST '), isA<EmailTarget>());
      expect((ConnectTarget.parse('lgx 7k3m9q') as CodeTarget).code, 'LGX-7K3M9Q');
      expect(ConnectTarget.parse('LGX-7K3M9O'), isNull); // O isn't in the alphabet
      expect(ConnectTarget.parse('hello'), isNull);
    });

    test('shared details fill only empty fields', () {
      final t = Tenant(id: 't', firstName: 'Typed', lastName: 'ByLandlord', phone: '0501111111');
      final d = SharedDetails(
          name: 'Sam Middle Renter', phone: '0509999999', email: 'a@b.test', passportNo: 'P1', passportExpiry: DateTime(2030));
      final out = fillEmptyFields(t, d);
      expect(out.firstName, 'Typed'); // the landlord's typing wins
      expect(out.phone, '0501111111');
      expect(out.email, 'a@b.test');
      expect(out.passportNo, 'P1');
      expect(out.passportExpiry, DateTime(2030));
      final blank = fillEmptyFields(Tenant(id: 't'), d);
      expect([blank.firstName, blank.middleName, blank.lastName], ['Sam', 'Middle', 'Renter']);
    });
  });

  group('service', () {
    test('lookup: none, self, exists, linked', () async {
      expect((await svc.lookup(_ll, const EmailTarget('nobody@example.test'))).exists, isFalse);
      expect((await svc.lookup(_ll, const EmailTarget('owner@example.test'))).self, isTrue);
      final found = await svc.lookup(_ll, const EmailTarget('tenant.sam@example.test'));
      expect([found.exists, found.linked, found.role], [true, false, UserRole.tenant]);
      await _record('t1');
      await DemoTenantPortal.demoLink(landlordUid: _ll, tenantId: 't1', tenantUid: _tn);
      expect((await svc.lookup(_ll, const EmailTarget('tenant.sam@example.test'))).linked, isTrue);
    });

    test('lookups are rate limited', () async {
      for (var i = 0; i < DemoConnectionsService.maxLookupsPerHour; i++) {
        await svc.lookup(_ll, const EmailTarget('x@example.test'));
      }
      expect(() => svc.lookup(_ll, const EmailTarget('x@example.test')),
          throwsA(isA<ConnectionException>().having((e) => e.reason, 'reason', ConnectionError.rateLimited)));
    });

    test('share codes are stable, unique and find the account', () async {
      final a = await svc.myShareCode(_ll);
      expect(a, matches(RegExp(r'^LGX-[A-Z2-9]{6}$')));
      expect(await svc.myShareCode(_ll), a);
      expect(await svc.myShareCode(_tn), isNot(a));
      expect((await svc.lookup(_tn, CodeTarget(a))).role, UserRole.landlord);
    });

    test('landlord invites by email; tenant accepts with consent; only empty fields fill', () async {
      await _record('t1', phone: '0501111111');
      await svc.inviteTenant(landlordUid: _ll, tenantRecordId: 't1', target: const EmailTarget('tenant.sam@example.test'));
      expect(
          () => svc.inviteTenant(landlordUid: _ll, tenantRecordId: 't1', target: const EmailTarget('tenant.sam@example.test')),
          throwsA(isA<ConnectionException>().having((e) => e.reason, 'reason', ConnectionError.duplicate)));
      final r = (await svc.watchIncoming(_tn).first).single;
      expect(r.propertyName, 'Tower A');
      expect(r.fromName, 'Mr Owner');
      expect(() => svc.accept(uid: _ll, requestId: r.id), throwsA(isA<ConnectionException>())); // only the recipient
      await svc.accept(uid: _tn, requestId: r.id, shareDetails: true);
      final t = (await demoRepo<Tenant>(_ll, 'tenants').get('t1'))!;
      expect(t.appUid, _tn);
      expect(t.phone, '0501111111'); // kept
      expect(t.passportNo, 'P1234567'); // filled from the tenant's details
      expect((await svc.watchOutgoing(_ll).first).single.status, ConnectionStatus.accepted);
    });

    test('accepting without consent shares nothing', () async {
      await _record('t1');
      await svc.inviteTenant(landlordUid: _ll, tenantRecordId: 't1', target: const EmailTarget('tenant.sam@example.test'));
      final r = (await svc.watchIncoming(_tn).first).single;
      await svc.accept(uid: _tn, requestId: r.id);
      expect((await demoRepo<Tenant>(_ll, 'tenants').get('t1'))!.passportNo, '');
    });

    test('decline and cancel', () async {
      await _record('t1');
      await svc.inviteTenant(landlordUid: _ll, tenantRecordId: 't1', target: const EmailTarget('tenant.sam@example.test'));
      var r = (await svc.watchIncoming(_tn).first).single;
      expect(() => svc.cancel(uid: _tn, requestId: r.id), throwsA(isA<ConnectionException>())); // only the sender
      await svc.decline(uid: _tn, requestId: r.id);
      expect((await svc.watchIncoming(_tn).first).single.status, ConnectionStatus.declined);
      await svc.inviteTenant(landlordUid: _ll, tenantRecordId: 't1', target: const EmailTarget('tenant.sam@example.test'));
      r = (await svc.watchOutgoing(_ll).first).firstWhere((x) => x.isPending);
      await svc.cancel(uid: _ll, requestId: r.id);
      expect((await svc.watchOutgoing(_ll).first).where((x) => x.isPending), isEmpty);
    });

    test('tenant asks a landlord by code; landlord picks the record', () async {
      await _record('t1', email: 'tenant.sam@example.test');
      final code = await svc.myShareCode(_ll);
      await svc.requestLandlord(tenantUid: _tn, target: CodeTarget(code), shareDetails: true);
      // Nobody can send a request to their own code.
      expect(() => svc.requestLandlord(tenantUid: _ll, target: CodeTarget(code), shareDetails: false),
          throwsA(isA<ConnectionException>().having((e) => e.reason, 'reason', ConnectionError.self)));
      final r = (await svc.watchIncoming(_ll).first).single;
      expect(r.direction, ConnectionDirection.tenantToLandlord);
      expect(r.target, code);
      expect(r.details!.passportNo, 'P1234567');
      await svc.accept(uid: _ll, requestId: r.id, tenantRecordId: 't1');
      final t = (await demoRepo<Tenant>(_ll, 'tenants').get('t1'))!;
      expect(t.appUid, _tn);
      expect(t.passportNo, 'P1234567');
    });

    test('a tenant account is the wrong role for a landlord request', () async {
      await InMemoryAccountRepository()
          .save(const AppUser(id: 'other-tenant', role: UserRole.tenant, email: 'tenant.other@example.test'));
      expect(() => svc.requestLandlord(tenantUid: _tn, target: const EmailTarget('tenant.other@example.test'), shareDetails: false),
          throwsA(isA<ConnectionException>().having((e) => e.reason, 'reason', ConnectionError.wrongRole)));
    });
  });

  group('screens at 1440x1000', () {
    testWidgets('tenant form: existing account banner and Send invitation', (tester) async {
      await _desktop(tester);
      await tester.runAsync(() => _record('t1'));
      final c = await _app(tester, 'owner@example.test');
      await _go(tester, c, '/tenants/t1/edit');
      await tester.enterText(find.byKey(const ValueKey('field-email')), 'tenant.sam@example.test');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('This person already uses LedGix Rent.').hitTestable(), findsOneWidget);
      await tester.tap(find.byKey(const Key('send-invitation')));
      await tester.pumpAndSettle();
      expect(find.text('Invitation sent, waiting for their answer.'), findsOneWidget);
      final sent = await tester.runAsync(() => DemoConnectionsService().watchOutgoing(_ll).first);
      expect(sent!.single.tenantRecordId, 't1');
    });

    testWidgets('tenant form: own email and unknown email', (tester) async {
      await _desktop(tester);
      await tester.runAsync(() => _record('t1'));
      final c = await _app(tester, 'owner@example.test');
      await _go(tester, c, '/tenants/t1/edit');
      await tester.enterText(find.byKey(const ValueKey('field-email')), 'owner@example.test');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text("That's your own email."), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('field-email')), 'nobody@example.test');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('email-account-check')), findsNothing);
    });

    testWidgets('tenant accepts an invitation from Home, sharing details', (tester) async {
      await _desktop(tester);
      await tester.runAsync(() async {
        await _record('t1');
        await DemoConnectionsService()
            .inviteTenant(landlordUid: _ll, tenantRecordId: 't1', target: const EmailTarget('tenant.sam@example.test'));
      });
      await _app(tester, 'tenant.sam@example.test');
      expect(find.text('Mr Owner wants to connect you to Tower A').hitTestable(), findsOneWidget);
      await tester.tap(find.textContaining('Accept').first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('share-my-details')), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-accept')));
      await tester.pumpAndSettle();
      final t = await tester.runAsync(() => demoRepo<Tenant>(_ll, 'tenants').get('t1'));
      expect(t!.appUid, _tn);
      expect(t.passportNo, 'P1234567');
      expect(find.text('Mr Owner wants to connect you to Tower A'), findsNothing);
    });

    testWidgets('tenant adds a landlord by email; the request shows as sent', (tester) async {
      await _desktop(tester);
      final c = await _app(tester, 'tenant.sam@example.test');
      await _go(tester, c, '/t/landlords');
      await tester.tap(find.byKey(const Key('add-landlord')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('add-landlord-code')), 'owner@example.test');
      await tester.tap(find.byKey(const Key('add-landlord-submit')));
      await tester.pumpAndSettle();
      expect(find.text('owner@example.test').hitTestable(), findsOneWidget);
      expect(find.textContaining('Waiting for their answer'), findsOneWidget);
    });

    testWidgets('landlord dashboard: accept a tenant request by choosing the record', (tester) async {
      await _desktop(tester);
      await tester.runAsync(() async {
        await _record('t1', email: 'tenant.sam@example.test');
        await DemoConnectionsService()
            .requestLandlord(tenantUid: _tn, target: const EmailTarget('owner@example.test'), shareDetails: true);
      });
      await _app(tester, 'owner@example.test');
      expect(find.byKey(const Key('connection-requests-card')).hitTestable(), findsOneWidget);
      await tester.tap(find.descendant(of: find.byKey(const Key('connection-requests-card')), matching: find.text('Accept')));
      await tester.pumpAndSettle();
      expect(find.text('Email matches'), findsOneWidget);
      await tester.tap(find.byKey(const Key('pick-tenant-t1')));
      await tester.pumpAndSettle();
      final t = await tester.runAsync(() => demoRepo<Tenant>(_ll, 'tenants').get('t1'));
      expect(t!.appUid, _tn);
      expect(find.byKey(const Key('connection-requests-card')), findsNothing);
    });

    testWidgets('My LedGix code and My details', (tester) async {
      await _desktop(tester);
      final c = await _app(tester, 'tenant.sam@example.test');
      await _go(tester, c, '/t/my-code');
      expect(find.byKey(const Key('my-code-qr')).hitTestable(), findsOneWidget);
      expect(find.textContaining('LGX-'), findsOneWidget);
      c.read(routerProvider).pop();
      await tester.pumpAndSettle();
      await _go(tester, c, '/t/my-details');
      expect(find.byKey(const ValueKey('my-name')).hitTestable(), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('my-eid')), '784-1990-2222222-2');
      await tester.tap(find.byKey(const Key('form-save')));
      await tester.pumpAndSettle();
      expect(InMemoryAccountRepository.byId(_tn)!.emiratesIdNo, '784-1990-2222222-2');
      expect(InMemoryAccountRepository.byId(_tn)!.passportNo, 'P1234567');
    });
  });
}
