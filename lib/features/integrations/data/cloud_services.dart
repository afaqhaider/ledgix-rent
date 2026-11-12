import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/utils/dates.dart';
import '../../leases/domain/lease.dart';
import '../../utilities/domain/utility_bill.dart';
import '../domain/integration_services.dart';

/// Calls the Cloud Functions in functions/src/integrations. The server decides
/// whether to use its mock or live gateway, so no credentials reach the app.
Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
  final r = await FirebaseFunctions.instance.httpsCallable(name).call<Map<Object?, Object?>>(data);
  return Map<String, dynamic>.from(r.data);
}

DateTime _d(Object? v) => DateTime.parse('$v');

class CloudEjariService implements EjariService {
  @override
  Future<EjariContract> lookupContract(String ejariNo) async {
    final m = await _call('ejariLookup', {'ejariNo': ejariNo});
    return EjariContract(
      ejariNo: ejariNo,
      startDate: _d(m['startDate']),
      expiry: _d(m['expiry']),
      annualRent: (m['annualRent'] as num?)?.toDouble(),
      tenantName: '${m['tenantName'] ?? ''}',
      unitRef: '${m['unitRef'] ?? ''}',
    );
  }

  @override
  Future<EjariStatus> getContractStatus(String ejariNo) async =>
      EjariStatus.fromExpiry((await lookupContract(ejariNo)).expiry, todayGst());

  @override
  Future<EjariRenewalInfo> getRenewalInfo(String ejariNo) async {
    final c = await lookupContract(ejariNo);
    return EjariRenewalInfo(
      expiry: c.expiry,
      renewalWindowOpens: c.expiry.subtract(const Duration(days: 90)),
      daysLeft: c.expiry.difference(todayGst()).inDays,
    );
  }
}

class CloudMollakService implements MollakService {
  @override
  Future<List<MollakCharge>> getServiceCharges(String unitRef) async {
    final m = await _call('mollakQuery', {'op': 'charges', 'ref': unitRef});
    return [
      for (final c in (m['charges'] as List))
        MollakCharge(
          period: '${c['period']}',
          amount: (c['amount'] as num).toDouble(),
          dueDate: _d(c['dueDate']),
          paid: c['paid'] == true,
        )
    ];
  }

  @override
  Future<double> getOutstandingBalance(String unitRef) async =>
      ((await _call('mollakQuery', {'op': 'balance', 'ref': unitRef}))['balance'] as num).toDouble();

  @override
  Future<MollakBudget> getBudget(String projectRef) async {
    final m = await _call('mollakQuery', {'op': 'budget', 'ref': projectRef});
    return MollakBudget(
      year: m['year'] as int,
      totalBudget: (m['totalBudget'] as num).toDouble(),
      spent: (m['spent'] as num).toDouble(),
      reserveFund: (m['reserveFund'] as num).toDouble(),
    );
  }
}

class CloudUtilityBillService implements UtilityBillService {
  @override
  Future<UtilityBillInfo> fetchBill(UtilityProvider provider, String accountNo) async {
    final m = await _call('utilityFetch', {'provider': provider.name, 'accountNo': accountNo});
    return UtilityBillInfo(
      amount: (m['amount'] as num).toDouble(),
      currency: '${m['currency'] ?? 'AED'}',
      dueDate: _d(m['dueDate']),
      periodStart: _d(m['periodStart']),
      periodEnd: _d(m['periodEnd']),
    );
  }

  @override
  Future<BillPaymentResult> payBill(UtilityProvider provider, String accountNo, double amount) async =>
      const BillPaymentResult(supported: false, message: 'Online bill payment is not available yet.');
}
