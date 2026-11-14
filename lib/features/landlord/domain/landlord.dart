import '../../../core/domain/entity.dart';

class Landlord implements Entity {
  const Landlord({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.language = 'en',
    this.emiratesIdNo = '',
    this.passportNo = '',
    this.emiratesIdExpiry,
    this.passportExpiry,
  });

  @override
  final String id;
  final String name, phone, email, language;

  /// The landlord's own ID numbers. Scans that match them are never treated
  /// as a tenant.
  final String emiratesIdNo, passportNo;

  /// Expiry dates of the landlord's own Emirates ID and passport (optional).
  final DateTime? emiratesIdExpiry, passportExpiry;

  /// Same landlord with new ID details. Unlike [copyWith], null expiries clear
  /// the stored dates (the profile form can remove them).
  Landlord withIdentity({
    required String emiratesIdNo,
    required String passportNo,
    required DateTime? emiratesIdExpiry,
    required DateTime? passportExpiry,
  }) =>
      Landlord(
        id: id,
        name: name,
        phone: phone,
        email: email,
        language: language,
        emiratesIdNo: emiratesIdNo,
        passportNo: passportNo,
        emiratesIdExpiry: emiratesIdExpiry,
        passportExpiry: passportExpiry,
      );

  Landlord copyWith({String? name, String? phone, String? email, String? language, String? emiratesIdNo, String? passportNo}) =>
      Landlord(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        language: language ?? this.language,
        emiratesIdNo: emiratesIdNo ?? this.emiratesIdNo,
        passportNo: passportNo ?? this.passportNo,
        emiratesIdExpiry: emiratesIdExpiry,
        passportExpiry: passportExpiry,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'language': language,
        'emiratesIdNo': emiratesIdNo,
        'passportNo': passportNo,
        'emiratesIdExpiry': dateKey(emiratesIdExpiry),
        'passportExpiry': dateKey(passportExpiry),
      };

  factory Landlord.fromMap(Map<String, dynamic> m) => Landlord(
        id: m['id'] as String,
        name: '${m['name'] ?? ''}',
        phone: '${m['phone'] ?? ''}',
        email: '${m['email'] ?? ''}',
        language: '${m['language'] ?? 'en'}',
        emiratesIdNo: '${m['emiratesIdNo'] ?? ''}',
        passportNo: '${m['passportNo'] ?? ''}',
        emiratesIdExpiry: parseDate(m['emiratesIdExpiry']),
        passportExpiry: parseDate(m['passportExpiry']),
      );
}
