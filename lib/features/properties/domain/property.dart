import '../../../core/domain/entity.dart';
import '../../documents/domain/app_document.dart';
import '../../expenses/domain/service_charge_plan.dart';

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
    this.ownerEmiratesIdExpiry,
    this.ownerPassportExpiry,
    this.annualRent,
    this.documents = const [],
    this.isJointlyOwned = false,
    this.mollakUnitRef = '',
    this.chillerProvider = '',
    this.chillerAccountNo = '',
    this.defaultVendorId,
    this.utilityPaidBy = PaidBy.tenant,
    this.serviceChargeAnnual,
    this.serviceChargeFrequency = ServiceChargeFrequency.quarterly,
    this.serviceChargeNextDue,
    this.serviceChargeNotes = '',
    this.purchasePrice,
  });

  @override
  final String id;
  final String landlordId, name, address, community, titleDeedNo, dewaAccountNo;
  final String dewaPremiseNo, hoaName, hoaPhone, ownerEmiratesIdNo, ownerPassportNo;

  /// Expiry dates of the owner's Emirates ID and passport (optional).
  final DateTime? ownerEmiratesIdExpiry, ownerPassportExpiry;

  /// Expected annual rent for the unit (the agreement holds the actual figure).
  final double? annualRent;
  final PropertyType type;
  final List<PropertyDocument> documents;
  final bool isJointlyOwned;
  final String mollakUnitRef, chillerProvider, chillerAccountNo;
  final String? defaultVendorId;

  /// Who pays utility bills for this unit.
  final PaidBy utilityPaidBy;

  /// Service charges (HOA / developer): annual amount, billing frequency and
  /// the next due date. Instalments are generated as expenses on save.
  final double? serviceChargeAnnual;
  final ServiceChargeFrequency serviceChargeFrequency;
  final DateTime? serviceChargeNextDue;
  final String serviceChargeNotes;

  /// Optional, for net yield in the profitability report.
  final double? purchasePrice;

  /// The service-charge plan, when an amount and next due date are set.
  ServiceChargePlan? get serviceChargePlan => serviceChargeAnnual == null || serviceChargeAnnual! <= 0 || serviceChargeNextDue == null
      ? null
      : ServiceChargePlan(
          annualAmount: serviceChargeAnnual!,
          frequency: serviceChargeFrequency,
          nextDue: serviceChargeNextDue!,
          payee: hoaName,
          notes: serviceChargeNotes,
        );

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
        ownerEmiratesIdExpiry: ownerEmiratesIdExpiry,
        ownerPassportExpiry: ownerPassportExpiry,
        annualRent: annualRent,
        documents: documents ?? this.documents,
        isJointlyOwned: isJointlyOwned,
        mollakUnitRef: mollakUnitRef,
        chillerProvider: chillerProvider,
        chillerAccountNo: chillerAccountNo,
        defaultVendorId: defaultVendorId ?? this.defaultVendorId,
        utilityPaidBy: utilityPaidBy ?? this.utilityPaidBy,
        serviceChargeAnnual: serviceChargeAnnual,
        serviceChargeFrequency: serviceChargeFrequency,
        serviceChargeNextDue: serviceChargeNextDue,
        serviceChargeNotes: serviceChargeNotes,
        purchasePrice: purchasePrice,
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
        'ownerEmiratesIdExpiry': dateKey(ownerEmiratesIdExpiry),
        'ownerPassportExpiry': dateKey(ownerPassportExpiry),
        'annualRent': annualRent,
        'documents': documents.map((d) => d.toMap()).toList(),
        'isJointlyOwned': isJointlyOwned,
        'mollakUnitRef': mollakUnitRef,
        'chillerProvider': chillerProvider,
        'chillerAccountNo': chillerAccountNo,
        'defaultVendorId': defaultVendorId,
        'utilityPaidBy': utilityPaidBy.name,
        'serviceChargeAnnual': serviceChargeAnnual,
        'serviceChargeFrequency': serviceChargeFrequency.name,
        'serviceChargeNextDue': dateKey(serviceChargeNextDue),
        'serviceChargeNotes': serviceChargeNotes,
        'purchasePrice': purchasePrice,
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
        ownerEmiratesIdExpiry: parseDate(m['ownerEmiratesIdExpiry']),
        ownerPassportExpiry: parseDate(m['ownerPassportExpiry']),
        annualRent: (m['annualRent'] as num?)?.toDouble(),
        documents: AppDocument.listFrom(m['documents']),
        isJointlyOwned: m['isJointlyOwned'] == true,
        mollakUnitRef: '${m['mollakUnitRef'] ?? ''}',
        chillerProvider: '${m['chillerProvider'] ?? ''}',
        chillerAccountNo: '${m['chillerAccountNo'] ?? ''}',
        defaultVendorId: m['defaultVendorId'] as String?,
        utilityPaidBy: enumByName(PaidBy.values, m['utilityPaidBy'], PaidBy.tenant),
        serviceChargeAnnual: (m['serviceChargeAnnual'] as num?)?.toDouble(),
        serviceChargeFrequency:
            enumByName(ServiceChargeFrequency.values, m['serviceChargeFrequency'], ServiceChargeFrequency.quarterly),
        serviceChargeNextDue: parseDate(m['serviceChargeNextDue']),
        serviceChargeNotes: '${m['serviceChargeNotes'] ?? ''}',
        purchasePrice: (m['purchasePrice'] as num?)?.toDouble(),
      );
}
