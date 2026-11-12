import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../domain/property_report.dart';

final reportsProvider = Provider<List<PropertyReport>>((ref) => PropertyReport.compute(
      year: todayGst().year,
      properties: ref.watch(propertiesProvider).value ?? const [],
      leases: ref.watch(leasesProvider).value ?? const [],
      payments: ref.watch(paymentsProvider).value ?? const [],
      tickets: ref.watch(ticketsProvider).value ?? const [],
      bills: ref.watch(utilityBillsProvider).value ?? const [],
      charges: ref.watch(serviceChargesProvider).value ?? const [],
    ));

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final reports = ref.watch(reportsProvider);
    Widget row(String k, String v, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(child: Text(k, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null)),
            Text(v, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: Text('${l.reports} · ${todayGst().year}')),
      body: reports.isEmpty
          ? const EmptyState()
          : ListView(padding: const EdgeInsets.all(12), children: [
              for (final r in reports)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.property.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      row(l.income, formatAed(r.income)),
                      row(l.maintenanceCost, formatAed(r.maintenance)),
                      row(l.utilitiesCost, formatAed(r.utilities)),
                      row(l.serviceCharges, formatAed(r.serviceCharges)),
                      const Divider(),
                      row(l.expenses, formatAed(r.expenses)),
                      row(l.net, formatAed(r.net), bold: true),
                      row(l.yieldLabel, '${r.yieldPercent.toStringAsFixed(1)}%', bold: true),
                    ]),
                  ),
                ),
            ]),
    );
  }
}
