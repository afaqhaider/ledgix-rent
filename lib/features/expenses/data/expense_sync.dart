import '../../../core/domain/entity.dart';
import '../../../core/utils/dates.dart';
import '../../leases/domain/lease.dart';
import '../../maintenance/domain/maintenance_ticket.dart';
import '../../properties/domain/property.dart';
import '../domain/expense.dart';

/// Keeps generated expenses in step with the records they come from:
/// service-charge plans on properties, agency fees on agreements and costs
/// on maintenance tickets. Hand-entered expenses are never touched.
class ExpenseSync {
  ExpenseSync(this.repo);
  final CrudRepository<Expense> repo;

  Future<List<Expense>> _all() => repo.watchAll().first;

  /// After a property is saved: (re)generate its unpaid service-charge
  /// instalments from the plan, or remove them if the plan was cleared.
  Future<void> serviceCharges(Property p) async {
    final all = await _all();
    final plan = p.serviceChargePlan;
    if (plan == null) {
      for (final e in all) {
        if (e.propertyId == p.id && e.source == ExpenseSource.schedule && !e.isPaid) await repo.delete(e.id);
      }
      return;
    }
    final r = plan.reconcile(p.id, all);
    for (final id in r.delete) {
      await repo.delete(id);
    }
    for (final e in r.save) {
      final old = all.where((x) => x.id == e.id).firstOrNull;
      // Keep a receipt or notes the landlord added to an unpaid instalment.
      await repo.save(old == null ? e : e.copyWith(receiptUrl: old.receiptUrl, notes: old.notes.isEmpty ? e.notes : old.notes));
    }
  }

  /// Marks paid; once the last generated instalment of a property is paid,
  /// next year's instalments are created from its plan.
  Future<void> markPaid(Expense e, DateTime on, {String? receiptUrl, Property? property}) async {
    await repo.save(e.markPaid(on, receiptUrl: receiptUrl));
    final plan = property?.serviceChargePlan;
    if (plan == null || e.source != ExpenseSource.schedule) return;
    for (final next in plan.rollForward(e.propertyId, await _all())) {
      await repo.save(next);
    }
  }

  static String agencyId(String leaseId) => 'ag_$leaseId';
  static String ticketId(String ticketId) => 'mx_$ticketId';

  /// After an agreement is saved: one agency-fee expense when a fee is set.
  Future<void> agencyFee(Lease lease) async {
    final id = agencyId(lease.id);
    final fee = lease.agencyFee ?? 0;
    if (fee <= 0) {
      if (await repo.get(id) != null) await repo.delete(id);
      return;
    }
    final old = await repo.get(id);
    final paid = lease.agencyFeePaidDate;
    await repo.save(Expense(
      id: id,
      propertyId: lease.propertyId,
      type: ExpenseType.agencyFee,
      amount: fee,
      dueDate: dateOnly(paid ?? lease.startDate),
      status: paid != null ? ExpenseStatus.paid : (old?.status ?? ExpenseStatus.due),
      paidDate: paid ?? old?.paidDate,
      payee: lease.agencyName,
      notes: old?.notes ?? '',
      leaseId: lease.id,
      receiptUrl: old?.receiptUrl,
      source: ExpenseSource.agreement,
    ));
  }

  /// After a ticket is saved: once a quote is approved (the ticket carries a
  /// cost), record it as a maintenance expense; keep it paid if it was.
  Future<void> maintenance(MaintenanceTicket t, {String payee = ''}) async {
    final id = ticketId(t.id);
    final committed = t.cost > 0 && t.status.index >= TicketStatus.approved.index;
    final old = await repo.get(id);
    if (!committed) {
      if (old != null && !old.isPaid) await repo.delete(id);
      return;
    }
    await repo.save(Expense(
      id: id,
      propertyId: t.propertyId,
      type: ExpenseType.maintenance,
      amount: t.cost,
      dueDate: dateOnly(old?.dueDate ?? t.confirmedVisit ?? todayGst()),
      status: old?.status ?? ExpenseStatus.due,
      paidDate: old?.paidDate,
      payee: payee.isNotEmpty ? payee : (old?.payee ?? ''),
      notes: t.title,
      ticketId: t.id,
      receiptUrl: old?.receiptUrl,
      source: ExpenseSource.ticket,
    ));
  }
}
