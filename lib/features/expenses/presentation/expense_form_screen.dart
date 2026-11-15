import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/forms.dart';
import '../../documents/presentation/documents_editor.dart' show documentPickerProvider;
import '../../properties/domain/property.dart';
import '../domain/expense.dart';
import 'expense_ui.dart';

/// Add an expense, or edit one when [id] is given.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, this.id, this.prefill});
  final String? id;

  /// From the Expenses / Service charges pages: `type` and `propertyId`.
  final Map<String, String>? prefill;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _key = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _payee = TextEditingController();
  final _notes = TextEditingController();
  final _period = TextEditingController();
  Expense? _existing;
  String? _property;
  ExpenseType _type = ExpenseType.other;
  DateTime? _due;
  bool _paid = false;
  DateTime? _paidOn;
  XFile? _receipt;

  @override
  void initState() {
    super.initState();
    _existing = widget.id == null ? null : ref.read(expensesProvider).value?.where((e) => e.id == widget.id).firstOrNull;
    final e = _existing;
    if (e != null) {
      _property = e.propertyId;
      _type = e.type;
      _due = e.dueDate;
      _paid = e.isPaid;
      _paidOn = e.paidDate;
      _amount.text = e.amount == e.amount.roundToDouble() ? e.amount.toInt().toString() : '${e.amount}';
      _payee.text = e.payee;
      _notes.text = e.notes;
      _period.text = e.period;
    } else {
      _property = widget.prefill?['propertyId'];
      _type = ExpenseType.values.where((t) => t.name == widget.prefill?['type']).firstOrNull ?? ExpenseType.other;
      _due = todayGst();
    }
  }

  @override
  void dispose() {
    for (final c in [_amount, _payee, _notes, _period]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final e = _existing;
    final id = e?.id ?? newId();
    var receiptUrl = e?.receiptUrl;
    if (_receipt != null) receiptUrl = await ref.read(fileStorageProvider).uploadFile('expenses/$id/${_receipt!.name}', _receipt!);
    final paid = _paid;
    await ref.read(expenseRepositoryProvider).save(Expense(
          id: id,
          propertyId: _property!,
          type: _type,
          amount: parseMoney(_amount.text)!,
          dueDate: _due!,
          status: paid ? ExpenseStatus.paid : ExpenseStatus.due,
          paidDate: paid ? (_paidOn ?? todayGst()) : null,
          payee: _payee.text.trim(),
          notes: _notes.text.trim(),
          period: _period.text.trim(),
          leaseId: e?.leaseId,
          ticketId: e?.ticketId,
          receiptUrl: receiptUrl,
          source: e?.source ?? ExpenseSource.manual,
        ));
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final l = context.l;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.exDeleteExpense),
        content: Text(l.exDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(expenseRepositoryProvider).delete(_existing!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final props = ref.watch(propertiesProvider).value ?? const <Property>[];
    final e = _existing;
    final source = e == null ? null : expenseSourceLabel(l, e.source);
    return FormPage(
      title: e == null ? l.exAddExpense : l.exEditExpense,
      formKey: _key,
      onSave: _save,
      header: e == null
          ? null
          : Row(children: [
              if (source != null) Expanded(child: Text(source, style: Theme.of(context).textTheme.bodySmall)) else const Spacer(),
              TextButton.icon(
                key: const Key('delete-expense'),
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(l.exDeleteExpense),
              ),
            ]),
      children: [
        FormSection(title: l.exExpenses, icon: Icons.receipt_long_outlined, children: [
          FieldGrid(children: [
            DropdownButtonFormField<String>(
              key: const ValueKey('field-expense-property'),
              initialValue: props.any((p) => p.id == _property) ? _property : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: req(l.exProperty)),
              items: [for (final p in props) DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))],
              validator: (v) => v == null ? l.required : null,
              onChanged: (v) => setState(() => _property = v),
            ),
            DropdownButtonFormField<ExpenseType>(
              key: const ValueKey('field-expense-type'),
              initialValue: _type,
              isExpanded: true,
              decoration: InputDecoration(labelText: req(l.exType)),
              items: [for (final t in ExpenseType.values) DropdownMenuItem(value: t, child: Text(expenseTypeLabel(l, t)))],
              onChanged: (t) => setState(() => _type = t ?? _type),
            ),
            TextFormField(
              key: const ValueKey('field-expense-amount'),
              controller: _amount,
              decoration: InputDecoration(labelText: req(l.exAmount), suffixText: l.aed),
              keyboardType: moneyKeyboard,
              inputFormatters: moneyInput,
              validator: (v) => (parseMoney(v ?? '') ?? 0) <= 0 ? l.required : null,
            ),
            DateField(label: req(l.exDueDate), value: _due, onChanged: (d) => setState(() => _due = d)),
            TextFormField(controller: _payee, decoration: InputDecoration(labelText: l.exPayee)),
            TextFormField(controller: _period, decoration: InputDecoration(labelText: l.exPeriod, hintText: 'Q1 2027')),
            FullRow(TextFormField(controller: _notes, decoration: InputDecoration(labelText: l.exNotes), maxLines: 2)),
          ]),
        ]),
        FormSection(title: l.exStatusPaid, icon: Icons.task_alt, children: [
          SwitchListTile(
            key: const Key('field-expense-paid'),
            contentPadding: EdgeInsets.zero,
            title: Text(l.exStatusPaid),
            value: _paid,
            onChanged: (v) => setState(() {
              _paid = v;
              _paidOn ??= todayGst();
            }),
          ),
          if (_paid) DateField(label: l.exPaidDate, value: _paidOn, onChanged: (d) => setState(() => _paidOn = d)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            OutlinedButton.icon(
              key: const Key('expense-receipt'),
              onPressed: () async {
                final f = await ref.read(documentPickerProvider)(context);
                if (f != null) setState(() => _receipt = f);
              },
              icon: const Icon(Icons.attach_file),
              label: Text(e?.receiptUrl == null && _receipt == null ? l.exAttachReceipt : l.exReplaceReceipt),
            ),
            if (_receipt != null) Text(_receipt!.name),
            if (_receipt == null && e?.receiptUrl != null)
              TextButton(
                onPressed: () => launchUrl(Uri.parse(e!.receiptUrl!), mode: LaunchMode.externalApplication),
                child: Text(l.exViewReceipt),
              ),
          ]),
        ]),
      ],
    );
  }
}
