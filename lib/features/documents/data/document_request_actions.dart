import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../leases/domain/lease.dart';
import '../../properties/domain/property.dart';
import '../domain/document_request.dart';

/// Where the landlord's answer to [r] is stored: the tenant's rent agreement
/// for a tenancy contract / Ejari, otherwise the property.
class RequestTarget {
  const RequestTarget({this.property, this.lease});
  final Property? property;
  final Lease? lease;

  List<AppDocument> get documents => lease?.documents ?? property?.documents ?? const [];
  bool get isEmpty => property == null && lease == null;
}

RequestTarget requestTarget(DocumentRequest r, List<Property> properties, List<Lease> leases) {
  final mine = leases.where((x) => x.tenantId == r.tenantId).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
  final propertyId = r.propertyId.isNotEmpty ? r.propertyId : (mine.lastOrNull?.propertyId ?? '');
  final property = properties.where((p) => p.id == propertyId).firstOrNull;
  if (r.doc.belongsToLease) {
    final lease = leases.where((x) => x.id == r.leaseId).firstOrNull ??
        mine.where((x) => x.propertyId == propertyId).lastOrNull;
    if (lease != null) return RequestTarget(lease: lease);
  }
  return RequestTarget(property: property);
}

/// An already-attached but unshared document that would answer [r].
AppDocument? unsharedMatch(DocumentRequest r, RequestTarget t) {
  if (r.doc == RequestableDoc.other) return null;
  return t.documents.where((d) => !d.sharedWithTenant && d.url.isNotEmpty && r.doc.kinds.contains(d.kind)).firstOrNull;
}

/// Landlord actions on a tenant's document request.
class DocumentRequestActions {
  DocumentRequestActions(this.ref);
  final WidgetRef ref;

  Future<void> _save(RequestTarget t, List<AppDocument> docs) async {
    if (t.lease case final lease?) {
      await ref.read(leaseRepositoryProvider).save(Lease.fromMap({
        ...lease.toMap(),
        'documents': [for (final d in docs) d.toMap()],
      }));
    } else if (t.property case final p?) {
      await ref.read(propertyRepositoryProvider).save(p.copyWith(documents: docs));
    }
  }

  Future<void> _resolve(DocumentRequest r, DocumentRequestStatus status, {String response = ''}) =>
      ref.read(documentRequestRepositoryProvider).save(r.copyWith(status: status, response: response, respondedAt: nowGst()));

  /// Turns on "Share with tenant" for an attached document.
  Future<void> shareExisting(DocumentRequest r, RequestTarget t, AppDocument doc) async {
    await _save(t, [for (final d in t.documents) identical(d, doc) ? d.withShared(true) : d]);
    await _resolve(r, DocumentRequestStatus.fulfilled);
  }

  /// Uploads [file] into the right slot (replacing a fixed slot's file),
  /// shares it, and marks the request fulfilled.
  Future<void> uploadAndShare(DocumentRequest r, RequestTarget t, XFile file, {required String label}) async {
    final ownerId = t.lease?.id ?? t.property?.id ?? 'misc';
    final folder = t.lease != null ? 'leases' : 'documents';
    final url = await ref.read(fileStorageProvider).uploadFile('$folder/$ownerId/${newId()}_${file.name}', file);
    final kind = r.doc.uploadKind;
    final slot = t.lease == null && DocumentKinds.propertySlots.contains(kind);
    final kept = [for (final d in t.documents) if (!slot || d.kind != kind) d];
    final name = r.doc == RequestableDoc.other && r.note.isNotEmpty ? r.note : label;
    await _save(t, [...kept, AppDocument(name: name, url: url, kind: kind, sharedWithTenant: true)]);
    await _resolve(r, DocumentRequestStatus.fulfilled);
  }

  Future<void> decline(DocumentRequest r, String reason) => _resolve(r, DocumentRequestStatus.declined, response: reason.trim());
}
