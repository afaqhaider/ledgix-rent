import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/data/in_memory_repository.dart';
import '../../../core/providers.dart' show demoRepo, newId;
import '../../account/data/account_repository.dart';
import '../../account/domain/app_user.dart';
import '../../landlord/domain/landlord.dart';
import '../../leases/domain/lease.dart';
import '../../properties/domain/property.dart';
import '../../tenant_portal/data/tenant_portal.dart';
import '../../tenants/domain/tenant.dart';
import '../domain/connection.dart';

/// Finding accounts by email or LedGix code, personal share codes, and
/// connection requests in both directions. See domain/connection.dart.
abstract class ConnectionsService {
  /// Background check while typing an email or code. Rate-limited.
  Future<AccountLookup> lookup(String callerUid, ConnectTarget target);

  /// The caller's personal LedGix code (created on first use).
  Future<String> myShareCode(String uid);

  /// Landlord: invite the account behind [target] to link to tenant record [tenantRecordId].
  Future<void> inviteTenant({required String landlordUid, required String tenantRecordId, required ConnectTarget target});

  /// Tenant: ask the landlord behind [target] to connect.
  Future<void> requestLandlord({required String tenantUid, required ConnectTarget target, required bool shareDetails});

  /// Recipient accepts. Tenants may share their details; landlords answering
  /// a tenant's request choose which tenant record to link.
  Future<void> accept({required String uid, required String requestId, bool shareDetails = false, String? tenantRecordId});
  Future<void> decline({required String uid, required String requestId});

  /// Sender withdraws a pending request.
  Future<void> cancel({required String uid, required String requestId});

  Stream<List<ConnectionRequest>> watchIncoming(String uid);
  Stream<List<ConnectionRequest>> watchOutgoing(String uid);
}

ConnectionError _reasonOf(FirebaseFunctionsException e) {
  final r = '${(e.details as Map?)?['reason'] ?? ''}';
  return ConnectionError.values.where((x) => x.name == r).firstOrNull ??
      switch (e.code) {
        'resource-exhausted' => ConnectionError.rateLimited,
        'not-found' => ConnectionError.notFound,
        'permission-denied' => ConnectionError.notAllowed,
        _ => ConnectionError.invalid,
      };
}

class FirebaseConnectionsService implements ConnectionsService {
  final _fns = FirebaseFunctions.instance;
  final _col = FirebaseFirestore.instance.collection('connectionRequests');

  Future<Map<Object?, Object?>> _call(String name, Map<String, Object?> data) async {
    try {
      final r = await _fns.httpsCallable(name).call<Map<Object?, Object?>?>(data);
      return r.data ?? const {};
    } on FirebaseFunctionsException catch (e) {
      throw ConnectionException(_reasonOf(e));
    }
  }

  @override
  Future<AccountLookup> lookup(String callerUid, ConnectTarget target) async {
    final r = await _call('lookupAccount', target.toMap());
    return AccountLookup(
      exists: r['exists'] == true,
      self: r['self'] == true,
      linked: r['linked'] == true,
      role: UserRole.values.where((x) => x.name == r['role']).firstOrNull,
    );
  }

  @override
  Future<String> myShareCode(String uid) async => '${(await _call('getMyShareCode', const {}))['code'] ?? ''}';

  @override
  Future<void> inviteTenant({required String landlordUid, required String tenantRecordId, required ConnectTarget target}) =>
      _call('sendConnectionRequest', {'direction': 'landlordToTenant', 'tenantRecordId': tenantRecordId, ...target.toMap()});

  @override
  Future<void> requestLandlord({required String tenantUid, required ConnectTarget target, required bool shareDetails}) =>
      _call('sendConnectionRequest', {'direction': 'tenantToLandlord', 'shareDetails': shareDetails, ...target.toMap()});

  @override
  Future<void> accept({required String uid, required String requestId, bool shareDetails = false, String? tenantRecordId}) =>
      _call('respondToConnectionRequest', {
        'requestId': requestId,
        'action': 'accept',
        'shareDetails': shareDetails,
        'tenantRecordId': ?tenantRecordId,
      });

  @override
  Future<void> decline({required String uid, required String requestId}) =>
      _call('respondToConnectionRequest', {'requestId': requestId, 'action': 'decline'});

  @override
  Future<void> cancel({required String uid, required String requestId}) =>
      _call('respondToConnectionRequest', {'requestId': requestId, 'action': 'cancel'});

  Stream<List<ConnectionRequest>> _watch(String field, String uid) => _col.where(field, isEqualTo: uid).snapshots().map((s) =>
      [for (final d in s.docs) ConnectionRequest.fromMap({...d.data(), 'id': d.id})]
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))));

  @override
  Stream<List<ConnectionRequest>> watchIncoming(String uid) => _watch('toUid', uid);

  @override
  Stream<List<ConnectionRequest>> watchOutgoing(String uid) => _watch('fromUid', uid);
}

/// Demo mode and tests: accounts come from the in-memory account repository,
/// links go through the demo tenant portal.
class DemoConnectionsService implements ConnectionsService {
  static final _requests = <String, ConnectionRequest>{};
  static final _codes = <String, String>{}; // uid -> code
  static final _lookups = <String, List<DateTime>>{};
  static const maxLookupsPerHour = 30;

  /// Clears demo requests, codes and quotas (tests).
  static void reset() {
    _requests.clear();
    _codes.clear();
    _lookups.clear();
  }

  static void _changed() => InMemoryRepository.changes.add(null);

  String? _resolve(ConnectTarget t) => switch (t) {
        EmailTarget(:final email) => AccountRepositoryLookup.byEmail(email)?.id,
        CodeTarget(:final code) => _codes.entries.where((e) => e.value == code).firstOrNull?.key,
      };

  void _quota(String uid) {
    final now = DateTime.now();
    final recent = (_lookups[uid] ?? const <DateTime>[]).where((t) => now.difference(t).inMinutes < 60).toList();
    if (recent.length >= maxLookupsPerHour) throw const ConnectionException(ConnectionError.rateLimited);
    _lookups[uid] = [...recent, now];
  }

  static UserRole _roleOf(String uid) => AccountRepositoryLookup.byId(uid)?.role ?? UserRole.landlord;

  @override
  Future<AccountLookup> lookup(String callerUid, ConnectTarget target) async {
    _quota(callerUid);
    final uid = _resolve(target);
    if (uid == null) return AccountLookup.none;
    if (uid == callerUid) return const AccountLookup(exists: true, self: true);
    final linked = demoRepo<Tenant>(callerUid, 'tenants').items.any((t) => t.appUid == uid);
    return AccountLookup(exists: true, linked: linked, role: _roleOf(uid));
  }

  @override
  Future<String> myShareCode(String uid) async => _codes.putIfAbsent(uid, () {
        final r = Random();
        String code;
        do {
          code = 'LGX-${List.generate(6, (_) => ShareCodes.alphabet[r.nextInt(ShareCodes.alphabet.length)]).join()}';
        } while (_codes.containsValue(code));
        return code;
      });

  bool _hasPending(String from, String to, String? record) =>
      _requests.values.any((r) => r.isPending && r.fromUid == from && r.toUid == to && r.tenantRecordId == record);

  String _landlordName(String uid) {
    final p = demoRepo<Landlord>(uid, 'profile').items.firstOrNull?.name ?? '';
    return p.isNotEmpty ? p : (AccountRepositoryLookup.byId(uid)?.name ?? '');
  }

  String _propertyFor(String landlordUid, String tenantId) {
    final lease = demoRepo<Lease>(landlordUid, 'leases').items.where((x) => x.tenantId == tenantId).lastOrNull;
    if (lease == null) return '';
    return demoRepo<Property>(landlordUid, 'properties').items.where((p) => p.id == lease.propertyId).firstOrNull?.name ?? '';
  }

  @override
  Future<void> inviteTenant({required String landlordUid, required String tenantRecordId, required ConnectTarget target}) async {
    final to = _resolve(target);
    if (to == null) throw const ConnectionException(ConnectionError.notFound);
    if (to == landlordUid) throw const ConnectionException(ConnectionError.self);
    final record = await demoRepo<Tenant>(landlordUid, 'tenants').get(tenantRecordId);
    if (record == null) throw const ConnectionException(ConnectionError.invalid);
    if (record.appUid != null) throw const ConnectionException(ConnectionError.alreadyLinked);
    if (_hasPending(landlordUid, to, tenantRecordId)) throw const ConnectionException(ConnectionError.duplicate);
    final id = newId();
    _requests[id] = ConnectionRequest(
      id: id,
      fromUid: landlordUid,
      toUid: to,
      landlordUid: landlordUid,
      tenantUid: to,
      direction: ConnectionDirection.landlordToTenant,
      tenantRecordId: tenantRecordId,
      target: target.label,
      propertyName: _propertyFor(landlordUid, tenantRecordId),
      fromName: _landlordName(landlordUid),
      createdAt: DateTime.now(),
    );
    _changed();
  }

  @override
  Future<void> requestLandlord({required String tenantUid, required ConnectTarget target, required bool shareDetails}) async {
    final to = _resolve(target);
    if (to == null) throw const ConnectionException(ConnectionError.notFound);
    if (to == tenantUid) throw const ConnectionException(ConnectionError.self);
    if (_roleOf(to).isTenant) throw const ConnectionException(ConnectionError.wrongRole);
    if (_hasPending(tenantUid, to, null)) throw const ConnectionException(ConnectionError.duplicate);
    final me = AccountRepositoryLookup.byId(tenantUid);
    final id = newId();
    _requests[id] = ConnectionRequest(
      id: id,
      fromUid: tenantUid,
      toUid: to,
      landlordUid: to,
      tenantUid: tenantUid,
      direction: ConnectionDirection.tenantToLandlord,
      fromName: me?.name ?? '',
      fromEmail: me?.email ?? '',
      target: target.label,
      details: shareDetails && me != null ? SharedDetails.of(me) : null,
      createdAt: DateTime.now(),
    );
    _changed();
  }

  ConnectionRequest _pending(String requestId) {
    final r = _requests[requestId];
    if (r == null || !r.isPending) throw const ConnectionException(ConnectionError.invalid);
    return r;
  }

  @override
  Future<void> accept({required String uid, required String requestId, bool shareDetails = false, String? tenantRecordId}) async {
    final r = _pending(requestId);
    if (r.toUid != uid) throw const ConnectionException(ConnectionError.notAllowed);
    final recordId = r.direction == ConnectionDirection.landlordToTenant ? r.tenantRecordId : tenantRecordId;
    if (recordId == null) throw const ConnectionException(ConnectionError.invalid);
    final repo = demoRepo<Tenant>(r.landlordUid, 'tenants');
    final record = await repo.get(recordId);
    if (record == null) throw const ConnectionException(ConnectionError.invalid);
    if (record.appUid != null && record.appUid != r.tenantUid) throw const ConnectionException(ConnectionError.alreadyLinked);

    // Details reach the landlord's record only with the tenant's consent.
    final details = r.direction == ConnectionDirection.landlordToTenant
        ? (shareDetails ? AccountRepositoryLookup.byId(r.tenantUid) : null)?.let(SharedDetails.of)
        : r.details;
    if (details != null) await repo.save(fillEmptyFields(record, details));
    await DemoTenantPortal.demoLink(landlordUid: r.landlordUid, tenantId: recordId, tenantUid: r.tenantUid);
    _requests[requestId] = r.withStatus(ConnectionStatus.accepted, tenantRecordId: recordId);
    _changed();
  }

  @override
  Future<void> decline({required String uid, required String requestId}) async {
    final r = _pending(requestId);
    if (r.toUid != uid) throw const ConnectionException(ConnectionError.notAllowed);
    _requests[requestId] = r.withStatus(ConnectionStatus.declined);
    _changed();
  }

  @override
  Future<void> cancel({required String uid, required String requestId}) async {
    final r = _pending(requestId);
    if (r.fromUid != uid) throw const ConnectionException(ConnectionError.notAllowed);
    _requests[requestId] = r.withStatus(ConnectionStatus.cancelled);
    _changed();
  }

  Stream<List<ConnectionRequest>> _live(bool Function(ConnectionRequest) where) async* {
    List<ConnectionRequest> read() =>
        _requests.values.where(where).toList()..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    yield read();
    yield* InMemoryRepository.changes.stream.map((_) => read());
  }

  @override
  Stream<List<ConnectionRequest>> watchIncoming(String uid) => _live((r) => r.toUid == uid);

  @override
  Stream<List<ConnectionRequest>> watchOutgoing(String uid) => _live((r) => r.fromUid == uid);
}

extension _Let<T extends Object> on T {
  R let<R>(R Function(T) f) => f(this);
}

/// Demo account lookups (kept separate so the repository stays small).
abstract final class AccountRepositoryLookup {
  static AppUser? byEmail(String email) => InMemoryAccountRepository.byEmail(email);
  static AppUser? byId(String uid) => InMemoryAccountRepository.byId(uid);
}
