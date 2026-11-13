import '../../../core/domain/entity.dart';
import '../../documents/domain/app_document.dart';
import '../../documents/domain/form_fill.dart';

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
    this.documents = const [],
  })  : firstName = firstName.isNotEmpty || lastName.isNotEmpty ? firstName : splitName(name).first,
        middleName = firstName.isNotEmpty || lastName.isNotEmpty ? middleName : splitName(name).middle,
        lastName = firstName.isNotEmpty || lastName.isNotEmpty ? lastName : splitName(name).last;

  @override
  final String id;
  final String firstName, middleName, lastName, phone, email, emiratesIdNo, passportNo;
  final List<AppDocument> documents;

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
        'documents': documents.map((d) => d.toMap()).toList(),
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
      documents: [...docs, ...legacy],
    );
  }
}
