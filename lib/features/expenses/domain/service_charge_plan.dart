import '../../../core/domain/entity.dart';
import '../../../core/utils/dates.dart';
import 'expense.dart';

/// How often a building's service charges are billed.
enum ServiceChargeFrequency {
  annual(1),
  semiAnnual(2),
  quarterly(4),
  monthly(12),

  /// Instalments are added by hand on the Service charges page.
  custom(0);

  const ServiceChargeFrequency(this.perYear);
  final int perYear;

  int get monthsBetween => perYear == 0 ? 0 : 12 ~/ perYear;
}

/// The service-charge arrangement saved on a property.
class ServiceChargePlan {
  const ServiceChargePlan({
    required this.annualAmount,
    required this.frequency,
    required this.nextDue,
    this.payee = '',
    this.notes = '',
  });

  final double annualAmount;
  final ServiceChargeFrequency frequency;
  final DateTime nextDue;
  final String payee, notes;

  double get instalment => frequency.perYear == 0 ? annualAmount : annualAmount / frequency.perYear;

  /// Stable id per property and due date, so saving the plan again updates
  /// the same instalments instead of adding duplicates.
  static String instalmentId(String propertyId, DateTime due) => 'sc_${propertyId}_${dateKey(due)}';

  /// "Q1 2027", "H2 2026", "2027", "Mar 2027".
  static String periodLabel(ServiceChargeFrequency f, DateTime due) => switch (f) {
        ServiceChargeFrequency.quarterly => 'Q${(due.month - 1) ~/ 3 + 1} ${due.year}',
        ServiceChargeFrequency.semiAnnual => 'H${due.month <= 6 ? 1 : 2} ${due.year}',
        ServiceChargeFrequency.annual => '${due.year}',
        ServiceChargeFrequency.monthly ||
        ServiceChargeFrequency.custom =>
          '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][due.month - 1]} ${due.year}',
      };

  /// One year of instalments starting at [from] (default [nextDue]).
  /// Custom plans generate nothing: their instalments are entered by hand.
  List<Expense> instalments(String propertyId, {DateTime? from}) {
    if (frequency == ServiceChargeFrequency.custom || annualAmount <= 0) return const [];
    final start = dateOnly(from ?? nextDue);
    return [
      for (var i = 0; i < frequency.perYear; i++)
        () {
          final due = addMonths(start, i * frequency.monthsBetween);
          return Expense(
            id: instalmentId(propertyId, due),
            propertyId: propertyId,
            type: ExpenseType.serviceCharge,
            amount: double.parse(instalment.toStringAsFixed(2)),
            dueDate: due,
            payee: payee,
            notes: notes,
            period: periodLabel(frequency, due),
            source: ExpenseSource.schedule,
          );
        }(),
    ];
  }

  /// What to write and delete when the plan is saved, given the property's
  /// existing expenses: unpaid generated instalments from [nextDue] onwards
  /// are replaced; paid ones and hand-entered ones are never touched.
  ({List<Expense> save, List<String> delete}) reconcile(String propertyId, List<Expense> existing) {
    final fresh = instalments(propertyId);
    final freshIds = {for (final e in fresh) e.id};
    final mine = existing.where((e) => e.propertyId == propertyId && e.source == ExpenseSource.schedule).toList();
    final paidIds = {for (final e in mine) if (e.isPaid) e.id};
    return (
      save: [for (final e in fresh) if (!paidIds.contains(e.id)) e],
      delete: [
        for (final e in mine)
          if (!e.isPaid && !freshIds.contains(e.id) && !e.dueDate.isBefore(dateOnly(nextDue))) e.id,
      ],
    );
  }

  /// After an instalment is paid: if no unpaid generated instalment is left,
  /// the next year's instalments, starting one interval after the last one.
  List<Expense> rollForward(String propertyId, List<Expense> existing) {
    if (frequency == ServiceChargeFrequency.custom) return const [];
    final mine = existing.where((e) => e.propertyId == propertyId && e.source == ExpenseSource.schedule).toList();
    if (mine.isEmpty || mine.any((e) => !e.isPaid)) return const [];
    final last = mine.map((e) => e.dueDate).reduce((a, b) => a.isAfter(b) ? a : b);
    final ids = {for (final e in mine) e.id};
    return [
      for (final e in instalments(propertyId, from: addMonths(last, frequency.monthsBetween)))
        if (!ids.contains(e.id)) e,
    ];
  }
}

/// Agency commission: Dubai agents usually charge 5% of the annual rent.
double agencyFeeFivePercent(double annualRent) => double.parse((annualRent * 0.05).toStringAsFixed(2));
