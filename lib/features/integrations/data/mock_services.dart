import '../../../core/utils/dates.dart';
import '../../leases/domain/lease.dart';
import '../../utilities/domain/utility_bill.dart';
import '../domain/integration_services.dart';

int _seed(String s) => s.codeUnits.fold(7, (a, c) => (a * 31 + c) & 0x7fffffff);

/// Realistic sample data derived deterministically from the input.
class MockEjariService implements EjariService {
  MockEjariService({DateTime Function()? today}) : _today = today ?? todayGst;
  final DateTime Function() _today;

  @override
  Future<EjariContract> lookupContract(String ejariNo) async {
    final n = _seed(ejariNo);
    final today = _today();
    // Spread expiries from ~1 month ago to ~10 months ahead.
    final expiry = today.add(Duration(days: (n % 11) * 30 - 30));
    return EjariContract(
      ejariNo: ejariNo,
      startDate: addMonths(expiry, -12).add(const Duration(days: 1)),
      expiry: expiry,
      annualRent: 60000 + (n % 12) * 5000.0,
      tenantName: 'Sample Tenant',
      unitRef: 'DXB-${n % 9000 + 1000}',
    );
  }

  @override
  Future<EjariStatus> getContractStatus(String ejariNo) async =>
      EjariStatus.fromExpiry((await lookupContract(ejariNo)).expiry, _today());

  @override
  Future<EjariRenewalInfo> getRenewalInfo(String ejariNo) async {
    final c = await lookupContract(ejariNo);
    return EjariRenewalInfo(
      expiry: c.expiry,
      renewalWindowOpens: c.expiry.subtract(const Duration(days: 90)),
      daysLeft: c.expiry.difference(_today()).inDays,
    );
  }
}

class MockMollakService implements MollakService {
  MockMollakService({DateTime Function()? today}) : _today = today ?? todayGst;
  final DateTime Function() _today;

  @override
  Future<List<MollakCharge>> getServiceCharges(String unitRef) async {
    final today = _today();
    final base = 4000 + (_seed(unitRef) % 20) * 100.0;
    return [
      for (var i = 0; i < 4; i++)
        () {
          final due = DateTime(today.year, 1 + i * 3, 1);
          return MollakCharge(
            period: 'Q${i + 1} ${today.year}',
            amount: base,
            dueDate: due,
            paid: due.isBefore(today.subtract(const Duration(days: 30))),
          );
        }(),
    ];
  }

  @override
  Future<double> getOutstandingBalance(String unitRef) async =>
      (await getServiceCharges(unitRef)).where((c) => !c.paid).fold<double>(0, (a, c) => a + c.amount);

  @override
  Future<MollakBudget> getBudget(String projectRef) async {
    final n = _seed(projectRef) % 10;
    final total = 2500000 + n * 100000.0;
    return MollakBudget(year: _today().year, totalBudget: total, spent: total * 0.42, reserveFund: total * 0.15);
  }
}

class MockUtilityBillService implements UtilityBillService {
  MockUtilityBillService({DateTime Function()? today}) : _today = today ?? todayGst;
  final DateTime Function() _today;

  @override
  Future<UtilityBillInfo> fetchBill(UtilityProvider provider, String accountNo) async {
    final today = _today();
    final n = _seed('${provider.name}$accountNo');
    final end = DateTime(today.year, today.month, 0); // last day of previous month
    return UtilityBillInfo(
      amount: (provider == UtilityProvider.chiller ? 350 : 400) + (n % 60) * 10.0,
      dueDate: DateTime(today.year, today.month, 20),
      periodStart: DateTime(end.year, end.month, 1),
      periodEnd: end,
    );
  }

  @override
  Future<BillPaymentResult> payBill(UtilityProvider provider, String accountNo, double amount) async =>
      const BillPaymentResult(supported: false, message: 'Online bill payment is not available yet.');
}
