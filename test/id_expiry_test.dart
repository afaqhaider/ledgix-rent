import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/core/routing/app_router.dart';
import 'package:ledgix_rent/core/utils/dates.dart';
import 'package:ledgix_rent/features/documents/data/document_scanner.dart';
import 'package:ledgix_rent/features/documents/domain/document_reader.dart';
import 'package:ledgix_rent/features/documents/domain/expiry.dart';
import 'package:ledgix_rent/features/documents/domain/form_fill.dart';
import 'package:ledgix_rent/features/documents/domain/scanned_document.dart';
import 'package:ledgix_rent/features/documents/presentation/documents_editor.dart';
import 'package:ledgix_rent/features/documents/presentation/scan_to_fill.dart';
import 'package:ledgix_rent/features/landlord/domain/landlord.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';
import 'package:ledgix_rent/features/tenants/domain/tenant.dart';
import 'package:ledgix_rent/main.dart';
import 'package:material_ui/material_ui.dart';

// All data here is made up.

class _FakeScanner implements DocumentScanner {
  _FakeScanner(this.result);
  final ScannedDocument result;
  @override
  bool get isSupported => true;
  @override
  Future<ScannedDocument> scan(XFile file) async => result;
}

XFile _file(String name) => XFile.fromData(Uint8List.fromList(List.filled(2048, 1)), name: name);

Future<ProviderContainer> _app(WidgetTester tester, {Size size = const Size(390, 844), ScannedDocument? scan}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [
    documentScannerProvider.overrideWithValue(_FakeScanner(scan ?? const ScannedDocument(ScannedKind.unknown, {}))),
    documentPickerProvider.overrideWithValue((_) async => _file('scan.png')),
  ]);
  addTearDown(container.dispose);
  container.listen(userIdProvider, (_, _) {});
  await tester.runAsync(() async {
    await container.read(authRepositoryProvider).signInWithEmail('expiry@test.local', 'x');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await container.read(landlordRepositoryProvider).save(const Landlord(id: 'demo', name: 'Me Landlord'));
  });
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const LedgixApp()));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _go(WidgetTester tester, ProviderContainer c, String path) async {
  c.read(routerProvider).push(path);
  await tester.pumpAndSettle();
}

DateTime _in(int days) => todayGst().add(Duration(days: days));

void main() {
  group('models', () {
    test('old records without expiry dates still load', () {
      final t = Tenant.fromMap({'id': 't1', 'name': 'Sam Test', 'emiratesIdNo': '784-1990-2222222-2'});
      expect(t.emiratesIdExpiry, isNull);
      expect(t.passportExpiry, isNull);
      expect(Property.fromMap({'id': 'p1', 'name': 'Unit 1'}).ownerEmiratesIdExpiry, isNull);
      expect(Landlord.fromMap({'id': 'l1', 'name': 'Me'}).passportExpiry, isNull);
    });

    test('expiry dates round-trip as yyyy-MM-dd', () {
      final t = Tenant(id: 't1', firstName: 'Sam', lastName: 'Test', emiratesIdExpiry: DateTime(2028, 3, 12), passportExpiry: DateTime(2030, 1, 1));
      final m = t.toMap();
      expect(m['emiratesIdExpiry'], '2028-03-12');
      expect(m['passportExpiry'], '2030-01-01');
      final back = Tenant.fromMap(m);
      expect(back.emiratesIdExpiry, DateTime(2028, 3, 12));
      expect(back.passportExpiry, DateTime(2030, 1, 1));
      // Copies keep them.
      expect(back.withInvite('ABCDEFGH', DateTime(2027)).emiratesIdExpiry, DateTime(2028, 3, 12));
      expect(back.joined('uid').passportExpiry, DateTime(2030, 1, 1));

      final p = Property.fromMap(Property(id: 'p1', landlordId: 'l', name: 'U', ownerEmiratesIdExpiry: DateTime(2027, 5, 6)).toMap());
      expect(p.ownerEmiratesIdExpiry, DateTime(2027, 5, 6));
      expect(p.copyWith(defaultVendorId: 'v').ownerEmiratesIdExpiry, DateTime(2027, 5, 6));

      final me = Landlord.fromMap(const Landlord(id: 'l', name: 'Me').withIdentity(
        emiratesIdNo: '784-1985-3333333-3',
        passportNo: '',
        emiratesIdExpiry: DateTime(2029, 9, 9),
        passportExpiry: null,
      ).toMap());
      expect(me.emiratesIdExpiry, DateTime(2029, 9, 9));
      expect(me.copyWith(name: 'New').emiratesIdExpiry, DateTime(2029, 9, 9));
      expect(me.withIdentity(emiratesIdNo: '', passportNo: '', emiratesIdExpiry: null, passportExpiry: null).emiratesIdExpiry, isNull);
    });
  });

  group('document slots', () {
    test('older documents map into slots; extras and unknown kinds go to Other', () {
      final c = DocumentsController(
        kinds: DocumentKinds.property,
        required: DocumentKinds.propertyRequired,
        slots: DocumentKinds.propertySlots,
        existing: const [
          AppDocument(name: 'Deed', url: 'https://x/d1.pdf', kind: DocumentKinds.titleDeed),
          AppDocument(name: 'Deed (old)', url: 'https://x/d0.pdf', kind: DocumentKinds.titleDeed),
          AppDocument(name: 'ID', url: 'https://x/id.jpg', kind: DocumentKinds.emiratesId), // legacy on a property
          AppDocument(name: 'Mystery', url: 'https://x/m.pdf', kind: 'somethingNew'),
          AppDocument(name: 'Mollak', url: 'https://x/mo.pdf', kind: DocumentKinds.mollak),
        ],
      );
      expect(c.slot(DocumentKinds.titleDeed)!.saved!.name, 'Deed');
      expect(c.slot(DocumentKinds.ownerEmiratesId)!.saved!.name, 'ID');
      expect(c.slot(DocumentKinds.dewaBill), isNull);
      expect(c.others.map((d) => d.saved!.name), ['Deed (old)', 'Mystery', 'Mollak']);
      expect(c.others[1].kind, DocumentKinds.other);
      expect(c.missing, isEmpty);
      expect(c.otherKinds, isNot(contains(DocumentKinds.titleDeed)));
    });

    test('a scanned file replaces the slot and keeps its share setting', () async {
      final c = DocumentsController(
        kinds: DocumentKinds.tenant,
        required: DocumentKinds.tenantRequired,
        slots: DocumentKinds.tenantSlots,
        existing: const [AppDocument(name: 'EID', url: 'https://x/e.jpg', kind: DocumentKinds.emiratesId, sharedWithTenant: true)],
      );
      await c.add(_file('new-eid.png'), kind: DocumentKinds.emiratesId);
      expect(c.drafts, hasLength(1));
      expect(c.slot(DocumentKinds.emiratesId)!.file, isNotNull);
      expect(c.slot(DocumentKinds.emiratesId)!.saved, isNull);
      expect(c.slot(DocumentKinds.emiratesId)!.shared, isTrue);
    });
  });

  group('expiry status', () {
    final today = DateTime(2026, 11, 14);
    test('boundaries', () {
      expect(expiryStatus(DateTime(2026, 11, 13), today), ExpiryStatus.expired);
      expect(expiryStatus(DateTime(2026, 11, 14), today), ExpiryStatus.within30);
      expect(expiryStatus(today.add(const Duration(days: 30)), today), ExpiryStatus.within30);
      expect(expiryStatus(today.add(const Duration(days: 31)), today), ExpiryStatus.within60);
      expect(expiryStatus(today.add(const Duration(days: 60)), today), ExpiryStatus.within60);
      expect(expiryStatus(today.add(const Duration(days: 61)), today), ExpiryStatus.ok);
    });

    test('tracked expiries cover tenants, owners and me, soonest first; alerts skip ok ones', () {
      final all = trackedExpiries(
        tenants: [Tenant(id: 't1', firstName: 'Sam', lastName: 'Test', emiratesIdExpiry: today.add(const Duration(days: 20)), passportExpiry: DateTime(2035))],
        properties: [Property(id: 'p1', landlordId: 'l', name: 'Unit 1', ownerPassportExpiry: today.subtract(const Duration(days: 3)))],
        me: Landlord(id: 'me', name: 'Me', emiratesIdExpiry: today.add(const Duration(days: 45))),
      );
      expect(all.map((e) => (e.holder, e.doc)), [
        (ExpiryHolder.propertyOwner, IdDocType.passport),
        (ExpiryHolder.tenant, IdDocType.emiratesId),
        (ExpiryHolder.me, IdDocType.emiratesId),
        (ExpiryHolder.tenant, IdDocType.passport),
      ]);
      final alerts = expiryAlerts(all, today);
      expect(alerts, hasLength(3));
      expect(alerts.first.route, '/property/p1/edit');
      expect(alerts[1].route, '/tenants/t1/edit');
      expect(alerts[2].route, '/profile');
    });

    test('tenant badge status is the worst of EID and passport', () {
      expect(tenantIdStatus(Tenant(id: 't', firstName: 'A', lastName: 'B'), today), isNull);
      expect(tenantIdStatus(Tenant(id: 't', firstName: 'A', lastName: 'B', passportExpiry: DateTime(2035)), today), isNull);
      expect(
        tenantIdStatus(Tenant(id: 't', firstName: 'A', lastName: 'B', emiratesIdExpiry: today.add(const Duration(days: 10)), passportExpiry: DateTime(2020)), today),
        ExpiryStatus.expired,
      );
    });
  });

  group('scanning reads expiry dates', () {
    const reader = DocumentReader();
    test('Emirates ID front: Expiry Date', () {
      final d = reader.read(['UNITED ARAB EMIRATES', 'Resident Identity Card', 'ID Number 784-1990-2222222-2', 'Name: Alex Tenant Example',
          'Issuing Date 12/03/2023', 'Expiry Date 11/03/2028']);
      expect(d.kind, ScannedKind.emiratesId);
      expect(d[ScanField.personEmiratesIdExpiry], '2028-03-11');
      expect(tenantValues(d)[FormKeys.eidExpiry], '2028-03-11');
      expect(propertyValues(d)[FormKeys.ownerEidExpiry], '2028-03-11');
    });

    test('Emirates ID back: MRZ', () {
      final d = reader.read(['ILARE7841990222222227841990222222<<<<<<<', '9001011M2803114ARE<<<<<<<<<<<6', 'EXAMPLE<<ALEX<TENANT<<<<<<<<<<', 'Resident Identity Card', 'ID Number 784-1990-2222222-2']);
      expect(d[ScanField.personEmiratesIdExpiry], '2028-03-11');
    });

    test('passport MRZ', () {
      final d = reader.read(['PASSPORT', 'P<TSTEXAMPLE<<ALEX<TENANT<<<<<<<<<<<<<<<<<<<<<', 'X1234567<3TST9001011M3001014<<<<<<<<<<<<<<02']);
      expect(d[ScanField.personPassportExpiry], '2030-01-01');
      expect(tenantValues(d)[FormKeys.passportExpiry], '2030-01-01');
    });

    test('scanned dates only fill empty date fields', () {
      final v = {FormKeys.eidExpiry: '2028-03-11', FormKeys.passportExpiry: '2030-01-01'};
      final got = newScannedDates(v, {FormKeys.eidExpiry: null, FormKeys.passportExpiry: DateTime(2031)});
      expect(got, {FormKeys.eidExpiry: DateTime(2028, 3, 11)});
    });
  });

  group('screens', () {
    testWidgets('tenant form: ID slots with expiry, scan fills the expiry, saved with the tenant', (tester) async {
      final c = await _app(
        tester,
        scan: const ScannedDocument(ScannedKind.emiratesId, {
          ScanField.personEmiratesId: '784-1990-2222222-2',
          ScanField.personName: 'ALEX TENANT EXAMPLE',
          ScanField.personEmiratesIdExpiry: '2028-03-11',
        }),
      );
      await _go(tester, c, '/tenants/new');
      expect(find.byKey(const Key('slot-row-emiratesId')), findsOneWidget);
      expect(find.byKey(const Key('slot-row-passport')), findsOneWidget);
      expect(find.text('Emirates ID *'), findsWidgets);
      await tester.ensureVisible(find.byKey(const Key('scan-to-fill')));
      await tester.tap(find.byKey(const Key('scan-to-fill')));
      await tester.pumpAndSettle();
      expect(find.text('11/03/2028'), findsOneWidget); // the expiry field
      expect(find.textContaining('Expires 11/03/2028'), findsOneWidget); // the note under the ID slot
      await tester.enterText(find.byKey(const ValueKey('field-phone')), '0501234567');
      await tester.tap(find.byKey(const Key('form-save')));
      await tester.pumpAndSettle();
      if (find.text('Later').evaluate().isNotEmpty) {
        await tester.tap(find.text('Later'));
        await tester.pumpAndSettle();
      }
      final t = (await tester.runAsync(() => c.read(tenantRepositoryProvider).watchAll().first))!.single;
      expect(t.emiratesIdExpiry, DateTime(2028, 3, 11));
      expect(t.documents.single.kind, DocumentKinds.emiratesId);
    });

    testWidgets('property form: title deed slot still mandatory; other documents get a name', (tester) async {
      final c = await _app(tester);
      await _go(tester, c, '/property/new');
      for (final k in DocumentKinds.propertySlots) {
        expect(find.byKey(Key('slot-row-$k')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('form-save')));
      await tester.pumpAndSettle();
      expect(find.text('Attach: Title deed'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('field-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apartment').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('field-name')), 'Test Tower 101');
      await tester.enterText(find.byKey(const ValueKey('field-address')), 'Unit 101, Test Tower');
      for (final k in ['slot-titleDeed', 'slot-dewaBill', 'add-other-document']) {
        await tester.ensureVisible(find.byKey(Key(k)));
        await tester.tap(find.byKey(Key(k)));
        await tester.pumpAndSettle();
      }
      await tester.enterText(find.widgetWithText(TextFormField, 'Document name'), 'Floor plan');
      await tester.tap(find.byKey(const Key('form-save')));
      await tester.pumpAndSettle();
      final p = (await tester.runAsync(() => c.read(propertyRepositoryProvider).watchAll().first))!.single;
      expect(p.documents.map((d) => d.kind), [DocumentKinds.titleDeed, DocumentKinds.dewaBill, DocumentKinds.other]);
      expect(p.documents.last.name, 'Floor plan');
    });

    testWidgets('dashboard ID expiries card and tenant badge', (tester) async {
      final c = await _app(tester);
      await tester.runAsync(() async {
        await c.read(tenantRepositoryProvider).save(Tenant(id: 't1', firstName: 'Sam', lastName: 'Test', emiratesIdExpiry: _in(20)));
        await c.read(propertyRepositoryProvider).save(Property(id: 'p1', landlordId: 'demo', name: 'Unit 9', ownerPassportExpiry: _in(-2)));
      });
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(const Key('id-expiries-card')), 200, scrollable: find.byType(Scrollable).first);
      expect(find.byKey(const Key('id-expiries-card')), findsOneWidget);
      expect(find.text('Sam Test · Emirates ID'), findsOneWidget);
      expect(find.text('Owner · Unit 9 · Passport'), findsOneWidget);
      expect(find.textContaining('Expired'), findsWidgets);

      await _go(tester, c, '/tenants');
      expect(find.byKey(const Key('id-expiry-badge')), findsOneWidget);
      expect(find.text('ID expiring'), findsOneWidget);
    });

    // Wide screens once hid form bodies entirely; check the new fields are
    // really on screen and tappable at desktop size.
    for (final (path, keys) in [
      ('/tenants/new', ['field-eidExpiry', 'field-passportExpiry', 'slot-emiratesId', 'slot-passport']),
      ('/property/new', ['field-ownerEidExpiry', 'slot-titleDeed', 'slot-dewaBill', 'add-other-document']),
      ('/profile', ['profile-eidExpiry', 'profile-passportExpiry']),
    ]) {
      testWidgets('desktop: new fields visible on $path', (tester) async {
        final c = await _app(tester, size: const Size(1440, 900));
        await _go(tester, c, path);
        for (final k in keys) {
          final f = find.byKey(k.startsWith('field-') || k.startsWith('profile-') ? ValueKey(k) : Key(k));
          await tester.ensureVisible(f);
          await tester.pumpAndSettle();
          expect(f.hitTestable(), findsOneWidget, reason: k);
        }
      });
    }

    testWidgets('desktop: dashboard expiry card visible', (tester) async {
      final c = await _app(tester, size: const Size(1440, 900));
      await tester.runAsync(() => c.read(tenantRepositoryProvider).save(Tenant(id: 't1', firstName: 'Sam', lastName: 'Test', passportExpiry: _in(5))));
      await tester.pumpAndSettle();
      final card = find.byKey(const Key('id-expiries-card'));
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('id-expiry-tenant-t1-passport')).hitTestable(), findsOneWidget);
    });
  });
}
