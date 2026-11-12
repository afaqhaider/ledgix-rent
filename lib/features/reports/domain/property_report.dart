import '../../leases/domain/lease.dart';
import '../../maintenance/domain/maintenance_ticket.dart';
import '../../payments/domain/payment.dart';
import '../../properties/domain/property.dart';
import '../../servicecharges/domain/service_charge.dart';
import '../../utilities/domain/utility_bill.dart';

/// Per-unit income, expenses and yield for one calendar year.
class PropertyReport {
  const PropertyReport({
    required this.property,
    required this.income,
    required this.maintenance,
    required this.utilities,
    required this.serviceCharges,
  });

  final Property property;
  final double income, maintenance, utilities, serviceCharges;

  double get expenses => maintenance + utilities + serviceCharges;
  double get net => income - expenses;

  /// Net yield on collected rent: (income − expenses) / income, as a percentage.
  double get yieldPercent => income == 0 ? 0 : net / income * 100;

  static List<PropertyReport> compute({
    required int year,
    required List<Property> properties,
    required List<Lease> leases,
    required List<Payment> payments,
    required List<MaintenanceTicket> tickets,
    required List<UtilityBill> bills,
    required List<ServiceCharge> charges,
  }) {
    final leaseProperty = {for (final l in leases) l.id: l.propertyId};
    return [
      for (final p in properties)
        PropertyReport(
          property: p,
          income: payments
              .where((x) => x.isSettled && x.dueDate.year == year && leaseProperty[x.leaseId] == p.id)
              .fold(0.0, (a, x) => a + x.amount),
          maintenance: tickets
              .where((t) => t.propertyId == p.id && t.isClosedOut)
              .fold(0.0, (a, t) => a + t.cost),
          // Only bills the landlord pays count as an expense of the unit.
          utilities: bills
              .where((b) => b.propertyId == p.id && b.paidBy == PaidBy.landlord && b.dueDate.year == year)
              .fold(0.0, (a, b) => a + b.amount),
          serviceCharges: charges
              .where((c) => c.propertyId == p.id && c.dueDate.year == year)
              .fold(0.0, (a, c) => a + c.amount),
        ),
    ];
  }
}
