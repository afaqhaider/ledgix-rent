/// A file attached to a property, tenant or rent agreement.
///
/// [kind] is one of the [DocumentKinds] ids. Older records used
/// `lease` and `emiratesId`; they still load.
class AppDocument {
  const AppDocument({required this.name, required this.url, this.kind = DocumentKinds.other, this.sharedWithTenant = false});
  final String name, url;
  final String kind;

  /// Visible to the linked tenant in their app (off unless the landlord shares it).
  final bool sharedWithTenant;

  AppDocument withShared(bool shared) => AppDocument(name: name, url: url, kind: kind, sharedWithTenant: shared);

  Map<String, dynamic> toMap() => {'name': name, 'url': url, 'kind': kind, 'shared': sharedWithTenant};
  factory AppDocument.fromMap(Map<String, dynamic> m) => AppDocument(
        name: '${m['name'] ?? ''}',
        url: '${m['url'] ?? ''}',
        kind: '${m['kind'] ?? DocumentKinds.other}',
        sharedWithTenant: m['shared'] == true,
      );

  static List<AppDocument> listFrom(Object? raw) => [
        for (final d in (raw as List? ?? const []))
          if (d is Map) AppDocument.fromMap(Map<String, dynamic>.from(d)),
      ];
}

/// Document type ids, shared by the upload dropdowns and the scanner.
abstract final class DocumentKinds {
  static const dewaBill = 'dewaBill';
  static const titleDeed = 'titleDeed';
  static const ownerEmiratesId = 'ownerEmiratesId';
  static const ownerPassport = 'ownerPassport';
  static const mollak = 'mollak';
  static const ejari = 'ejari';
  static const tenancyContract = 'tenancyContract';
  static const emiratesId = 'emiratesId'; // tenant's Emirates ID (and legacy property docs)
  static const passport = 'passport'; // tenant's passport
  static const lease = 'lease'; // legacy
  static const other = 'other';

  static const property = [dewaBill, titleDeed, ownerEmiratesId, ownerPassport, mollak, ejari, tenancyContract, other];
  static const tenant = [emiratesId, passport, other];
  static const agreement = [ejari, tenancyContract, other];

  /// Documents that must be attached before saving.
  static const propertyRequired = {titleDeed};
  static const tenantRequired = {emiratesId};
  static const agreementRequired = <String>{};
}
