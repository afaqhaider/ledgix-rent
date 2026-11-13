import 'app_document.dart';

/// What the scanner recognised a document as.
enum ScannedKind { dewaBill, ejari, tenancyContract, titleDeed, emiratesId, passport, unknown }

extension ScannedKindX on ScannedKind {
  /// The matching upload type, so a scanned file can be attached as-is.
  String get documentKind => switch (this) {
        ScannedKind.dewaBill => DocumentKinds.dewaBill,
        ScannedKind.ejari => DocumentKinds.ejari,
        ScannedKind.tenancyContract => DocumentKinds.tenancyContract,
        ScannedKind.titleDeed => DocumentKinds.titleDeed,
        ScannedKind.emiratesId => DocumentKinds.emiratesId,
        ScannedKind.passport => DocumentKinds.passport,
        ScannedKind.unknown => DocumentKinds.other,
      };
}

/// Fields the scanner can pull out, grouped by who they belong to.
enum ScanField {
  // Property / premises
  propertyType,
  buildingName,
  unitNo,
  community,
  plotNo,
  dewaPremiseNo,
  dewaAccountNo,
  titleDeedNo,
  // Owner / lessor
  ownerName,
  ownerEmiratesId,
  ownerPassport,
  ownerPhone,
  ownerEmail,
  // Tenant
  tenantName,
  tenantEmiratesId,
  tenantPassport,
  tenantPhone,
  tenantEmail,
  // Agreement
  ejariNo,
  startDate,
  endDate,
  annualRent,
  securityDeposit,
  numberOfCheques,
  // A standalone ID card or passport: whose it is depends on the form.
  personName,
  personEmiratesId,
  personPassport,
}

/// Result of reading one document. Values are plain strings as printed
/// (dates normalised to yyyy-MM-dd, amounts to plain numbers).
class ScannedDocument {
  const ScannedDocument(this.kind, this.fields);
  final ScannedKind kind;
  final Map<ScanField, String> fields;

  String? operator [](ScanField f) => fields[f];
  bool get isEmpty => fields.isEmpty;
}
