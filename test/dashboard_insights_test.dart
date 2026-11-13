import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/layout/navigation.dart';
import 'package:ledgix_rent/features/dashboard/domain/dashboard_insights.dart';
import 'package:ledgix_rent/features/leases/domain/lease.dart';
import 'package:ledgix_rent/features/payments/domain/payment.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';

Payment pay(String id, DateTime due, double amount, {PaymentStatus status = PaymentStatus.pending}) =>
    Payment(id: id, leaseId: 'l1', type: PaymentMethod.cheque, amount: amount, dueDate: due, status: status);

Lease lease(String id, String propertyId, DateTime end, {LeaseStatus status = LeaseStatus.active}) => Lease(
    id: id, propertyId: propertyId, tenantId: 't', startDate: DateTime(2025, 1, 1), endDate: end, annualRent: 1, status: status);

void main() {
  final today = DateTime(2026, 11, 13);

  test('monthlyCollections: six months oldest first, collected = cleared only', () {
    final months = monthlyCollections([
      pay('a', DateTime(2026, 11, 1), 1000, status: PaymentStatus.cleared),
      pay('b', DateTime(2026, 11, 20), 500),
      pay('c', DateTime(2026, 6, 5), 300, status: PaymentStatus.cleared),
      pay('d', DateTime(2026, 5, 30), 999, status: PaymentStatus.cleared), // outside the window
    ], today);
    expect(months, hasLength(6));
    expect(months.first.month, DateTime(2026, 6));
    expect(months.last.month, DateTime(2026, 11));
    expect(months.last.due, 1500);
    expect(months.last.collected, 1000);
    expect(months.first.collected, 300);
  });

  test('monthlyCollections crosses the year boundary', () {
    final months = monthlyCollections(const [], DateTime(2026, 2, 10));
    expect(months.map((m) => m.month), [
      DateTime(2025, 9), DateTime(2025, 10), DateTime(2025, 11), DateTime(2025, 12), DateTime(2026, 1), DateTime(2026, 2),
    ]);
  });

  test('dueWithin: unsettled, from today up to N days, soonest first', () {
    final due = dueWithin([
      pay('late', DateTime(2026, 12, 20), 1),
      pay('soon', DateTime(2026, 11, 14), 1),
      pay('today', today, 1),
      pay('paid', DateTime(2026, 11, 15), 1, status: PaymentStatus.cleared),
      pay('past', DateTime(2026, 11, 1), 1),
    ], today, 30);
    expect(due.map((p) => p.id), ['today', 'soon']);
  });

  test('upcomingRenewals: active leases ending within 90 days', () {
    final r = upcomingRenewals([
      lease('a', 'p1', DateTime(2027, 1, 10)),
      lease('b', 'p2', DateTime(2026, 12, 1)),
      lease('c', 'p3', DateTime(2027, 6, 1)), // too far
      lease('d', 'p4', DateTime(2026, 12, 1), status: LeaseStatus.terminated),
      lease('e', 'p5', DateTime(2026, 11, 1)), // already ended
    ], today);
    expect(r.map((l) => l.id), ['b', 'a']);
  });

  test('occupancy counts properties with an active, unexpired lease', () {
    const props = [
      Property(id: 'p1', landlordId: 'x', name: 'A'),
      Property(id: 'p2', landlordId: 'x', name: 'B'),
      Property(id: 'p3', landlordId: 'x', name: 'C'),
    ];
    final o = occupancy(props, [
      lease('a', 'p1', DateTime(2027, 1, 1)),
      lease('b', 'p1', DateTime(2027, 2, 1)), // second lease on the same unit
      lease('c', 'p2', DateTime(2026, 1, 1)), // expired
    ], today);
    expect(o.occupied, 1);
    expect(o.total, 3);
  });

  test('navigation: detail and sub-pages highlight their section', () {
    expect(navItemFor('/')?.path, '/');
    expect(navItemFor('/property/p1')?.path, '/portfolio');
    expect(navItemFor('/property/new')?.path, '/portfolio');
    expect(navItemFor('/property/p1/bills')?.path, '/utilities');
    expect(navItemFor('/tickets/t1')?.path, '/maintenance');
    expect(navItemFor('/leases/new')?.path, '/leases');
    expect(navItemFor('/profile')?.path, '/settings');
    expect(isNarrowPage('/settings'), isTrue);
    expect(isNarrowPage('/portfolio'), isFalse);
  });
}
