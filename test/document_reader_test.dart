import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/features/documents/domain/document_reader.dart';
import 'package:ledgix_rent/features/documents/domain/form_fill.dart';
import 'package:ledgix_rent/features/documents/domain/scanned_document.dart';
import 'package:ledgix_rent/features/documents/domain/text_layout.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';

// All names and numbers below are made up. Rows mimic what OCR returns: pieces
// side by side on the page are separated by two spaces; Arabic comes back as
// noise, simulated with "xx".

const _dewaBill = [
  'Government of Dubai  Dubai Electricity & Water Authority',
  'Green Bill  Invoice: 100000000001',
  'Tax Invoice  Issue Date:01/02/2026',
  '2099999999',
  'Account Number',
  'This number can be used for EasyPay',
  'Account Type',
  'Residential',
  'Business Partner',
  '10000001',
  'JOHN SAMPLE TESTER',
  'BLDG.A1 FLAT-101',
  'Premise Number: 600000001',
  'Premise Type: RESIDENTIAL - FLAT',
  'Total Due(incl. VAT)  1,234.00 AED',
];

const _ejari = [
  'TENANCY CONTRACT INFORMATION REGISTRATION CERTIFICATE',
  'Contract No: 0120260101000001 (v. 1)  Registration Date: 01-01-2026',
  'Owner  xxxx',
  'Owner Name  JANE OWNER SAMPLE  xx xxx',
  'Owner Number  12345  xxx',
  'Nationality  Testland  xxx',
  'Property Management  xxxx',
  'Property Management Name  SAMPLE BROKER LLC',
  'Tenancy Contract Details  xxxx',
  'Start Date  01-03-2026  xx  End Date  28-02-2027  xx',
  'Grace Start Date  xx  Grace End Date  xx',
  'Discount  0.00 AED  xx  Security Deposit  3,000.00 AED  xx',
  'Contract Amount  60,000.00 AED  xx  Annual Amount  60,000.00 AED  xx',
  'Actual Contract Amount  60,000.00 AED  Actual Annual Amount  60,000.00 AED',
  'Tenant  xxxx',
  'Tenant Name  ALEX TENANT EXAMPLE  xx',
  'Tenant No  0400000000000001  xx  Nationality  Testland',
  'Passport/Expiry  X1234567 / 01-01-2030  xx  Emirates ID  784200012345678  xx',
  'Visa No & Expiry  20100000000000 / 01-01-2027  Mobile No  0501234567',
  'Leased Unit  (Unit)  xxxx',
  'Building Name/No  T-01  xx',
  'Land Area  Test Gardens  xx  Plot Number  100-0  xx',
  'Property No.(s) / xx  Type / xx  SubType / xx  Usage / xx  Size / xx  DEWA Premise No. / xx',
  '305  Flat  Studio  Residential  40.00 (Sq.m)  600000002',
];

const _contract = [
  'Date  01/01/2026  TENANCY CONTRACT',
  'Owner / Lessor Information  xxxx',
  "Owner's Name  MS JANE OWNER SAMPLE  xx",
  "Lessor's Name  MS JANE OWNER SAMPLE  xx",
  "Lessor's Emirates ID  784-1970-1111111-1  xx",
  "Lessor's Email  OWNER@EXAMPLE.COM  xx",
  "Lessor's Phone  04-0000000",
  'Tenant Information  xxxx',
  "Tenant's Name  ALEX TENANT EXAMPLE  xx",
  "Tenant's Emirates ID  784-1990-2222222-2  xx",
  'License No.  xx  Licensing Authority',
  "Tenant's Email  ALEX@EXAMPLE.COM  xx",
  "Tenant's Phone  050-1234567  xx",
  'Property Information  xxxx',
  'Plot No.  100  xx  Makani No.  xx',
  'Building Name  T-01 TEST CLUSTER  xx  Property No.  305  xx',
  'Property Type  STUDIO  xx  Property Area (s.m)  40.00',
  'Location  TEST GARDENS  xx  Premises No. (DEWA)  600000002',
  'Contract Information  xxxx',
  '01/03/2026  28/02/2027',
  'Contract Period  xx  Contract Value  AED 60,000/- ONE YEAR',
  'Annual Rent  AED 60,000/- ONE YEAR  xx  Security Deposit Amount  3,000 REFUNDABLE',
  'Mode of Payment  PAYMENT BY 4 CHEQUES ONLY',
  'Terms and Conditions  xxxx',
];

const _titleDeed = [
  'xxxx',
  'Title Deed',
  'Issue Date  01/02/2026  xx',
  'Mortgage Status:  Not mortgaged  xx',
  'Property Type:  Flat  xx',
  'Community:  Test Gardens  xx',
  'Plot No:  100  xx',
  'Municipality No:  600 - 1000  xx',
  'Building No:  1  xx',
  'Building Name:  T-01  xx',
  'Property No:  G05  xx',
  'Floor No:  G  xx',
  'Area Sq Meter :  80  xx',
  'Owners numbers and their shares:  Area (Sq Meter)  xx',
  '(1234567) JANE OWNER  80  xx',
  'SAMPLE',
  'Purchased from SOMEONE ELSE by the Land Registration No. : 10000/2026',
  '20001/2026',
  'R.T. Centre No. 1/1',
];

void main() {
  const reader = DocumentReader();

  test('rebuilds printed rows from OCR line positions', () {
    final rows = rowsFromLines(const [
      OcrLine('419', 300, 101, 330, 115),
      OcrLine('Plot No:', 20, 100, 90, 116),
      OcrLine('Building Name:', 20, 130, 120, 146),
      OcrLine('T-01', 300, 131, 340, 145),
    ]);
    expect(rows, ['Plot No:  419', 'Building Name:  T-01']);
  });

  test('classifies each document type', () {
    expect(reader.classify(_dewaBill), ScannedKind.dewaBill);
    expect(reader.classify(_ejari), ScannedKind.ejari);
    expect(reader.classify(_contract), ScannedKind.tenancyContract);
    expect(reader.classify(_titleDeed), ScannedKind.titleDeed);
    expect(reader.classify(['UNITED ARAB EMIRATES', 'Resident Identity Card', 'ID Number  784-1990-2222222-2', 'Name: Alex Tenant']),
        ScannedKind.emiratesId);
    expect(reader.classify(['P<TSTEXAMPLE<<ALEX<TENANT<<<<<<<<<<<<<<<<<<<<<', 'X1234567<3TST9001011M3001014<<<<<<<<<<<<<<02']),
        ScannedKind.passport);
    expect(reader.classify(['Some shopping receipt', 'Total 12.00']), ScannedKind.unknown);
  });

  test('DEWA bill: premise and account numbers', () {
    final d = reader.read(_dewaBill);
    expect(d[ScanField.dewaPremiseNo], '600000001');
    expect(d[ScanField.dewaAccountNo], '2099999999');
    expect(propertyTypeFrom(d[ScanField.propertyType]), PropertyType.apartment);
  });

  test('Ejari: owner, tenant, unit and contract sections go to the right fields', () {
    final d = reader.read(_ejari);
    expect(d[ScanField.ejariNo], '0120260101000001');
    expect(d[ScanField.ownerName], 'JANE OWNER SAMPLE');
    expect(d[ScanField.startDate], '2026-03-01');
    expect(d[ScanField.endDate], '2027-02-28');
    expect(d[ScanField.annualRent], '60000');
    expect(d[ScanField.securityDeposit], '3000');
    expect(d[ScanField.tenantName], 'ALEX TENANT EXAMPLE');
    expect(d[ScanField.tenantEmiratesId], '784-2000-1234567-8');
    expect(d[ScanField.tenantPassport], 'X1234567');
    expect(d[ScanField.tenantPhone], '0501234567');
    expect(d[ScanField.buildingName], 'T-01');
    expect(d[ScanField.community], 'Test Gardens');
    expect(d[ScanField.plotNo], '100-0');
    expect(d[ScanField.unitNo], '305');
    expect(d[ScanField.dewaPremiseNo], '600000002');
    expect(propertyTypeFrom(d[ScanField.propertyType]), PropertyType.studio);
    // The owner never lands in tenant fields.
    expect(tenantValues(d)[FormKeys.firstName], 'Alex');
  });

  test('Tenancy contract: lessor -> owner, tenant -> tenant, contract terms', () {
    final d = reader.read(_contract);
    expect(d[ScanField.ownerName], 'MS JANE OWNER SAMPLE');
    expect(d[ScanField.ownerEmiratesId], '784-1970-1111111-1');
    expect(d[ScanField.ownerEmail], 'owner@example.com');
    expect(d[ScanField.tenantName], 'ALEX TENANT EXAMPLE');
    expect(d[ScanField.tenantEmiratesId], '784-1990-2222222-2');
    expect(d[ScanField.tenantEmail], 'alex@example.com');
    expect(d[ScanField.tenantPhone], '0501234567');
    expect(d[ScanField.plotNo], '100');
    expect(d[ScanField.buildingName], 'T-01 TEST CLUSTER');
    expect(d[ScanField.unitNo], '305');
    expect(d[ScanField.community], 'TEST GARDENS');
    expect(d[ScanField.dewaPremiseNo], '600000002');
    expect(d[ScanField.startDate], '2026-03-01');
    expect(d[ScanField.endDate], '2027-02-28');
    expect(d[ScanField.annualRent], '60000');
    expect(d[ScanField.securityDeposit], '3000');
    expect(d[ScanField.numberOfCheques], '4');

    final p = propertyValues(d);
    expect(p[FormKeys.ownerEid], '784-1970-1111111-1');
    expect(p[FormKeys.dewaPremise], '600000002');
    expect(p[FormKeys.type], PropertyType.studio.name);
    final a = agreementValues(d);
    expect(a[FormKeys.cheques], '4');
    expect(a[FormKeys.annualRent], '60000');
  });

  test('Title deed: deed number, unit and owner', () {
    final d = reader.read(_titleDeed);
    expect(d[ScanField.titleDeedNo], '20001/2026');
    expect(d[ScanField.community], 'Test Gardens');
    expect(d[ScanField.plotNo], '100');
    expect(d[ScanField.buildingName], 'T-01');
    expect(d[ScanField.unitNo], 'G05');
    expect(d[ScanField.ownerName], 'JANE OWNER SAMPLE');
    expect(propertyTypeFrom(d[ScanField.propertyType]), PropertyType.apartment);
  });

  test('Emirates ID card and passport MRZ', () {
    final id = reader.read(['UNITED ARAB EMIRATES', 'Resident Identity Card', 'ID Number  784 1990 2222222 2', 'Name: Alex Tenant Example']);
    expect(id[ScanField.personEmiratesId], '784-1990-2222222-2');
    expect(id[ScanField.personName], 'Alex Tenant Example');

    final p = reader.read(['PASSPORT', 'P<TSTEXAMPLE<<ALEX<TENANT<<<<<<<<<<<<<<<<<<<<<', 'X1234567<3TST9001011M3001014<<<<<<<<<<<<<<02']);
    expect(p[ScanField.personPassport], 'X1234567');
    expect(p[ScanField.personName], 'ALEX TENANT EXAMPLE');
    final t = tenantValues(p);
    expect(t[FormKeys.firstName], 'Alex');
    expect(t[FormKeys.middleName], 'Tenant');
    expect(t[FormKeys.lastName], 'Example');
    expect(t[FormKeys.passport], 'X1234567');
  });

  group('landlord\'s own ID is never taken as a tenant', () {
    test('matches regardless of dashes and spaces', () {
      final own = OwnIdentity(['784-1990-2222222-2', '']);
      expect(own.matches('784199022222222'), isTrue);
      expect(own.matches('784 1990 2222222 2'), isTrue);
      expect(own.matches('784-1990-2222222-3'), isFalse);
    });

    test('Ejari where the landlord is the tenant is flagged', () {
      final d = reader.read(_ejari);
      expect(isLandlordsOwnId(d, OwnIdentity(['784-2000-1234567-8'])), isTrue);
      expect(isLandlordsOwnId(d, OwnIdentity(['784-1970-1111111-1'])), isFalse);
    });

    test('own Emirates ID card or passport is flagged', () {
      final id = reader.read(['Resident Identity Card', 'ID Number  784-1985-3333333-3', 'Name: Me Landlord']);
      expect(isLandlordsOwnId(id, OwnIdentity(['784198533333333'])), isTrue);
      final pp = reader.read(['P<TSTLANDLORD<<ME<<<<<<<<<<<<<<<<<<<<<<<<<<<<<', 'Y7654321<3TST8501011M3001014<<<<<<<<<<<<<<02']);
      expect(isLandlordsOwnId(pp, OwnIdentity(['y7654321'])), isTrue);
    });
  });

  test('names are tidied and split', () {
    expect(tidyName('MS JANE  OWNER'), 'Jane Owner');
    final n = splitName('alex tenant middle example');
    expect(n.first, 'Alex');
    expect(n.middle, 'Tenant Middle');
    expect(n.last, 'Example');
  });
}
