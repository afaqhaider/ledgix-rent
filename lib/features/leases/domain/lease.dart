import '../../../core/domain/entity.dart';

enum PaymentMethod { cheque, directDebit }

enum LeaseStatus { active, expired, terminated }

enum EjariStatus {
  unknown,
  active,
  expiring,
  expired;

  /// Expiring = within [windowDays] of the expiry date.
  static EjariStatus fromExpiry(DateTime expiry, DateTime today, {int windowDays = 90}) {
    final e = DateTime(expiry.year, expiry.month, expiry.day);
    if (e.isBefore(today)) return EjariStatus.expired;
    if (e.difference(today).inDays <= windowDays) return EjariStatus.expiring;
    return EjariStatus.active;
  }
}

class Lease implements Entity {
  const Lease({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.startDate,
    required this.endDate,
    required this.annualRent,
    this.securityDeposit = 0,
    this.ejariNo = '',
    this.numberOfCheques = 1,
    this.paymentMethod = PaymentMethod.cheque,
    this.status = LeaseStatus.active,
    this.ejariStatus = EjariStatus.unknown,
    this.ejariExpiry,
    this.ejariLastSynced,
  });

  @override
  final String id;
  final String propertyId, tenantId, ejariNo;
  final DateTime startDate, endDate;
  final double annualRent, securityDeposit;
  final int numberOfCheques;
  final PaymentMethod paymentMethod;
  final LeaseStatus status;

  /// Cached Ejari details (see EjariService) with the time of the last sync.
  final EjariStatus ejariStatus;
  final DateTime? ejariExpiry, ejariLastSynced;

  /// Date renewal alerts count back from: the Ejari expiry when known.
  DateTime get renewalDate => ejariExpiry ?? endDate;

  Lease withEjari({String? ejariNo, required EjariStatus status, DateTime? expiry, required DateTime syncedAt}) => Lease(
        id: id,
        propertyId: propertyId,
        tenantId: tenantId,
        startDate: startDate,
        endDate: endDate,
        annualRent: annualRent,
        securityDeposit: securityDeposit,
        ejariNo: ejariNo ?? this.ejariNo,
        numberOfCheques: numberOfCheques,
        paymentMethod: paymentMethod,
        status: this.status,
        ejariStatus: status,
        ejariExpiry: expiry,
        ejariLastSynced: syncedAt,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'propertyId': propertyId,
        'tenantId': tenantId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'annualRent': annualRent,
        'securityDeposit': securityDeposit,
        'ejariNo': ejariNo,
        'numberOfCheques': numberOfCheques,
        'paymentMethod': paymentMethod.name,
        'status': status.name,
        'ejariStatus': ejariStatus.name,
        'ejariExpiry': ejariExpiry?.toIso8601String(),
        'ejariLastSynced': ejariLastSynced?.toIso8601String(),
      };

  factory Lease.fromMap(Map<String, dynamic> m) => Lease(
        id: m['id'] as String,
        propertyId: '${m['propertyId']}',
        tenantId: '${m['tenantId']}',
        startDate: parseDate(m['startDate'])!,
        endDate: parseDate(m['endDate'])!,
        annualRent: (m['annualRent'] as num).toDouble(),
        securityDeposit: ((m['securityDeposit'] ?? 0) as num).toDouble(),
        ejariNo: '${m['ejariNo'] ?? ''}',
        numberOfCheques: (m['numberOfCheques'] ?? 1) as int,
        paymentMethod: enumByName(PaymentMethod.values, m['paymentMethod'], PaymentMethod.cheque),
        status: enumByName(LeaseStatus.values, m['status'], LeaseStatus.active),
        ejariStatus: enumByName(EjariStatus.values, m['ejariStatus'], EjariStatus.unknown),
        ejariExpiry: parseDate(m['ejariExpiry']),
        ejariLastSynced: parseDate(m['ejariLastSynced']),
      );
}
