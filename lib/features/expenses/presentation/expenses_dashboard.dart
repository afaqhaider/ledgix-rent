import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../domain/expense.dart';
import '../domain/profitability.dart';
import 'expense_ui.dart';

class _CardShell extends StatelessWidget {
  const _CardShell({required this.title, this.subtitle, this.badge = 0, this.action, required this.child, super.key});
  final String title;
  final String? subtitle;
  final int badge;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                  if (badge > 0) ...[
                    const SizedBox(width: 8),
                    Badge(label: Text('$badge'), backgroundColor: context.status.danger),
                  ],
                ]),
                if (subtitle != null)
                  Text(subtitle!, style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ),
            ?action,
          ]),
          const SizedBox(height: 8),
          child,
        ]),
      ),
    );
  }
}

/// Service-charge instalments due in the next 60 days or overdue, across all
/// properties, with a quick "Mark paid".
class ServiceChargesDueCard extends ConsumerWidget {
  const ServiceChargesDueCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final today = todayGst();
    final expenses = ref.watch(expensesProvider).value ?? const <Expense>[];
    final names = {for (final p in ref.watch(propertiesProvider).value ?? const []) p.id: p.name};
    final due = upcomingExpenses(expenses, today, type: ExpenseType.serviceCharge);
    final overdue = due.where((e) => e.statusOn(today) == ExpenseStatus.overdue).length;
    return _CardShell(
      key: const Key('service-charges-due'),
      title: l.exServiceChargesDue,
      subtitle: due.isEmpty ? null : l.exServiceChargesDueSub(due.length),
      badge: overdue,
      action: TextButton(onPressed: () => context.go('/service-charges'), child: Text(l.viewAll)),
      child: due.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
                Text(l.exNoServiceChargesDue, style: Theme.of(context).textTheme.bodyMedium),
                TextButton(onPressed: () => context.go('/service-charges'), child: Text(l.exSetUpServiceCharges)),
              ]),
            )
          : Column(children: [
              for (final e in due.take(6)) ExpenseTile(expense: e, propertyName: names[e.propertyId] ?? '', dense: true),
            ]),
    );
  }
}

/// This year's rent collected vs expenses, and net, for the portfolio.
class ProfitabilityCard extends ConsumerWidget {
  const ProfitabilityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final status = context.status;
    final t = Theme.of(context).textTheme;
    final p = ref.watch(profitThisYearProvider).total;
    final max = [p.rentCollected, p.totalExpenses, 1.0].reduce((a, b) => a > b ? a : b);
    Widget bar(String label, double v, Color color) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [Expanded(child: Text(label)), Text(formatAed(v), style: const TextStyle(fontWeight: FontWeight.w600))]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: v / max,
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ]),
        );
    return _CardShell(
      key: const Key('profitability-card'),
      title: l.exProfitThisYear,
      action: TextButton(onPressed: () => context.go('/reports'), child: Text(l.exViewReport)),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          bar(l.exRentCollected, p.rentCollected, status.success),
          bar(l.exTotalExpenses, p.totalExpenses, status.warning),
          if (p.totalExpenses > 0)
            Text(
              [
                if (p.serviceCharges > 0) '${l.serviceCharges} ${formatAed(p.serviceCharges)}',
                if (p.agencyFees > 0) '${l.exAgencyFees} ${formatAed(p.agencyFees)}',
                if (p.maintenance > 0) '${l.exMaintenance} ${formatAed(p.maintenance)}',
                if (p.utilities + p.other > 0) '${l.exOther} ${formatAed(p.utilities + p.other)}',
              ].join(' · '),
              style: t.bodySmall,
            ),
          const Divider(height: 20),
          Row(children: [
            Expanded(child: Text(l.exNetIncome, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
            Text(
              formatAed(p.net),
              key: const Key('profit-net'),
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: p.net < 0 ? status.danger : status.success),
            ),
          ]),
        ]),
      ),
    );
  }
}
