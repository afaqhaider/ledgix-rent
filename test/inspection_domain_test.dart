import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/features/inspections/data/inspection_pdf.dart';
import 'package:ledgix_rent/features/inspections/domain/comparison.dart';
import 'package:ledgix_rent/features/inspections/domain/inspection.dart';
import 'package:ledgix_rent/features/inspections/domain/templates.dart';
import 'package:ledgix_rent/features/inspections/presentation/inspection_editor.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';

// All data here is made up.

String Function() _ids() {
  var n = 0;
  return () => 'id${n++}';
}

Inspection _inspection({InspectionType type = InspectionType.moveIn, List<InspectionRoom>? rooms}) => Inspection(
      id: 'i1',
      leaseId: 'l1',
      propertyId: 'p1',
      tenantId: 't1',
      type: type,
      createdAt: DateTime(2026, 11, 1, 10),
      rooms: rooms ??
          const [
            InspectionRoom(id: 'r1', name: 'Kitchen', items: [
              InspectionItem(id: 'a', name: 'Floor', condition: Condition.good),
              InspectionItem(id: 'b', name: 'Sink & taps', condition: Condition.excellent),
              InspectionItem(id: 'c', name: 'Cabinets', condition: Condition.na),
            ]),
          ],
    );

/// Text drawn in an uncompressed PDF, word by word, joined with spaces.
String _pdfText(List<int> bytes) {
  final raw = latin1.decode(bytes);
  return RegExp(r'\(((?:\\.|[^\\)])*)\)').allMatches(raw).map((m) => m.group(1)!.replaceAll(r'\(', '(').replaceAll(r'\)', ')')).join(' ');
}

void main() {
  group('Inspection model', () {
    test('toMap/fromMap round-trips every field', () {
      final full = _inspection().copyWith(
        status: InspectionStatus.awaitingTenant,
        scheduledAt: DateTime(2026, 11, 2),
        completedAt: DateTime(2026, 11, 3),
        meters: const MeterReadings(
          electricity: '12345',
          water: '678',
          gas: '9',
          photos: [InspectionMedia(url: 'https://x/m.jpg', storagePath: 's/m.jpg')],
        ),
        keys: const KeyHandover(mainDoor: '2', mailbox: '1', parking: '1 card', accessCards: '2', remotes: '1', other: 'gym fob'),
        generalNotes: 'Freshly painted',
        landlordSignedAt: DateTime(2026, 11, 2, 9),
        tenantConfirmedAt: DateTime(2026, 11, 3, 9),
        tenantComments: [TenantComment(text: 'Scratch on door', at: DateTime(2026, 11, 2, 12), itemId: 'a')],
        tenantMedia: [
          InspectionMedia(url: 'https://x/v.mp4', type: MediaType.video, by: MediaBy.tenant, takenAt: DateTime(2026, 11, 2), itemId: 'a'),
        ],
        completionNote: 'Signed on paper',
      );
      final back = Inspection.fromMap(jsonDecode(jsonEncode(full.toMap())) as Map<String, dynamic>);
      expect(back.toMap(), full.toMap());
      expect(back.tenantMedia.single.isVideo, isTrue);
      expect(back.keys.other, 'gym fob');
    });

    test('fromMap tolerates missing and odd fields', () {
      final i = Inspection.fromMap({'id': 'x', 'rooms': [{'name': 'Hall', 'items': [{'name': 'Floor', 'condition': 'weird'}]}], 'meters': null});
      expect(i.type, InspectionType.moveIn);
      expect(i.status, InspectionStatus.draft);
      expect(i.rooms.single.items.single.condition, Condition.na);
      expect(i.meters.isEmpty, isTrue);
      expect(i.keys.isEmpty, isTrue);
      expect(Inspection.fromMap(const {}).rooms, isEmpty);
    });

    test('progress counts rated items', () {
      final i = _inspection(rooms: const [
        InspectionRoom(id: 'r', name: 'R', items: [
          InspectionItem(id: 'a', name: 'A', condition: Condition.good),
          InspectionItem(id: 'b', name: 'B'),
        ]),
      ]);
      expect(i.ratedCount, 1);
      expect(i.itemCount, 2);
      expect(i.progress, 0.5);
      expect(i.rooms.single.isDone, isFalse);
    });
  });

  group('templates', () {
    test('studio has no bedroom, a living room, kitchen, bathroom and balcony', () {
      final rooms = buildRooms(PropertyType.studio, newId: _ids());
      final names = rooms.map((r) => r.name).toList();
      expect(names, containsAll(['Living room', 'Kitchen', 'Bathroom', 'Balcony', 'Entrance & corridor']));
      expect(names.where((n) => n.startsWith('Bedroom')), isEmpty);
    });

    test('numbers bedrooms and bathrooms when there are several', () {
      final names = buildRooms(PropertyType.apartment, bedrooms: 3, bathrooms: 2, newId: _ids()).map((r) => r.name).toList();
      expect(names, containsAll(['Bedroom 1', 'Bedroom 2', 'Bedroom 3', 'Bathroom 1', 'Bathroom 2']));
    });

    test('villa adds laundry, parking and exterior; every id is unique', () {
      final rooms = buildRooms(PropertyType.villa, newId: _ids());
      expect(rooms.map((r) => r.name), containsAll(['Laundry', 'Parking', 'Exterior & garden']));
      final ids = [for (final r in rooms) ...[r.id, for (final i in r.items) i.id]];
      expect(ids.toSet().length, ids.length);
      expect(rooms.every((r) => r.items.isNotEmpty), isTrue);
    });

    test('Arabic names', () {
      final rooms = buildRooms(PropertyType.studio, lang: 'ar', newId: _ids());
      expect(rooms.map((r) => r.name), contains('المطبخ'));
    });
  });

  group('move-out comparison', () {
    test('move-out rooms keep ids and names but start unrated', () {
      final out = moveOutRoomsFrom(_inspection());
      expect(out.single.id, 'r1');
      expect(out.single.items.map((i) => i.id), ['a', 'b', 'c']);
      expect(out.single.items.every((i) => i.condition == null && i.media.isEmpty), isTrue);
    });

    test('flags only items that got worse, most severe first', () {
      final moveIn = _inspection();
      final moveOut = _inspection(type: InspectionType.moveOut, rooms: const [
        InspectionRoom(id: 'r1', name: 'Kitchen', items: [
          InspectionItem(id: 'a', name: 'Floor', condition: Condition.fair), // good -> fair: 1 step
          InspectionItem(id: 'b', name: 'Sink & taps', condition: Condition.damaged), // excellent -> damaged: 4 steps
          InspectionItem(id: 'c', name: 'Cabinets', condition: Condition.damaged), // n/a at move-in: ignored
        ]),
      ]);
      final w = worsenedItems(moveIn, moveOut);
      expect(w.map((c) => c.itemName), ['Sink & taps', 'Floor']);
      expect(w.first.severity, 4);
    });

    test('better, equal or unrated items are not flagged', () {
      final moveOut = _inspection(type: InspectionType.moveOut, rooms: const [
        InspectionRoom(id: 'r1', name: 'Kitchen', items: [
          InspectionItem(id: 'a', name: 'Floor', condition: Condition.excellent),
          InspectionItem(id: 'b', name: 'Sink & taps', condition: Condition.excellent),
          InspectionItem(id: 'c', name: 'Cabinets'),
        ]),
      ]);
      expect(worsenedItems(_inspection(), moveOut), isEmpty);
    });

    test('matches by room and item name when ids differ', () {
      final moveOut = _inspection(type: InspectionType.moveOut, rooms: const [
        InspectionRoom(id: 'other', name: 'kitchen ', items: [InspectionItem(id: 'z', name: 'FLOOR', condition: Condition.poor)]),
      ]);
      final cmp = compareInspections(_inspection(), moveOut);
      final floor = cmp.firstWhere((c) => c.moveOut?.id == 'z');
      expect(floor.moveIn?.id, 'a');
      expect(floor.worsened, isTrue);
      // Move-in items not inspected at move-out are still listed, unflagged.
      expect(cmp.where((c) => c.missingAtMoveOut).length, 2);
      expect(worsenedItems(_inspection(), moveOut).length, 1);
    });
  });

  group('media targets', () {
    test('adds and removes media on rooms, items and meters', () {
      const m = InspectionMedia(url: 'u1');
      var i = _inspection();
      i = addMediaTo(i, const ItemMedia('r1', 'b'), m);
      i = addMediaTo(i, const RoomMedia('r1'), m);
      i = addMediaTo(i, const MeterMedia(), m);
      expect(i.rooms.single.items[1].media.single.url, 'u1');
      expect(i.rooms.single.media, hasLength(1));
      expect(i.meters.photos, hasLength(1));
      i = removeMediaFrom(i, const ItemMedia('r1', 'b'), m);
      expect(i.rooms.single.items[1].media, isEmpty);
      expect(i.rooms.single.media, hasLength(1));
    });
  });

  group('PDF report', () {
    test('builds a move-in report with the cover, rooms and confirmations', () async {
      final insp = _inspection().copyWith(
        meters: const MeterReadings(electricity: '4321'),
        keys: const KeyHandover(mainDoor: '2'),
        landlordSignedAt: DateTime(2026, 11, 2, 9),
      );
      final bytes = await buildInspectionPdf(
        insp,
        info: const InspectionReportInfo(propertyName: 'Marina Studio', tenantName: 'Test Tenant'),
        googleFonts: false,
        compress: false,
        loadImage: (_) async => null,
      );
      expect(bytes.length, greaterThan(1000));
      expect(latin1.decode(bytes), startsWith('%PDF'));
      final text = _pdfText(bytes);
      for (final s in ['Move-in inspection', 'Marina Studio', 'Test Tenant', 'Kitchen', 'Sink & taps', '4321', 'Landlord signed']) {
        expect(text, contains(s), reason: s);
      }
    });

    test('move-out report includes the comparison and worsened items', () async {
      final moveOut = _inspection(type: InspectionType.moveOut, rooms: const [
        InspectionRoom(id: 'r1', name: 'Kitchen', items: [InspectionItem(id: 'a', name: 'Floor', condition: Condition.damaged, notes: 'Cracked tile')]),
      ]);
      final bytes = await buildInspectionPdf(moveOut,
          moveIn: _inspection(), googleFonts: false, compress: false, loadImage: (_) async => null);
      final text = _pdfText(bytes);
      expect(text, contains('Move-out inspection'));
      expect(text, contains('Move-in vs move-out'));
      expect(text, contains('Items in worse condition'));
      expect(text, contains('Cracked tile'));
    });
  });
}
