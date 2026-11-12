import '../../../core/domain/entity.dart';

enum ChargeStatus { due, paid, overdue }

class ServiceCharge implements Entity {
  const ServiceCharge({
    required this.id,
    required this.propertyId,
    required this.period,
    required this.amount,
    required this.dueDate,
    this.status = ChargeStatus.due,
  });

  @override
  final String id;
  final String propertyId, period;
  final double amount;
  final DateTime dueDate;
  final ChargeStatus status;

  ChargeStatus effectiveStatus(DateTime today) =>
      status == ChargeStatus.due && dueDate.isBefore(today) ? ChargeStatus.overdue : status;

  ServiceCharge copyWith({ChargeStatus? status}) => ServiceCharge(
      id: id, propertyId: propertyId, period: period, amount: amount, dueDate: dueDate, status: status ?? this.status);

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'propertyId': propertyId,
        'period': period,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'status': status.name,
      };

  factory ServiceCharge.fromMap(Map<String, dynamic> m) => ServiceCharge(
        id: m['id'] as String,
        propertyId: '${m['propertyId']}',
        period: '${m['period'] ?? ''}',
        amount: ((m['amount'] ?? 0) as num).toDouble(),
        dueDate: DateTime.parse('${m['dueDate']}'),
        status: enumByName(ChargeStatus.values, m['status'], ChargeStatus.due),
      );
}
