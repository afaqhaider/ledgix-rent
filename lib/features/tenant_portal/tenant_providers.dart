import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/file_storage.dart';
import '../../core/providers.dart';
import 'data/tenant_portal.dart';
import 'domain/tenant_view.dart';

final tenantPortalProvider = Provider<TenantPortal>((ref) => useFirebase ? FirebaseTenantPortal() : DemoTenantPortal());

String _uid(Ref ref) => ref.watch(userIdProvider).value ?? 'anon';

/// The tenant's landlords (active and former).
final tenantLinksProvider =
    StreamProvider<List<TenantLink>>((ref) => ref.watch(tenantPortalProvider).watchLinks(_uid(ref)));

Stream<List<T>> _view<T>(Ref ref, String collection, T Function(Map<String, dynamic>) fromMap) =>
    ref.watch(tenantPortalProvider).watchView(_uid(ref), collection).map((l) => l.map(fromMap).toList());

final tenantLandlordsProvider = StreamProvider<List<TvLandlord>>((ref) => _view(ref, 'landlords', TvLandlord.fromMap));
final tenantPropertiesProvider = StreamProvider<List<TvProperty>>((ref) => _view(ref, 'properties', TvProperty.fromMap));
final tenantLeasesProvider = StreamProvider<List<TvLease>>((ref) => _view(ref, 'leases', TvLease.fromMap));
final tenantPaymentsProvider = StreamProvider<List<TvPayment>>(
    (ref) => _view(ref, 'payments', TvPayment.fromMap).map((l) => l..sort((a, b) => a.dueDate.compareTo(b.dueDate))));
final tenantDocumentsProvider = StreamProvider<List<TvDocument>>((ref) => _view(ref, 'documents', TvDocument.fromMap));
final tenantInspectionsProvider = StreamProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(tenantPortalProvider).watchView(_uid(ref), 'inspections'));

/// Tenants upload their own files (maintenance photos) under `tenants/{uid}/`.
final tenantFileStorageProvider = Provider<FileStorage>((ref) => useFirebase
    ? FirebaseFileStorage(ref.watch(userIdProvider).value ?? 'anon', root: 'tenants')
    : LocalFileStorage());
