import '../../../core/domain/entity.dart';

/// Move-in or move-out walkthrough of a rented unit.
///
/// Stored at `landlords/{uid}/inspections/{id}`. The tenant app reads a copy
/// at `tenantViews/{tenantUid}/inspections/{id}` (plus a `landlordUid` field)
/// and writes back only through Cloud Functions (functions/src/inspections.ts).
enum InspectionType { moveIn, moveOut }

enum InspectionStatus { draft, awaitingTenant, completed }

/// Ordered best to worst so comparisons can tell when an item got worse.
/// [na] (not applicable) never counts as worse or better.
enum Condition {
  excellent,
  good,
  fair,
  poor,
  damaged,
  missing,
  na;

  /// 0 = best. Null for [na] and for unrated items.
  int? get rank => this == na ? null : index;
}

enum MediaType { photo, video }

enum MediaBy { landlord, tenant }

Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? v) => [
      for (final e in (v is List ? v : const []))
        if (e is Map) Map<String, dynamic>.from(e),
    ];

String _s(Object? v) => v == null ? '' : '$v';

class InspectionMedia {
  const InspectionMedia({
    required this.url,
    this.storagePath = '',
    this.type = MediaType.photo,
    this.takenAt,
    this.by = MediaBy.landlord,
    this.thumbUrl,
    this.itemId,
  });

  final String url, storagePath;
  final MediaType type;
  final DateTime? takenAt;
  final MediaBy by;
  final String? thumbUrl;

  /// Set on tenant media that belongs to a specific item.
  final String? itemId;

  bool get isVideo => type == MediaType.video;

  Map<String, dynamic> toMap() => {
        'url': url,
        'storagePath': storagePath,
        'type': type.name,
        'takenAt': takenAt?.toIso8601String(),
        'by': by.name,
        if (thumbUrl != null) 'thumbUrl': thumbUrl,
        if (itemId != null) 'itemId': itemId,
      };

  factory InspectionMedia.fromMap(Map<String, dynamic> m) => InspectionMedia(
        url: _s(m['url']),
        storagePath: _s(m['storagePath']),
        type: enumByName(MediaType.values, m['type'], MediaType.photo),
        takenAt: parseDate(m['takenAt']),
        by: enumByName(MediaBy.values, m['by'], MediaBy.landlord),
        thumbUrl: m['thumbUrl'] == null ? null : _s(m['thumbUrl']),
        itemId: m['itemId'] == null ? null : _s(m['itemId']),
      );

  static List<InspectionMedia> listFrom(Object? v) => [for (final m in _maps(v)) InspectionMedia.fromMap(m)];
}

class InspectionItem {
  const InspectionItem({required this.id, required this.name, this.condition, this.notes = '', this.media = const []});

  final String id, name, notes;

  /// Null until rated.
  final Condition? condition;
  final List<InspectionMedia> media;

  bool get isRated => condition != null;

  InspectionItem copyWith({String? name, Condition? condition, bool clearCondition = false, String? notes, List<InspectionMedia>? media}) =>
      InspectionItem(
        id: id,
        name: name ?? this.name,
        condition: clearCondition ? null : (condition ?? this.condition),
        notes: notes ?? this.notes,
        media: media ?? this.media,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'condition': condition?.name,
        'notes': notes,
        'media': [for (final m in media) m.toMap()],
      };

  factory InspectionItem.fromMap(Map<String, dynamic> m) => InspectionItem(
        id: _s(m['id']),
        name: _s(m['name']),
        condition: m['condition'] == null ? null : enumByName(Condition.values, m['condition'], Condition.na),
        notes: _s(m['notes']),
        media: InspectionMedia.listFrom(m['media']),
      );
}

class InspectionRoom {
  const InspectionRoom({required this.id, required this.name, this.items = const [], this.media = const [], this.notes = ''});

  final String id, name, notes;
  final List<InspectionItem> items;
  final List<InspectionMedia> media;

  int get ratedCount => items.where((i) => i.isRated).length;
  bool get isDone => items.isNotEmpty && ratedCount == items.length;

  InspectionRoom copyWith({String? name, List<InspectionItem>? items, List<InspectionMedia>? media, String? notes}) =>
      InspectionRoom(
        id: id,
        name: name ?? this.name,
        items: items ?? this.items,
        media: media ?? this.media,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'items': [for (final i in items) i.toMap()],
        'media': [for (final m in media) m.toMap()],
        'notes': notes,
      };

  factory InspectionRoom.fromMap(Map<String, dynamic> m) => InspectionRoom(
        id: _s(m['id']),
        name: _s(m['name']),
        items: [for (final i in _maps(m['items'])) InspectionItem.fromMap(i)],
        media: InspectionMedia.listFrom(m['media']),
        notes: _s(m['notes']),
      );
}

class MeterReadings {
  const MeterReadings({this.electricity = '', this.water = '', this.gas = '', this.photos = const []});
  final String electricity, water, gas;
  final List<InspectionMedia> photos;

  bool get isEmpty => electricity.isEmpty && water.isEmpty && gas.isEmpty && photos.isEmpty;

  MeterReadings copyWith({String? electricity, String? water, String? gas, List<InspectionMedia>? photos}) => MeterReadings(
        electricity: electricity ?? this.electricity,
        water: water ?? this.water,
        gas: gas ?? this.gas,
        photos: photos ?? this.photos,
      );

  Map<String, dynamic> toMap() => {
        'electricityReading': electricity,
        'waterReading': water,
        'gasReading': gas,
        'photos': [for (final p in photos) p.toMap()],
      };

  factory MeterReadings.fromMap(Map<String, dynamic> m) => MeterReadings(
        electricity: _s(m['electricityReading']),
        water: _s(m['waterReading']),
        gas: _s(m['gasReading']),
        photos: InspectionMedia.listFrom(m['photos']),
      );
}

/// Keys and access devices handed over (counts as text so "2 + spare" works).
class KeyHandover {
  const KeyHandover({
    this.mainDoor = '',
    this.mailbox = '',
    this.parking = '',
    this.accessCards = '',
    this.remotes = '',
    this.other = '',
  });
  final String mainDoor, mailbox, parking, accessCards, remotes, other;

  bool get isEmpty => [mainDoor, mailbox, parking, accessCards, remotes, other].every((v) => v.isEmpty);

  KeyHandover copyWith({String? mainDoor, String? mailbox, String? parking, String? accessCards, String? remotes, String? other}) =>
      KeyHandover(
        mainDoor: mainDoor ?? this.mainDoor,
        mailbox: mailbox ?? this.mailbox,
        parking: parking ?? this.parking,
        accessCards: accessCards ?? this.accessCards,
        remotes: remotes ?? this.remotes,
        other: other ?? this.other,
      );

  Map<String, dynamic> toMap() => {
        'mainDoor': mainDoor,
        'mailbox': mailbox,
        'parking': parking,
        'accessCards': accessCards,
        'remotes': remotes,
        'other': other,
      };

  factory KeyHandover.fromMap(Map<String, dynamic> m) => KeyHandover(
        mainDoor: _s(m['mainDoor']),
        mailbox: _s(m['mailbox']),
        parking: _s(m['parking']),
        accessCards: _s(m['accessCards']),
        remotes: _s(m['remotes']),
        other: _s(m['other']),
      );
}

class TenantComment {
  const TenantComment({required this.text, required this.at, this.itemId});
  final String text;
  final DateTime at;
  final String? itemId;

  Map<String, dynamic> toMap() => {'text': text, 'at': at.toIso8601String(), if (itemId != null) 'itemId': itemId};

  factory TenantComment.fromMap(Map<String, dynamic> m) => TenantComment(
        text: _s(m['text']),
        at: parseDate(m['at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        itemId: m['itemId'] == null ? null : _s(m['itemId']),
      );
}

class Inspection implements Entity {
  const Inspection({
    required this.id,
    required this.leaseId,
    required this.propertyId,
    required this.tenantId,
    required this.type,
    required this.createdAt,
    this.status = InspectionStatus.draft,
    this.scheduledAt,
    this.completedAt,
    this.rooms = const [],
    this.meters = const MeterReadings(),
    this.keys = const KeyHandover(),
    this.generalNotes = '',
    this.landlordSignedAt,
    this.tenantConfirmedAt,
    this.tenantComments = const [],
    this.tenantMedia = const [],
    this.completionNote = '',
    this.moveInId,
  });

  @override
  final String id;
  final String leaseId, propertyId, tenantId;
  final InspectionType type;
  final InspectionStatus status;
  final DateTime createdAt;
  final DateTime? scheduledAt, completedAt, landlordSignedAt, tenantConfirmedAt;
  final List<InspectionRoom> rooms;
  final MeterReadings meters;
  final KeyHandover keys;
  final String generalNotes;
  final List<TenantComment> tenantComments;
  final List<InspectionMedia> tenantMedia;

  /// Why the landlord completed it without the tenant's confirmation.
  final String completionNote;

  /// For a move-out: the move-in inspection it is compared with.
  final String? moveInId;

  bool get isMoveOut => type == InspectionType.moveOut;
  bool get isEditable => status == InspectionStatus.draft;

  int get itemCount => rooms.fold(0, (n, r) => n + r.items.length);
  int get ratedCount => rooms.fold(0, (n, r) => n + r.ratedCount);
  double get progress => itemCount == 0 ? 0 : ratedCount / itemCount;

  Iterable<InspectionMedia> get allMedia sync* {
    for (final r in rooms) {
      yield* r.media;
      for (final i in r.items) {
        yield* i.media;
      }
    }
    yield* meters.photos;
    yield* tenantMedia;
  }

  Inspection copyWith({
    InspectionStatus? status,
    DateTime? scheduledAt,
    DateTime? completedAt,
    List<InspectionRoom>? rooms,
    MeterReadings? meters,
    KeyHandover? keys,
    String? generalNotes,
    DateTime? landlordSignedAt,
    DateTime? tenantConfirmedAt,
    List<TenantComment>? tenantComments,
    List<InspectionMedia>? tenantMedia,
    String? completionNote,
  }) =>
      Inspection(
        id: id,
        leaseId: leaseId,
        propertyId: propertyId,
        tenantId: tenantId,
        type: type,
        createdAt: createdAt,
        status: status ?? this.status,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        completedAt: completedAt ?? this.completedAt,
        rooms: rooms ?? this.rooms,
        meters: meters ?? this.meters,
        keys: keys ?? this.keys,
        generalNotes: generalNotes ?? this.generalNotes,
        landlordSignedAt: landlordSignedAt ?? this.landlordSignedAt,
        tenantConfirmedAt: tenantConfirmedAt ?? this.tenantConfirmedAt,
        tenantComments: tenantComments ?? this.tenantComments,
        tenantMedia: tenantMedia ?? this.tenantMedia,
        completionNote: completionNote ?? this.completionNote,
        moveInId: moveInId,
      );

  /// Replaces one room (matched by id).
  Inspection withRoom(InspectionRoom room) =>
      copyWith(rooms: [for (final r in rooms) r.id == room.id ? room : r]);

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'leaseId': leaseId,
        'propertyId': propertyId,
        'tenantId': tenantId,
        'type': type.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'scheduledAt': scheduledAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'rooms': [for (final r in rooms) r.toMap()],
        'meters': meters.toMap(),
        'keys': keys.toMap(),
        'generalNotes': generalNotes,
        'landlordSignedAt': landlordSignedAt?.toIso8601String(),
        'tenantConfirmedAt': tenantConfirmedAt?.toIso8601String(),
        'tenantComments': [for (final c in tenantComments) c.toMap()],
        'tenantMedia': [for (final m in tenantMedia) m.toMap()],
        'completionNote': completionNote,
        'moveInId': moveInId,
      };

  /// Tolerates missing fields, Firestore Timestamps rendered as strings and
  /// older documents.
  factory Inspection.fromMap(Map<String, dynamic> m) => Inspection(
        id: _s(m['id']),
        leaseId: _s(m['leaseId']),
        propertyId: _s(m['propertyId']),
        tenantId: _s(m['tenantId']),
        type: enumByName(InspectionType.values, m['type'], InspectionType.moveIn),
        status: enumByName(InspectionStatus.values, m['status'], InspectionStatus.draft),
        createdAt: _date(m['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        scheduledAt: _date(m['scheduledAt']),
        completedAt: _date(m['completedAt']),
        rooms: [for (final r in _maps(m['rooms'])) InspectionRoom.fromMap(r)],
        meters: MeterReadings.fromMap(_map(m['meters'])),
        keys: KeyHandover.fromMap(_map(m['keys'])),
        generalNotes: _s(m['generalNotes']),
        landlordSignedAt: _date(m['landlordSignedAt']),
        tenantConfirmedAt: _date(m['tenantConfirmedAt']),
        tenantComments: [for (final c in _maps(m['tenantComments'])) TenantComment.fromMap(c)],
        tenantMedia: InspectionMedia.listFrom(m['tenantMedia']),
        completionNote: _s(m['completionNote']),
        moveInId: m['moveInId'] == null ? null : _s(m['moveInId']),
      );
}

/// Cloud Functions write server timestamps; the Firestore SDK hands those
/// over as Timestamp objects, which expose toDate().
DateTime? _date(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  try {
    // ignore: avoid_dynamic_calls
    final d = (v as dynamic).toDate();
    if (d is DateTime) return d;
  } catch (_) {}
  return null;
}
