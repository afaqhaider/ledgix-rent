import '../../../core/domain/entity.dart';
import '../../documents/domain/app_document.dart';

export '../../documents/domain/app_document.dart';

enum PropertyType { villa, apartment, studio, other }

enum PaidBy { landlord, tenant }

/// Kept as an alias: property documents are now [AppDocument]s.
typedef PropertyDocument = AppDocument;

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
    this.dewaPremiseNo = '',
    this.hoaName = '',
    this.hoaPhone = '',
    this.ownerEmiratesIdNo = '',
    this.ownerPassportNo = '',
    this.annualRent,
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
  final String dewaPremiseNo, hoaName, hoaPhone, ownerEmiratesIdNo, ownerPassportNo;

  /// Expected annual rent for the unit (the agreement holds the actual figure).
  final double? annualRent;
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
        dewaPremiseNo: dewaPremiseNo,
        hoaName: hoaName,
        hoaPhone: hoaPhone,
        ownerEmiratesIdNo: ownerEmiratesIdNo,
        ownerPassportNo: ownerPassportNo,
        annualRent: annualRent,
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
        'dewaPremiseNo': dewaPremiseNo,
        'hoaName': hoaName,
        'hoaPhone': hoaPhone,
        'ownerEmiratesIdNo': ownerEmiratesIdNo,
        'ownerPassportNo': ownerPassportNo,
        'annualRent': annualRent,
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
        dewaPremiseNo: '${m['dewaPremiseNo'] ?? ''}',
        hoaName: '${m['hoaName'] ?? ''}',
        hoaPhone: '${m['hoaPhone'] ?? ''}',
        ownerEmiratesIdNo: '${m['ownerEmiratesIdNo'] ?? ''}',
        ownerPassportNo: '${m['ownerPassportNo'] ?? ''}',
        annualRent: (m['annualRent'] as num?)?.toDouble(),
        documents: AppDocument.listFrom(m['documents']),
        isJointlyOwned: m['isJointlyOwned'] == true,
        mollakUnitRef: '${m['mollakUnitRef'] ?? ''}',
        chillerProvider: '${m['chillerProvider'] ?? ''}',
        chillerAccountNo: '${m['chillerAccountNo'] ?? ''}',
        defaultVendorId: m['defaultVendorId'] as String?,
        utilityPaidBy: enumByName(PaidBy.values, m['utilityPaidBy'], PaidBy.tenant),
      );
}
