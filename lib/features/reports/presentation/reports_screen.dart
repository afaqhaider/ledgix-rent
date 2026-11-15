import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/file_export.dart';
import '../../../core/widgets/common.dart';
import '../../expenses/domain/profitability.dart';
import '../../expenses/presentation/profitability_widgets.dart';

enum ReportPeriod { thisYear, last12, custom }

/// Profitability of every unit for a period: rent collected and outstanding,
/// service charges, agency fees, maintenance, utilities and other expenses,
/// net income and (with a purchase price) net yield. Best net first.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.thisYear;
  DateRange? _custom;

  DateRange _range(DateTime today) => switch (_period) {
        ReportPeriod.thisYear => DateRange.thisYear(today),
        ReportPeriod.last12 => DateRange.last12Months(today),
        ReportPeriod.custom => _custom ?? DateRange.thisYear(today),
      };

  Future<void> _pickCustom() async {
    final today = todayGst();
    final r = _range(today);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 10),
      lastDate: DateTime(today.year + 5, 12, 31),
      initialDateRange: DateTimeRange(start: r.from, end: r.to),
    );
    if (picked != null) {
      setState(() {
        _period = ReportPeriod.custom;
        _custom = DateRange(picked.start, picked.end);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final today = todayGst();
    final range = _range(today);
    final props = ref.watch(propertiesProvider).value;
    final report = Profitability.compute(
      range: range,
      today: today,
      properties: props ?? const [],
      leases: ref.watch(leasesProvider).value ?? const [],
      payments: ref.watch(paymentsProvider).value ?? const [],
      expenses: ref.watch(expensesProvider).value ?? const [],
      tickets: ref.watch(ticketsProvider).value ?? const [],
      bills: ref.watch(utilityBillsProvider).value ?? const [],
    );
    final gutter = MediaQuery.sizeOf(context).width >= 600 ? 20.0 : 12.0;
    final wide = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      appBar: ShellAppBar(title: Text(l.exProfitabilityReport), actions: [
        Builder(
          builder: (button) => IconButton(
            key: const Key('export-csv'),
            tooltip: l.exExportCsv,
            icon: const Icon(Icons.download_outlined),
            onPressed: report.units.isEmpty
                ? null
                : () async {
                    final csv = report.toCsv(totalLabel: l.exTotal, header: [
                      l.exProperty, l.exRentCollected, l.exRentOutstanding, l.serviceCharges, l.exAgencyFees,
                      l.exMaintenance, l.exUtilities, l.exOther, l.exTotalExpenses, l.exNetIncome, '${l.exNetYield} %',
                    ]);
                    final name = 'ledgix-rent-profitability-${todayGst().toIso8601String().substring(0, 10)}.csv';
                    // Browser: download. Phones: share sheet with a .csv file. Else: clipboard.
                    final result = await exportCsv(name, csv, anchor: button);
                    if (!context.mounted || result == ExportResult.shared) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(result == ExportResult.downloaded ? l.fxCsvDownloaded : l.exCsvCopied)));
                  },
          ),
        ),
      ]),
      body: props == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32), children: [
              Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                for (final (p, label) in [
                  (ReportPeriod.thisYear, l.exPeriodThisYear),
                  (ReportPeriod.last12, l.exPeriodLast12),
                ])
                  ChoiceChip(
                    key: Key('period-${p.name}'),
                    label: Text(label),
                    selected: _period == p,
                    onSelected: (_) => setState(() => _period = p),
                  ),
                ChoiceChip(
                  key: const Key('period-custom'),
                  label: Text(_period == ReportPeriod.custom ? l.exRange(formatDate(range.from), formatDate(range.to)) : l.exPeriodCustom),
                  selected: _period == ReportPeriod.custom,
                  onSelected: (_) => _pickCustom(),
                ),
              ]),
              const SizedBox(height: 8),
              Text(
                '${l.exRange(formatDate(range.from), formatDate(range.to))} · ${l.exUnits(report.units.length)} · ${l.exPnlNote}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (report.units.isEmpty)
                const SizedBox(height: 160, child: EmptyState())
              else ...[
                PnlSummaryCard(key: const Key('pnl-total'), title: l.exTotal, pnl: report.total),
                const SizedBox(height: 12),
                if (wide)
                  ProfitabilityTable(report: report, onOpen: (id) => context.push('/property/$id'))
                else
                  for (final u in report.units) ...[
                    PnlSummaryCard(
                      key: Key('pnl-${u.property.id}'),
                      title: u.property.name,
                      pnl: u.pnl,
                      yieldPercent: u.yieldPercent,
                      onTap: () => context.push('/property/${u.property.id}'),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ]),
    );
  }
}
