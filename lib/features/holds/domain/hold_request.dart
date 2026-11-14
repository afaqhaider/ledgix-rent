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
    this.source = '',
    this.tenantId = '',
    this.leaseId = '',
    this.requestedByUid = '',
    this.note = '',
    this.createdAt,
  });

  @override
  final String id;
  final String paymentId, requestedBy, reason, response;
  final DateTime originalDate, requestedDate;
  final HoldStatus status;

  /// 'tenant' when the tenant asked from the tenant app; empty when the
  /// landlord recorded it.
  final String source;
  final String tenantId, leaseId, requestedByUid, note;
  final DateTime? createdAt;

  bool get fromTenantApp => source == 'tenant';

  HoldRequest copyWith({HoldStatus? status, String? response}) => HoldRequest(
        id: id,
        paymentId: paymentId,
        originalDate: originalDate,
        requestedDate: requestedDate,
        requestedBy: requestedBy,
        reason: reason,
        status: status ?? this.status,
        response: response ?? this.response,
        source: source,
        tenantId: tenantId,
        leaseId: leaseId,
        requestedByUid: requestedByUid,
        note: note,
        createdAt: createdAt,
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
        'source': source,
        'tenantId': tenantId,
        'leaseId': leaseId,
        'requestedByUid': requestedByUid,
        'note': note,
        'createdAt': createdAt?.toIso8601String(),
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
        source: '${m['source'] ?? ''}',
        tenantId: '${m['tenantId'] ?? ''}',
        leaseId: '${m['leaseId'] ?? ''}',
        requestedByUid: '${m['requestedByUid'] ?? ''}',
        note: '${m['note'] ?? ''}',
        createdAt: parseDate(m['createdAt']),
      );
}

/// Why a tenant can't ask to hold a payment.
enum HoldRequestError { reasonRequired, dateNotAfterDue, dateTooFar, alreadyOpen, notAllowed }

/// Longest a tenant may ask to push a payment back.
const maxHoldDays = 90;

/// Rules for a tenant's hold request, shared by the app and (mirrored) the
/// createTenantHoldRequest Cloud Function. Returns null when it's fine.
HoldRequestError? checkTenantHoldRequest({
  required PaymentStatus status,
  required DateTime dueDate,
  required DateTime requestedDate,
  required String reason,
  required Iterable<HoldRequest> existing,
  required String paymentId,
}) {
  if (status != PaymentStatus.pending && status != PaymentStatus.onHold) return HoldRequestError.notAllowed;
  if (existing.any((r) => r.paymentId == paymentId && r.status == HoldStatus.pending)) {
    return HoldRequestError.alreadyOpen;
  }
  if (reason.trim().isEmpty) return HoldRequestError.reasonRequired;
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final req = DateTime(requestedDate.year, requestedDate.month, requestedDate.day);
  if (!req.isAfter(due)) return HoldRequestError.dateNotAfterDue;
  if (req.difference(due).inDays > maxHoldDays) return HoldRequestError.dateTooFar;
  return null;
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
