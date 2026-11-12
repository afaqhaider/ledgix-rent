import '../../../core/domain/entity.dart';
import '../../properties/domain/property.dart';

enum UtilityProvider { dewa, chiller, sewa, addc, aadc }

enum BillStatus { unpaid, paid, overdue }

class UtilityBill implements Entity {
  const UtilityBill({
    required this.id,
    required this.propertyId,
    required this.provider,
    required this.accountNo,
    required this.period,
    required this.amount,
    required this.dueDate,
    this.status = BillStatus.unpaid,
    this.paidBy = PaidBy.tenant,
    this.pdfUrl,
    this.source = 'manual',
  });

  @override
  final String id;
  final String propertyId, accountNo;

  /// 'yyyy-MM' of the billing month.
  final String period;
  final UtilityProvider provider;
  final double amount;
  final DateTime dueDate;
  final BillStatus status;
  final PaidBy paidBy;
  final String? pdfUrl;

  /// 'manual' or 'api'
  final String source;

  /// Overdue is derived: unpaid past its due date.
  BillStatus effectiveStatus(DateTime today) =>
      status == BillStatus.unpaid && dueDate.isBefore(today) ? BillStatus.overdue : status;

  UtilityBill copyWith({BillStatus? status, PaidBy? paidBy, String? pdfUrl}) => UtilityBill(
        id: id,
        propertyId: propertyId,
        provider: provider,
        accountNo: accountNo,
        period: period,
        amount: amount,
        dueDate: dueDate,
        status: status ?? this.status,
        paidBy: paidBy ?? this.paidBy,
        pdfUrl: pdfUrl ?? this.pdfUrl,
        source: source,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'propertyId': propertyId,
        'provider': provider.name,
        'accountNo': accountNo,
        'period': period,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'status': status.name,
        'paidBy': paidBy.name,
        'pdfUrl': pdfUrl,
        'source': source,
      };

  factory UtilityBill.fromMap(Map<String, dynamic> m) => UtilityBill(
        id: m['id'] as String,
        propertyId: '${m['propertyId']}',
        provider: enumByName(UtilityProvider.values, m['provider'], UtilityProvider.dewa),
        accountNo: '${m['accountNo'] ?? ''}',
        period: '${m['period'] ?? ''}',
        amount: ((m['amount'] ?? 0) as num).toDouble(),
        dueDate: DateTime.parse('${m['dueDate']}'),
        status: enumByName(BillStatus.values, m['status'], BillStatus.unpaid),
        paidBy: enumByName(PaidBy.values, m['paidBy'], PaidBy.tenant),
        pdfUrl: m['pdfUrl'] as String?,
        source: '${m['source'] ?? 'manual'}',
      );
}
