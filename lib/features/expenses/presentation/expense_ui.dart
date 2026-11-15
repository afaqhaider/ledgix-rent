import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/forms.dart';
import '../../documents/presentation/documents_editor.dart' show documentPickerProvider;
import '../../properties/domain/property.dart';
import '../data/expense_sync.dart';
import '../domain/expense.dart';
import '../domain/profitability.dart';
import '../domain/service_charge_plan.dart';

final expenseSyncProvider = Provider<ExpenseSync>((ref) => ExpenseSync(ref.watch(expenseRepositoryProvider)));

/// Portfolio profit and loss for this calendar year (dashboard card).
final profitThisYearProvider = Provider<Profitability>((ref) {
  final today = todayGst();
  return Profitability.compute(
    range: DateRange.thisYear(today),
    today: today,
    properties: ref.watch(propertiesProvider).value ?? const [],
    leases: ref.watch(leasesProvider).value ?? const [],
    payments: ref.watch(paymentsProvider).value ?? const [],
    expenses: ref.watch(expensesProvider).value ?? const [],
    tickets: ref.watch(ticketsProvider).value ?? const [],
    bills: ref.watch(utilityBillsProvider).value ?? const [],
  );
});

String expenseTypeLabel(AppLocalizations l, ExpenseType t) => switch (t) {
      ExpenseType.serviceCharge => l.exTypeServiceCharge,
      ExpenseType.agencyFee => l.exTypeAgencyFee,
      ExpenseType.maintenance => l.exTypeMaintenance,
      ExpenseType.other => l.exTypeOther,
    };

IconData expenseTypeIcon(ExpenseType t) => switch (t) {
      ExpenseType.serviceCharge => Icons.apartment_outlined,
      ExpenseType.agencyFee => Icons.handshake_outlined,
      ExpenseType.maintenance => Icons.handyman_outlined,
      ExpenseType.other => Icons.receipt_outlined,
    };

String expenseStatusLabel(AppLocalizations l, ExpenseStatus s) => switch (s) {
      ExpenseStatus.due => l.exStatusDue,
      ExpenseStatus.paid => l.exStatusPaid,
      ExpenseStatus.overdue => l.exStatusOverdue,
    };

Color expenseStatusColor(BuildContext context, ExpenseStatus s) => switch (s) {
      ExpenseStatus.due => context.status.info,
      ExpenseStatus.paid => context.status.success,
      ExpenseStatus.overdue => context.status.danger,
    };

IconData expenseStatusIcon(ExpenseStatus s) => switch (s) {
      ExpenseStatus.due => Icons.schedule,
      ExpenseStatus.paid => Icons.check_circle_outline,
      ExpenseStatus.overdue => Icons.error_outline,
    };

String frequencyLabel(AppLocalizations l, ServiceChargeFrequency f) => switch (f) {
      ServiceChargeFrequency.annual => l.exFreqAnnual,
      ServiceChargeFrequency.semiAnnual => l.exFreqSemiAnnual,
      ServiceChargeFrequency.quarterly => l.exFreqQuarterly,
      ServiceChargeFrequency.monthly => l.exFreqMonthly,
      ServiceChargeFrequency.custom => l.exFreqCustom,
    };

String? expenseSourceLabel(AppLocalizations l, ExpenseSource s) => switch (s) {
      ExpenseSource.schedule => l.exFromPlan,
      ExpenseSource.agreement => l.exFromAgreement,
      ExpenseSource.ticket => l.exFromTicket,
      ExpenseSource.manual => null,
    };

/// "Due 12/03/2027", "Paid 01/03/2027" or "5 days overdue".
String expenseWhen(AppLocalizations l, Expense e, DateTime today) => switch (e.statusOn(today)) {
      ExpenseStatus.paid => l.exPaidOn(formatDate(e.paidDate ?? e.dueDate)),
      ExpenseStatus.overdue => l.exOverdueDays(today.difference(e.dueDate).inDays),
      ExpenseStatus.due => l.exDueOn(formatDate(e.dueDate)),
    };

/// Asks for the paid date (and an optional receipt), then marks [e] paid.
/// Returns true when it was marked.
Future<bool> markExpensePaid(BuildContext context, WidgetRef ref, Expense e) async {
  final l = context.l;
  final picked = await showDialog<({DateTime date, bool receipt})>(
    context: context,
    builder: (c) {
      var date = todayGst();
      return StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(l.exMarkPaid),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${expenseTypeLabel(l, e.type)} · ${formatAed(e.amount)}'),
            const SizedBox(height: 16),
            DateField(label: l.exPaidDate, value: date, onChanged: (d) => set(() => date = d)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
            TextButton(
              key: const Key('mark-paid-with-receipt'),
              onPressed: () => Navigator.pop(c, (date: date, receipt: true)),
              child: Text(l.exAttachReceipt),
            ),
            FilledButton(
              key: const Key('mark-paid-confirm'),
              onPressed: () => Navigator.pop(c, (date: date, receipt: false)),
              child: Text(l.exMarkPaid),
            ),
          ],
        ),
      );
    },
  );
  if (picked == null || !context.mounted) return false;
  String? receipt;
  if (picked.receipt) {
    final file = await ref.read(documentPickerProvider)(context);
    if (file != null) receipt = await ref.read(fileStorageProvider).uploadFile('expenses/${e.id}/${file.name}', file);
  }
  final property = (ref.read(propertiesProvider).value ?? const <Property>[]).where((p) => p.id == e.propertyId).firstOrNull;
  await ref.read(expenseSyncProvider).markPaid(e, picked.date, receiptUrl: receipt, property: property);
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.exMarkedPaid)));
  return true;
}

/// One expense in a list: type icon, property, amount, when, status and a
/// quick "Mark paid" for unpaid ones.
class ExpenseTile extends ConsumerWidget {
  const ExpenseTile({super.key, required this.expense, required this.propertyName, this.onTap, this.dense = false});
  final Expense expense;
  final String propertyName;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final today = todayGst();
    final s = expense.statusOn(today);
    final color = expenseStatusColor(context, s);
    final title = [propertyName, if (expense.period.isNotEmpty) expense.period].where((x) => x.isNotEmpty).join(' · ');
    return ListTile(
      key: Key('expense-${expense.id}'),
      dense: dense,
      contentPadding: const EdgeInsetsDirectional.only(start: 0, end: 4),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        child: Icon(expenseTypeIcon(expense.type), size: 20),
      ),
      title: Text(title.isEmpty ? expenseTypeLabel(l, expense.type) : title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [expenseTypeLabel(l, expense.type), expenseWhen(l, expense, today), if (expense.payee.isNotEmpty) expense.payee].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatAed(expense.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
          StatusChip(expenseStatusLabel(l, s), color, icon: expenseStatusIcon(s)),
        ]),
        if (!expense.isPaid)
          IconButton(
            key: Key('mark-paid-${expense.id}'),
            tooltip: l.exMarkPaid,
            icon: const Icon(Icons.task_alt),
            onPressed: () => markExpensePaid(context, ref, expense),
          ),
      ]),
    );
  }
}
