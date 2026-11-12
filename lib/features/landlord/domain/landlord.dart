import '../../../core/domain/entity.dart';

class Landlord implements Entity {
  const Landlord({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.language = 'en',
  });

  @override
  final String id;
  final String name, phone, email, language;

  Landlord copyWith({String? name, String? phone, String? email, String? language}) =>
      Landlord(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        language: language ?? this.language,
      );

  @override
  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'phone': phone, 'email': email, 'language': language};

  factory Landlord.fromMap(Map<String, dynamic> m) => Landlord(
        id: m['id'] as String,
        name: (m['name'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        email: (m['email'] ?? '') as String,
        language: (m['language'] ?? 'en') as String,
      );
}
