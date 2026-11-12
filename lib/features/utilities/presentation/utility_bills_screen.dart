import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../properties/domain/property.dart';
import '../domain/utility_bill.dart';

String providerLabel(AppLocalizations l, UtilityProvider p) => switch (p) {
      UtilityProvider.dewa => l.dewaLabel,
      UtilityProvider.chiller => l.chillerLabel,
      UtilityProvider.sewa => l.sewaLabel,
      UtilityProvider.addc => l.addcLabel,
      UtilityProvider.aadc => l.aadcLabel,
    };

String billStatusLabel(AppLocalizations l, BillStatus s) =>
    switch (s) { BillStatus.unpaid => l.billUnpaid, BillStatus.paid => l.billPaid, BillStatus.overdue => l.billOverdue };

class UtilityBillsScreen extends ConsumerWidget {
  const UtilityBillsScreen({super.key, required this.propertyId});
  final String propertyId;

  Future<void> _fetch(BuildContext context, WidgetRef ref, Property p) async {
    final l = context.l;
    final accounts = <UtilityProvider, String>{
      if (p.dewaAccountNo.isNotEmpty) UtilityProvider.dewa: p.dewaAccountNo,
      if (p.chillerAccountNo.isNotEmpty) UtilityProvider.chiller: p.chillerAccountNo,
    };
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.noAccountNo)));
      return;
    }
    final existing = await ref.read(utilityBillRepositoryProvider).watchAll().first;
    for (final e in accounts.entries) {
      final info = await ref.read(utilityBillServiceProvider).fetchBill(e.key, e.value);
      final dup = existing.any((b) => b.propertyId == p.id && b.provider == e.key && b.period == info.period);
      if (dup) continue;
      await ref.read(utilityBillRepositoryProvider).save(UtilityBill(
            id: newId(),
            propertyId: p.id,
            provider: e.key,
            accountNo: e.value,
            period: info.period,
            amount: info.amount,
            dueDate: info.dueDate,
            paidBy: p.utilityPaidBy,
            source: 'api',
          ));
    }
  }

  Future<void> _manual(BuildContext context, WidgetRef ref, Property p) async {
    final l = context.l;
    final amount = TextEditingController(), account = TextEditingController();
    var provider = UtilityProvider.dewa;
    var due = todayGst().add(const Duration(days: 14));
    String? pdf;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(l.addBill),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<UtilityProvider>(
                initialValue: provider,
                decoration: InputDecoration(labelText: l.provider),
                items: [for (final x in UtilityProvider.values) DropdownMenuItem(value: x, child: Text(providerLabel(l, x)))],
                onChanged: (v) => set(() => provider = v ?? provider),
              ),
              TextField(controller: account, decoration: InputDecoration(labelText: l.accountNo)),
              TextField(controller: amount, decoration: InputDecoration(labelText: l.amount), keyboardType: TextInputType.number),
              ListTile(
                title: Text(l.dueDate),
                trailing: Text(formatDate(due)),
                onTap: () async {
                  final d = await pickDate(c, due);
                  if (d != null) set(() => due = d);
                },
              ),
              OutlinedButton.icon(
                icon: Icon(pdf == null ? Icons.attach_file : Icons.check),
                label: Text(pdf == null ? l.attachBill : l.attached),
                onPressed: () async {
                  final f = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (f == null) return;
                  final url = await ref.read(fileStorageProvider).upload('bills/${p.id}/${newId()}_${f.name}', f.path);
                  set(() => pdf = url);
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.save)),
          ],
        ),
      ),
    );
    final a = double.tryParse(amount.text);
    if (ok != true || a == null) return;
    await ref.read(utilityBillRepositoryProvider).save(UtilityBill(
          id: newId(),
          propertyId: p.id,
          provider: provider,
          accountNo: account.text.trim().isEmpty
              ? (provider == UtilityProvider.dewa ? p.dewaAccountNo : p.chillerAccountNo)
              : account.text.trim(),
          period: '${due.year}-${due.month.toString().padLeft(2, '0')}',
          amount: a,
          dueDate: due,
          paidBy: p.utilityPaidBy,
          pdfUrl: pdf,
        ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final p = ref.watch(propertiesProvider).value?.where((x) => x.id == propertyId).firstOrNull;
    if (p == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final today = todayGst();
    final bills = ref.watch(utilityBillsProvider).whenData((all) =>
        all.where((b) => b.propertyId == propertyId).toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate)));
    return Scaffold(
      appBar: AppBar(title: Text('${l.utilityBills} · ${p.name}'), actions: [
        IconButton(tooltip: l.fetchBill, icon: const Icon(Icons.cloud_download_outlined), onPressed: () => _fetch(context, ref, p)),
      ]),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => _manual(context, ref, p),
        icon: const Icon(Icons.add),
        label: Text(l.addBill),
      ),
      body: Column(children: [
        ListTile(
          title: Text(l.paidBy),
          trailing: SegmentedButton<PaidBy>(
            segments: [
              ButtonSegment(value: PaidBy.landlord, label: Text(l.landlord)),
              ButtonSegment(value: PaidBy.tenant, label: Text(l.tenant)),
            ],
            selected: {p.utilityPaidBy},
            onSelectionChanged: (s) => ref.read(propertyRepositoryProvider).save(p.copyWith(utilityPaidBy: s.first)),
          ),
        ),
        Expanded(
          child: AsyncList<UtilityBill>(
            items: bills,
            builder: (c, b) {
              final st = b.effectiveStatus(today);
              final color = switch (st) { BillStatus.paid => Colors.green, BillStatus.overdue => Colors.red, BillStatus.unpaid => Colors.orange };
              return Card(
                child: ListTile(
                  title: Text('${providerLabel(l, b.provider)} · ${b.period}  ${formatAed(b.amount)}'),
                  subtitle: Text('${l.dueDate}: ${formatDate(b.dueDate)} · ${l.paidBy}: ${b.paidBy == PaidBy.landlord ? l.landlord : l.tenant}'
                      '${b.pdfUrl != null ? ' · 📎' : ''}'),
                  trailing: st == BillStatus.paid
                      ? StatusChip(billStatusLabel(l, st), color)
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          StatusChip(billStatusLabel(l, st), color),
                          GestureDetector(
                            onTap: () => ref.read(utilityBillRepositoryProvider).save(b.copyWith(status: BillStatus.paid)),
                            child: Text(l.markPaid, style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
                          ),
                        ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
