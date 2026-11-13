import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/data/in_memory_repository.dart';
import '../../../core/providers.dart' show demoRepo, newId;
import '../../../core/utils/dates.dart';
import '../../landlord/domain/landlord.dart';
import '../../leases/domain/lease.dart';
import '../../maintenance/domain/maintenance_ticket.dart';
import '../../payments/domain/payment.dart';
import '../../properties/domain/property.dart';
import '../../tenants/domain/tenant.dart';
import '../domain/tenant_view.dart';

/// An invite code the landlord shares with a tenant.
class TenantInvite {
  const TenantInvite({required this.code, required this.expiresAt});
  final String code;
  final DateTime expiresAt;
}

/// Why redeeming a code failed (shown to the tenant).
enum RedeemError { invalid, expired, used, ownCode, alreadyLinked }

class RedeemException implements Exception {
  const RedeemException(this.reason);
  final RedeemError reason;
  @override
  String toString() => 'RedeemException(${reason.name})';
}

/// Landlord <-> tenant connection: invite codes, links, the tenant's read
/// model, and tenant maintenance requests.
abstract class TenantPortal {
  // Landlord side.
  Future<TenantInvite> createInvite({required String landlordUid, required String tenantId, String? leaseId});

  // Tenant side.
  Future<void> redeem({required String tenantUid, required String code});
  Future<void> removeLandlord({required String tenantUid, required String landlordUid});
  Future<void> createMaintenanceRequest({
    required String tenantUid,
    required String landlordUid,
    required String propertyId,
    required String title,
    String description = '',
    List<String> photos = const [],
  });
  Stream<List<TenantLink>> watchLinks(String tenantUid);

  /// One collection of the read model: landlords, properties, leases,
  /// payments, documents or inspections.
  Stream<List<Map<String, dynamic>>> watchView(String tenantUid, String collection);

  /// Unambiguous characters only (no 0/O, 1/I/L).
  static const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static String normalise(String code) => code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

class FirebaseTenantPortal implements TenantPortal {
  final _fns = FirebaseFunctions.instance;
  final _db = FirebaseFirestore.instance;

  @override
  Future<TenantInvite> createInvite({required String landlordUid, required String tenantId, String? leaseId}) async {
    final r = await _fns.httpsCallable('createTenantInvite').call<Map<Object?, Object?>>({
      'tenantId': tenantId,
      'leaseId': ?leaseId,
    });
    return TenantInvite(code: '${r.data['code']}', expiresAt: DateTime.parse('${r.data['expiresAt']}'));
  }

  @override
  Future<void> redeem({required String tenantUid, required String code}) async {
    try {
      await _fns.httpsCallable('redeemTenantInvite').call<Object?>({'code': TenantPortal.normalise(code)});
    } on FirebaseFunctionsException catch (e) {
      final reason = switch ('${(e.details as Map?)?['reason'] ?? ''}') {
        'expired' => RedeemError.expired,
        'used' => RedeemError.used,
        'ownCode' => RedeemError.ownCode,
        'alreadyLinked' => RedeemError.alreadyLinked,
        _ => RedeemError.invalid,
      };
      throw RedeemException(reason);
    }
  }

  @override
  Future<void> removeLandlord({required String tenantUid, required String landlordUid}) =>
      _fns.httpsCallable('removeLandlordLink').call<Object?>({'landlordUid': landlordUid});

  @override
  Future<void> createMaintenanceRequest({
    required String tenantUid,
    required String landlordUid,
    required String propertyId,
    required String title,
    String description = '',
    List<String> photos = const [],
  }) =>
      _fns.httpsCallable('createTenantMaintenanceRequest').call<Object?>({
        'landlordUid': landlordUid,
        'propertyId': propertyId,
        'title': title,
        'description': description,
        'photos': photos,
      });

  @override
  Stream<List<TenantLink>> watchLinks(String tenantUid) => _db
      .collection('tenantLinks/$tenantUid/landlords')
      .snapshots()
      .map((s) => [for (final d in s.docs) TenantLink.fromMap({...d.data(), 'landlordUid': d.id})]);

  @override
  Stream<List<Map<String, dynamic>>> watchView(String tenantUid, String collection) => _db
      .collection('tenantViews/$tenantUid/$collection')
      .snapshots()
      .map((s) => [for (final d in s.docs) {...d.data(), 'id': d.data()['id'] ?? d.id}]);
}

class _DemoInvite {
  _DemoInvite(this.landlordUid, this.tenantId, this.expiresAt);
  final String landlordUid, tenantId;
  final DateTime expiresAt;
  bool used = false;
}

/// Demo mode and tests: codes, links and the read model are computed from
/// the in-memory landlord repositories, live.
class DemoTenantPortal implements TenantPortal {
  static final _invites = <String, _DemoInvite>{};
  static final _links = <String, Map<String, TenantLink>>{};
  static final _random = Random();

  /// Clears demo invites and links (tests).
  static void reset() {
    _invites.clear();
    _links.clear();
  }

  @override
  Future<TenantInvite> createInvite({required String landlordUid, required String tenantId, String? leaseId}) async {
    _invites.removeWhere((_, i) => i.landlordUid == landlordUid && i.tenantId == tenantId && !i.used);
    final code = List.generate(8, (_) => TenantPortal.alphabet[_random.nextInt(TenantPortal.alphabet.length)]).join();
    final expires = DateTime.now().add(const Duration(days: 30));
    _invites[code] = _DemoInvite(landlordUid, tenantId, expires);
    final repo = demoRepo<Tenant>(landlordUid, 'tenants');
    final t = await repo.get(tenantId);
    if (t != null) await repo.save(t.withInvite(code, expires));
    return TenantInvite(code: code, expiresAt: expires);
  }

  @override
  Future<void> redeem({required String tenantUid, required String code}) async {
    final inv = _invites[TenantPortal.normalise(code)];
    if (inv == null) throw const RedeemException(RedeemError.invalid);
    if (inv.used) throw const RedeemException(RedeemError.used);
    if (inv.expiresAt.isBefore(DateTime.now())) throw const RedeemException(RedeemError.expired);
    if (inv.landlordUid == tenantUid) throw const RedeemException(RedeemError.ownCode);
    final repo = demoRepo<Tenant>(inv.landlordUid, 'tenants');
    final t = await repo.get(inv.tenantId);
    if (t == null) throw const RedeemException(RedeemError.invalid);
    if (t.appUid != null && t.appUid != tenantUid) throw const RedeemException(RedeemError.alreadyLinked);
    inv.used = true;
    await repo.save(t.joined(tenantUid));
    final mine = _links.putIfAbsent(tenantUid, () => {});
    final prev = mine[inv.landlordUid];
    mine[inv.landlordUid] = TenantLink(
      landlordUid: inv.landlordUid,
      status: LinkStatus.active,
      tenantIds: {...?prev?.tenantIds, inv.tenantId}.toList(),
      since: prev?.since ?? DateTime.now(),
    );
    InMemoryRepository.changes.add(null);
  }

  @override
  Future<void> removeLandlord({required String tenantUid, required String landlordUid}) async {
    final link = _links[tenantUid]?[landlordUid];
    if (link == null) return;
    if (_view(tenantUid, link).status != LinkStatus.former) {
      throw StateError('Only former landlords can be removed.');
    }
    _links[tenantUid]!.remove(landlordUid);
    InMemoryRepository.changes.add(null);
  }

  @override
  Future<void> createMaintenanceRequest({
    required String tenantUid,
    required String landlordUid,
    required String propertyId,
    required String title,
    String description = '',
    List<String> photos = const [],
  }) async {
    if (_links[tenantUid]?[landlordUid] == null) throw StateError('Not linked to this landlord.');
    await demoRepo<MaintenanceTicket>(landlordUid, 'maintenanceTickets').save(MaintenanceTicket(
      id: newId(),
      propertyId: propertyId,
      title: title,
      description: description,
      photos: photos,
      raisedBy: 'tenant',
    ));
  }

  TenantViewData _view(String tenantUid, TenantLink link) {
    final ll = link.landlordUid;
    final profile = demoRepo<Landlord>(ll, 'profile').items.firstOrNull;
    return buildTenantView(
      landlordUid: ll,
      tenantUid: tenantUid,
      profile: profile,
      tenants: demoRepo<Tenant>(ll, 'tenants').items,
      leases: demoRepo<Lease>(ll, 'leases').items,
      properties: demoRepo<Property>(ll, 'properties').items,
      payments: demoRepo<Payment>(ll, 'payments').items,
      inspections: _inspections(ll),
      today: todayGst(),
      since: link.since,
    );
  }

  /// Demo inspections, if the inspections feature stores them in a demo repo.
  List<Map<String, dynamic>> _inspections(String landlordUid) => const [];

  List<TenantLink> _currentLinks(String tenantUid) => [
        for (final l in (_links[tenantUid] ?? const <String, TenantLink>{}).values)
          TenantLink(landlordUid: l.landlordUid, status: _view(tenantUid, l).status, tenantIds: l.tenantIds, since: l.since),
      ];

  Stream<T> _live<T>(T Function() read) async* {
    yield read();
    yield* InMemoryRepository.changes.stream.map((_) => read());
  }

  @override
  Stream<List<TenantLink>> watchLinks(String tenantUid) => _live(() => _currentLinks(tenantUid));

  @override
  Stream<List<Map<String, dynamic>>> watchView(String tenantUid, String collection) => _live(() {
        final out = <Map<String, dynamic>>[];
        for (final link in (_links[tenantUid] ?? const <String, TenantLink>{}).values) {
          final v = _view(tenantUid, link);
          switch (collection) {
            case 'landlords':
              out.add(v.landlord.toMap());
            case 'properties':
              out.addAll(v.properties.map((p) => p.toMap()));
            case 'leases':
              out.addAll(v.leases.map((p) => p.toMap()));
            case 'payments':
              out.addAll(v.payments.map((p) => p.toMap()));
            case 'documents':
              out.addAll(v.documents.map((p) => p.toMap()));
            case 'inspections':
              out.addAll(v.inspections);
          }
        }
        return out;
      });
}
