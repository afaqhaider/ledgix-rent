import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/features/integrations/data/mock_services.dart';
import 'package:ledgix_rent/features/leases/domain/lease.dart';
import 'package:ledgix_rent/features/maintenance/domain/maintenance_ticket.dart';
import 'package:ledgix_rent/features/maintenance/domain/quote.dart';
import 'package:ledgix_rent/features/maintenance/domain/work_order.dart';
import 'package:ledgix_rent/features/payments/domain/payment.dart';
import 'package:ledgix_rent/features/payments/domain/reminder_planner.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';
import 'package:ledgix_rent/features/reports/domain/property_report.dart';
import 'package:ledgix_rent/features/servicecharges/domain/service_charge.dart';
import 'package:ledgix_rent/features/tenants/domain/tenant.dart';
import 'package:ledgix_rent/features/utilities/domain/utility_bill.dart';
import 'package:ledgix_rent/features/vendors/domain/vendor.dart';

final today = DateTime(2026, 6, 1);
const property = Property(id: 'p1', landlordId: 'u', name: 'Marina 1203', community: 'Dubai Marina', address: 'Tower A', defaultVendorId: 'v2');
final ticket = MaintenanceTicket(
  id: 't1',
  propertyId: 'p1',
  title: 'AC not cooling',
  category: TicketCategory.ac,
  priority: TicketPriority.high,
  description: 'Warm air',
  visitRequired: true,
  timeSlots: [DateTime(2026, 6, 5, 10)],
  accessNotes: 'Call security',
  photos: const ['a.jpg'],
);

void main() {
  group('WorkOrderBuilder', () {
    test('contains property, ticket, slots and default message', () {
      final t = WorkOrderBuilder.text(ticket: ticket, property: property);
      expect(t, contains('Dubai Marina'));
      expect(t, contains('Category: ac'));
      expect(t, contains('05/06/2026 10:00'));
      expect(t, contains('Call security'));
      expect(t, contains(defaultWorkOrderMessage));
    });

    test('tenant contact only when allowed', () {
      final tenant = Tenant(id: 'x', name: 'Sara', phone: '0501234567');
      expect(WorkOrderBuilder.text(ticket: ticket, property: property, tenant: tenant), isNot(contains('Sara')));
      final shared = ticket.copyWith(shareTenantContact: true);
      expect(WorkOrderBuilder.text(ticket: shared, property: property, tenant: tenant), contains('Sara (0501234567)'));
    });

    test('no slots when visit not required; landlord note prepended', () {
      final t = MaintenanceTicket(id: 'a', propertyId: 'p1', title: 'Gate', timeSlots: [DateTime(2026, 1, 1)]);
      final text = WorkOrderBuilder.text(ticket: t, property: property, note: 'Urgent please');
      expect(text, contains('Visit required: no'));
      expect(text, isNot(contains('Available')));
      expect(text, startsWith('WORK ORDER'));
      expect(text, contains('Urgent please'));
    });

    test('channel follows whether the company uses the app; link expires in 7 days', () {
      const email = Vendor(id: 'v1', name: 'FixIt', email: 'a@b.ae');
      const app = Vendor(id: 'v2', name: 'AppCo', linkedAccountId: 'acc');
      final o1 = WorkOrderBuilder.build(id: 'o', token: 'tk', ticket: ticket, property: property, vendor: email, now: today);
      final o2 = WorkOrderBuilder.build(id: 'o', token: 'tk', ticket: ticket, property: property, vendor: app, now: today);
      expect(o1.channel, ForwardChannel.email);
      expect(o2.channel, ForwardChannel.app);
      expect(o1.isExpired(today.add(const Duration(days: 6))), isFalse);
      expect(o1.isExpired(today.add(const Duration(days: 7))), isTrue);
      expect(WorkOrder.fromMap(o1.toMap()).toMap(), o1.toMap());
    });

    test('default vendor: property first, then category', () {
      const a = Vendor(id: 'v1', name: 'A', defaultCategories: ['ac']);
      const b = Vendor(id: 'v2', name: 'B');
      expect(WorkOrderBuilder.defaultVendor(ticket, property, [a, b])!.id, 'v2');
      expect(WorkOrderBuilder.defaultVendor(ticket, const Property(id: 'p', landlordId: 'u', name: 'x'), [a, b])!.id, 'v1');
    });
  });

  group('QuoteFlow', () {
    final requested = ticket.copyWith(status: TicketStatus.requested);
    final quote = Quote(id: 'q', ticketId: 't1', vendorId: 'v1', amount: 400, vat: 20, proposedVisit: DateTime(2026, 6, 6, 9));

    test('quote moves requested → quoted', () {
      expect(QuoteFlow.onQuoteReceived(requested).status, TicketStatus.quoted);
      expect(QuoteFlow.onQuoteReceived(ticket).status, TicketStatus.open);
    });

    test('approve schedules visit, logs cost and notifies tenant', () {
      final r = QuoteFlow.approve(quote, requested);
      expect(r.quote.status, QuoteStatus.approved);
      expect(r.ticket.status, TicketStatus.scheduled);
      expect(r.ticket.cost, 420);
      expect(QuoteFlow.tenantVisitNotice(r.ticket, (d) => '${d.day}/${d.month}'), contains('6/6'));
    });

    test('approve without a visit slot stays approved', () {
      final q = Quote(id: 'q', ticketId: 't1', vendorId: 'v1', amount: 100);
      expect(QuoteFlow.approve(q, requested).ticket.status, TicketStatus.approved);
    });

    test('reject keeps ticket; ask records question; confirm closes with rating', () {
      expect(QuoteFlow.reject(quote, requested).ticket.status, TicketStatus.requested);
      expect(QuoteFlow.ask(quote, requested, 'Why?').quote.status, QuoteStatus.questionAsked);
      final closed = QuoteFlow.tenantConfirm(QuoteFlow.complete(QuoteFlow.start(requested)), 9);
      expect(closed.status, TicketStatus.closed);
      expect(closed.tenantRating, 5);
    });

    test('ticket and quote round trip', () {
      expect(MaintenanceTicket.fromMap(ticket.toMap()).toMap(), ticket.toMap());
      expect(Quote.fromMap(quote.toMap()).toMap(), quote.toMap());
    });
  });

  group('Ejari', () {
    test('status from expiry', () {
      expect(EjariStatus.fromExpiry(DateTime(2026, 5, 31), today), EjariStatus.expired);
      expect(EjariStatus.fromExpiry(DateTime(2026, 7, 1), today), EjariStatus.expiring);
      expect(EjariStatus.fromExpiry(DateTime(2027, 1, 1), today), EjariStatus.active);
    });

    test('mock is deterministic and consistent', () async {
      final s = MockEjariService(today: () => today);
      final a = await s.lookupContract('EJ-100');
      expect((await s.lookupContract('EJ-100')).expiry, a.expiry);
      expect(await s.getContractStatus('EJ-100'), EjariStatus.fromExpiry(a.expiry, today));
      expect((await s.getRenewalInfo('EJ-100')).daysLeft, a.expiry.difference(today).inDays);
    });

    test('renewal reminders count back from the Ejari expiry', () {
      final lease = Lease(
        id: 'l', propertyId: 'p', tenantId: 't', startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 12, 31), annualRent: 1,
      ).withEjari(status: EjariStatus.active, expiry: DateTime(2026, 10, 1), syncedAt: today);
      expect(ReminderPlanner.forLease(lease).last.date, DateTime(2026, 9, 1));
      expect(Lease.fromMap(lease.toMap()).ejariExpiry, DateTime(2026, 10, 1));
    });
  });

  group('Mollak & utilities mocks', () {
    test('mollak outstanding = unpaid charges', () async {
      final s = MockMollakService(today: () => today);
      final charges = await s.getServiceCharges('U1');
      expect(await s.getOutstandingBalance('U1'), charges.where((c) => !c.paid).fold<double>(0, (a, c) => a + c.amount));
      expect((await s.getBudget('P1')).spent, lessThan((await s.getBudget('P1')).totalBudget));
    });

    test('utility mock returns last month bill; pay is stubbed', () async {
      final s = MockUtilityBillService(today: () => today);
      final b = await s.fetchBill(UtilityProvider.dewa, '123');
      expect(b.period, '2026-05');
      expect(b.dueDate, DateTime(2026, 6, 20));
      expect((await s.payBill(UtilityProvider.dewa, '123', 1)).supported, isFalse);
    });

    test('bill overdue is derived', () {
      final b = UtilityBill(id: 'b', propertyId: 'p', provider: UtilityProvider.dewa, accountNo: '1', period: '2026-04', amount: 1, dueDate: DateTime(2026, 5, 20));
      expect(b.effectiveStatus(today), BillStatus.overdue);
      expect(b.copyWith(status: BillStatus.paid).effectiveStatus(today), BillStatus.paid);
      expect(UtilityBill.fromMap(b.toMap()).toMap(), b.toMap());
    });
  });

  test('PropertyReport includes service charges, landlord-paid bills and maintenance', () {
    final lease = Lease(id: 'l', propertyId: 'p1', tenantId: 't', startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 12, 31), annualRent: 100000);
    final r = PropertyReport.compute(
      year: 2026,
      properties: [property],
      leases: [lease],
      payments: [
        Payment(id: '1', leaseId: 'l', type: PaymentMethod.cheque, amount: 100000, dueDate: DateTime(2026, 2, 1), status: PaymentStatus.cleared),
        Payment(id: '2', leaseId: 'l', type: PaymentMethod.cheque, amount: 5000, dueDate: DateTime(2026, 8, 1)),
      ],
      tickets: [ticket.copyWith(status: TicketStatus.completed, cost: 1000), ticket.copyWith(cost: 999)],
      bills: [
        UtilityBill(id: 'b1', propertyId: 'p1', provider: UtilityProvider.dewa, accountNo: '1', period: '2026-03', amount: 500, dueDate: DateTime(2026, 4, 1), paidBy: PaidBy.landlord),
        UtilityBill(id: 'b2', propertyId: 'p1', provider: UtilityProvider.dewa, accountNo: '1', period: '2026-03', amount: 700, dueDate: DateTime(2026, 4, 1)),
      ],
      charges: [ServiceCharge(id: 'c', propertyId: 'p1', period: 'Q1', amount: 3500, dueDate: DateTime(2026, 1, 1))],
    ).single;
    expect(r.income, 100000);
    expect(r.maintenance, 1000);
    expect(r.utilities, 500);
    expect(r.serviceCharges, 3500);
    expect(r.net, 95000);
    expect(r.yieldPercent, 95);
  });
}
