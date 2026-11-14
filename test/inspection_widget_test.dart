import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/core/l10n/gen/app_localizations.dart';
import 'package:ledgix_rent/core/routing/app_router.dart';
import 'package:ledgix_rent/features/inspections/data/inspection_providers.dart';
import 'package:ledgix_rent/features/inspections/data/tenant_inspection_actions.dart';
import 'package:ledgix_rent/features/inspections/domain/inspection.dart';
import 'package:ledgix_rent/features/inspections/presentation/inspection_actions.dart';
import 'package:ledgix_rent/features/inspections/presentation/inspection_view.dart';
import 'package:ledgix_rent/features/landlord/domain/landlord.dart';
import 'package:ledgix_rent/features/leases/domain/lease.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';
import 'package:ledgix_rent/features/tenants/domain/tenant.dart';
import 'package:ledgix_rent/main.dart';
import 'package:material_ui/material_ui.dart';

// All data here is made up.

XFile _photo(String name) => XFile.fromData(Uint8List.fromList(List.filled(512, 7)), name: name, path: '/tmp/$name');

/// Signed-in demo app with one studio, tenant and rent agreement, on a phone.
Future<ProviderContainer> _app(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [
    inspectionMediaPickerProvider.overrideWithValue((_) async => [(_photo('crack.jpg'), MediaType.photo)]),
  ]);
  addTearDown(container.dispose);
  container.listen(userIdProvider, (_, _) {});
  container.listen(inspectionsProvider, (_, _) {});
  await tester.runAsync(() async {
    await container.read(authRepositoryProvider).signInWithEmail('insp@test.local', 'x');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await container.read(landlordRepositoryProvider).save(Landlord(id: 'demo', name: 'Test Landlord'));
    await container.read(propertyRepositoryProvider).save(Property(id: 'pS', landlordId: 'demo', name: 'Test Studio', type: PropertyType.studio));
    await container.read(tenantRepositoryProvider).save(Tenant(id: 'tS', firstName: 'Test', lastName: 'Tenant'));
    await container.read(leaseRepositoryProvider).save(Lease(
          id: 'lS',
          propertyId: 'pS',
          tenantId: 'tS',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
          annualRent: 60000,
        ));
  });
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const LedgixApp()));
  await tester.pumpAndSettle();
  return container;
}

Future<Inspection> _saved(ProviderContainer c) async =>
    (await c.read(inspectionRepositoryProvider).watchAll().first).firstWhere((i) => i.leaseId == 'lS');

/// Lets the editor's half-second save run.
Future<void> _settleSave(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('move-in walkthrough: rate, notes, photo, rooms, items, meters, keys, send', (tester) async {
    final c = await _app(tester);
    c.read(routerProvider).push('/leases/lS/edit');
    await tester.pumpAndSettle();

    // Start from the rent agreement; a studio defaults to 0 bedrooms, 1 bathroom.
    await tester.scrollUntilVisible(find.byKey(const Key('lease-move-in')), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('lease-move-in')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-inspection')));
    await tester.pumpAndSettle();

    var insp = await tester.runAsync(() => _saved(c));
    final total = insp!.itemCount;
    expect(find.text('0 of $total rated'), findsOneWidget);

    // Open the kitchen and rate its first item; tapping again clears it.
    final kitchen = insp.rooms.firstWhere((r) => r.name == 'Kitchen');
    final first = kitchen.items.first;
    await tester.tap(find.byKey(Key('room-${kitchen.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('cond-${first.id}-good')));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.byKey(Key('cond-${first.id}-good'))).selected, isTrue);
    await tester.tap(find.byKey(Key('cond-${first.id}-excellent')));
    await tester.enterText(find.byKey(Key('notes-${first.id}')), 'Small scratch near the door');

    // Photo from the (fake) picker uploads in the background and shows up.
    await tester.tap(find.byKey(Key('add-media-${first.id}')));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    // Add an item to the room.
    await tester.tap(find.byKey(const Key('add-item')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ask-text')), 'Extractor hood');
    await tester.tap(find.byKey(const Key('ask-text-ok')));
    await tester.pumpAndSettle();
    expect(find.text('Extractor hood'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('1 of ${total + 1} rated'), findsOneWidget);

    // Add a room (picks the first kind in the sheet, keeps its suggested name).
    await tester.tap(find.byKey(const Key('add-room')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Living room').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ask-text')), 'Maid room');
    await tester.tap(find.byKey(const Key('ask-text-ok')));
    await tester.pumpAndSettle();
    expect(find.text('Maid room'), findsOneWidget);

    // Meters and keys.
    await tester.scrollUntilVisible(find.byKey(const Key('meters-keys')), 300, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300)); // clear the bottom bar
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('meters-keys')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('meter-electricity')), '45678');
    await tester.scrollUntilVisible(find.byKey(const Key('keys-main')), 300, scrollable: find.byType(Scrollable).last);
    await tester.enterText(find.byKey(const Key('keys-main')), '2');
    await tester.pageBack();
    await _settleSave(tester);

    insp = await tester.runAsync(() => _saved(c));
    final item = insp!.rooms.firstWhere((r) => r.name == 'Kitchen').items.first;
    expect(item.condition, Condition.excellent);
    expect(item.notes, 'Small scratch near the door');
    expect(item.media.single.url, '/tmp/crack.jpg');
    expect(insp.rooms.map((r) => r.name), contains('Maid room'));
    expect(insp.meters.electricity, '45678');
    expect(insp.keys.mainDoor, '2');

    // Review & send: most items are unrated, so it asks first.
    await tester.tap(find.byKey(const Key('review-and-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send-to-tenant')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send-anyway')));
    await tester.pumpAndSettle();

    insp = await tester.runAsync(() => _saved(c));
    expect(insp!.status, InspectionStatus.awaitingTenant);
    expect(insp.landlordSignedAt, isNotNull);
    // The draft walkthrough becomes the read-only report with "Mark as completed".
    expect(find.byKey(const Key('review-and-send')), findsNothing);
    await tester.scrollUntilVisible(find.byKey(const Key('mark-completed')), 300, scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('mark-completed')), findsOneWidget);
  });

  testWidgets('move-out copies the move-in rooms and flags worse items', (tester) async {
    final c = await _app(tester);
    final repo = c.read(inspectionRepositoryProvider);
    await tester.runAsync(() => repo.save(Inspection(
          id: 'in1',
          leaseId: 'lS',
          propertyId: 'pS',
          tenantId: 'tS',
          type: InspectionType.moveIn,
          status: InspectionStatus.completed,
          createdAt: DateTime(2026, 1, 1),
          rooms: const [
            InspectionRoom(id: 'r1', name: 'Kitchen', items: [InspectionItem(id: 'a', name: 'Floor', condition: Condition.good)]),
          ],
        )));
    await tester.pumpAndSettle();
    c.read(routerProvider).push('/leases/lS/edit');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('lease-move-out')), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('lease-move-out')));
    await tester.pumpAndSettle();

    // No layout question: rooms come from the move-in.
    expect(find.text('Rooms copied from the move-in inspection. The move-in condition shows on each item.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('room-r1')));
    await tester.pumpAndSettle();
    expect(find.text('Move-in: '), findsOneWidget);
    await tester.tap(find.byKey(const Key('cond-a-damaged')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('review-and-send')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('worsened-item')), findsOneWidget);
    expect(find.text('Kitchen · Floor'), findsOneWidget);
  });

  testWidgets('tenant mode: comment, photo and confirm go through the tenant actions', (tester) async {
    final c = await _app(tester);
    final repo = c.read(inspectionRepositoryProvider);
    final actions = DemoTenantInspectionActions(repo);
    final insp = Inspection(
      id: 'aw1',
      leaseId: 'lS',
      propertyId: 'pS',
      tenantId: 'tS',
      type: InspectionType.moveIn,
      status: InspectionStatus.awaitingTenant,
      createdAt: DateTime(2026, 1, 1),
      rooms: const [
        InspectionRoom(id: 'r1', name: 'Kitchen', items: [InspectionItem(id: 'a', name: 'Floor', condition: Condition.good)]),
      ],
    );
    await tester.runAsync(() => repo.save(insp));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: ProviderScope(
        overrides: [tenantInspectionActionsProvider.overrideWithValue(actions)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: InspectionView(data: {...insp.toMap(), 'landlordUid': 'll1'}, tenantMode: true)),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    Future<void> tapKey(String k) async {
      await tester.scrollUntilVisible(find.byKey(Key(k)), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.byKey(Key(k)));
      await tester.pumpAndSettle();
    }

    await tapKey('tenant-add-comment');
    await tester.enterText(find.byKey(const Key('ask-text')), 'Tap in kitchen drips');
    await tester.tap(find.byKey(const Key('ask-text-ok')));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));

    await tapKey('tenant-add-media');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();

    await tapKey('tenant-confirm');
    await tester.tap(find.byKey(const Key('confirm-inspection-ok')));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));

    expect(actions.calls, ['comment:aw1', 'media:aw1', 'confirm:aw1']);
    final saved = await tester.runAsync(() => repo.get('aw1'));
    expect(saved!.tenantComments.single.text, 'Tap in kitchen drips');
    expect(saved.tenantMedia.single.by, MediaBy.tenant);
    expect(saved.status, InspectionStatus.completed);
    expect(saved.tenantConfirmedAt, isNotNull);
  });

  testWidgets('landlord view hides tenant actions', (tester) async {
    final insp = Inspection(
      id: 'v1',
      leaseId: 'l',
      propertyId: 'p',
      tenantId: 't',
      type: InspectionType.moveOut,
      status: InspectionStatus.awaitingTenant,
      createdAt: DateTime(2026, 1, 1),
    );
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: InspectionView(data: insp.toMap(), tenantMode: false)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Move-out inspection'), findsOneWidget);
    expect(find.byKey(const Key('tenant-confirm')), findsNothing);
    expect(find.byKey(const Key('inspection-pdf')), findsOneWidget);
  });
}
