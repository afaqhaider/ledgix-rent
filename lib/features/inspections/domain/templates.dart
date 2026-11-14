import '../../properties/domain/property.dart';
import 'inspection.dart';

/// Default rooms and items for a new walkthrough. Names are stored as text
/// in the landlord's language at creation time, so they print as typed.
enum RoomKind { living, bedroom, kitchen, bathroom, balcony, entrance, laundry, parking, exterior, office, storage }

enum ItemKind {
  walls,
  ceiling,
  floor,
  doors,
  windows,
  lights,
  ac,
  curtains,
  cabinets,
  appliances,
  plumbing,
  smokeDetector,
  wardrobe,
  sockets,
  mirror,
  shower,
  toilet,
  sink,
  railing,
  gate,
  garden,
  pool,
}

const _roomNames = {
  'en': {
    RoomKind.living: 'Living room',
    RoomKind.bedroom: 'Bedroom',
    RoomKind.kitchen: 'Kitchen',
    RoomKind.bathroom: 'Bathroom',
    RoomKind.balcony: 'Balcony',
    RoomKind.entrance: 'Entrance & corridor',
    RoomKind.laundry: 'Laundry',
    RoomKind.parking: 'Parking',
    RoomKind.exterior: 'Exterior & garden',
    RoomKind.office: 'Office area',
    RoomKind.storage: 'Storage',
  },
  'ar': {
    RoomKind.living: 'غرفة المعيشة',
    RoomKind.bedroom: 'غرفة النوم',
    RoomKind.kitchen: 'المطبخ',
    RoomKind.bathroom: 'الحمام',
    RoomKind.balcony: 'الشرفة',
    RoomKind.entrance: 'المدخل والممر',
    RoomKind.laundry: 'غرفة الغسيل',
    RoomKind.parking: 'موقف السيارات',
    RoomKind.exterior: 'الواجهة والحديقة',
    RoomKind.office: 'منطقة المكتب',
    RoomKind.storage: 'المخزن',
  },
};

const _itemNames = {
  'en': {
    ItemKind.walls: 'Walls & paint',
    ItemKind.ceiling: 'Ceiling',
    ItemKind.floor: 'Floor',
    ItemKind.doors: 'Doors & locks',
    ItemKind.windows: 'Windows',
    ItemKind.lights: 'Lights & switches',
    ItemKind.ac: 'AC & vents',
    ItemKind.curtains: 'Curtains & blinds',
    ItemKind.cabinets: 'Cabinets & counters',
    ItemKind.appliances: 'Appliances',
    ItemKind.plumbing: 'Plumbing & fixtures',
    ItemKind.smokeDetector: 'Smoke detector',
    ItemKind.wardrobe: 'Wardrobe',
    ItemKind.sockets: 'Sockets',
    ItemKind.mirror: 'Mirror',
    ItemKind.shower: 'Shower / bathtub',
    ItemKind.toilet: 'Toilet',
    ItemKind.sink: 'Sink & taps',
    ItemKind.railing: 'Railing',
    ItemKind.gate: 'Gate',
    ItemKind.garden: 'Garden & irrigation',
    ItemKind.pool: 'Pool',
  },
  'ar': {
    ItemKind.walls: 'الجدران والدهان',
    ItemKind.ceiling: 'السقف',
    ItemKind.floor: 'الأرضية',
    ItemKind.doors: 'الأبواب والأقفال',
    ItemKind.windows: 'النوافذ',
    ItemKind.lights: 'الإنارة والمفاتيح',
    ItemKind.ac: 'التكييف والفتحات',
    ItemKind.curtains: 'الستائر',
    ItemKind.cabinets: 'الخزائن والأسطح',
    ItemKind.appliances: 'الأجهزة',
    ItemKind.plumbing: 'السباكة والتجهيزات',
    ItemKind.smokeDetector: 'كاشف الدخان',
    ItemKind.wardrobe: 'خزانة الملابس',
    ItemKind.sockets: 'المقابس',
    ItemKind.mirror: 'المرآة',
    ItemKind.shower: 'الدش / حوض الاستحمام',
    ItemKind.toilet: 'المرحاض',
    ItemKind.sink: 'المغسلة والحنفيات',
    ItemKind.railing: 'الدرابزين',
    ItemKind.gate: 'البوابة',
    ItemKind.garden: 'الحديقة والري',
    ItemKind.pool: 'المسبح',
  },
};

const _baseItems = [ItemKind.walls, ItemKind.ceiling, ItemKind.floor, ItemKind.doors, ItemKind.lights];

const roomItems = <RoomKind, List<ItemKind>>{
  RoomKind.living: [..._baseItems, ItemKind.windows, ItemKind.ac, ItemKind.curtains, ItemKind.sockets, ItemKind.smokeDetector],
  RoomKind.bedroom: [..._baseItems, ItemKind.windows, ItemKind.ac, ItemKind.curtains, ItemKind.wardrobe, ItemKind.sockets],
  RoomKind.kitchen: [..._baseItems, ItemKind.cabinets, ItemKind.appliances, ItemKind.sink, ItemKind.plumbing, ItemKind.ac, ItemKind.smokeDetector],
  RoomKind.bathroom: [..._baseItems, ItemKind.mirror, ItemKind.shower, ItemKind.toilet, ItemKind.sink, ItemKind.plumbing],
  RoomKind.balcony: [ItemKind.floor, ItemKind.doors, ItemKind.railing, ItemKind.lights],
  RoomKind.entrance: [..._baseItems, ItemKind.smokeDetector],
  RoomKind.laundry: [..._baseItems, ItemKind.appliances, ItemKind.plumbing],
  RoomKind.parking: [ItemKind.floor, ItemKind.lights, ItemKind.gate],
  RoomKind.exterior: [ItemKind.walls, ItemKind.gate, ItemKind.garden, ItemKind.pool, ItemKind.lights],
  RoomKind.office: [..._baseItems, ItemKind.windows, ItemKind.ac, ItemKind.sockets],
  RoomKind.storage: [ItemKind.walls, ItemKind.floor, ItemKind.doors, ItemKind.lights],
};

String roomName(RoomKind k, String lang, {int? number}) {
  final n = (_roomNames[lang] ?? _roomNames['en']!)[k]!;
  return number == null ? n : '$n $number';
}

String itemName(ItemKind k, String lang) => (_itemNames[lang] ?? _itemNames['en']!)[k]!;

/// Suggested bedroom/bathroom counts when the landlord hasn't said.
({int bedrooms, int bathrooms}) defaultLayout(PropertyType t) => switch (t) {
      PropertyType.studio => (bedrooms: 0, bathrooms: 1),
      PropertyType.apartment => (bedrooms: 2, bathrooms: 2),
      PropertyType.villa => (bedrooms: 4, bathrooms: 4),
      PropertyType.other => (bedrooms: 0, bathrooms: 1),
    };

/// Room list for a property. A studio's living room doubles as the bedroom;
/// villas get a laundry, parking and exterior; "other" (offices, shops) gets
/// an office area and storage.
List<RoomKind> roomPlan(PropertyType t, {required int bedrooms, required int bathrooms}) => [
      RoomKind.entrance,
      if (t == PropertyType.other) RoomKind.office else RoomKind.living,
      for (var i = 0; i < bedrooms; i++) RoomKind.bedroom,
      if (t != PropertyType.other) RoomKind.kitchen,
      for (var i = 0; i < bathrooms; i++) RoomKind.bathroom,
      if (t == PropertyType.apartment || t == PropertyType.studio) RoomKind.balcony,
      if (t == PropertyType.villa) ...[RoomKind.laundry, RoomKind.parking, RoomKind.exterior],
      if (t == PropertyType.other) RoomKind.storage,
    ];

/// Builds the default rooms with unique ids from [newId].
List<InspectionRoom> buildRooms(
  PropertyType type, {
  int? bedrooms,
  int? bathrooms,
  String lang = 'en',
  required String Function() newId,
}) {
  final d = defaultLayout(type);
  final beds = bedrooms ?? d.bedrooms;
  final baths = bathrooms ?? d.bathrooms;
  final plan = roomPlan(type, bedrooms: beds, bathrooms: baths);
  var bed = 0, bath = 0;
  return [
    for (final k in plan)
      InspectionRoom(
        id: newId(),
        name: switch (k) {
          RoomKind.bedroom => roomName(k, lang, number: beds > 1 ? ++bed : null),
          RoomKind.bathroom => roomName(k, lang, number: baths > 1 ? ++bath : null),
          _ => roomName(k, lang),
        },
        items: [for (final i in roomItems[k]!) InspectionItem(id: newId(), name: itemName(i, lang))],
      ),
  ];
}

/// Default items for a room the landlord adds by hand.
List<InspectionItem> defaultItemsFor(RoomKind k, {String lang = 'en', required String Function() newId}) =>
    [for (final i in roomItems[k]!) InspectionItem(id: newId(), name: itemName(i, lang))];
