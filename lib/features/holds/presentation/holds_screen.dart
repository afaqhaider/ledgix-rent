import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../domain/hold_request.dart';

class HoldsScreen extends ConsumerWidget {
  const HoldsScreen({super.key});

  String _label(AppLocalizations l, HoldStatus s) => switch (s) {
        HoldStatus.pending => l.holdPending,
        HoldStatus.approved => l.holdApproved,
        HoldStatus.rejected => l.holdRejected,
      };

  Future<void> _decide(WidgetRef ref, HoldRequest r, {required bool approve}) async {
    final payment = await ref.read(paymentRepositoryProvider).get(r.paymentId);
    if (payment == null) return;
    final res = approve ? HoldService.approve(r, payment) : HoldService.reject(r, payment);
    await ref.read(holdRepositoryProvider).save(res.request);
    await ref.read(paymentRepositoryProvider).save(res.payment);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final holds = ref.watch(holdsProvider).whenData((h) => [...h]..sort((a, b) => b.originalDate.compareTo(a.originalDate)));
    return Scaffold(
      appBar: AppBar(title: Text(l.holdRequests)),
      body: AsyncList<HoldRequest>(
        items: holds,
        builder: (c, r) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${l.originalDate}: ${formatDate(r.originalDate)}'),
              Text('${l.requestedDate}: ${formatDate(r.requestedDate)}'),
              if (r.reason.isNotEmpty) Text('${l.reason}: ${r.reason}'),
              const SizedBox(height: 8),
              if (r.status == HoldStatus.pending)
                Row(children: [
                  FilledButton(onPressed: () => _decide(ref, r, approve: true), child: Text(l.approve)),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () => _decide(ref, r, approve: false), child: Text(l.reject)),
                ])
              else
                StatusChip(_label(l, r.status), r.status == HoldStatus.approved ? Colors.green : Colors.red),
            ]),
          ),
        ),
      ),
    );
  }
}
