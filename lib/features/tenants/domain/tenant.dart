import '../../../core/domain/entity.dart';
import '../../documents/domain/app_document.dart';
import '../../documents/domain/form_fill.dart';

enum TenantInviteStatus { notInvited, invited, joined }

class Tenant implements Entity {
  /// [name] is for callers that only have a full name (and old records); it
  /// is split into first / middle / last when those are not given.
  Tenant({
    required this.id,
    String name = '',
    String firstName = '',
    String middleName = '',
    String lastName = '',
    this.phone = '',
    this.email = '',
    this.emiratesIdNo = '',
    this.passportNo = '',
    this.emiratesIdExpiry,
    this.passportExpiry,
    this.documents = const [],
    this.appUid,
    this.inviteCode,
    this.inviteExpiresAt,
  })  : firstName = firstName.isNotEmpty || lastName.isNotEmpty ? firstName : splitName(name).first,
        middleName = firstName.isNotEmpty || lastName.isNotEmpty ? middleName : splitName(name).middle,
        lastName = firstName.isNotEmpty || lastName.isNotEmpty ? lastName : splitName(name).last;

  @override
  final String id;
  final String firstName, middleName, lastName, phone, email, emiratesIdNo, passportNo;

  /// Expiry dates of the Emirates ID and passport (optional).
  final DateTime? emiratesIdExpiry, passportExpiry;
  final List<AppDocument> documents;

  /// Set by the backend when the tenant joins the app with an invite code.
  final String? appUid;

  /// The current, unused invite code (written by the backend).
  final String? inviteCode;
  final DateTime? inviteExpiresAt;

  TenantInviteStatus inviteStatus(DateTime now) => appUid != null
      ? TenantInviteStatus.joined
      : (inviteCode != null && (inviteExpiresAt == null || inviteExpiresAt!.isAfter(now)))
          ? TenantInviteStatus.invited
          : TenantInviteStatus.notInvited;

  /// Same tenant with new details, keeping the app link and invite.
  Tenant copyDetails({
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String phone,
    required String emiratesIdNo,
    required String passportNo,
    required List<AppDocument> documents,
    DateTime? emiratesIdExpiry,
    DateTime? passportExpiry,
  }) =>
      Tenant(
        id: id,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        email: email,
        phone: phone,
        emiratesIdNo: emiratesIdNo,
        passportNo: passportNo,
        emiratesIdExpiry: emiratesIdExpiry,
        passportExpiry: passportExpiry,
        documents: documents,
        appUid: appUid,
        inviteCode: inviteCode,
        inviteExpiresAt: inviteExpiresAt,
      );

  Tenant withInvite(String code, DateTime expiresAt) => Tenant(
        id: id,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        email: email,
        phone: phone,
        emiratesIdNo: emiratesIdNo,
        passportNo: passportNo,
        emiratesIdExpiry: emiratesIdExpiry,
        passportExpiry: passportExpiry,
        documents: documents,
        appUid: appUid,
        inviteCode: code,
        inviteExpiresAt: expiresAt,
      );

  Tenant joined(String uid) => Tenant(
        id: id,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        email: email,
        phone: phone,
        emiratesIdNo: emiratesIdNo,
        passportNo: passportNo,
        emiratesIdExpiry: emiratesIdExpiry,
        passportExpiry: passportExpiry,
        documents: documents,
        appUid: uid,
      );

  String get name => [firstName, middleName, lastName].where((s) => s.trim().isNotEmpty).join(' ');

  String? docUrl(String kind) => documents.where((d) => d.kind == kind).firstOrNull?.url;

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name, // kept for older app versions and the Cloud Functions
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'emiratesIdNo': emiratesIdNo,
        'passportNo': passportNo,
        'emiratesIdExpiry': dateKey(emiratesIdExpiry),
        'passportExpiry': dateKey(passportExpiry),
        'documents': documents.map((d) => d.toMap()).toList(),
        'appUid': appUid,
        'inviteCode': inviteCode,
        'inviteExpiresAt': inviteExpiresAt?.toIso8601String(),
      };

  /// Reads current and pre-documents records (single `name`, separate
  /// passport / Emirates ID copy URLs).
  factory Tenant.fromMap(Map<String, dynamic> m) {
    final docs = AppDocument.listFrom(m['documents']);
    final legacy = [
      if (m['emiratesIdCopyUrl'] is String && !docs.any((d) => d.kind == DocumentKinds.emiratesId))
        AppDocument(name: 'Emirates ID', url: m['emiratesIdCopyUrl'] as String, kind: DocumentKinds.emiratesId),
      if (m['passportCopyUrl'] is String && !docs.any((d) => d.kind == DocumentKinds.passport))
        AppDocument(name: 'Passport', url: m['passportCopyUrl'] as String, kind: DocumentKinds.passport),
    ];
    return Tenant(
      id: m['id'] as String,
      name: '${m['name'] ?? ''}',
      firstName: '${m['firstName'] ?? ''}',
      middleName: '${m['middleName'] ?? ''}',
      lastName: '${m['lastName'] ?? ''}',
      phone: '${m['phone'] ?? ''}',
      email: '${m['email'] ?? ''}',
      emiratesIdNo: '${m['emiratesIdNo'] ?? ''}',
      passportNo: '${m['passportNo'] ?? ''}',
      emiratesIdExpiry: parseDate(m['emiratesIdExpiry']),
      passportExpiry: parseDate(m['passportExpiry']),
      documents: [...docs, ...legacy],
      appUid: m['appUid'] as String?,
      inviteCode: m['inviteCode'] as String?,
      inviteExpiresAt: parseDate(m['inviteExpiresAt']),
    );
  }
}
