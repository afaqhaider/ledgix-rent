import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/features/leases/domain/lease.dart';
import 'package:ledgix_rent/features/payments/domain/payment.dart';
import 'package:ledgix_rent/features/payments/domain/payment_scheduler.dart';
import 'package:ledgix_rent/features/payments/domain/schedule_update.dart';

// Made-up data only.
Lease _lease({double rent = 60000, int cheques = 4, DateTime? start}) => Lease(
      id: 'L1',
      propertyId: 'P1',
      tenantId: 'T1',
      startDate: start ?? DateTime(2026, 1, 1),
      endDate: DateTime(2026, 12, 31),
      annualRent: rent,
      numberOfCheques: cheques,
    );

void main() {
  var n = 0;
  String id() => 'new${n++}';

  test('affectsSchedule only for dates, rent, cheques and method', () {
    final a = _lease();
    expect(ScheduleUpdate.affectsSchedule(a, _lease()), isFalse);
    expect(ScheduleUpdate.affectsSchedule(a, _lease(rent: 72000)), isTrue);
    expect(ScheduleUpdate.affectsSchedule(a, _lease(cheques: 2)), isTrue);
    expect(ScheduleUpdate.affectsSchedule(a, _lease(start: DateTime(2026, 2, 1))), isTrue);
  });

  test('all untouched: replaces everything with the new schedule', () {
    final old = PaymentScheduler.generate(_lease(), id);
    final plan = ScheduleUpdate.plan(lease: _lease(rent: 72000, cheques: 6), existing: old, paymentsWithHolds: {}, newId: id);
    expect(plan.keep, isEmpty);
    expect(plan.remove.length, 4);
    expect(plan.add.length, 6);
    expect(plan.add.fold<double>(0, (s, p) => s + p.amount), 72000);
  });

  test('cleared, on-hold, held and cheque-detail payments are kept; the rest share the remaining rent', () {
    final old = PaymentScheduler.generate(_lease(), id); // 4 x 15,000
    final existing = [
      old[0].copyWith(status: PaymentStatus.cleared),
      old[1].copyWith(chequeNo: '000123'),
      old[2],
      old[3],
    ];
    final plan = ScheduleUpdate.plan(
      lease: _lease(rent: 66000), // rent goes up
      existing: existing,
      paymentsWithHolds: {old[2].id}, // a hold request exists on the third
      newId: id,
    );
    expect(plan.keep.map((p) => p.id), [old[0].id, old[1].id, old[2].id]);
    expect(plan.remove.map((p) => p.id), [old[3].id]);
    expect(plan.add.length, 1);
    expect(plan.add.single.amount, 66000 - 45000);
  });

  test('nothing added when kept payments already cover the rent', () {
    final old = PaymentScheduler.generate(_lease(cheques: 2), id);
    final existing = [for (final p in old) p.copyWith(status: PaymentStatus.deposited)];
    final plan = ScheduleUpdate.plan(lease: _lease(rent: 50000, cheques: 2), existing: existing, paymentsWithHolds: {}, newId: id);
    expect(plan.isEmpty, isTrue);
  });

  test('other leases are never touched', () {
    final other = Payment(id: 'x', leaseId: 'OTHER', type: PaymentMethod.cheque, amount: 1, dueDate: DateTime(2026));
    final plan = ScheduleUpdate.plan(lease: _lease(), existing: [other], paymentsWithHolds: {}, newId: id);
    expect(plan.remove, isEmpty);
    expect(plan.keep, isEmpty);
  });
}
