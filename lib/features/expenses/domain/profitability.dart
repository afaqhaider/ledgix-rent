import '../../../core/utils/dates.dart';
import '../../leases/domain/lease.dart';
import '../../maintenance/domain/maintenance_ticket.dart';
import '../../payments/domain/payment.dart';
import '../../properties/domain/property.dart';
import '../../utilities/domain/utility_bill.dart';
import 'expense.dart';

/// An inclusive date range for reports.
class DateRange {
  const DateRange(this.from, this.to);
  final DateTime from, to;

  bool contains(DateTime d) {
    final x = dateOnly(d);
    return !x.isBefore(dateOnly(from)) && !x.isAfter(dateOnly(to));
  }

  int get days => dateOnly(to).difference(dateOnly(from)).inDays + 1;

  static DateRange thisYear(DateTime today) => DateRange(DateTime(today.year), DateTime(today.year, 12, 31));
  static DateRange last12Months(DateTime today) =>
      DateRange(DateTime(today.year - 1, today.month, today.day + 1), dateOnly(today));
}

/// Income and expenses of one unit (or the whole portfolio) for a period.
///
/// Rent counts by the payment's due date: [rentCollected] is cleared
/// payments, [rentOutstanding] everything else due in the period. Expenses
/// count by their due date whether paid yet or not, so a service charge
/// belongs to the quarter it's billed for.
class Pnl {
  const Pnl({
    this.rentCollected = 0,
    this.rentOutstanding = 0,
    this.serviceCharges = 0,
    this.agencyFees = 0,
    this.maintenance = 0,
    this.utilities = 0,
    this.other = 0,
    this.unpaidExpenses = 0,
  });

  final double rentCollected, rentOutstanding;
  final double serviceCharges, agencyFees, maintenance, utilities, other;

  /// Part of [totalExpenses] not marked paid yet.
  final double unpaidExpenses;

  double get totalExpenses => serviceCharges + agencyFees + maintenance + utilities + other;
  double get net => rentCollected - totalExpenses;

  /// Net as a share of collected rent (%), or null with no rent collected.
  double? get marginPercent => rentCollected == 0 ? null : net / rentCollected * 100;

  Pnl operator +(Pnl o) => Pnl(
        rentCollected: rentCollected + o.rentCollected,
        rentOutstanding: rentOutstanding + o.rentOutstanding,
        serviceCharges: serviceCharges + o.serviceCharges,
        agencyFees: agencyFees + o.agencyFees,
        maintenance: maintenance + o.maintenance,
        utilities: utilities + o.utilities,
        other: other + o.other,
        unpaidExpenses: unpaidExpenses + o.unpaidExpenses,
      );
}

class UnitPnl {
  const UnitPnl(this.property, this.pnl, this.range);
  final Property property;
  final Pnl pnl;
  final DateRange range;

  /// Net yield on the purchase price, annualised (%), when a price is set.
  double? get yieldPercent {
    final price = property.purchasePrice;
    if (price == null || price <= 0) return null;
    return pnl.net * 365 / range.days / price * 100;
  }
}

class Profitability {
  const Profitability(this.units, this.range);
  final List<UnitPnl> units;
  final DateRange range;

  Pnl get total => units.fold(const Pnl(), (a, u) => a + u.pnl);

  /// Per-unit P&L, best net first.
  static Profitability compute({
    required DateRange range,
    required DateTime today,
    required List<Property> properties,
    required List<Lease> leases,
    required List<Payment> payments,
    required List<Expense> expenses,
    List<MaintenanceTicket> tickets = const [],
    List<UtilityBill> bills = const [],
  }) {
    final leaseProperty = {for (final l in leases) l.id: l.propertyId};
    final ticketsWithExpense = {for (final e in expenses) if (e.ticketId != null) e.ticketId};
    final units = <UnitPnl>[];
    for (final p in properties) {
      var collected = 0.0, outstanding = 0.0;
      for (final x in payments) {
        if (leaseProperty[x.leaseId] != p.id || !range.contains(x.dueDate)) continue;
        if (x.isSettled) {
          collected += x.amount;
        } else {
          outstanding += x.amount;
        }
      }
      final by = {for (final t in ExpenseType.values) t: 0.0};
      var unpaid = 0.0;
      for (final e in expenses) {
        if (e.propertyId != p.id || !range.contains(e.dueDate)) continue;
        by[e.type] = by[e.type]! + e.amount;
        if (!e.isPaid) unpaid += e.amount;
      }
      // Tickets costed before expenses existed: count them by visit date
      // (or in the current period when they have none).
      for (final t in tickets) {
        if (t.propertyId != p.id || t.cost <= 0 || !t.isClosedOut || ticketsWithExpense.contains(t.id)) continue;
        final when = t.confirmedVisit;
        if (when == null ? range.contains(today) : range.contains(when)) by[ExpenseType.maintenance] = by[ExpenseType.maintenance]! + t.cost;
      }
      final utilities = bills
          .where((b) => b.propertyId == p.id && b.paidBy == PaidBy.landlord && range.contains(b.dueDate))
          .fold(0.0, (a, b) => a + b.amount);
      units.add(UnitPnl(
        p,
        Pnl(
          rentCollected: collected,
          rentOutstanding: outstanding,
          serviceCharges: by[ExpenseType.serviceCharge]!,
          agencyFees: by[ExpenseType.agencyFee]!,
          maintenance: by[ExpenseType.maintenance]!,
          utilities: utilities,
          other: by[ExpenseType.other]!,
          unpaidExpenses: unpaid,
        ),
        range,
      ));
    }
    units.sort((a, b) => b.pnl.net.compareTo(a.pnl.net));
    return Profitability(units, range);
  }

  /// CSV with one row per unit plus a total row.
  String toCsv({required List<String> header, required String totalLabel}) {
    String n(double v) => v.toStringAsFixed(2);
    String q(String s) => '"${s.replaceAll('"', '""')}"';
    final rows = <String>[header.map(q).join(',')];
    List<String> cells(Pnl p) => [
          n(p.rentCollected), n(p.rentOutstanding), n(p.serviceCharges), n(p.agencyFees), n(p.maintenance),
          n(p.utilities), n(p.other), n(p.totalExpenses), n(p.net),
        ];
    for (final u in units) {
      rows.add([q(u.property.name), ...cells(u.pnl), u.yieldPercent?.toStringAsFixed(2) ?? ''].join(','));
    }
    rows.add([q(totalLabel), ...cells(total), ''].join(','));
    return rows.join('\n');
  }
}

/// Service charges and other expenses due soon or overdue, earliest first.
List<Expense> upcomingExpenses(List<Expense> expenses, DateTime today, {int days = 60, ExpenseType? type}) {
  final until = today.add(Duration(days: days));
  return expenses
      .where((e) => !e.isPaid && (type == null || e.type == type) && !e.dueDate.isAfter(until))
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
}
