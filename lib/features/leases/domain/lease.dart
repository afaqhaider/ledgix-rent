import '../../../core/domain/entity.dart';

enum PaymentMethod { cheque, directDebit }

enum LeaseStatus { active, expired, terminated }

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
  });

  @override
  final String id;
  final String propertyId, tenantId, ejariNo;
  final DateTime startDate, endDate;
  final double annualRent, securityDeposit;
  final int numberOfCheques;
  final PaymentMethod paymentMethod;
  final LeaseStatus status;

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
      );
}
