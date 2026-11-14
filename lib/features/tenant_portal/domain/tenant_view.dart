import '../../../core/domain/entity.dart';
import '../../holds/domain/hold_request.dart';
import '../../landlord/domain/landlord.dart';
import '../../leases/domain/lease.dart';
import '../../payments/domain/payment.dart';
import '../../properties/domain/property.dart';
import '../../tenants/domain/tenant.dart';

/// What a tenant can see of one landlord's data. In production this read
/// model lives at `tenantViews/{tenantUid}/{collection}/{id}` and is kept up to
/// date by Cloud Functions (functions/src/tenants.ts mirrors [buildTenantView]);
/// in demo mode it is computed on the fly.

enum LinkStatus { active, former }

/// `tenantLinks/{tenantUid}/landlords/{landlordUid}`.
class TenantLink {
  const TenantLink({required this.landlordUid, required this.status, this.tenantIds = const [], this.since, this.endedAt});
  final String landlordUid;
  final LinkStatus status;
  final List<String> tenantIds;
  final DateTime? since, endedAt;

  Map<String, dynamic> toMap() => {
        'landlordUid': landlordUid,
        'status': status.name,
        'tenantIds': tenantIds,
        'since': since?.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
      };

  factory TenantLink.fromMap(Map<String, dynamic> m) => TenantLink(
        landlordUid: '${m['landlordUid']}',
        status: enumByName(LinkStatus.values, m['status'], LinkStatus.active),
        tenantIds: [for (final t in (m['tenantIds'] as List? ?? const [])) '$t'],
        since: _date(m['since']),
        endedAt: _date(m['endedAt']),
      );
}

/// Firestore Timestamps (from the backend) or ISO strings.
DateTime? _date(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  try {
    final dynamic d = v;
    if (v is! String && v is! num) return (d.toDate() as DateTime);
  } catch (_) {}
  return parseDate(v);
}

double _num(Object? v) => (v as num?)?.toDouble() ?? 0;

/// Landlord details shown to their tenants.
class TvLandlord {
  const TvLandlord({
    required this.landlordUid,
    required this.name,
    this.email = '',
    this.phone = '',
    this.emiratesIdNo = '',
    this.status = LinkStatus.active,
    this.since,
  });
  final String landlordUid, name, email, phone, emiratesIdNo;
  final LinkStatus status;
  final DateTime? since;

  Map<String, dynamic> toMap() => {
        'landlordUid': landlordUid,
        'name': name,
        'email': email,
        'phone': phone,
        'emiratesIdNo': emiratesIdNo,
        'status': status.name,
        'since': since?.toIso8601String(),
      };

  factory TvLandlord.fromMap(Map<String, dynamic> m) => TvLandlord(
        landlordUid: '${m['landlordUid']}',
        name: '${m['name'] ?? ''}',
        email: '${m['email'] ?? ''}',
        phone: '${m['phone'] ?? ''}',
        emiratesIdNo: '${m['emiratesIdNo'] ?? ''}',
        status: enumByName(LinkStatus.values, m['status'], LinkStatus.active),
        since: _date(m['since']),
      );
}

class TvProperty {
  const TvProperty({
    required this.landlordUid,
    required this.id,
    required this.name,
    this.type = '',
    this.address = '',
    this.community = '',
    this.titleDeedNo = '',
    this.dewaPremiseNo = '',
    this.dewaAccountNo = '',
    this.mollakUnitRef = '',
    this.hoaName = '',
    this.hoaPhone = '',
    this.agreementAmount,
    this.leaseIds = const [],
  });
  final String landlordUid, id, name, type, address, community, titleDeedNo;
  final String dewaPremiseNo, dewaAccountNo, mollakUnitRef, hoaName, hoaPhone;

  /// Annual rent on the tenant's (latest) agreement for this unit.
  final double? agreementAmount;
  final List<String> leaseIds;

  Map<String, dynamic> toMap() => {
        'landlordUid': landlordUid,
        'id': id,
        'name': name,
        'type': type,
        'address': address,
        'community': community,
        'titleDeedNo': titleDeedNo,
        'dewaPremiseNo': dewaPremiseNo,
        'dewaAccountNo': dewaAccountNo,
        'mollakUnitRef': mollakUnitRef,
        'hoaName': hoaName,
        'hoaPhone': hoaPhone,
        'agreementAmount': agreementAmount,
        'leaseIds': leaseIds,
      };

  factory TvProperty.fromMap(Map<String, dynamic> m) => TvProperty(
        landlordUid: '${m['landlordUid']}',
        id: '${m['id']}',
        name: '${m['name'] ?? ''}',
        type: '${m['type'] ?? ''}',
        address: '${m['address'] ?? ''}',
        community: '${m['community'] ?? ''}',
        titleDeedNo: '${m['titleDeedNo'] ?? ''}',
        dewaPremiseNo: '${m['dewaPremiseNo'] ?? ''}',
        dewaAccountNo: '${m['dewaAccountNo'] ?? ''}',
        mollakUnitRef: '${m['mollakUnitRef'] ?? ''}',
        hoaName: '${m['hoaName'] ?? ''}',
        hoaPhone: '${m['hoaPhone'] ?? ''}',
        agreementAmount: (m['agreementAmount'] as num?)?.toDouble(),
        leaseIds: [for (final x in (m['leaseIds'] as List? ?? const [])) '$x'],
      );
}

class TvLease {
  const TvLease({
    required this.landlordUid,
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    required this.startDate,
    required this.endDate,
    required this.annualRent,
    this.securityDeposit = 0,
    this.numberOfCheques = 1,
    this.paymentMethod = 'cheque',
    this.ejariNo = '',
    this.status = 'active',
  });
  final String landlordUid, id, propertyId, propertyName, paymentMethod, ejariNo, status;
  final DateTime startDate, endDate;
  final double annualRent, securityDeposit;
  final int numberOfCheques;

  bool isCurrent(DateTime today) => status == LeaseStatus.active.name && !endDate.isBefore(today);

  Map<String, dynamic> toMap() => {
        'landlordUid': landlordUid,
        'id': id,
        'propertyId': propertyId,
        'propertyName': propertyName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'annualRent': annualRent,
        'securityDeposit': securityDeposit,
        'numberOfCheques': numberOfCheques,
        'paymentMethod': paymentMethod,
        'ejariNo': ejariNo,
        'status': status,
      };

  factory TvLease.fromMap(Map<String, dynamic> m) => TvLease(
        landlordUid: '${m['landlordUid']}',
        id: '${m['id']}',
        propertyId: '${m['propertyId'] ?? ''}',
        propertyName: '${m['propertyName'] ?? ''}',
        startDate: _date(m['startDate']) ?? DateTime(2000),
        endDate: _date(m['endDate']) ?? DateTime(2000),
        annualRent: _num(m['annualRent']),
        securityDeposit: _num(m['securityDeposit']),
        numberOfCheques: (m['numberOfCheques'] as num?)?.toInt() ?? 1,
        paymentMethod: '${m['paymentMethod'] ?? 'cheque'}',
        ejariNo: '${m['ejariNo'] ?? ''}',
        status: '${m['status'] ?? 'active'}',
      );
}

class TvPayment {
  const TvPayment({
    required this.landlordUid,
    required this.id,
    required this.leaseId,
    this.propertyId = '',
    this.propertyName = '',
    this.type = 'cheque',
    required this.amount,
    required this.dueDate,
    this.chequeNo = '',
    this.bankName = '',
    this.status = PaymentStatus.pending,
    this.imageUrl,
  });
  final String landlordUid, id, leaseId, propertyId, propertyName, type, chequeNo, bankName;
  final double amount;
  final DateTime dueDate;
  final PaymentStatus status;

  /// Cheque copy, only when the landlord shares it.
  final String? imageUrl;

  Map<String, dynamic> toMap() => {
        'landlordUid': landlordUid,
        'id': id,
        'leaseId': leaseId,
        'propertyId': propertyId,
        'propertyName': propertyName,
        'type': type,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'chequeNo': chequeNo,
        'bankName': bankName,
        'status': status.name,
        'imageUrl': imageUrl,
      };

  factory TvPayment.fromMap(Map<String, dynamic> m) => TvPayment(
        landlordUid: '${m['landlordUid']}',
        id: '${m['id']}',
        leaseId: '${m['leaseId'] ?? ''}',
        propertyId: '${m['propertyId'] ?? ''}',
        propertyName: '${m['propertyName'] ?? ''}',
        type: '${m['type'] ?? 'cheque'}',
        amount: _num(m['amount']),
        dueDate: _date(m['dueDate']) ?? DateTime(2000),
        chequeNo: '${m['chequeNo'] ?? ''}',
        bankName: '${m['bankName'] ?? ''}',
        status: enumByName(PaymentStatus.values, m['status'], PaymentStatus.pending),
        imageUrl: m['imageUrl'] as String?,
      );
}

/// A tenant's request to hold one of their payments, and the landlord's answer.
class TvHoldRequest {
  const TvHoldRequest({
    required this.landlordUid,
    required this.id,
    required this.paymentId,
    required this.originalDate,
    required this.requestedDate,
    this.reason = '',
    this.note = '',
    this.status = HoldStatus.pending,
    this.response = '',
    this.createdAt,
  });
  final String landlordUid, id, paymentId, reason, note, response;
  final DateTime originalDate, requestedDate;
  final HoldStatus status;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
        'landlordUid': landlordUid,
        'id': id,
        'paymentId': paymentId,
        'originalDate': originalDate.toIso8601String(),
        'requestedDate': requestedDate.toIso8601String(),
        'reason': reason,
        'note': note,
        'status': status.name,
        'response': response,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory TvHoldRequest.fromMap(Map<String, dynamic> m) => TvHoldRequest(
        landlordUid: '${m['landlordUid']}',
        id: '${m['id']}',
        paymentId: '${m['paymentId'] ?? ''}',
        originalDate: _date(m['originalDate']) ?? DateTime(2000),
        requestedDate: _date(m['requestedDate']) ?? DateTime(2000),
        reason: '${m['reason'] ?? ''}',
        note: '${m['note'] ?? ''}',
        status: enumByName(HoldStatus.values, m['status'], HoldStatus.pending),
        response: '${m['response'] ?? ''}',
        createdAt: _date(m['createdAt']),
      );

  /// As a [HoldRequest], for the shared rules in [checkTenantHoldRequest].
  HoldRequest asHoldRequest() => HoldRequest(
        id: id,
        paymentId: paymentId,
        originalDate: originalDate,
        requestedDate: requestedDate,
        reason: reason,
        status: status,
        response: response,
      );
}

/// A document the landlord shared. [ownerType] is property, lease or tenant.
class TvDocument {
  const TvDocument({
    required this.landlordUid,
    required this.id,
    required this.ownerType,
    required this.ownerId,
    this.propertyId = '',
    required this.name,
    this.kind = 'other',
    required this.url,
  });
  final String landlordUid, id, ownerType, ownerId, propertyId, name, kind, url;

  Map<String, dynamic> toMap() => {
        'landlordUid': landlordUid,
        'id': id,
        'ownerType': ownerType,
        'ownerId': ownerId,
        'propertyId': propertyId,
        'name': name,
        'kind': kind,
        'url': url,
      };

  factory TvDocument.fromMap(Map<String, dynamic> m) => TvDocument(
        landlordUid: '${m['landlordUid']}',
        id: '${m['id']}',
        ownerType: '${m['ownerType'] ?? ''}',
        ownerId: '${m['ownerId'] ?? ''}',
        propertyId: '${m['propertyId'] ?? ''}',
        name: '${m['name'] ?? ''}',
        kind: '${m['kind'] ?? 'other'}',
        url: '${m['url'] ?? ''}',
      );
}

/// Everything one tenant sees of one landlord.
class TenantViewData {
  const TenantViewData({
    required this.landlord,
    required this.status,
    required this.tenantIds,
    this.properties = const [],
    this.leases = const [],
    this.payments = const [],
    this.documents = const [],
    this.inspections = const [],
    this.holdRequests = const [],
  });
  final TvLandlord landlord;
  final LinkStatus status;
  final List<String> tenantIds;
  final List<TvProperty> properties;
  final List<TvLease> leases;
  final List<TvPayment> payments;
  final List<TvDocument> documents;
  final List<Map<String, dynamic>> inspections;
  final List<TvHoldRequest> holdRequests;
}

/// Builds what [tenantUid] may see of [landlordUid]'s data: only their own
/// leases, the properties and payments of those leases, the landlord's public
/// profile, shared documents and cheque copies, and inspections of their leases.
/// The link is `former` once every lease has ended.
TenantViewData buildTenantView({
  required String landlordUid,
  required String tenantUid,
  required Landlord? profile,
  String landlordEmail = '',
  required List<Tenant> tenants,
  required List<Lease> leases,
  required List<Property> properties,
  required List<Payment> payments,
  List<Map<String, dynamic>> inspections = const [],
  List<HoldRequest> holdRequests = const [],
  required DateTime today,
  DateTime? since,
}) {
  final mine = tenants.where((t) => t.appUid == tenantUid).toList();
  final tenantIds = [for (final t in mine) t.id];
  final myLeases = leases.where((x) => tenantIds.contains(x.tenantId)).toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));
  final leaseIds = {for (final x in myLeases) x.id};
  final propertyIds = {for (final x in myLeases) x.propertyId};
  final propertyById = {for (final p in properties) p.id: p};

  final current = myLeases.any((x) => x.status == LeaseStatus.active && !x.endDate.isBefore(today));
  final status = myLeases.isEmpty || current ? LinkStatus.active : LinkStatus.former;

  final tvProperties = [
    for (final pid in propertyIds)
      if (propertyById[pid] case final p?)
        TvProperty(
          landlordUid: landlordUid,
          id: p.id,
          name: p.name,
          type: p.type.name,
          address: p.address,
          community: p.community,
          titleDeedNo: p.titleDeedNo,
          dewaPremiseNo: p.dewaPremiseNo,
          dewaAccountNo: p.dewaAccountNo,
          mollakUnitRef: p.mollakUnitRef,
          hoaName: p.hoaName,
          hoaPhone: p.hoaPhone,
          agreementAmount: myLeases.where((x) => x.propertyId == p.id).lastOrNull?.annualRent,
          leaseIds: [for (final x in myLeases) if (x.propertyId == p.id) x.id],
        ),
  ];

  String nameOf(String propertyId) => propertyById[propertyId]?.name ?? '';
  final propertyOfLease = {for (final x in myLeases) x.id: x.propertyId};

  final docs = <TvDocument>[];
  void addDocs(String ownerType, String ownerId, String propertyId, List<AppDocument> list) {
    for (var i = 0; i < list.length; i++) {
      final d = list[i];
      if (!d.sharedWithTenant || d.url.isEmpty) continue;
      docs.add(TvDocument(
        landlordUid: landlordUid,
        id: '${ownerType}_${ownerId}_$i',
        ownerType: ownerType,
        ownerId: ownerId,
        propertyId: propertyId,
        name: d.name,
        kind: d.kind,
        url: d.url,
      ));
    }
  }

  for (final pid in propertyIds) {
    if (propertyById[pid] case final p?) addDocs('property', p.id, p.id, p.documents);
  }
  for (final x in myLeases) {
    addDocs('lease', x.id, x.propertyId, x.documents);
  }
  for (final t in mine) {
    addDocs('tenant', t.id, '', t.documents);
  }

  return TenantViewData(
    landlord: TvLandlord(
      landlordUid: landlordUid,
      name: profile?.name ?? '',
      email: (profile?.email.isNotEmpty ?? false) ? profile!.email : landlordEmail,
      phone: profile?.phone ?? '',
      emiratesIdNo: profile?.emiratesIdNo ?? '',
      status: status,
      since: since,
    ),
    status: status,
    tenantIds: tenantIds,
    properties: tvProperties,
    leases: [
      for (final x in myLeases)
        TvLease(
          landlordUid: landlordUid,
          id: x.id,
          propertyId: x.propertyId,
          propertyName: nameOf(x.propertyId),
          startDate: x.startDate,
          endDate: x.endDate,
          annualRent: x.annualRent,
          securityDeposit: x.securityDeposit,
          numberOfCheques: x.numberOfCheques,
          paymentMethod: x.paymentMethod.name,
          ejariNo: x.ejariNo,
          status: x.status.name,
        ),
    ],
    payments: [
      for (final p in payments)
        if (leaseIds.contains(p.leaseId))
          TvPayment(
            landlordUid: landlordUid,
            id: p.id,
            leaseId: p.leaseId,
            propertyId: propertyOfLease[p.leaseId] ?? '',
            propertyName: nameOf(propertyOfLease[p.leaseId] ?? ''),
            type: p.type.name,
            amount: p.amount,
            dueDate: p.dueDate,
            chequeNo: p.chequeNo,
            bankName: p.bankName,
            status: p.status,
            imageUrl: p.shareImageWithTenant ? p.imageUrl : null,
          ),
    ],
    documents: docs,
    inspections: [
      for (final i in inspections)
        if (leaseIds.contains(i['leaseId'])) {...i, 'landlordUid': landlordUid},
    ],
    holdRequests: () {
      final myPayments = {for (final p in payments) if (leaseIds.contains(p.leaseId)) p.id};
      return [
        for (final r in holdRequests)
          if (myPayments.contains(r.paymentId))
            TvHoldRequest(
              landlordUid: landlordUid,
              id: r.id,
              paymentId: r.paymentId,
              originalDate: r.originalDate,
              requestedDate: r.requestedDate,
              reason: r.reason,
              note: r.note,
              status: r.status,
              response: r.response,
              createdAt: r.createdAt,
            ),
      ];
    }(),
  );
}

/// "{property-name} · Agreement AED {amount}" for the tenant's property list.
String tenantPropertyTitle(TvProperty p, String Function(double) aed, String agreementLabel) =>
    p.agreementAmount == null ? p.name : '${p.name} · $agreementLabel ${aed(p.agreementAmount!)}';
