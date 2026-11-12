import '../../../core/utils/dates.dart';
import '../../leases/domain/lease.dart';
import 'payment.dart';

class PlannedReminder {
  const PlannedReminder(this.date, this.daysBefore, this.kind);
  final DateTime date;
  final int daysBefore;

  /// 'deposit' or 'renewal'
  final String kind;
}

/// Same rules as the Cloud Function in functions/src/index.ts.
class ReminderPlanner {
  const ReminderPlanner._();

  static const depositDays = [3, 1];
  static const renewalDays = [90, 60, 30];

  static List<PlannedReminder> forPayment(Payment p) => p.status == PaymentStatus.pending ||
          p.status == PaymentStatus.onHold
      ? [
          for (final d in depositDays)
            PlannedReminder(dateOnly(p.dueDate).subtract(Duration(days: d)), d, 'deposit')
        ]
      : const [];

  static List<PlannedReminder> forLease(Lease l) => l.status == LeaseStatus.active
      ? [
          for (final d in renewalDays)
            PlannedReminder(dateOnly(l.endDate).subtract(Duration(days: d)), d, 'renewal')
        ]
      : const [];

  /// Reminders that fall exactly on [today].
  static List<PlannedReminder> dueOn(
          DateTime today, Iterable<Payment> payments, Iterable<Lease> leases) =>
      [
        for (final p in payments) ...forPayment(p),
        for (final l in leases) ...forLease(l),
      ].where((r) => r.date == dateOnly(today)).toList();
}
