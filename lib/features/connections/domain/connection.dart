import '../../../core/domain/entity.dart';
import '../../account/domain/app_user.dart';
import '../../tenants/domain/tenant.dart';

/// Landlord <-> tenant connection requests ("invitations").
///
/// Email is the source of truth: a landlord adding a tenant (or a tenant
/// adding a landlord) can find an existing LedGix Rent account by email or by
/// the person's LedGix code, then send a request the other side must accept.
/// Nothing links until it's accepted. Requests live in
/// `connectionRequests/{id}` and are written only by Cloud Functions
/// (functions/src/connections.ts).

enum ConnectionDirection { landlordToTenant, tenantToLandlord }

enum ConnectionStatus { pending, accepted, declined, cancelled }

/// Why sending or answering a request was refused.
enum ConnectionError { notFound, self, duplicate, alreadyLinked, rateLimited, wrongRole, notAllowed, invalid }

class ConnectionException implements Exception {
  const ConnectionException(this.reason);
  final ConnectionError reason;
  @override
  String toString() => 'ConnectionException(${reason.name})';
}

/// What the background email / code check may reveal: whether an account
/// exists and its role, never names or other details.
class AccountLookup {
  const AccountLookup({required this.exists, this.self = false, this.linked = false, this.role});
  static const none = AccountLookup(exists: false);

  final bool exists;

  /// The caller's own email or code.
  final bool self;

  /// Already connected to the caller (landlord: one of their tenants).
  final bool linked;
  final UserRole? role;
}

/// A person's own details they can choose to share (tenant "My details").
class SharedDetails {
  const SharedDetails({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.emiratesIdNo = '',
    this.emiratesIdExpiry,
    this.passportNo = '',
    this.passportExpiry,
  });

  factory SharedDetails.of(AppUser u) => SharedDetails(
        name: u.name,
        email: u.email,
        phone: u.phone,
        emiratesIdNo: u.emiratesIdNo,
        emiratesIdExpiry: u.emiratesIdExpiry,
        passportNo: u.passportNo,
        passportExpiry: u.passportExpiry,
      );

  final String name, email, phone, emiratesIdNo, passportNo;
  final DateTime? emiratesIdExpiry, passportExpiry;

  bool get isEmpty => [name, email, phone, emiratesIdNo, passportNo].every((s) => s.trim().isEmpty);

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'emiratesIdNo': emiratesIdNo,
        'emiratesIdExpiry': dateKey(emiratesIdExpiry),
        'passportNo': passportNo,
        'passportExpiry': dateKey(passportExpiry),
      };

  factory SharedDetails.fromMap(Map<String, dynamic>? m) => m == null
      ? const SharedDetails()
      : SharedDetails(
          name: '${m['name'] ?? ''}',
          email: '${m['email'] ?? ''}',
          phone: '${m['phone'] ?? ''}',
          emiratesIdNo: '${m['emiratesIdNo'] ?? ''}',
          emiratesIdExpiry: parseDate(m['emiratesIdExpiry']),
          passportNo: '${m['passportNo'] ?? ''}',
          passportExpiry: parseDate(m['passportExpiry']),
        );

  /// First / middle / last from a full name ("Ahmed Ali Khan" -> Ahmed, Ali, Khan).
  (String, String, String) get nameParts {
    final p = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (p.isEmpty) return ('', '', '');
    if (p.length == 1) return (p.first, '', '');
    return (p.first, p.sublist(1, p.length - 1).join(' '), p.last);
  }

  /// Prefill map for the tenant form (keys match FormKeys).
  Map<String, String> get prefill {
    final (first, middle, last) = nameParts;
    return {
      'firstName': first,
      'middleName': middle,
      'lastName': last,
      'email': email,
      'phone': phone,
      'emiratesId': emiratesIdNo,
      'passport': passportNo,
      if (emiratesIdExpiry != null) 'eidExpiry': dateKey(emiratesIdExpiry)!,
      if (passportExpiry != null) 'passportExpiry': dateKey(passportExpiry)!,
    }..removeWhere((_, v) => v.trim().isEmpty);
  }
}

/// The landlord's tenant record with [d] filled into empty fields only:
/// what the landlord already typed always wins. Mirrors fillEmptyTenantFields
/// in functions/src/connections.ts.
Tenant fillEmptyFields(Tenant t, SharedDetails d) {
  String pick(String current, String incoming) => current.trim().isEmpty ? incoming.trim() : current;
  final (first, middle, last) = d.nameParts;
  final noName = t.firstName.trim().isEmpty && t.lastName.trim().isEmpty;
  return t.copyDetails(
    firstName: noName ? first : t.firstName,
    middleName: noName ? middle : t.middleName,
    lastName: noName ? last : t.lastName,
    email: pick(t.email, d.email),
    phone: pick(t.phone, d.phone),
    emiratesIdNo: pick(t.emiratesIdNo, d.emiratesIdNo),
    passportNo: pick(t.passportNo, d.passportNo),
    documents: t.documents,
    emiratesIdExpiry: t.emiratesIdExpiry ?? d.emiratesIdExpiry,
    passportExpiry: t.passportExpiry ?? d.passportExpiry,
  );
}

class ConnectionRequest {
  const ConnectionRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.landlordUid,
    required this.tenantUid,
    required this.direction,
    this.status = ConnectionStatus.pending,
    this.tenantRecordId,
    this.leaseId,
    this.propertyName = '',
    this.fromName = '',
    this.fromEmail = '',
    this.target = '',
    this.details,
    this.createdAt,
    this.respondedAt,
  });

  final String id, fromUid, toUid, landlordUid, tenantUid;
  final ConnectionDirection direction;
  final ConnectionStatus status;

  /// Landlord -> tenant: the landlord's tenant record to link.
  final String? tenantRecordId, leaseId;
  final String propertyName, fromName, fromEmail;

  /// The email or LedGix code the sender typed (shown on their sent requests).
  final String target;

  /// Tenant -> landlord: details the tenant chose to share, for prefilling.
  final SharedDetails? details;
  final DateTime? createdAt, respondedAt;

  bool get isPending => status == ConnectionStatus.pending;
  bool sentBy(String uid) => fromUid == uid;

  ConnectionRequest withStatus(ConnectionStatus s, {String? tenantRecordId}) => ConnectionRequest(
        id: id,
        fromUid: fromUid,
        toUid: toUid,
        landlordUid: landlordUid,
        tenantUid: tenantUid,
        direction: direction,
        status: s,
        tenantRecordId: tenantRecordId ?? this.tenantRecordId,
        leaseId: leaseId,
        propertyName: propertyName,
        fromName: fromName,
        fromEmail: fromEmail,
        target: target,
        details: details,
        createdAt: createdAt,
        respondedAt: DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'fromUid': fromUid,
        'toUid': toUid,
        'landlordUid': landlordUid,
        'tenantUid': tenantUid,
        'direction': direction.name,
        'status': status.name,
        'tenantRecordId': tenantRecordId,
        'leaseId': leaseId,
        'propertyName': propertyName,
        'fromName': fromName,
        'fromEmail': fromEmail,
        'target': target,
        'details': details?.toMap(),
        'createdAt': createdAt?.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
      };

  factory ConnectionRequest.fromMap(Map<String, dynamic> m) => ConnectionRequest(
        id: '${m['id']}',
        fromUid: '${m['fromUid'] ?? ''}',
        toUid: '${m['toUid'] ?? ''}',
        landlordUid: '${m['landlordUid'] ?? ''}',
        tenantUid: '${m['tenantUid'] ?? ''}',
        direction: enumByName(ConnectionDirection.values, m['direction'], ConnectionDirection.landlordToTenant),
        status: enumByName(ConnectionStatus.values, m['status'], ConnectionStatus.pending),
        tenantRecordId: m['tenantRecordId'] as String?,
        leaseId: m['leaseId'] as String?,
        propertyName: '${m['propertyName'] ?? ''}',
        fromName: '${m['fromName'] ?? ''}',
        fromEmail: '${m['fromEmail'] ?? ''}',
        target: '${m['target'] ?? ''}',
        details: m['details'] is Map ? SharedDetails.fromMap(Map<String, dynamic>.from(m['details'] as Map)) : null,
        createdAt: _time(m['createdAt']),
        respondedAt: _time(m['respondedAt']),
      );

  static DateTime? _time(Object? v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    try {
      return (v as dynamic).toDate() as DateTime; // Firestore Timestamp
    } catch (_) {
      return null;
    }
  }
}

/// Personal LedGix codes: "LGX-" + 6 unambiguous characters (no 0/O, 1/I/L).
abstract final class ShareCodes {
  static const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static final _pattern = RegExp('^LGX[$alphabet]{6}\$');

  /// "lgx 7k3m9q" / "LGX-7K3M9Q" -> "LGX-7K3M9Q", or null if it isn't one.
  static String? normalise(String input) {
    final s = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return _pattern.hasMatch(s) ? 'LGX-${s.substring(3)}' : null;
  }
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// What someone typed into "email or LedGix code".
sealed class ConnectTarget {
  const ConnectTarget();

  static ConnectTarget? parse(String input) {
    final s = input.trim();
    if (_emailPattern.hasMatch(s)) return EmailTarget(s.toLowerCase());
    final code = ShareCodes.normalise(s);
    return code == null ? null : CodeTarget(code);
  }

  Map<String, String> toMap();

  /// The email or code as typed (normalised).
  String get label;
}

class EmailTarget extends ConnectTarget {
  const EmailTarget(this.email);
  final String email;
  @override
  Map<String, String> toMap() => {'email': email};
  @override
  String get label => email;
}

class CodeTarget extends ConnectTarget {
  const CodeTarget(this.code);
  final String code;
  @override
  Map<String, String> toMap() => {'code': code};
  @override
  String get label => code;
}
