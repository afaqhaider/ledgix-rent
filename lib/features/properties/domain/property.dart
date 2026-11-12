import '../../../core/domain/entity.dart';

enum PropertyType { villa, apartment, studio, other }

enum PaidBy { landlord, tenant }

class PropertyDocument {
  const PropertyDocument({required this.name, required this.url, this.kind = 'other'});
  final String name, url;

  /// lease, ejari, titleDeed, emiratesId, other
  final String kind;

  Map<String, dynamic> toMap() => {'name': name, 'url': url, 'kind': kind};
  factory PropertyDocument.fromMap(Map<String, dynamic> m) => PropertyDocument(
      name: '${m['name']}', url: '${m['url']}', kind: '${m['kind'] ?? 'other'}');
}

class Property implements Entity {
  const Property({
    required this.id,
    required this.landlordId,
    required this.name,
    this.type = PropertyType.apartment,
    this.address = '',
    this.community = '',
    this.titleDeedNo = '',
    this.dewaAccountNo = '',
    this.documents = const [],
    this.isJointlyOwned = false,
    this.mollakUnitRef = '',
    this.chillerProvider = '',
    this.chillerAccountNo = '',
    this.defaultVendorId,
    this.utilityPaidBy = PaidBy.tenant,
  });

  @override
  final String id;
  final String landlordId, name, address, community, titleDeedNo, dewaAccountNo;
  final PropertyType type;
  final List<PropertyDocument> documents;
  final bool isJointlyOwned;
  final String mollakUnitRef, chillerProvider, chillerAccountNo;
  final String? defaultVendorId;

  /// Who pays utility bills for this unit.
  final PaidBy utilityPaidBy;

  Property copyWith({List<PropertyDocument>? documents, PaidBy? utilityPaidBy, String? defaultVendorId}) => Property(
        id: id,
        landlordId: landlordId,
        name: name,
        type: type,
        address: address,
        community: community,
        titleDeedNo: titleDeedNo,
        dewaAccountNo: dewaAccountNo,
        documents: documents ?? this.documents,
        isJointlyOwned: isJointlyOwned,
        mollakUnitRef: mollakUnitRef,
        chillerProvider: chillerProvider,
        chillerAccountNo: chillerAccountNo,
        defaultVendorId: defaultVendorId ?? this.defaultVendorId,
        utilityPaidBy: utilityPaidBy ?? this.utilityPaidBy,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'landlordId': landlordId,
        'name': name,
        'type': type.name,
        'address': address,
        'community': community,
        'titleDeedNo': titleDeedNo,
        'dewaAccountNo': dewaAccountNo,
        'documents': documents.map((d) => d.toMap()).toList(),
        'isJointlyOwned': isJointlyOwned,
        'mollakUnitRef': mollakUnitRef,
        'chillerProvider': chillerProvider,
        'chillerAccountNo': chillerAccountNo,
        'defaultVendorId': defaultVendorId,
        'utilityPaidBy': utilityPaidBy.name,
      };

  factory Property.fromMap(Map<String, dynamic> m) => Property(
        id: m['id'] as String,
        landlordId: '${m['landlordId'] ?? ''}',
        name: '${m['name'] ?? ''}',
        type: enumByName(PropertyType.values, m['type'], PropertyType.other),
        address: '${m['address'] ?? ''}',
        community: '${m['community'] ?? ''}',
        titleDeedNo: '${m['titleDeedNo'] ?? ''}',
        dewaAccountNo: '${m['dewaAccountNo'] ?? ''}',
        documents: [
          for (final d in (m['documents'] as List? ?? const []))
            PropertyDocument.fromMap(Map<String, dynamic>.from(d as Map))
        ],
        isJointlyOwned: m['isJointlyOwned'] == true,
        mollakUnitRef: '${m['mollakUnitRef'] ?? ''}',
        chillerProvider: '${m['chillerProvider'] ?? ''}',
        chillerAccountNo: '${m['chillerAccountNo'] ?? ''}',
        defaultVendorId: m['defaultVendorId'] as String?,
        utilityPaidBy: enumByName(PaidBy.values, m['utilityPaidBy'], PaidBy.tenant),
      );
}
