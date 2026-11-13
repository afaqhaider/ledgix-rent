import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/core/routing/app_router.dart';
import 'package:ledgix_rent/features/documents/data/document_scanner.dart';
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
  ScannedDocument result;
  @override
  bool get isSupported => true;
  @override
  Future<ScannedDocument> scan(XFile file) async => result;
}

XFile _file(String name) => XFile.fromData(Uint8List.fromList(List.filled(2048, 1)), name: name);

/// Signed-in demo app with a landlord profile, on a phone-sized screen.
Future<ProviderContainer> _app(WidgetTester tester, {ScannedDocument? scan, String own = '784-1985-3333333-3'}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final scanner = _FakeScanner(scan ?? const ScannedDocument(ScannedKind.unknown, {}));
  final container = ProviderContainer(overrides: [
    documentScannerProvider.overrideWithValue(scanner),
    documentPickerProvider.overrideWithValue((_) async => _file('scan.png')),
  ]);
  addTearDown(container.dispose);
  container.listen(userIdProvider, (_, _) {});
  await tester.runAsync(() async {
    await container.read(authRepositoryProvider).signInWithEmail('forms@test.local', 'x');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await container.read(landlordRepositoryProvider).save(Landlord(id: 'demo', name: 'Me Landlord', emiratesIdNo: own));
  });
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const LedgixApp()));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _go(WidgetTester tester, ProviderContainer c, String path) async {
  c.read(routerProvider).push(path);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('form-save')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Add property: basic info and title deed are mandatory; the rest is optional', (tester) async {
    final c = await _app(tester);
    await _go(tester, c, '/property/new');
    expect(find.text('Property name *'), findsOneWidget);
    expect(find.text('DEWA premise no.'), findsOneWidget); // optional: no star

    await _save(tester);
    expect(find.text('Required'), findsWidgets);
    expect(find.text('Attach: Title deed'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('field-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apartment').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('field-name')), 'Test Tower 101');
    await tester.enterText(find.byKey(const ValueKey('field-address')), 'Unit 101, Test Tower, Test Gardens');
    await tester.ensureVisible(find.byKey(const Key('add-document')));
    await tester.tap(find.byKey(const Key('add-document')));
    await tester.pumpAndSettle();
    await _save(tester);

    final saved = await tester.runAsync(() => c.read(propertyRepositoryProvider).watchAll().first);
    final p = saved!.single;
    expect(p.name, 'Test Tower 101');
    expect(p.documents.single.kind, DocumentKinds.titleDeed);
  });

  testWidgets('Scan to fill: fills empty fields and keeps typed ones unless asked', (tester) async {
    final c = await _app(
      tester,
      scan: const ScannedDocument(ScannedKind.dewaBill, {
        ScanField.dewaPremiseNo: '600000001',
        ScanField.dewaAccountNo: '2099999999',
        ScanField.propertyType: 'RESIDENTIAL - FLAT',
      }),
    );
    await _go(tester, c, '/property/new');
    await tester.enterText(find.byKey(const ValueKey('field-dewaAccount')), '2011111111');
    await tester.ensureVisible(find.byKey(const Key('scan-to-fill')));
    await tester.tap(find.byKey(const Key('scan-to-fill')));
    await tester.pumpAndSettle();
    // Typed value differs: asked first, kept by default.
    expect(find.text('Replace what you typed?'), findsOneWidget);
    await tester.tap(find.text('Keep mine'));
    await tester.pumpAndSettle();
    expect(find.text('2 fields filled from DEWA bill, please review'), findsOneWidget);
    expect(find.text('600000001'), findsOneWidget);
    expect(find.text('2011111111'), findsOneWidget);
    expect(find.text('Filled from scan, please check'), findsWidgets);
  });

  testWidgets("Tenant: own Emirates ID is never filled in or saved as a tenant", (tester) async {
    final c = await _app(
      tester,
      scan: const ScannedDocument(ScannedKind.emiratesId, {
        ScanField.personEmiratesId: '784-1985-3333333-3',
        ScanField.personName: 'Me Landlord',
      }),
    );
    await _go(tester, c, '/tenants/new');
    await tester.ensureVisible(find.byKey(const Key('scan-to-fill')));
    await tester.tap(find.byKey(const Key('scan-to-fill')));
    await tester.pumpAndSettle();
    expect(find.text('This looks like your own Emirates ID'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Me'), findsNothing); // first name not filled

    // Typing it by hand is refused too.
    await tester.enterText(find.byKey(const ValueKey('field-firstName')), 'Me');
    await tester.enterText(find.byKey(const ValueKey('field-lastName')), 'Landlord');
    await tester.enterText(find.byKey(const ValueKey('field-phone')), '0500000000');
    await tester.enterText(find.byKey(const ValueKey('field-emiratesId')), '784198533333333');
    await _save(tester);
    expect(find.text("This is your own ID. A tenant can't use it."), findsOneWidget);
    final tenants = await tester.runAsync(() => c.read(tenantRepositoryProvider).watchAll().first);
    expect(tenants, isEmpty);
  });

  testWidgets('Tenant: mandatory fields and scan splits the name', (tester) async {
    final c = await _app(
      tester,
      scan: const ScannedDocument(ScannedKind.emiratesId, {
        ScanField.personEmiratesId: '784-1990-2222222-2',
        ScanField.personName: 'ALEX TENANT EXAMPLE',
      }),
    );
    await _go(tester, c, '/tenants/new');
    await _save(tester);
    expect(find.text('Required'), findsWidgets);
    expect(find.text('Attach: Emirates ID'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('scan-to-fill')));
    await tester.tap(find.byKey(const Key('scan-to-fill')));
    await tester.pumpAndSettle();
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Tenant'), findsWidgets);
    expect(find.text('Example'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('field-phone')), '0501234567');
    await _save(tester);
    final t = (await tester.runAsync(() => c.read(tenantRepositoryProvider).watchAll().first))!.single;
    expect(t.name, 'Alex Tenant Example');
    expect(t.emiratesIdNo, '784-1990-2222222-2');
    expect(t.documents.single.kind, DocumentKinds.emiratesId); // the scanned card was attached
  });

  testWidgets('Rent agreement: Add tenant opens the tenant form and selects the new tenant', (tester) async {
    final c = await _app(tester);
    await tester.runAsync(() => c.read(propertyRepositoryProvider).save(const Property(id: 'p1', landlordId: 'demo', name: 'Test Tower 101')));
    await _go(tester, c, '/leases/new');
    expect(find.text('Add rent agreement'), findsWidgets);
    await tester.tap(find.byKey(const Key('agreement-add-tenant')));
    await tester.pumpAndSettle();
    expect(find.text('Add tenant'), findsWidgets);
    await tester.enterText(find.byKey(const ValueKey('field-firstName')), 'Sam');
    await tester.enterText(find.byKey(const ValueKey('field-lastName')), 'Renter');
    await tester.enterText(find.byKey(const ValueKey('field-phone')), '0509999999');
    await tester.enterText(find.byKey(const ValueKey('field-emiratesId')), '784-1991-4444444-4');
    await tester.ensureVisible(find.byKey(const Key('add-document')));
    await tester.tap(find.byKey(const Key('add-document')));
    await tester.pumpAndSettle();
    await _save(tester);
    // Back on the agreement with the new tenant selected.
    expect(find.text('Add rent agreement'), findsWidgets);
    expect(find.text('Sam Renter'), findsOneWidget);
  });

  test('old tenant records with a single name still load', () {
    final t = Tenant.fromMap({'id': 't1', 'name': 'Sara Ali Khan', 'phone': '050', 'passportCopyUrl': 'https://x/p.jpg'});
    expect(t.firstName, 'Sara');
    expect(t.middleName, 'Ali');
    expect(t.lastName, 'Khan');
    expect(t.name, 'Sara Ali Khan');
    expect(t.documents.single.kind, DocumentKinds.passport);
    expect(Tenant.fromMap(t.toMap()).name, 'Sara Ali Khan');
  });
}
