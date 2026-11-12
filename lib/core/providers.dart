import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../features/auth/data/demo_auth_repository.dart';
import '../features/auth/data/firebase_auth_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/dashboard/domain/dashboard_stats.dart';
import '../features/holds/domain/hold_request.dart';
import '../features/landlord/domain/landlord.dart';
import '../features/leases/domain/lease.dart';
import '../features/maintenance/domain/maintenance_ticket.dart';
import '../features/payments/domain/payment.dart';
import '../features/properties/domain/property.dart';
import '../features/tenants/domain/tenant.dart';
import '../features/vendors/domain/vendor.dart';
import 'data/file_storage.dart';
import 'data/firestore_repository.dart';
import 'data/in_memory_repository.dart';
import 'domain/entity.dart';
import 'utils/dates.dart';

/// Build with `--dart-define=USE_FIREBASE=true` once Firebase is configured.
/// Without it the app runs in demo mode with in-memory data.
const useFirebase = bool.fromEnvironment('USE_FIREBASE');

const _uuid = Uuid();
String newId() => _uuid.v4();

typedef PropertyRepository = CrudRepository<Property>;
typedef TenantRepository = CrudRepository<Tenant>;
typedef LeaseRepository = CrudRepository<Lease>;
typedef PaymentRepository = CrudRepository<Payment>;
typedef HoldRequestRepository = CrudRepository<HoldRequest>;
typedef MaintenanceRepository = CrudRepository<MaintenanceTicket>;
typedef VendorRepository = CrudRepository<Vendor>;
typedef LandlordRepository = CrudRepository<Landlord>;

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => useFirebase ? FirebaseAuthRepository() : DemoAuthRepository());

final userIdProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.watchUserId();
});

final fileStorageProvider =
    Provider<FileStorage>((ref) => useFirebase ? FirebaseFileStorage() : LocalFileStorage());

/// Demo repositories live for the whole app session.
final _demoStore = <String, Object>{};

CrudRepository<T> _repo<T extends Entity>(
    Ref ref, String collection, T Function(Map<String, dynamic>) fromMap) {
  final uid = ref.watch(userIdProvider).value ?? 'anon';
  if (!useFirebase) {
    return _demoStore.putIfAbsent('$uid/$collection', () => InMemoryRepository<T>())
        as InMemoryRepository<T>;
  }
  return FirestoreRepository<T>(
      FirebaseFirestore.instance.collection('landlords/$uid/$collection'), fromMap);
}

final propertyRepositoryProvider =
    Provider<PropertyRepository>((r) => _repo(r, 'properties', Property.fromMap));
final tenantRepositoryProvider =
    Provider<TenantRepository>((r) => _repo(r, 'tenants', Tenant.fromMap));
final leaseRepositoryProvider =
    Provider<LeaseRepository>((r) => _repo(r, 'leases', Lease.fromMap));
final paymentRepositoryProvider =
    Provider<PaymentRepository>((r) => _repo(r, 'payments', Payment.fromMap));
final holdRepositoryProvider =
    Provider<HoldRequestRepository>((r) => _repo(r, 'holdRequests', HoldRequest.fromMap));
final maintenanceRepositoryProvider =
    Provider<MaintenanceRepository>((r) => _repo(r, 'maintenanceTickets', MaintenanceTicket.fromMap));
final vendorRepositoryProvider =
    Provider<VendorRepository>((r) => _repo(r, 'vendors', Vendor.fromMap));
final landlordRepositoryProvider =
    Provider<LandlordRepository>((r) => _repo(r, 'profile', Landlord.fromMap));

final propertiesProvider =
    StreamProvider((ref) => ref.watch(propertyRepositoryProvider).watchAll());
final tenantsProvider = StreamProvider((ref) => ref.watch(tenantRepositoryProvider).watchAll());
final leasesProvider = StreamProvider((ref) => ref.watch(leaseRepositoryProvider).watchAll());
final paymentsProvider = StreamProvider((ref) => ref.watch(paymentRepositoryProvider).watchAll());
final holdsProvider = StreamProvider((ref) => ref.watch(holdRepositoryProvider).watchAll());
final ticketsProvider = StreamProvider((ref) => ref.watch(maintenanceRepositoryProvider).watchAll());
final vendorsProvider = StreamProvider((ref) => ref.watch(vendorRepositoryProvider).watchAll());

final dashboardProvider = Provider<DashboardStats>((ref) => DashboardStats.compute(
      payments: ref.watch(paymentsProvider).value ?? const [],
      tickets: ref.watch(ticketsProvider).value ?? const [],
      today: todayGst(),
    ));

class LocaleNotifier extends Notifier<String> {
  @override
  String build() => 'en';
  void set(String code) => state = code;
}

final localeProvider = NotifierProvider<LocaleNotifier, String>(LocaleNotifier.new);
