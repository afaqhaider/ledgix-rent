import '../../leases/domain/lease.dart';
import '../../utilities/domain/utility_bill.dart';

// ---------------------------------------------------------------- Ejari

class EjariContract {
  const EjariContract({
    required this.ejariNo,
    required this.startDate,
    required this.expiry,
    this.annualRent,
    this.tenantName = '',
    this.unitRef = '',
  });
  final String ejariNo, tenantName, unitRef;
  final DateTime startDate, expiry;
  final double? annualRent;
}

class EjariRenewalInfo {
  const EjariRenewalInfo({required this.expiry, required this.renewalWindowOpens, required this.daysLeft});
  final DateTime expiry, renewalWindowOpens;
  final int daysLeft;
}

/// Dubai Land Department Ejari. Real access needs an approved DLD business
/// account, so only the mock is available until then.
abstract class EjariService {
  Future<EjariContract> lookupContract(String ejariNo);
  Future<EjariStatus> getContractStatus(String ejariNo);
  Future<EjariRenewalInfo> getRenewalInfo(String ejariNo);
}

// --------------------------------------------------------------- Mollak

class MollakCharge {
  const MollakCharge({required this.period, required this.amount, required this.dueDate, required this.paid});
  final String period;
  final double amount;
  final DateTime dueDate;
  final bool paid;
}

class MollakBudget {
  const MollakBudget({required this.year, required this.totalBudget, required this.spent, required this.reserveFund});
  final int year;
  final double totalBudget, spent, reserveFund;
}

/// Service charges of jointly owned buildings (DLD API Gateway).
abstract class MollakService {
  Future<List<MollakCharge>> getServiceCharges(String unitRef);
  Future<double> getOutstandingBalance(String unitRef);
  Future<MollakBudget> getBudget(String projectRef);
}

// -------------------------------------------------------- Utility bills

class UtilityBillInfo {
  const UtilityBillInfo({
    required this.amount,
    required this.dueDate,
    required this.periodStart,
    required this.periodEnd,
    this.currency = 'AED',
  });
  final double amount;
  final String currency;
  final DateTime dueDate, periodStart, periodEnd;

  /// 'yyyy-MM' of the period end.
  String get period => '${periodEnd.year}-${periodEnd.month.toString().padLeft(2, '0')}';
}

class BillPaymentResult {
  const BillPaymentResult({required this.supported, this.message = ''});
  final bool supported;
  final String message;
}

/// DEWA, chillers and other utilities, through a bank bill-payment API or a
/// licensed aggregator (needs a commercial agreement, so mock for now).
abstract class UtilityBillService {
  Future<UtilityBillInfo> fetchBill(UtilityProvider provider, String accountNo);

  /// Stubbed: online payment is a later version.
  Future<BillPaymentResult> payBill(UtilityProvider provider, String accountNo, double amount);
}
