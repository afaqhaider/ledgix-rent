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
class AppUser implements Entity {
  const AppUser({required this.id, required this.role, this.name = '', this.unitCount, this.email = ''});

  @override
  final String id;
  final UserRole role;
  final String name, email;

  /// How many units the landlord / manager looks after (onboarding answer).
  final int? unitCount;

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role.name,
        'name': name,
        'email': email,
        'unitCount': unitCount,
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: '${m['id']}',
        role: enumByName(UserRole.values, m['role'], UserRole.landlord),
        name: '${m['name'] ?? ''}',
        email: '${m['email'] ?? ''}',
        unitCount: (m['unitCount'] as num?)?.toInt(),
      );
}
