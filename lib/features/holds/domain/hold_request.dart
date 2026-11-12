import '../../../core/domain/entity.dart';
import '../../payments/domain/payment.dart';

enum HoldStatus { pending, approved, rejected }

class HoldRequest implements Entity {
  const HoldRequest({
    required this.id,
    required this.paymentId,
    required this.originalDate,
    required this.requestedDate,
    this.requestedBy = 'tenant',
    this.reason = '',
    this.status = HoldStatus.pending,
    this.response = '',
  });

  @override
  final String id;
  final String paymentId, requestedBy, reason, response;
  final DateTime originalDate, requestedDate;
  final HoldStatus status;

  HoldRequest copyWith({HoldStatus? status, String? response}) => HoldRequest(
        id: id,
        paymentId: paymentId,
        originalDate: originalDate,
        requestedDate: requestedDate,
        requestedBy: requestedBy,
        reason: reason,
        status: status ?? this.status,
        response: response ?? this.response,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'paymentId': paymentId,
        'requestedBy': requestedBy,
        'reason': reason,
        'originalDate': originalDate.toIso8601String(),
        'requestedDate': requestedDate.toIso8601String(),
        'status': status.name,
        'response': response,
      };

  factory HoldRequest.fromMap(Map<String, dynamic> m) => HoldRequest(
        id: m['id'] as String,
        paymentId: '${m['paymentId']}',
        requestedBy: '${m['requestedBy'] ?? 'tenant'}',
        reason: '${m['reason'] ?? ''}',
        originalDate: parseDate(m['originalDate'])!,
        requestedDate: parseDate(m['requestedDate'])!,
        status: enumByName(HoldStatus.values, m['status'], HoldStatus.pending),
        response: '${m['response'] ?? ''}',
      );
}

/// Pure hold-request rules: history is kept on the request, the payment's
/// due date moves only when a request is approved.
class HoldService {
  const HoldService._();

  static ({HoldRequest request, Payment payment}) open({
    required String id,
    required Payment payment,
    required DateTime requestedDate,
    String reason = '',
    String requestedBy = 'tenant',
  }) =>
      (
        request: HoldRequest(
          id: id,
          paymentId: payment.id,
          originalDate: payment.dueDate,
          requestedDate: requestedDate,
          reason: reason,
          requestedBy: requestedBy,
        ),
        payment: payment.copyWith(status: PaymentStatus.onHold),
      );

  static ({HoldRequest request, Payment payment}) approve(
          HoldRequest r, Payment p, {String response = ''}) =>
      (
        request: r.copyWith(status: HoldStatus.approved, response: response),
        payment: p.copyWith(dueDate: r.requestedDate, status: PaymentStatus.pending),
      );

  static ({HoldRequest request, Payment payment}) reject(
          HoldRequest r, Payment p, {String response = ''}) =>
      (
        request: r.copyWith(status: HoldStatus.rejected, response: response),
        payment: p.copyWith(status: PaymentStatus.pending),
      );
}
