import '../../properties/domain/property.dart';
import 'scanned_document.dart';

/// Digits and letters only, upper case: "784-1987-…" and "7841987…" compare equal.
String normalizeId(String s) => s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// The landlord's own identity numbers, from their profile and the owner
/// details on their properties.
class OwnIdentity {
  OwnIdentity(Iterable<String> ids) : ids = {for (final i in ids) if (normalizeId(i).length >= 6) normalizeId(i)};
  final Set<String> ids;

  bool matches(String? id) => id != null && ids.contains(normalizeId(id));
}

/// Tenant-side identity numbers in a scanned document: the tenant section of
/// an Ejari/contract, or the holder of a standalone ID card / passport.
List<String> tenantIds(ScannedDocument d) => [
      for (final f in const [ScanField.tenantEmiratesId, ScanField.tenantPassport, ScanField.personEmiratesId, ScanField.personPassport])
        if (d[f] != null) d[f]!,
    ];

/// True when the "tenant" in [d] is actually the landlord.
bool isLandlordsOwnId(ScannedDocument d, OwnIdentity own) => tenantIds(d).any(own.matches);

/// "SYED  ali  KHAN" -> "Syed Ali Khan"; drops Mr/Ms/Mrs/Miss prefixes.
String tidyName(String raw) {
  final words = raw
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList();
  while (words.isNotEmpty && RegExp(r'^(mr|ms|mrs|miss|dr)\.?$', caseSensitive: false).hasMatch(words.first)) {
    words.removeAt(0);
  }
  return words.map((w) => w == w.toUpperCase() || w == w.toLowerCase() ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : w).join(' ');
}

/// Splits a full name into first, middle and last.
({String first, String middle, String last}) splitName(String full) {
  final w = tidyName(full).split(' ').where((s) => s.isNotEmpty).toList();
  if (w.isEmpty) return (first: '', middle: '', last: '');
  if (w.length == 1) return (first: w.first, middle: '', last: '');
  return (first: w.first, middle: w.sublist(1, w.length - 1).join(' '), last: w.last);
}

PropertyType? propertyTypeFrom(String? raw) {
  final s = (raw ?? '').toLowerCase();
  if (s.contains('studio')) return PropertyType.studio;
  if (s.contains('villa') || s.contains('townhouse')) return PropertyType.villa;
  if (s.contains('flat') || s.contains('apartment')) return PropertyType.apartment;
  return s.isEmpty ? null : PropertyType.other;
}

/// Form field keys used by the Property, Tenant and Rent Agreement forms.
abstract final class FormKeys {
  // property
  static const type = 'type', name = 'name', address = 'address', community = 'community';
  static const dewaPremise = 'dewaPremise', dewaAccount = 'dewaAccount', mollak = 'mollak';
  static const titleDeed = 'titleDeed', ownerEid = 'ownerEid', ownerPassport = 'ownerPassport';
  static const ownerEidExpiry = 'ownerEidExpiry', ownerPassportExpiry = 'ownerPassportExpiry';
  static const annualRent = 'annualRent';
  // tenant
  static const firstName = 'firstName', middleName = 'middleName', lastName = 'lastName';
  static const email = 'email', phone = 'phone', emiratesId = 'emiratesId', passport = 'passport';
  static const eidExpiry = 'eidExpiry', passportExpiry = 'passportExpiry';
  // agreement
  static const ejariNo = 'ejariNo', start = 'start', end = 'end', deposit = 'deposit', cheques = 'cheques';
}

/// Property form values from a scan. Owner fields come from the owner/lessor
/// section; a standalone ID card or passport scanned here is the owner's.
Map<String, String> propertyValues(ScannedDocument d) {
  final building = d[ScanField.buildingName], unit = d[ScanField.unitNo], community = d[ScanField.community];
  final type = propertyTypeFrom(d[ScanField.propertyType]);
  return {
    if (type != null) FormKeys.type: type.name,
    if (building != null || unit != null) FormKeys.name: [building, unit].whereType<String>().join(' · '),
    if (building != null || community != null)
      FormKeys.address: [
        if (unit != null) 'Unit $unit',
        ?building,
        if (d[ScanField.plotNo] != null) 'Plot ${d[ScanField.plotNo]}',
        ?community,
      ].join(', '),
    if (community != null) FormKeys.community: tidyName(community),
    if (d[ScanField.dewaPremiseNo] != null) FormKeys.dewaPremise: d[ScanField.dewaPremiseNo]!,
    if (d[ScanField.dewaAccountNo] != null) FormKeys.dewaAccount: d[ScanField.dewaAccountNo]!,
    if (d[ScanField.titleDeedNo] != null) FormKeys.titleDeed: d[ScanField.titleDeedNo]!,
    if ((d[ScanField.ownerEmiratesId] ?? d[ScanField.personEmiratesId]) != null)
      FormKeys.ownerEid: (d[ScanField.ownerEmiratesId] ?? d[ScanField.personEmiratesId])!,
    if ((d[ScanField.ownerPassport] ?? d[ScanField.personPassport]) != null)
      FormKeys.ownerPassport: (d[ScanField.ownerPassport] ?? d[ScanField.personPassport])!,
    if (d[ScanField.annualRent] != null) FormKeys.annualRent: d[ScanField.annualRent]!,
    // A standalone ID card or passport scanned on the property form is the owner's.
    if (d[ScanField.personEmiratesIdExpiry] != null) FormKeys.ownerEidExpiry: d[ScanField.personEmiratesIdExpiry]!,
    if (d[ScanField.personPassportExpiry] != null) FormKeys.ownerPassportExpiry: d[ScanField.personPassportExpiry]!,
  };
}

/// Tenant form values from a scan: the tenant section of an Ejari/contract, or
/// the holder of an ID card/passport. Callers must check [isLandlordsOwnId]
/// first and not apply these when it is true.
Map<String, String> tenantValues(ScannedDocument d) {
  final full = d[ScanField.tenantName] ?? d[ScanField.personName];
  final n = full == null ? null : splitName(full);
  final eid = d[ScanField.tenantEmiratesId] ?? d[ScanField.personEmiratesId];
  final passport = d[ScanField.tenantPassport] ?? d[ScanField.personPassport];
  return {
    if (n != null && n.first.isNotEmpty) FormKeys.firstName: n.first,
    if (n != null && n.middle.isNotEmpty) FormKeys.middleName: n.middle,
    if (n != null && n.last.isNotEmpty) FormKeys.lastName: n.last,
    if (d[ScanField.tenantEmail] != null) FormKeys.email: d[ScanField.tenantEmail]!,
    if (d[ScanField.tenantPhone] != null) FormKeys.phone: d[ScanField.tenantPhone]!,
    FormKeys.emiratesId: ?eid,
    FormKeys.passport: ?passport,
    FormKeys.eidExpiry: ?d[ScanField.personEmiratesIdExpiry],
    FormKeys.passportExpiry: ?d[ScanField.personPassportExpiry],
  };
}

/// Agreement form values from an Ejari certificate or tenancy contract.
Map<String, String> agreementValues(ScannedDocument d) => {
      if (d[ScanField.ejariNo] != null) FormKeys.ejariNo: d[ScanField.ejariNo]!,
      if (d[ScanField.startDate] != null) FormKeys.start: d[ScanField.startDate]!,
      if (d[ScanField.endDate] != null) FormKeys.end: d[ScanField.endDate]!,
      if (d[ScanField.annualRent] != null) FormKeys.annualRent: d[ScanField.annualRent]!,
      if (d[ScanField.securityDeposit] != null) FormKeys.deposit: d[ScanField.securityDeposit]!,
      if (d[ScanField.numberOfCheques] != null) FormKeys.cheques: d[ScanField.numberOfCheques]!,
    };

/// Scanned dates (yyyy-MM-dd) for date fields that are still empty. A date
/// already set is never replaced. Keys are [FormKeys].
Map<String, DateTime> newScannedDates(Map<String, String> values, Map<String, DateTime?> current) => {
      for (final e in current.entries)
        if (e.value == null && values[e.key] != null && DateTime.tryParse(values[e.key]!) != null)
          e.key: DateTime.parse(values[e.key]!),
    };
