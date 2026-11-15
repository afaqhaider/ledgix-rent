import '../../../core/domain/entity.dart';

/// Who is using the app. Landlords and property managers use the landlord
/// app; tenants use the tenant app.
enum UserRole {
  landlord,
  propertyManager,
  tenant;

  bool get isTenant => this == UserRole.tenant;
}

/// The signed-in person's account record (`users/{uid}`).
///
/// Tenants keep their own details here ("My details") so they can share them
/// with a landlord when they accept or send a connection request.
/// [shareCode] is written only by the server and is never saved from the app.
class AppUser implements Entity {
  const AppUser({
    required this.id,
    required this.role,
    this.name = '',
    this.unitCount,
    this.email = '',
    this.phone = '',
    this.emiratesIdNo = '',
    this.emiratesIdExpiry,
    this.passportNo = '',
    this.passportExpiry,
    this.shareCode = '',
  });

  @override
  final String id;
  final UserRole role;
  final String name, email, phone, emiratesIdNo, passportNo;
  final DateTime? emiratesIdExpiry, passportExpiry;

  /// Personal LedGix code, e.g. "LGX-7K3M9Q" (server-assigned).
  final String shareCode;

  /// How many units the landlord / manager looks after (onboarding answer).
  final int? unitCount;

  AppUser copyWith({
    String? name,
    String? phone,
    String? emiratesIdNo,
    DateTime? emiratesIdExpiry,
    String? passportNo,
    DateTime? passportExpiry,
    bool clearEmiratesIdExpiry = false,
    bool clearPassportExpiry = false,
  }) =>
      AppUser(
        id: id,
        role: role,
        name: name ?? this.name,
        unitCount: unitCount,
        email: email,
        phone: phone ?? this.phone,
        emiratesIdNo: emiratesIdNo ?? this.emiratesIdNo,
        emiratesIdExpiry: clearEmiratesIdExpiry ? null : (emiratesIdExpiry ?? this.emiratesIdExpiry),
        passportNo: passportNo ?? this.passportNo,
        passportExpiry: clearPassportExpiry ? null : (passportExpiry ?? this.passportExpiry),
        shareCode: shareCode,
      );

  /// Saved fields. `shareCode` is deliberately left out (server-only).
  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role.name,
        'name': name,
        'email': email,
        'unitCount': unitCount,
        'phone': phone,
        'emiratesIdNo': emiratesIdNo,
        'emiratesIdExpiry': dateKey(emiratesIdExpiry),
        'passportNo': passportNo,
        'passportExpiry': dateKey(passportExpiry),
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: '${m['id']}',
        role: enumByName(UserRole.values, m['role'], UserRole.landlord),
        name: '${m['name'] ?? ''}',
        email: '${m['email'] ?? ''}',
        unitCount: (m['unitCount'] as num?)?.toInt(),
        phone: '${m['phone'] ?? ''}',
        emiratesIdNo: '${m['emiratesIdNo'] ?? ''}',
        emiratesIdExpiry: parseDate(m['emiratesIdExpiry']),
        passportNo: '${m['passportNo'] ?? ''}',
        passportExpiry: parseDate(m['passportExpiry']),
        shareCode: '${m['shareCode'] ?? ''}',
      );
}
