import '../../leases/domain/lease.dart';
import 'payment.dart';
import 'payment_scheduler.dart';

/// What changes in a lease's payment schedule when the agreement is edited.
class ScheduleUpdate {
  const ScheduleUpdate({required this.keep, required this.remove, required this.add});

  /// Payments that already happened or were worked on; never changed.
  final List<Payment> keep;

  /// Untouched pending payments that the new schedule replaces.
  final List<Payment> remove;

  /// New pending payments.
  final List<Payment> add;

  bool get isEmpty => remove.isEmpty && add.isEmpty;

  /// True when an edit changes anything the schedule is built from.
  static bool affectsSchedule(Lease before, Lease after) =>
      before.startDate != after.startDate ||
      before.endDate != after.endDate ||
      before.annualRent != after.annualRent ||
      before.numberOfCheques != after.numberOfCheques ||
      before.paymentMethod != after.paymentMethod;

  /// A payment is locked once it has moved past "pending", has a hold
  /// request, or the landlord has recorded cheque details or a photo on it.
  static bool isLocked(Payment p, Set<String> paymentsWithHolds) =>
      p.status != PaymentStatus.pending ||
      paymentsWithHolds.contains(p.id) ||
      p.chequeNo.trim().isNotEmpty ||
      p.bankName.trim().isNotEmpty ||
      (p.imageUrl ?? '').isNotEmpty;

  /// Rebuilds the schedule for [lease]. Locked payments stay as they are and
  /// each one takes the place of the new instalment closest to its due date;
  /// the remaining instalments share whatever rent the locked ones don't cover.
  static ScheduleUpdate plan({
    required Lease lease,
    required List<Payment> existing,
    required Set<String> paymentsWithHolds,
    required String Function() newId,
  }) {
    final mine = existing.where((p) => p.leaseId == lease.id).toList();
    final keep = [for (final p in mine) if (isLocked(p, paymentsWithHolds)) p];
    final remove = [for (final p in mine) if (!isLocked(p, paymentsWithHolds)) p];

    final slots = PaymentScheduler.generate(lease, newId);
    for (final k in keep) {
      if (slots.isEmpty) break;
      slots.sort((a, b) => a.dueDate.difference(k.dueDate).abs().compareTo(b.dueDate.difference(k.dueDate).abs()));
      slots.removeAt(0);
    }
    slots.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final covered = keep.fold<int>(0, (s, p) => s + (p.amount * 100).round());
    final left = (lease.annualRent * 100).round() - covered;
    if (slots.isEmpty || left <= 0) return ScheduleUpdate(keep: keep, remove: remove, add: const []);

    final base = left ~/ slots.length;
    final add = [
      for (var i = 0; i < slots.length; i++)
        // The last instalment absorbs the rounding remainder.
        slots[i].copyWith(amount: (i == slots.length - 1 ? left - base * (slots.length - 1) : base) / 100),
    ];
    return ScheduleUpdate(keep: keep, remove: remove, add: add);
  }
}
