import '../../../core/providers.dart' show demoRepo;
import '../../account/data/account_repository.dart';
import '../../account/domain/app_user.dart';
import '../../auth/data/demo_auth_repository.dart';
import '../../documents/domain/app_document.dart';
import '../../landlord/domain/landlord.dart';
import '../../leases/domain/lease.dart';
import '../../payments/domain/payment.dart';
import '../../properties/domain/property.dart';
import '../../tenants/domain/tenant.dart';
import 'tenant_portal.dart';

/// Demo mode only (`?demo=tenant` on the web demo build): a sample landlord
/// with one current and one ended tenancy, joined by the demo tenant, so the
/// tenant app can be previewed without a backend. All data is made up.
Future<void> seedTenantDemo(DemoAuthRepository auth) async {
  const ll = 'demo-landlord-xyz', ll2 = 'demo-landlord-old';
  final now = DateTime.now();
  Future<String> landlord(String id, String name, String property, {required bool ended}) async {
    await demoRepo<Landlord>(id, 'profile').save(Landlord(
        id: id, name: name, email: '$id@example.com', phone: '050 000 0000', emiratesIdNo: '784-1970-0000000-1'));
    await demoRepo<Property>(id, 'properties').save(Property(
      id: '$id-p',
      landlordId: id,
      name: property,
      type: PropertyType.apartment,
      address: 'Sample Tower, Dubai Marina',
      community: 'Dubai Marina',
      dewaPremiseNo: '000000000',
      dewaAccountNo: '0000000000',
      hoaName: 'Sample Owners Association',
      hoaPhone: '04 000 0000',
      documents: const [
        AppDocument(name: 'Title deed', url: 'https://example.com/title-deed.pdf', kind: DocumentKinds.titleDeed, sharedWithTenant: true),
        AppDocument(name: 'DEWA bill', url: 'https://example.com/dewa.pdf', kind: DocumentKinds.dewaBill, sharedWithTenant: true),
      ],
    ));
    await demoRepo<Tenant>(id, 'tenants').save(Tenant(id: '$id-t', firstName: 'Sample', lastName: 'Tenant', phone: '050 111 1111'));
    final start = ended ? DateTime(now.year - 2, 1, 1) : DateTime(now.year, 1, 1);
    final end = ended ? DateTime(now.year - 1, 12, 31) : DateTime(now.year + 1, 12, 31);
    await demoRepo<Lease>(id, 'leases').save(Lease(
      id: '$id-l',
      propertyId: '$id-p',
      tenantId: '$id-t',
      startDate: start,
      endDate: end,
      annualRent: ended ? 85000 : 120000,
      securityDeposit: 6000,
      ejariNo: '0000000000000000',
      numberOfCheques: 2,
      documents: const [
        AppDocument(name: 'Ejari', url: 'https://example.com/ejari.pdf', kind: DocumentKinds.ejari, sharedWithTenant: true),
      ],
    ));
    if (!ended) {
      for (final (i, days, status) in [(1, -120, PaymentStatus.cleared), (2, 12, PaymentStatus.pending)]) {
        await demoRepo<Payment>(id, 'payments').save(Payment(
          id: '$id-pay$i',
          leaseId: '$id-l',
          type: PaymentMethod.cheque,
          amount: 60000,
          dueDate: now.add(Duration(days: days)),
          chequeNo: '00000$i',
          bankName: 'Sample Bank',
          status: status,
          imageUrl: 'https://example.com/cheque$i.jpg',
        ));
      }
    }
    return (await DemoTenantPortal().createInvite(landlordUid: id, tenantId: '$id-t')).code;
  }

  final code1 = await landlord(ll, 'Mr XYZ', 'Marina Heights 1203', ended: false);
  final code2 = await landlord(ll2, 'Ms Former', 'Old Villa 7', ended: true);
  await auth.signInWithEmail('tenant@demo', '');
  final uid = auth.currentUserId!;
  await DemoTenantPortal().redeem(tenantUid: uid, code: code1);
  await DemoTenantPortal().redeem(tenantUid: uid, code: code2);
  await InMemoryAccountRepository().save(AppUser(id: uid, role: UserRole.tenant, name: 'Sample Tenant'));
}
