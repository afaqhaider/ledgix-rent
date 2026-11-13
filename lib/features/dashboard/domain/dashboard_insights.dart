import '../../leases/domain/lease.dart';
import '../../payments/domain/payment.dart';
import '../../properties/domain/property.dart';

/// One month of rent: what was due and how much of it has cleared.
class MonthTotal {
  const MonthTotal(this.month, {required this.due, required this.collected});
  final DateTime month; // first day of the month
  final double due, collected;
}

/// Due and collected totals for the [months] calendar months ending with
/// [today]'s month, oldest first. Payments count in the month they fall due.
List<MonthTotal> monthlyCollections(List<Payment> payments, DateTime today, {int months = 6}) => [
      for (var i = months - 1; i >= 0; i--)
        () {
          final m = DateTime(today.year, today.month - i);
          final inMonth = payments.where((p) => p.dueDate.year == m.year && p.dueDate.month == m.month);
          return MonthTotal(
            m,
            due: inMonth.fold(0.0, (a, p) => a + p.amount),
            collected: inMonth.where((p) => p.isSettled).fold(0.0, (a, p) => a + p.amount),
          );
        }(),
    ];

/// Unsettled payments falling due from [today] up to [days] days ahead, soonest first.
List<Payment> dueWithin(List<Payment> payments, DateTime today, int days) {
  final from = DateTime(today.year, today.month, today.day);
  final to = from.add(Duration(days: days));
  return payments.where((p) => !p.isSettled && !p.dueDate.isBefore(from) && !p.dueDate.isAfter(to)).toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
}

/// Active leases ending from [today] up to [days] days ahead, soonest first.
List<Lease> upcomingRenewals(List<Lease> leases, DateTime today, {int days = 90}) {
  final from = DateTime(today.year, today.month, today.day);
  final to = from.add(Duration(days: days));
  return leases
      .where((l) => l.status == LeaseStatus.active && !l.endDate.isBefore(from) && !l.endDate.isAfter(to))
      .toList()
    ..sort((a, b) => a.endDate.compareTo(b.endDate));
}

/// A property is occupied when it has an active lease that hasn't ended
/// (same rule as the portfolio list).
({int occupied, int total}) occupancy(List<Property> properties, List<Lease> leases, DateTime today) {
  final from = DateTime(today.year, today.month, today.day);
  final occupiedIds = {
    for (final l in leases)
      if (l.status == LeaseStatus.active && !l.endDate.isBefore(from)) l.propertyId,
  };
  return (occupied: properties.where((p) => occupiedIds.contains(p.id)).length, total: properties.length);
}
