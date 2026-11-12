import '../../../core/domain/entity.dart';

class Tenant implements Entity {
  const Tenant({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.emiratesIdNo = '',
    this.passportCopyUrl,
    this.emiratesIdCopyUrl,
  });

  @override
  final String id;
  final String name, phone, email, emiratesIdNo;
  final String? passportCopyUrl, emiratesIdCopyUrl;

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'emiratesIdNo': emiratesIdNo,
        'passportCopyUrl': passportCopyUrl,
        'emiratesIdCopyUrl': emiratesIdCopyUrl,
      };

  factory Tenant.fromMap(Map<String, dynamic> m) => Tenant(
        id: m['id'] as String,
        name: '${m['name'] ?? ''}',
        phone: '${m['phone'] ?? ''}',
        email: '${m['email'] ?? ''}',
        emiratesIdNo: '${m['emiratesIdNo'] ?? ''}',
        passportCopyUrl: m['passportCopyUrl'] as String?,
        emiratesIdCopyUrl: m['emiratesIdCopyUrl'] as String?,
      );
}
