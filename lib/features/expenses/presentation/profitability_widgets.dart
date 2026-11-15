import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../properties/domain/property.dart';
import '../domain/profitability.dart';

String _pct(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)}%';

/// Income, each expense line, and net for one unit or the portfolio.
class PnlSummaryCard extends StatelessWidget {
  const PnlSummaryCard({super.key, required this.title, required this.pnl, this.yieldPercent, this.onTap, this.subtitle});
  final String title;
  final String? subtitle;
  final Pnl pnl;
  final double? yieldPercent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final status = context.status;
    Widget row(String k, double v, {bool bold = false, Color? color, String? note}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(k, style: bold ? const TextStyle(fontWeight: FontWeight.w700) : null)),
            if (note != null) ...[Text(note, style: t.bodySmall), const SizedBox(width: 8)],
            Text(formatAed(v), style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color)),
          ]),
        );
    final net = pnl.net;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              if (onTap != null) const Icon(Icons.chevron_right),
            ]),
            if (subtitle != null) Text(subtitle!, style: t.bodySmall),
            const SizedBox(height: 8),
            row(l.exRentCollected, pnl.rentCollected, color: status.success),
            if (pnl.rentOutstanding > 0) row(l.exRentOutstanding, pnl.rentOutstanding, color: status.warning),
            const Divider(height: 16),
            if (pnl.serviceCharges > 0) row(l.serviceCharges, pnl.serviceCharges),
            if (pnl.agencyFees > 0) row(l.exAgencyFees, pnl.agencyFees),
            if (pnl.maintenance > 0) row(l.exMaintenance, pnl.maintenance),
            if (pnl.utilities > 0) row(l.exUtilities, pnl.utilities),
            if (pnl.other > 0) row(l.exOther, pnl.other),
            row(l.exTotalExpenses, pnl.totalExpenses,
                bold: true, note: pnl.unpaidExpenses > 0 ? l.exUnpaidPart(formatAed(pnl.unpaidExpenses)) : null),
            const Divider(height: 16),
            row(l.exNetIncome, net, bold: true, color: net < 0 ? status.danger : status.success),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                [
                  '${l.exMargin}: ${_pct(pnl.marginPercent)}',
                  if (yieldPercent != null) '${l.exNetYield}: ${_pct(yieldPercent)}',
                ].join(' · '),
                style: t.bodySmall,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// All units side by side on wide screens, with a total row.
class ProfitabilityTable extends StatelessWidget {
  const ProfitabilityTable({super.key, required this.report, this.onOpen});
  final Profitability report;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final status = context.status;
    DataCell money(double v, {bool bold = false, Color? color}) => DataCell(Text(
          formatAed(v),
          style: TextStyle(fontWeight: bold ? FontWeight.w700 : null, color: color),
        ));
    List<DataCell> cells(Pnl p) => [
          money(p.rentCollected, color: status.success),
          money(p.rentOutstanding),
          money(p.serviceCharges),
          money(p.agencyFees),
          money(p.maintenance),
          money(p.utilities + p.other),
          money(p.totalExpenses, bold: true),
          money(p.net, bold: true, color: p.net < 0 ? status.danger : status.success),
        ];
    final total = report.total;
    return Card(
      key: const Key('profitability-table'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          showCheckboxColumn: false,
          headingTextStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          columns: [
            DataColumn(label: Text(l.exProperty)),
            DataColumn(label: Text(l.exRentCollected), numeric: true),
            DataColumn(label: Text(l.exRentOutstanding), numeric: true),
            DataColumn(label: Text(l.serviceCharges), numeric: true),
            DataColumn(label: Text(l.exAgencyFees), numeric: true),
            DataColumn(label: Text(l.exMaintenance), numeric: true),
            DataColumn(label: Text('${l.exUtilities} / ${l.exOther}'), numeric: true),
            DataColumn(label: Text(l.exTotalExpenses), numeric: true),
            DataColumn(label: Text(l.exNetIncome), numeric: true),
            DataColumn(label: Text(l.exNetYield), numeric: true),
          ],
          rows: [
            for (final u in report.units)
              DataRow(
                key: ValueKey('pnl-row-${u.property.id}'),
                onSelectChanged: onOpen == null ? null : (_) => onOpen!(u.property.id),
                cells: [
                  DataCell(Text(u.property.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ...cells(u.pnl),
                  DataCell(Text(_pct(u.yieldPercent))),
                ],
              ),
            DataRow(
              color: WidgetStatePropertyAll(Theme.of(context).colorScheme.surfaceContainerHighest),
              cells: [
                DataCell(Text(l.exTotal, style: const TextStyle(fontWeight: FontWeight.w700))),
                ...cells(total),
                const DataCell(Text('')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// This year's P&L of one property, for its detail page.
class PropertyPnlCard extends ConsumerWidget {
  const PropertyPnlCard({super.key, required this.property});
  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final today = todayGst();
    final report = Profitability.compute(
      range: DateRange.thisYear(today),
      today: today,
      properties: [property],
      leases: ref.watch(leasesProvider).value ?? const [],
      payments: ref.watch(paymentsProvider).value ?? const [],
      expenses: ref.watch(expensesProvider).value ?? const [],
      tickets: ref.watch(ticketsProvider).value ?? const [],
      bills: ref.watch(utilityBillsProvider).value ?? const [],
    );
    final u = report.units.first;
    return PnlSummaryCard(
      key: const Key('property-pnl'),
      title: '${l.exPnlTitle} · ${today.year}',
      pnl: u.pnl,
      yieldPercent: u.yieldPercent,
      onTap: () => context.push('/reports'),
    );
  }
}
