import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'inspection_media.dart';
import 'tenant_inspection_actions.dart';

/// Landlord-side uploads (landlords/{uid}/inspections/...).
final inspectionMediaStoreProvider = Provider<InspectionMediaStore>((ref) => useFirebase
    ? FirebaseInspectionMediaStore(ref.watch(userIdProvider).value ?? 'anon')
    : LocalInspectionMediaStore());

/// Tenant-side comments, confirmation and uploads (tenantUploads/{uid}/...).
final tenantInspectionActionsProvider = Provider<TenantInspectionActions>((ref) => useFirebase
    ? CloudTenantInspectionActions(FirebaseInspectionMediaStore(ref.watch(userIdProvider).value ?? 'anon', asTenant: true))
    : DemoTenantInspectionActions(ref.watch(inspectionRepositoryProvider)));
