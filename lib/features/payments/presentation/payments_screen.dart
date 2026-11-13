import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../holds/domain/hold_request.dart';
import '../../leases/domain/lease.dart';
import '../domain/payment.dart';

String statusLabel(AppLocalizations l, PaymentStatus s) => switch (s) {
      PaymentStatus.pending => l.statusPending,
      PaymentStatus.deposited => l.statusDeposited,
      PaymentStatus.cleared => l.statusCleared,
      PaymentStatus.bounced => l.statusBounced,
      PaymentStatus.onHold => l.statusOnHold,
    };

/// Cheque manager (type == cheque) and direct-debit tracking (type == directDebit).
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key, required this.type});
  final PaymentMethod type;
  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  PaymentStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final all = ref.watch(paymentsProvider);
    final list = all.whenData((ps) => (ps.where((p) => p.type == widget.type && (_filter == null || p.status == _filter)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate))));
    final title = widget.type == PaymentMethod.cheque ? l.cheques : l.directDebits;
    return Scaffold(
      appBar: ShellAppBar(title: Text(title)),
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: ChoiceChip(label: Text(l.all), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
            ),
            for (final s in PaymentStatus.values)
              Padding(
                padding: const EdgeInsets.all(4),
                child: ChoiceChip(label: Text(statusLabel(l, s)), selected: _filter == s, onSelected: (_) => setState(() => _filter = s)),
              ),
          ]),
        ),
        Expanded(child: AsyncList<Payment>(items: list, builder: (c, p) => PaymentCard(payment: p))),
      ]),
    );
  }
}

class PaymentCard extends ConsumerWidget {
  const PaymentCard({super.key, required this.payment});
  final Payment payment;

  Future<void> _set(WidgetRef ref, PaymentStatus s) => ref.read(paymentRepositoryProvider).save(
      payment.copyWith(status: s, depositedDate: s == PaymentStatus.deposited ? todayGst() : null));

  Future<void> _attach(WidgetRef ref) async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f == null) return;
    final url = await ref.read(fileStorageProvider).upload('cheques/${payment.id}/${f.name}', f.path);
    await ref.read(paymentRepositoryProvider).save(payment.copyWith(imageUrl: url));
  }

  Future<void> _requestHold(BuildContext context, WidgetRef ref) async {
    final reason = TextEditingController();
    var date = payment.dueDate.add(const Duration(days: 14));
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(c.l.requestHold),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              title: Text(c.l.requestedDate),
              trailing: Text(formatDate(date)),
              onTap: () async {
                final d = await pickDate(c, date);
                if (d != null) set(() => date = d);
              },
            ),
            TextField(controller: reason, decoration: InputDecoration(labelText: c.l.reason)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(c.l.save)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final r = HoldService.open(id: newId(), payment: payment, requestedDate: date, reason: reason.text.trim());
    await ref.read(holdRepositoryProvider).save(r.request);
    await ref.read(paymentRepositoryProvider).save(r.payment);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final color = AppTheme.statusColor(context, payment.status);
    final isCheque = payment.type == PaymentMethod.cheque;
    final failedDebit = !isCheque && payment.status == PaymentStatus.bounced;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(formatAed(payment.amount), style: Theme.of(context).textTheme.titleLarge)),
            StatusChip(failedDebit ? l.failedDebit : statusLabel(l, payment.status), color, icon: AppTheme.statusIcon(payment.status)),
          ]),
          const SizedBox(height: 4),
          Text('${l.dueDate}: ${formatDate(payment.dueDate)}'),
          if (payment.chequeNo.isNotEmpty || payment.bankName.isNotEmpty)
            Text('${payment.chequeNo} ${payment.bankName}'.trim()),
          if (payment.imageUrl != null) Text('📎 ${l.attached}'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            if (payment.status == PaymentStatus.pending && isCheque)
              ActionChip(label: Text(l.markDeposited), onPressed: () => _set(ref, PaymentStatus.deposited)),
            if (payment.status == PaymentStatus.pending && !isCheque)
              ActionChip(label: Text(l.markCleared), onPressed: () => _set(ref, PaymentStatus.cleared)),
            if (payment.status == PaymentStatus.deposited)
              ActionChip(label: Text(l.markCleared), onPressed: () => _set(ref, PaymentStatus.cleared)),
            if (payment.status == PaymentStatus.pending || payment.status == PaymentStatus.deposited)
              ActionChip(label: Text(l.markBounced), onPressed: () => _set(ref, PaymentStatus.bounced)),
            if (isCheque) ActionChip(label: Text(l.attachPhoto), onPressed: () => _attach(ref)),
            if (payment.status == PaymentStatus.pending)
              ActionChip(label: Text(l.requestHold), onPressed: () => _requestHold(context, ref)),
          ]),
        ]),
      ),
    );
  }
}
