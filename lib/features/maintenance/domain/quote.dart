import '../../../core/domain/entity.dart';
import 'maintenance_ticket.dart';

enum QuoteStatus { submitted, approved, rejected, questionAsked }

class Quote implements Entity {
  const Quote({
    required this.id,
    required this.ticketId,
    required this.vendorId,
    required this.amount,
    this.vat = 0,
    this.scope = '',
    this.proposedVisit,
    this.status = QuoteStatus.submitted,
    this.question = '',
    this.invoiceUrl,
    this.completionPhotos = const [],
  });

  @override
  final String id;
  final String ticketId, vendorId, scope, question;
  final double amount, vat;
  final DateTime? proposedVisit;
  final QuoteStatus status;
  final String? invoiceUrl;
  final List<String> completionPhotos;

  double get total => amount + vat;

  Quote copyWith({QuoteStatus? status, String? question, String? invoiceUrl, List<String>? completionPhotos}) => Quote(
        id: id,
        ticketId: ticketId,
        vendorId: vendorId,
        amount: amount,
        vat: vat,
        scope: scope,
        proposedVisit: proposedVisit,
        status: status ?? this.status,
        question: question ?? this.question,
        invoiceUrl: invoiceUrl ?? this.invoiceUrl,
        completionPhotos: completionPhotos ?? this.completionPhotos,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'ticketId': ticketId,
        'vendorId': vendorId,
        'amount': amount,
        'vat': vat,
        'scope': scope,
        'proposedVisit': proposedVisit?.toIso8601String(),
        'status': status.name,
        'question': question,
        'invoiceUrl': invoiceUrl,
        'completionPhotos': completionPhotos,
      };

  factory Quote.fromMap(Map<String, dynamic> m) => Quote(
        id: m['id'] as String,
        ticketId: '${m['ticketId']}',
        vendorId: '${m['vendorId']}',
        amount: ((m['amount'] ?? 0) as num).toDouble(),
        vat: ((m['vat'] ?? 0) as num).toDouble(),
        scope: '${m['scope'] ?? ''}',
        proposedVisit: parseDate(m['proposedVisit']),
        status: enumByName(QuoteStatus.values, m['status'], QuoteStatus.submitted),
        question: '${m['question'] ?? ''}',
        invoiceUrl: m['invoiceUrl'] as String?,
        completionPhotos: [for (final p in (m['completionPhotos'] as List? ?? const [])) '$p'],
      );
}

/// Pure quote / job flow rules:
/// requested → quoted → approved → scheduled → in progress → completed → closed.
class QuoteFlow {
  const QuoteFlow._();

  static MaintenanceTicket onQuoteReceived(MaintenanceTicket t) =>
      t.status == TicketStatus.requested ? t.copyWith(status: TicketStatus.quoted) : t;

  /// Approving logs the quoted total as the ticket cost; with a proposed visit
  /// the job is scheduled and the tenant is told the confirmed time.
  static ({Quote quote, MaintenanceTicket ticket}) approve(Quote q, MaintenanceTicket t) => (
        quote: q.copyWith(status: QuoteStatus.approved),
        ticket: t.copyWith(
          status: q.proposedVisit == null ? TicketStatus.approved : TicketStatus.scheduled,
          vendorId: q.vendorId,
          cost: q.total,
          confirmedVisit: q.proposedVisit,
        ),
      );

  static ({Quote quote, MaintenanceTicket ticket}) reject(Quote q, MaintenanceTicket t) =>
      (quote: q.copyWith(status: QuoteStatus.rejected), ticket: t);

  static ({Quote quote, MaintenanceTicket ticket}) ask(Quote q, MaintenanceTicket t, String question) =>
      (quote: q.copyWith(status: QuoteStatus.questionAsked, question: question), ticket: t);

  static MaintenanceTicket start(MaintenanceTicket t) => t.copyWith(status: TicketStatus.inProgress);

  static MaintenanceTicket complete(MaintenanceTicket t) => t.copyWith(status: TicketStatus.completed);

  /// Tenant confirms the fix and rates the job (1–5), closing the ticket.
  static MaintenanceTicket tenantConfirm(MaintenanceTicket t, int rating) =>
      t.copyWith(status: TicketStatus.closed, tenantRating: rating.clamp(1, 5));

  /// Tenant notification text once a visit time is confirmed, null if none yet.
  static String? tenantVisitNotice(MaintenanceTicket t, String Function(DateTime) fmt) =>
      t.confirmedVisit == null ? null : 'Your "${t.title}" visit is confirmed for ${fmt(t.confirmedVisit!)}.';
}
