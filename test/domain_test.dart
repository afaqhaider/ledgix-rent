import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/utils/dates.dart';
import 'package:ledgix_rent/features/dashboard/domain/dashboard_stats.dart';
import 'package:ledgix_rent/features/holds/domain/hold_request.dart';
import 'package:ledgix_rent/features/leases/domain/lease.dart';
import 'package:ledgix_rent/features/maintenance/domain/maintenance_ticket.dart';
import 'package:ledgix_rent/features/payments/domain/payment.dart';
import 'package:ledgix_rent/features/payments/domain/payment_scheduler.dart';
import 'package:ledgix_rent/features/payments/domain/reminder_planner.dart';

Lease lease({int cheques = 4, double rent = 100000, DateTime? start}) => Lease(
      id: 'l1',
      propertyId: 'p1',
      tenantId: 't1',
      startDate: start ?? DateTime(2026, 1, 31),
      endDate: DateTime(2026, 12, 30),
      annualRent: rent,
      numberOfCheques: cheques,
    );

void main() {
  group('PaymentScheduler', () {
    test('splits rent evenly and spaces dates', () {
      var i = 0;
      final ps = PaymentScheduler.generate(lease(), () => 'x${i++}');
      expect(ps.map((p) => p.amount), [25000, 25000, 25000, 25000]);
      expect(ps.map((p) => p.dueDate), [
        DateTime(2026, 1, 31),
        DateTime(2026, 4, 30),
        DateTime(2026, 7, 31),
        DateTime(2026, 10, 31),
      ]);
    });

    test('last instalment absorbs rounding', () {
      var i = 0;
      final ps = PaymentScheduler.generate(lease(cheques: 3, rent: 100000), () => 'x${i++}');
      expect(ps.fold<double>(0, (a, p) => a + p.amount).toStringAsFixed(2), '100000.00');
    });

    test('12 cheques are monthly; 1 cheque is a single payment', () {
      var i = 0;
      final m = PaymentScheduler.generate(lease(cheques: 12), () => 'm${i++}');
      expect(m.length, 12);
      expect(m[1].dueDate, DateTime(2026, 2, 28));
      expect(PaymentScheduler.generate(lease(cheques: 1), () => 's').single.amount, 100000);
    });
  });

  group('HoldService', () {
    final p = Payment(
        id: 'p', leaseId: 'l1', type: PaymentMethod.cheque, amount: 1, dueDate: DateTime(2026, 3, 1));

    test('open puts the payment on hold and records the original date', () {
      final r = HoldService.open(id: 'h', payment: p, requestedDate: DateTime(2026, 3, 15));
      expect(r.payment.status, PaymentStatus.onHold);
      expect(r.request.originalDate, DateTime(2026, 3, 1));
    });

    test('approve moves the due date and keeps history', () {
      final o = HoldService.open(id: 'h', payment: p, requestedDate: DateTime(2026, 3, 15));
      final a = HoldService.approve(o.request, o.payment);
      expect(a.payment.dueDate, DateTime(2026, 3, 15));
      expect(a.payment.status, PaymentStatus.pending);
      expect(a.request.originalDate, DateTime(2026, 3, 1));
      expect(a.request.status, HoldStatus.approved);
    });

    test('reject keeps the due date', () {
      final o = HoldService.open(id: 'h', payment: p, requestedDate: DateTime(2026, 3, 15));
      final r = HoldService.reject(o.request, o.payment);
      expect(r.payment.dueDate, DateTime(2026, 3, 1));
      expect(r.payment.status, PaymentStatus.pending);
    });
  });

  group('ReminderPlanner', () {
    test('deposit reminders 3 and 1 days before; none once cleared', () {
      final p = Payment(
          id: 'p', leaseId: 'l', type: PaymentMethod.cheque, amount: 1, dueDate: DateTime(2026, 3, 10));
      expect(ReminderPlanner.forPayment(p).map((r) => r.date), [DateTime(2026, 3, 7), DateTime(2026, 3, 9)]);
      expect(ReminderPlanner.forPayment(p.copyWith(status: PaymentStatus.cleared)), isEmpty);
    });

    test('renewal alerts at 90, 60, 30 days', () {
      final r = ReminderPlanner.forLease(lease());
      expect(r.map((e) => e.daysBefore), [90, 60, 30]);
      expect(r.last.date, DateTime(2026, 11, 30));
    });
  });

  group('DashboardStats', () {
    test('splits collected vs outstanding by month and year', () {
      Payment pay(String id, DateTime d, PaymentStatus s, double a) => Payment(
          id: id, leaseId: 'l', type: PaymentMethod.cheque, amount: a, dueDate: d, status: s);
      final s = DashboardStats.compute(
        today: DateTime(2026, 5, 10),
        payments: [
          pay('1', DateTime(2026, 5, 1), PaymentStatus.cleared, 100),
          pay('2', DateTime(2026, 5, 20), PaymentStatus.pending, 50),
          pay('3', DateTime(2026, 8, 1), PaymentStatus.pending, 200),
          pay('4', DateTime(2025, 8, 1), PaymentStatus.cleared, 999),
        ],
        tickets: const [
          MaintenanceTicket(id: 't1', propertyId: 'p', title: 'a'),
          MaintenanceTicket(id: 't2', propertyId: 'p', title: 'b', status: TicketStatus.completed),
        ],
      );
      expect(s.collectedMonth, 100);
      expect(s.outstandingMonth, 50);
      expect(s.collectedYear, 100);
      expect(s.outstandingYear, 250);
      expect(s.upcoming.map((p) => p.id), ['2', '3']);
      expect(s.openTickets, 1);
    });
  });

  test('addMonths clamps day', () => expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28)));

  test('model round trip', () {
    final p = Payment(
        id: 'p', leaseId: 'l', type: PaymentMethod.directDebit, amount: 12.5, dueDate: DateTime(2026, 3, 1));
    expect(Payment.fromMap(p.toMap()).toMap(), p.toMap());
  });
}
