import '../../../core/domain/entity.dart';

/// What a landlord pays out for a unit.
enum ExpenseType { serviceCharge, agencyFee, maintenance, other }

/// Stored status. "Overdue" is derived from the due date, see [Expense.statusOn].
enum ExpenseStatus { due, paid, overdue }

/// Where an expense came from, so regenerating a schedule or re-saving an
/// agreement updates its own rows and never touches hand-entered ones.
enum ExpenseSource { manual, schedule, agreement, ticket }

/// One expense of a property: a service-charge instalment, an agency fee,
/// a maintenance job or anything else. Stored at landlords/{uid}/expenses.
/// Landlord-only: never copied to tenants.
class Expense implements Entity {
  const Expense({
    required this.id,
    required this.propertyId,
    required this.type,
    required this.amount,
    required this.dueDate,
    this.status = ExpenseStatus.due,
    this.paidDate,
    this.payee = '',
    this.notes = '',
    this.period = '',
    this.leaseId,
    this.ticketId,
    this.receiptUrl,
    this.source = ExpenseSource.manual,
  });

  @override
  final String id;
  final String propertyId;
  final ExpenseType type;
  final double amount;
  final DateTime dueDate;
  final ExpenseStatus status;
  final DateTime? paidDate;
  final String payee, notes;

  /// Human label such as "Q1 2027" for service-charge instalments.
  final String period;
  final String? leaseId, ticketId, receiptUrl;
  final ExpenseSource source;

  bool get isPaid => status == ExpenseStatus.paid;

  /// Paid, due, or overdue once the due date has passed unpaid.
  ExpenseStatus statusOn(DateTime today) =>
      isPaid ? ExpenseStatus.paid : (dueDate.isBefore(today) ? ExpenseStatus.overdue : ExpenseStatus.due);

  Expense copyWith({
    String? propertyId,
    ExpenseType? type,
    double? amount,
    DateTime? dueDate,
    ExpenseStatus? status,
    DateTime? paidDate,
    bool clearPaidDate = false,
    String? payee,
    String? notes,
    String? period,
    String? receiptUrl,
  }) =>
      Expense(
        id: id,
        propertyId: propertyId ?? this.propertyId,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        paidDate: clearPaidDate ? null : (paidDate ?? this.paidDate),
        payee: payee ?? this.payee,
        notes: notes ?? this.notes,
        period: period ?? this.period,
        leaseId: leaseId,
        ticketId: ticketId,
        receiptUrl: receiptUrl ?? this.receiptUrl,
        source: source,
      );

  Expense markPaid(DateTime on, {String? receiptUrl}) =>
      copyWith(status: ExpenseStatus.paid, paidDate: on, receiptUrl: receiptUrl);

  Expense markUnpaid() => copyWith(status: ExpenseStatus.due, clearPaidDate: true);

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'propertyId': propertyId,
        'type': type.name,
        'amount': amount,
        'dueDate': dateKey(dueDate),
        // Overdue is derived, so only due/paid are stored.
        'status': isPaid ? 'paid' : 'due',
        'paidDate': dateKey(paidDate),
        'payee': payee,
        'notes': notes,
        'period': period,
        'leaseId': leaseId,
        'ticketId': ticketId,
        'receiptUrl': receiptUrl,
        'source': source.name,
      };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
        id: '${m['id']}',
        propertyId: '${m['propertyId'] ?? ''}',
        type: enumByName(ExpenseType.values, m['type'], ExpenseType.other),
        amount: ((m['amount'] ?? 0) as num).toDouble(),
        dueDate: parseDate(m['dueDate']) ?? DateTime(2000),
        status: m['status'] == 'paid' ? ExpenseStatus.paid : ExpenseStatus.due,
        paidDate: parseDate(m['paidDate']),
        payee: '${m['payee'] ?? ''}',
        notes: '${m['notes'] ?? ''}',
        period: '${m['period'] ?? ''}',
        leaseId: m['leaseId'] as String?,
        ticketId: m['ticketId'] as String?,
        receiptUrl: m['receiptUrl'] as String?,
        source: enumByName(ExpenseSource.values, m['source'], ExpenseSource.manual),
      );
}
