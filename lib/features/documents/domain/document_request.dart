import '../../../core/domain/entity.dart';
import 'app_document.dart';

/// Documents a tenant can ask their landlord for. Each maps to the document
/// kinds that satisfy it (see [DocumentKinds]).
enum RequestableDoc {
  landlordEmiratesId,
  landlordPassport,
  titleDeed,
  tenancyContract,
  ejari,
  dewaBill,
  other;

  /// Kinds that count as "this document is available".
  Set<String> get kinds => switch (this) {
        landlordEmiratesId => {DocumentKinds.ownerEmiratesId},
        landlordPassport => {DocumentKinds.ownerPassport},
        titleDeed => {DocumentKinds.titleDeed},
        tenancyContract => {DocumentKinds.tenancyContract, DocumentKinds.lease},
        ejari => {DocumentKinds.ejari},
        dewaBill => {DocumentKinds.dewaBill},
        other => const <String>{},
      };

  /// The kind a newly uploaded file gets when the landlord answers a request.
  String get uploadKind => switch (this) {
        landlordEmiratesId => DocumentKinds.ownerEmiratesId,
        landlordPassport => DocumentKinds.ownerPassport,
        titleDeed => DocumentKinds.titleDeed,
        tenancyContract => DocumentKinds.tenancyContract,
        ejari => DocumentKinds.ejari,
        dewaBill => DocumentKinds.dewaBill,
        other => DocumentKinds.other,
      };

  /// Stored on the rent agreement rather than the property.
  bool get belongsToLease => this == tenancyContract || this == ejari;

  /// The landlord's personal identification: only shown while a tenancy is
  /// current, and only requestable then.
  bool get isPersonalId => this == landlordEmiratesId || this == landlordPassport;

  static RequestableDoc byName(Object? name) =>
      RequestableDoc.values.where((x) => x.name == '$name').firstOrNull ?? RequestableDoc.other;
}

/// The landlord's personal identification document kinds. Shared ones are
/// visible to tenants only while they have a current tenancy; once every
/// lease with that landlord has ended they disappear from the tenant's view.
/// Mirrored in functions/src/tenants.ts (LANDLORD_PERSONAL_ID_KINDS).
const landlordPersonalIdKinds = {DocumentKinds.ownerEmiratesId, DocumentKinds.ownerPassport};

/// True when a document attached to a property (or lease) is the landlord's
/// personal ID. Older property records stored the owner's ID as the generic
/// `emiratesId` / `passport` kinds; on a tenant record those kinds are the
/// tenant's own ID and are never hidden from them.
bool isLandlordPersonalId(String ownerType, String kind) =>
    landlordPersonalIdKinds.contains(kind) ||
    (ownerType != 'tenant' && (kind == DocumentKinds.emiratesId || kind == DocumentKinds.passport));

enum DocumentRequestStatus { pending, fulfilled, declined }

/// A tenant asking their landlord for a document. Stored at
/// `landlords/{uid}/documentRequests/{id}`; created by the requestDocument
/// Cloud Function, answered by the landlord.
class DocumentRequest implements Entity {
  const DocumentRequest({
    required this.id,
    required this.doc,
    this.propertyId = '',
    this.tenantId = '',
    this.tenantUid = '',
    this.leaseId = '',
    this.note = '',
    this.status = DocumentRequestStatus.pending,
    this.response = '',
    this.createdAt,
    this.respondedAt,
    this.landlordUid = '',
  });

  @override
  final String id;
  final RequestableDoc doc;
  final String propertyId, tenantId, tenantUid, leaseId, note, response;
  final DocumentRequestStatus status;
  final DateTime? createdAt, respondedAt;

  /// Set on the tenant's copy (tenantViews); empty on the landlord's.
  final String landlordUid;

  bool get isOpen => status == DocumentRequestStatus.pending;

  DocumentRequest copyWith({DocumentRequestStatus? status, String? response, DateTime? respondedAt}) => DocumentRequest(
        id: id,
        doc: doc,
        propertyId: propertyId,
        tenantId: tenantId,
        tenantUid: tenantUid,
        leaseId: leaseId,
        note: note,
        status: status ?? this.status,
        response: response ?? this.response,
        createdAt: createdAt,
        respondedAt: respondedAt ?? this.respondedAt,
        landlordUid: landlordUid,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': doc.name,
        'propertyId': propertyId,
        'tenantId': tenantId,
        'tenantUid': tenantUid,
        'leaseId': leaseId,
        'note': note,
        'status': status.name,
        'response': response,
        'createdAt': createdAt?.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
        if (landlordUid.isNotEmpty) 'landlordUid': landlordUid,
      };

  factory DocumentRequest.fromMap(Map<String, dynamic> m) => DocumentRequest(
        id: '${m['id']}',
        doc: RequestableDoc.byName(m['kind']),
        propertyId: '${m['propertyId'] ?? ''}',
        tenantId: '${m['tenantId'] ?? ''}',
        tenantUid: '${m['tenantUid'] ?? ''}',
        leaseId: '${m['leaseId'] ?? ''}',
        note: '${m['note'] ?? ''}',
        status: DocumentRequestStatus.values.where((x) => x.name == m['status']).firstOrNull ?? DocumentRequestStatus.pending,
        response: '${m['response'] ?? ''}',
        createdAt: _date(m['createdAt']),
        respondedAt: _date(m['respondedAt']),
        landlordUid: '${m['landlordUid'] ?? ''}',
      );
}

DateTime? _date(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  try {
    return (v as dynamic).toDate() as DateTime; // Firestore Timestamp
  } catch (_) {
    return null;
  }
}

/// Why a document request was refused (shown to the tenant).
enum DocumentRequestError { alreadyOpen, notAllowed, noteRequired }

/// Rules shared by the app and (mirrored) the requestDocument Cloud Function.
/// [linkActive] is false once every lease with that landlord has ended.
DocumentRequestError? checkDocumentRequest({
  required RequestableDoc doc,
  required bool linkActive,
  required String propertyId,
  required String note,
  required Iterable<DocumentRequest> existing,
  required List<String> tenantIds,
}) {
  if (doc.isPersonalId && !linkActive) return DocumentRequestError.notAllowed;
  if (doc == RequestableDoc.other && note.trim().isEmpty) return DocumentRequestError.noteRequired;
  final open = existing.any((r) =>
      r.isOpen && r.doc == doc && r.propertyId == propertyId && tenantIds.contains(r.tenantId) &&
      (doc != RequestableDoc.other || r.note.trim().toLowerCase() == note.trim().toLowerCase()));
  if (open) return DocumentRequestError.alreadyOpen;
  return null;
}

/// What the tenant sees on one checklist row.
enum DocAvailability { available, requested, declined, notAvailable, endedPersonalId }

DocAvailability docAvailability({
  required RequestableDoc doc,
  required bool available,
  required bool linkActive,
  DocumentRequest? latest,
}) {
  if (available) return DocAvailability.available;
  if (doc.isPersonalId && !linkActive) return DocAvailability.endedPersonalId;
  if (latest == null) return DocAvailability.notAvailable;
  return switch (latest.status) {
    DocumentRequestStatus.pending => DocAvailability.requested,
    DocumentRequestStatus.declined => DocAvailability.declined,
    DocumentRequestStatus.fulfilled => DocAvailability.notAvailable, // fulfilled but since unshared
  };
}
