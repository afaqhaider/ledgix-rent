import '../../../core/domain/entity.dart';
import '../../leases/domain/lease.dart';

enum PaymentStatus { pending, deposited, cleared, bounced, onHold }

class Payment implements Entity {
  const Payment({
    required this.id,
    required this.leaseId,
    required this.type,
    required this.amount,
    required this.dueDate,
    this.chequeNo = '',
    this.bankName = '',
    this.status = PaymentStatus.pending,
    this.depositedDate,
    this.notes = '',
    this.imageUrl,
    this.shareImageWithTenant = true,
  });

  @override
  final String id;
  final String leaseId, chequeNo, bankName, notes;
  final PaymentMethod type;
  final double amount;
  final DateTime dueDate;
  final PaymentStatus status;
  final DateTime? depositedDate;
  final String? imageUrl;

  /// The cheque copy is visible to the lease's tenant (on by default).
  final bool shareImageWithTenant;

  bool get isSettled => status == PaymentStatus.cleared;

  Payment copyWith({
    String? chequeNo,
    String? bankName,
    DateTime? dueDate,
    PaymentStatus? status,
    DateTime? depositedDate,
    String? notes,
    String? imageUrl,
    bool? shareImageWithTenant,
  }) =>
      Payment(
        id: id,
        leaseId: leaseId,
        type: type,
        amount: amount,
        dueDate: dueDate ?? this.dueDate,
        chequeNo: chequeNo ?? this.chequeNo,
        bankName: bankName ?? this.bankName,
        status: status ?? this.status,
        depositedDate: depositedDate ?? this.depositedDate,
        notes: notes ?? this.notes,
        imageUrl: imageUrl ?? this.imageUrl,
        shareImageWithTenant: shareImageWithTenant ?? this.shareImageWithTenant,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'leaseId': leaseId,
        'type': type.name,
        'chequeNo': chequeNo,
        'bankName': bankName,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'status': status.name,
        'depositedDate': depositedDate?.toIso8601String(),
        'notes': notes,
        'image': imageUrl,
        'shareImage': shareImageWithTenant,
      };

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
        id: m['id'] as String,
        leaseId: '${m['leaseId']}',
        type: enumByName(PaymentMethod.values, m['type'], PaymentMethod.cheque),
        chequeNo: '${m['chequeNo'] ?? ''}',
        bankName: '${m['bankName'] ?? ''}',
        amount: (m['amount'] as num).toDouble(),
        dueDate: parseDate(m['dueDate'])!,
        status: enumByName(PaymentStatus.values, m['status'], PaymentStatus.pending),
        depositedDate: parseDate(m['depositedDate']),
        notes: '${m['notes'] ?? ''}',
        imageUrl: m['image'] as String?,
        shareImageWithTenant: m['shareImage'] != false,
      );
}
