import '../../maintenance/domain/maintenance_ticket.dart';
import '../../payments/domain/payment.dart';

class DashboardStats {
  const DashboardStats({
    required this.collectedMonth,
    required this.outstandingMonth,
    required this.collectedYear,
    required this.outstandingYear,
    required this.upcoming,
    required this.openTickets,
  });

  final double collectedMonth, outstandingMonth, collectedYear, outstandingYear;
  final List<Payment> upcoming;
  final int openTickets;

  static DashboardStats compute({
    required List<Payment> payments,
    required List<MaintenanceTicket> tickets,
    required DateTime today,
    int upcomingLimit = 5,
  }) {
    double sum(Iterable<Payment> ps) => ps.fold(0.0, (a, p) => a + p.amount);
    final year = payments.where((p) => p.dueDate.year == today.year);
    final month = year.where((p) => p.dueDate.month == today.month);
    final upcoming = payments
        .where((p) =>
            p.status != PaymentStatus.cleared && !p.dueDate.isBefore(DateTime(today.year, today.month, today.day)))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return DashboardStats(
      collectedMonth: sum(month.where((p) => p.isSettled)),
      outstandingMonth: sum(month.where((p) => !p.isSettled)),
      collectedYear: sum(year.where((p) => p.isSettled)),
      outstandingYear: sum(year.where((p) => !p.isSettled)),
      upcoming: upcoming.take(upcomingLimit).toList(),
      openTickets: tickets.where((t) => t.status != TicketStatus.resolved).length,
    );
  }
}
