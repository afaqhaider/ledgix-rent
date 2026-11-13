import 'package:cloud_functions/cloud_functions.dart';
import 'package:cross_file/cross_file.dart';

import '../../../core/domain/entity.dart';
import '../domain/inspection.dart';
import 'inspection_media.dart';

/// What a tenant can do to a landlord's inspection. In production every call
/// goes through a Cloud Function (functions/src/inspections.ts), which checks
/// the tenant is linked to that landlord and to the inspection's tenant record.
abstract class TenantInspectionActions {
  Future<void> addComment({required String landlordUid, required String inspectionId, required String text, String? itemId});
  Future<void> confirm({required String landlordUid, required String inspectionId});
  Future<void> attachMedia({
    required String landlordUid,
    required String inspectionId,
    required XFile file,
    required MediaType type,
    String? itemId,
    void Function(double progress)? onProgress,
  });
}

class CloudTenantInspectionActions implements TenantInspectionActions {
  CloudTenantInspectionActions(this.media);

  /// Must be a tenant store (`asTenant: true`).
  final InspectionMediaStore media;

  HttpsCallable _fn(String name) => FirebaseFunctions.instance.httpsCallable(name);

  @override
  Future<void> addComment({required String landlordUid, required String inspectionId, required String text, String? itemId}) =>
      _fn('addInspectionTenantComment').call<void>({
        'landlordUid': landlordUid,
        'inspectionId': inspectionId,
        'text': text,
        'itemId': ?itemId,
      });

  @override
  Future<void> confirm({required String landlordUid, required String inspectionId}) =>
      _fn('confirmInspectionAsTenant').call<void>({'landlordUid': landlordUid, 'inspectionId': inspectionId});

  @override
  Future<void> attachMedia({
    required String landlordUid,
    required String inspectionId,
    required XFile file,
    required MediaType type,
    String? itemId,
    void Function(double progress)? onProgress,
  }) async {
    final up = await media.upload(inspectionId, file, type: type, onProgress: onProgress);
    await _fn('attachInspectionTenantMedia').call<void>({
      'landlordUid': landlordUid,
      'inspectionId': inspectionId,
      'storagePath': up.storagePath,
      'type': type.name,
      'itemId': ?itemId,
    });
  }
}

/// Demo mode and tests: applies the same changes the Cloud Functions make,
/// straight to the (in-memory) inspection repository, so one device can play
/// both sides.
class DemoTenantInspectionActions implements TenantInspectionActions {
  DemoTenantInspectionActions(this.repo, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;
  final CrudRepository<Inspection> repo;
  final DateTime Function() _now;

  /// Every call, for tests.
  final calls = <String>[];

  Future<void> _update(String id, Inspection Function(Inspection) f) async {
    final i = await repo.get(id);
    if (i != null) await repo.save(f(i));
  }

  @override
  Future<void> addComment({required String landlordUid, required String inspectionId, required String text, String? itemId}) {
    calls.add('comment:$inspectionId');
    return _update(inspectionId,
        (i) => i.copyWith(tenantComments: [...i.tenantComments, TenantComment(text: text, at: _now(), itemId: itemId)]));
  }

  @override
  Future<void> confirm({required String landlordUid, required String inspectionId}) {
    calls.add('confirm:$inspectionId');
    return _update(
        inspectionId,
        (i) => i.status == InspectionStatus.awaitingTenant
            ? i.copyWith(tenantConfirmedAt: _now(), status: InspectionStatus.completed, completedAt: _now())
            : i);
  }

  @override
  Future<void> attachMedia({
    required String landlordUid,
    required String inspectionId,
    required XFile file,
    required MediaType type,
    String? itemId,
    void Function(double progress)? onProgress,
  }) async {
    calls.add('media:$inspectionId');
    onProgress?.call(1);
    final p = file.path.isNotEmpty ? file.path : file.name;
    await _update(
        inspectionId,
        (i) => i.copyWith(tenantMedia: [
              ...i.tenantMedia,
              InspectionMedia(url: p, storagePath: p, type: type, takenAt: _now(), by: MediaBy.tenant, itemId: itemId),
            ]));
  }
}
