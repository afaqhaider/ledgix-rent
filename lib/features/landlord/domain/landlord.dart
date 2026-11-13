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
  });

  @override
  final String id;
  final String name, phone, email, language;

  /// The landlord's own ID numbers. Scans that match them are never treated
  /// as a tenant.
  final String emiratesIdNo, passportNo;

  Landlord copyWith({String? name, String? phone, String? email, String? language, String? emiratesIdNo, String? passportNo}) =>
      Landlord(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        language: language ?? this.language,
        emiratesIdNo: emiratesIdNo ?? this.emiratesIdNo,
        passportNo: passportNo ?? this.passportNo,
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
      };

  factory Landlord.fromMap(Map<String, dynamic> m) => Landlord(
        id: m['id'] as String,
        name: '${m['name'] ?? ''}',
        phone: '${m['phone'] ?? ''}',
        email: '${m['email'] ?? ''}',
        language: '${m['language'] ?? 'en'}',
        emiratesIdNo: '${m['emiratesIdNo'] ?? ''}',
        passportNo: '${m['passportNo'] ?? ''}',
      );
}
