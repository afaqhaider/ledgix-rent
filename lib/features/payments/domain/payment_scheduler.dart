import '../../../core/utils/dates.dart';
import '../../leases/domain/lease.dart';
import 'payment.dart';

/// Builds the payment schedule of a lease from its number of cheques.
class PaymentScheduler {
  const PaymentScheduler._();

  static List<Payment> generate(Lease lease, String Function() newId) {
    final n = lease.numberOfCheques < 1 ? 1 : lease.numberOfCheques;
    final cents = (lease.annualRent * 100).round();
    final base = cents ~/ n;
    final gapMonths = 12 / n;
    return [
      for (var i = 0; i < n; i++)
        Payment(
          id: newId(),
          leaseId: lease.id,
          type: lease.paymentMethod,
          // The last instalment absorbs the rounding remainder.
          amount: (i == n - 1 ? cents - base * (n - 1) : base) / 100,
          dueDate: addMonths(lease.startDate, (gapMonths * i).round()),
        ),
    ];
  }
}
