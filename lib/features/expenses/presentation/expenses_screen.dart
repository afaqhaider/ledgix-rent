import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../properties/domain/property.dart';
import '../domain/expense.dart';
import '../domain/profitability.dart';
import 'expense_ui.dart';

enum ExpensePeriod { thisYear, last12, all }

/// Every expense across the portfolio, with filters and quick "Mark paid".
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key, this.initialType});

  /// Opens pre-filtered, e.g. the Service charges page.
  final ExpenseType? initialType;

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String? _property;
  ExpenseType? _type;
  ExpenseStatus? _status;
  ExpensePeriod _period = ExpensePeriod.thisYear;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final today = todayGst();
    final all = ref.watch(expensesProvider).value;
    final props = ref.watch(propertiesProvider).value ?? const <Property>[];
    final name = {for (final p in props) p.id: p.name};
    final range = switch (_period) {
      ExpensePeriod.thisYear => DateRange.thisYear(today),
      ExpensePeriod.last12 => DateRange.last12Months(today),
      ExpensePeriod.all => null,
    };
    final list = [
      for (final e in all ?? const <Expense>[])
        if ((_property == null || e.propertyId == _property) &&
            (_type == null || e.type == _type) &&
            (_status == null || e.statusOn(today) == _status) &&
            (range == null || range.contains(e.dueDate) || (!e.isPaid && e.dueDate.isBefore(today))))
          e,
    ]..sort((a, b) {
        // Unpaid first (overdue, then soonest), then paid newest first.
        if (a.isPaid != b.isPaid) return a.isPaid ? 1 : -1;
        return a.isPaid ? b.dueDate.compareTo(a.dueDate) : a.dueDate.compareTo(b.dueDate);
      });
    final total = list.fold(0.0, (a, e) => a + e.amount);
    final unpaid = list.where((e) => !e.isPaid).fold(0.0, (a, e) => a + e.amount);
    final gutter = MediaQuery.sizeOf(context).width >= 600 ? 20.0 : 12.0;

    Widget dropdown<T>(Key key, String label, T? value, List<(T?, String)> items, ValueChanged<T?> onChanged) => SizedBox(
          width: 200,
          child: DropdownButtonFormField<T?>(
            key: key,
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(labelText: label, isDense: true),
            items: [for (final (v, t) in items) DropdownMenuItem(value: v, child: Text(t, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => setState(() => onChanged(v)),
          ),
        );

    return Scaffold(
      appBar: ShellAppBar(title: Text(widget.initialType == ExpenseType.serviceCharge ? l.serviceCharges : l.exExpenses)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        key: const Key('add-expense'),
        onPressed: () => context.push('/expenses/new', extra: {'type': (_type ?? ExpenseType.other).name, 'propertyId': ?_property}),
        icon: const Icon(Icons.add),
        label: Text(widget.initialType == ExpenseType.serviceCharge ? l.exAddInstalment : l.exAddExpense),
      ),
      body: all == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 96), children: [
              if (widget.initialType == ExpenseType.serviceCharge) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                  child: Text(l.exServiceChargesHint, style: Theme.of(context).textTheme.bodyMedium),
                ),
                _PlansCard(properties: props),
                const SizedBox(height: 12),
              ],
              Wrap(spacing: 12, runSpacing: 12, children: [
                dropdown<String>(const Key('filter-property'), l.exProperty, _property,
                    [(null, l.exAllProperties), for (final p in props) (p.id, p.name)], (v) => _property = v),
                if (widget.initialType == null)
                  dropdown<ExpenseType>(const Key('filter-type'), l.exType, _type,
                      [(null, l.exAllTypes), for (final t in ExpenseType.values) (t, expenseTypeLabel(l, t))], (v) => _type = v),
                dropdown<ExpenseStatus>(const Key('filter-status'), l.exStatus, _status,
                    [(null, l.exAllStatuses), for (final s in ExpenseStatus.values) (s, expenseStatusLabel(l, s))], (v) => _status = v),
                dropdown<ExpensePeriod>(const Key('filter-period'), l.exPeriod, _period, [
                  (ExpensePeriod.thisYear, l.exPeriodThisYear),
                  (ExpensePeriod.last12, l.exPeriodLast12),
                  (ExpensePeriod.all, l.exPeriodAll),
                ], (v) => _period = v ?? ExpensePeriod.thisYear),
              ]),
              const SizedBox(height: 12),
              if (list.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    '${l.exTotal}: ${formatAed(total)}${unpaid > 0 ? ' · ${l.exUnpaidPart(formatAed(unpaid))}' : ''}',
                    key: const Key('expenses-total'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              if (all.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Text(l.exNoExpenses, textAlign: TextAlign.center))
              else if (list.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Text(l.exNoMatches, textAlign: TextAlign.center))
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 4),
                    child: Column(children: [
                      for (final e in list)
                        ExpenseTile(
                          expense: e,
                          propertyName: name[e.propertyId] ?? '',
                          onTap: () => context.push('/expenses/${e.id}/edit'),
                        ),
                    ]),
                  ),
                ),
            ]),
    );
  }
}

/// Service-charge set-up per property (amount, frequency, next due), with a
/// shortcut to the property form where the plan lives.
class _PlansCard extends StatelessWidget {
  const _PlansCard({required this.properties});
  final List<Property> properties;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    if (properties.isEmpty) return const SizedBox.shrink();
    return Card(
      key: const Key('service-charge-plans'),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
        child: Column(children: [
          for (final p in properties)
            ListTile(
              key: Key('plan-${p.id}'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.apartment_outlined),
              title: Text(p.name),
              subtitle: Text(p.serviceChargeAnnual == null || p.serviceChargeAnnual! <= 0
                  ? l.exNoPlan
                  : [
                      '${formatAed(p.serviceChargeAnnual!)} / ${l.exFreqAnnual.toLowerCase()}',
                      frequencyLabel(l, p.serviceChargeFrequency),
                      if (p.serviceChargeNextDue != null) l.exDueOn(formatDate(p.serviceChargeNextDue!)),
                      if (p.hoaName.isNotEmpty) p.hoaName,
                    ].join(' · ')),
              trailing: TextButton(
                onPressed: () => context.push('/property/${p.id}/edit'),
                child: Text(p.serviceChargeAnnual == null ? l.exSetUpServiceCharges : l.edit),
              ),
            ),
        ]),
      ),
    );
  }
}
