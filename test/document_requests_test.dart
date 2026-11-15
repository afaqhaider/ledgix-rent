import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/core/routing/app_router.dart';
import 'package:ledgix_rent/features/account/data/account_repository.dart';
import 'package:ledgix_rent/features/documents/domain/document_request.dart';
import 'package:ledgix_rent/features/landlord/domain/landlord.dart';
import 'package:ledgix_rent/features/leases/domain/lease.dart';
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

const _deed = AppDocument(
  name: 'Deed',
  url: 'https://example.test/deed.pdf',
  kind: DocumentKinds.titleDeed,
  sharedWithTenant: true,
);
const _dewa = AppDocument(
  name: 'DEWA',
  url: 'https://example.test/dewa.pdf',
  kind: DocumentKinds.dewaBill,
  sharedWithTenant: true,
);
const _ownerEid = AppDocument(
  name: 'EID',
  url: 'https://example.test/eid.jpg',
  kind: DocumentKinds.ownerEmiratesId,
  sharedWithTenant: true,
);
const _ownerPp = AppDocument(
  name: 'PP',
  url: 'https://example.test/pp.jpg',
  kind: DocumentKinds.ownerPassport,
  sharedWithTenant: true,
);
const _legacyEid = AppDocument(
  name: 'Old EID',
  url: 'https://example.test/old.jpg',
  kind: DocumentKinds.emiratesId,
  sharedWithTenant: true,
);
const _other = AppDocument(
  name: 'Floor plan',
  url: 'https://example.test/plan.pdf',
  kind: DocumentKinds.other,
  sharedWithTenant: true,
);
const _ejari = AppDocument(
  name: 'Ejari',
  url: 'https://example.test/ejari.pdf',
  kind: DocumentKinds.ejari,
  sharedWithTenant: true,
);
const _contract = AppDocument(
  name: 'Contract',
  url: 'https://example.test/c.pdf',
  kind: DocumentKinds.tenancyContract,
  sharedWithTenant: true,
);
const _myEid = AppDocument(
  name: 'My EID',
  url: 'https://example.test/mine.jpg',
  kind: DocumentKinds.emiratesId,
  sharedWithTenant: true,
);

TenantViewData _view({required bool ended}) => buildTenantView(
  landlordUid: 'L',
  tenantUid: 'u1',
  profile: const Landlord(id: 'L', name: 'Mr XYZ', emiratesIdNo: '784-1970-1111111-1'),
  tenants: [
    Tenant(id: 't1', firstName: 'Sam', lastName: 'Renter', appUid: 'u1', documents: const [_myEid]),
  ],
  leases: [
    Lease(
      id: 'l1',
      propertyId: 'p1',
      tenantId: 't1',
      startDate: DateTime(2025, 1, 1),
      endDate: ended ? DateTime(2025, 12, 31) : DateTime(2027, 12, 31),
      annualRent: 120000,
      documents: const [_ejari, _contract],
    ),
  ],
  properties: const [
    Property(
      id: 'p1',
      landlordId: 'L',
      name: 'Tower A',
      documents: [_deed, _dewa, _ownerEid, _ownerPp, _legacyEid, _other],
    ),
  ],
  payments: const [],
  today: DateTime(2026, 11, 15),
);

void main() {
  setUp(() {
    InMemoryAccountRepository.reset();
    DemoTenantPortal.reset();
  });

  test('personal-ID classification lives in one place', () {
    expect(landlordPersonalIdKinds, {DocumentKinds.ownerEmiratesId, DocumentKinds.ownerPassport});
    expect(isLandlordPersonalId('property', DocumentKinds.ownerEmiratesId), isTrue);
    expect(isLandlordPersonalId('property', DocumentKinds.ownerPassport), isTrue);
    expect(isLandlordPersonalId('property', DocumentKinds.emiratesId), isTrue); // legacy owner ID
    expect(isLandlordPersonalId('tenant', DocumentKinds.emiratesId), isFalse); // the tenant's own
    for (final k in [
      DocumentKinds.titleDeed,
      DocumentKinds.dewaBill,
      DocumentKinds.ejari,
      DocumentKinds.tenancyContract,
      DocumentKinds.other,
    ]) {
      expect(isLandlordPersonalId('property', k), isFalse, reason: k);
    }
    expect(RequestableDoc.values.where((d) => d.isPersonalId), [
      RequestableDoc.landlordEmiratesId,
      RequestableDoc.landlordPassport,
    ]);
  });

  test('during a tenancy every shared document and the landlord EID number are visible', () {
    final v = _view(ended: false);
    expect(v.status, LinkStatus.active);
    expect(v.landlord.emiratesIdNo, '784-1970-1111111-1');
    expect(v.documents.map((d) => d.name).toSet(), {
      'Deed',
      'DEWA',
      'EID',
      'PP',
      'Old EID',
      'Floor plan',
      'Ejari',
      'Contract',
      'My EID',
    });
  });

  test('after the tenancy the landlord\'s personal ID is hidden; everything else stays', () {
    final v = _view(ended: true);
    expect(v.status, LinkStatus.former);
    expect(v.landlord.emiratesIdNo, isEmpty);
    expect(v.documents.map((d) => d.name).toSet(), {'Deed', 'DEWA', 'Floor plan', 'Ejari', 'Contract', 'My EID'});
  });

  group('checkDocumentRequest', () {
    DocumentRequestError? check(
      RequestableDoc d, {
      bool active = true,
      String note = '',
      List<DocumentRequest> existing = const [],
    }) => checkDocumentRequest(
      doc: d,
      linkActive: active,
      propertyId: 'p1',
      note: note,
      existing: existing,
      tenantIds: const ['t1'],
    );

    test('former tenants can still ask for property documents, not personal ID', () {
      expect(check(RequestableDoc.landlordEmiratesId), isNull);
      expect(check(RequestableDoc.landlordEmiratesId, active: false), DocumentRequestError.notAllowed);
      expect(check(RequestableDoc.landlordPassport, active: false), DocumentRequestError.notAllowed);
      expect(check(RequestableDoc.titleDeed, active: false), isNull);
      expect(check(RequestableDoc.ejari, active: false), isNull);
    });

    test('one open request per document; "other" needs a description', () {
      final open = DocumentRequest(id: 'r1', doc: RequestableDoc.dewaBill, propertyId: 'p1', tenantId: 't1');
      expect(check(RequestableDoc.dewaBill, existing: [open]), DocumentRequestError.alreadyOpen);
      expect(check(RequestableDoc.dewaBill, existing: [open.copyWith(status: DocumentRequestStatus.declined)]), isNull);
      expect(check(RequestableDoc.other), DocumentRequestError.noteRequired);
      expect(check(RequestableDoc.other, note: 'Floor plan'), isNull);
    });

    test('availability states', () {
      final pending = DocumentRequest(id: 'r', doc: RequestableDoc.titleDeed);
      expect(
        docAvailability(doc: RequestableDoc.titleDeed, available: true, linkActive: true),
        DocAvailability.available,
      );
      expect(
        docAvailability(doc: RequestableDoc.titleDeed, available: false, linkActive: true),
        DocAvailability.notAvailable,
      );
      expect(
        docAvailability(doc: RequestableDoc.titleDeed, available: false, linkActive: true, latest: pending),
        DocAvailability.requested,
      );
      expect(
        docAvailability(
          doc: RequestableDoc.titleDeed,
          available: false,
          linkActive: true,
          latest: pending.copyWith(status: DocumentRequestStatus.declined),
        ),
        DocAvailability.declined,
      );
      expect(
        docAvailability(doc: RequestableDoc.landlordEmiratesId, available: false, linkActive: false),
        DocAvailability.endedPersonalId,
      );
    });
  });

  test('demo portal: request, duplicate refused, landlord declines, tenant sees it', () async {
    const ll = 'llD';
    await demoRepo<Landlord>(ll, 'profile').save(const Landlord(id: ll, name: 'Mr XYZ'));
    await demoRepo<Property>(ll, 'properties').save(const Property(id: 'p1', landlordId: ll, name: 'Tower A'));
    await demoRepo<Tenant>(ll, 'tenants').save(Tenant(id: 't1', firstName: 'Sam', lastName: 'Renter', phone: '1'));
    await demoRepo<Lease>(ll, 'leases').save(
      Lease(id: 'l1', propertyId: 'p1', tenantId: 't1', startDate: _day(-30), endDate: _day(300), annualRent: 120000),
    );
    await DemoTenantPortal.demoLink(landlordUid: ll, tenantId: 't1', tenantUid: 'u1');
    final portal = DemoTenantPortal();

    await portal.requestDocument(
      tenantUid: 'u1',
      landlordUid: ll,
      doc: RequestableDoc.landlordEmiratesId,
      propertyId: 'p1',
    );
    final repo = demoRepo<DocumentRequest>(ll, 'documentRequests');
    expect(repo.items.single.tenantId, 't1');
    expect(repo.items.single.leaseId, 'l1');
    await expectLater(
      portal.requestDocument(
        tenantUid: 'u1',
        landlordUid: ll,
        doc: RequestableDoc.landlordEmiratesId,
        propertyId: 'p1',
      ),
      throwsA(isA<DocumentRequestException>().having((e) => e.reason, 'reason', DocumentRequestError.alreadyOpen)),
    );

    await repo.save(repo.items.single.copyWith(status: DocumentRequestStatus.declined, response: 'Not now'));
    final seen = await portal.watchView('u1', 'documentRequests').first;
    expect(seen.single['status'], 'declined');
    expect(seen.single['response'], 'Not now');
    expect(seen.single['landlordUid'], ll);
  });

  Future<void> desktop(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  for (final size in const [Size(1440, 900), Size(390, 844)]) {
    testWidgets('tenant (${size.width.toInt()}px): Landlords > Mr XYZ > Emirates ID not available > Request now', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ll = 'llT${size.width.toInt()}';
      final code = (await tester.runAsync(() async {
        await demoRepo<Landlord>(ll, 'profile').save(Landlord(id: ll, name: 'Mr XYZ', email: 'llT@example.test'));
        await demoRepo<Property>(
          ll,
          'properties',
        ).save(Property(id: 'p1', landlordId: ll, name: 'Tower A', documents: const [_deed]));
        await demoRepo<Tenant>(ll, 'tenants').save(Tenant(id: 't1', firstName: 'Sam', lastName: 'Renter', phone: '1'));
        await demoRepo<Lease>(ll, 'leases').save(
          Lease(
            id: 'l1',
            propertyId: 'p1',
            tenantId: 't1',
            startDate: _day(-30),
            endDate: _day(300),
            annualRent: 120000,
          ),
        );
        return (await DemoTenantPortal().createInvite(landlordUid: ll, tenantId: 't1', leaseId: 'l1')).code;
      }))!;
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const LedgixApp()));
      await tester.pumpAndSettle();
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

      c.read(routerProvider).go('/t/landlords/$ll');
      await tester.pumpAndSettle();
      // The shared deed opens; the landlord's ID isn't shared yet.
      final deed = find.byKey(const Key('doc-open-titleDeed-p1'));
      await tester.ensureVisible(deed);
    await tester.pumpAndSettle();
      expect(deed.hitTestable(), findsOneWidget);
      final request = find.byKey(const Key('doc-request-landlordEmiratesId-p1'));
      await tester.ensureVisible(request);
    await tester.pumpAndSettle();
      expect(request.hitTestable(), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('doc-row-landlordEmiratesId-p1')),
          matching: find.text('Not available'),
        ),
        findsOneWidget,
      );

      await tester.tap(request);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('doc-request-note')).hitTestable(), findsOneWidget);
      await tester.enterText(find.byKey(const Key('doc-request-note')), 'Needed for my DEWA move-in');
      await tester.tap(find.byKey(const Key('doc-request-send')));
      await tester.pumpAndSettle();
      final snack = find.descendant(of: find.byType(SnackBar), matching: find.byType(Text));
      expect(snack.evaluate().map((e) => (e.widget as Text).data).toList(), ['Request sent to your landlord.']);
      expect(
        find.descendant(of: find.byKey(const Key('doc-row-landlordEmiratesId-p1')), matching: find.text('Requested')),
        findsOneWidget,
      );
      expect(demoRepo<DocumentRequest>(ll, 'documentRequests').items.single.note, 'Needed for my DEWA move-in');
    });
  }

  testWidgets('landlord (desktop): dashboard card shares an attached ID or declines with a reason', (tester) async {
    await desktop(tester);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.listen(userIdProvider, (_, _) {});
    const ll = 'demo';
    const ownerEid = AppDocument(name: 'EID', url: 'https://example.test/eid.jpg', kind: DocumentKinds.ownerEmiratesId);
    await tester.runAsync(() async {
      await c.read(authRepositoryProvider).signInWithEmail('landlord@test.local', 'x');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await demoRepo<Landlord>(ll, 'profile').save(const Landlord(id: ll, name: 'Me Landlord'));
      await demoRepo<Property>(
        ll,
        'properties',
      ).save(const Property(id: 'p1', landlordId: ll, name: 'Tower A', documents: [ownerEid]));
      await demoRepo<Tenant>(ll, 'tenants').save(Tenant(id: 't1', firstName: 'Sam', lastName: 'Renter', phone: '1'));
      await demoRepo<Lease>(ll, 'leases').save(
        Lease(id: 'l1', propertyId: 'p1', tenantId: 't1', startDate: _day(-30), endDate: _day(300), annualRent: 120000),
      );
      final repo = demoRepo<DocumentRequest>(ll, 'documentRequests');
      await repo.save(
        DocumentRequest(
          id: 'r-eid',
          doc: RequestableDoc.landlordEmiratesId,
          propertyId: 'p1',
          tenantId: 't1',
          leaseId: 'l1',
          createdAt: _day(0),
        ),
      );
      await repo.save(
        DocumentRequest(
          id: 'r-dewa',
          doc: RequestableDoc.dewaBill,
          propertyId: 'p1',
          tenantId: 't1',
          leaseId: 'l1',
          createdAt: _day(0),
        ),
      );
    });
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const LedgixApp()));
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('document-requests-card'));
    await tester.ensureVisible(find.byKey(const Key('document-requests-card'), skipOffstage: false));
    await tester.pumpAndSettle();
    expect(card.hitTestable(), findsOneWidget);
    expect(find.byKey(const Key('docreq-share-r-eid')).hitTestable(), findsOneWidget);
    expect(find.byKey(const Key('docreq-decline-r-dewa')).hitTestable(), findsOneWidget);
    expect(find.descendant(of: card, matching: find.textContaining('Sam Renter')), findsNWidgets(2));

    // The ID is attached but private: share it.
    await tester.tap(find.byKey(const Key('docreq-share-r-eid')));
    await tester.pumpAndSettle();
    final p = demoRepo<Property>(ll, 'properties').items.single;
    expect(p.documents.single.sharedWithTenant, isTrue);
    final repo = demoRepo<DocumentRequest>(ll, 'documentRequests');
    expect(repo.items.firstWhere((r) => r.id == 'r-eid').status, DocumentRequestStatus.fulfilled);

    // No DEWA bill: decline with a reason.
    await tester.ensureVisible(find.byKey(const Key('docreq-decline-r-dewa'), skipOffstage: false));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('docreq-share-r-dewa')), findsNothing);
    await tester.tap(find.byKey(const Key('docreq-decline-r-dewa')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('docreq-decline-reason')), 'Tenant pays DEWA directly');
    await tester.tap(find.byKey(const Key('docreq-decline-confirm')));
    await tester.pumpAndSettle();
    final dewa = repo.items.firstWhere((r) => r.id == 'r-dewa');
    expect(dewa.status, DocumentRequestStatus.declined);
    expect(dewa.response, 'Tenant pays DEWA directly');
    expect(find.byKey(const Key('document-requests-card'), skipOffstage: false), findsNothing); // nothing open any more
    await tester.pumpWidget(const SizedBox());
  });
}
