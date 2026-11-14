import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../leases/domain/lease.dart';
import '../../payments/domain/payment.dart';
import '../../properties/domain/property.dart';
import '../../tenants/domain/tenant.dart';
import '../domain/hold_request.dart';

/// Who and what a hold request is about, for the landlord's lists.
class HoldDetails {
  const HoldDetails({this.tenantName = '', this.propertyName = '', this.payment});
  final String tenantName, propertyName;
  final Payment? payment;
}

/// Looks up the tenant, property and cheque behind each hold request.
Map<String, HoldDetails> holdDetails(WidgetRef ref, Iterable<HoldRequest> holds) {
  final payments = {for (final p in ref.watch(paymentsProvider).value ?? const <Payment>[]) p.id: p};
  final leases = {for (final x in ref.watch(leasesProvider).value ?? const <Lease>[]) x.id: x};
  final tenants = {for (final t in ref.watch(tenantsProvider).value ?? const <Tenant>[]) t.id: t};
  final props = {for (final p in ref.watch(propertiesProvider).value ?? const <Property>[]) p.id: p};
  return {
    for (final r in holds)
      r.id: () {
        final pay = payments[r.paymentId];
        final lease = leases[r.leaseId.isNotEmpty ? r.leaseId : pay?.leaseId];
        final tenant = tenants[r.tenantId.isNotEmpty ? r.tenantId : lease?.tenantId];
        return HoldDetails(
          tenantName: tenant?.name ?? '',
          propertyName: props[lease?.propertyId]?.name ?? '',
          payment: pay,
        );
      }(),
  };
}

/// Asks the landlord for a short response when declining. Null if cancelled.
Future<String?> askDeclineResponse(BuildContext context) =>
    showDialog<String>(context: context, builder: (_) => const _DeclineDialog());

/// Owns its text controller, so it's disposed only after the close animation.
class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog();
  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AlertDialog(
      title: Text(l.hrDeclineTitle),
      content: SizedBox(
        width: 420,
        child: TextField(
          key: const Key('hold-decline-response'),
          controller: _ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(labelText: l.hrResponse, hintText: l.hrResponseHint),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          key: const Key('hold-decline-confirm'),
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: Text(l.hrDecline),
        ),
      ],
    );
  }
}

/// Approves (moves the due date) or declines a hold request.
Future<void> decideHold(WidgetRef ref, HoldRequest r, {required bool approve, String response = ''}) async {
  final payment = await ref.read(paymentRepositoryProvider).get(r.paymentId);
  if (payment == null) return;
  final res = approve
      ? HoldService.approve(r, payment, response: response)
      : HoldService.reject(r, payment, response: response);
  await ref.read(holdRepositoryProvider).save(res.request);
  await ref.read(paymentRepositoryProvider).save(res.payment);
}

/// Approve / Decline buttons, with the decline response dialog.
class HoldDecisionButtons extends ConsumerWidget {
  const HoldDecisionButtons({super.key, required this.request, this.dense = false});
  final HoldRequest request;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    final size = dense ? const Size(0, 36) : null;
    return Wrap(spacing: 8, runSpacing: 8, children: [
      FilledButton(
        key: Key('hold-approve-${request.id}'),
        style: FilledButton.styleFrom(minimumSize: size),
        onPressed: () async {
          await decideHold(ref, request, approve: true);
          messenger.showSnackBar(SnackBar(content: Text(l.hrApproved)));
        },
        child: Text(l.approve),
      ),
      OutlinedButton(
        key: Key('hold-decline-${request.id}'),
        style: OutlinedButton.styleFrom(minimumSize: size),
        onPressed: () async {
          final response = await askDeclineResponse(context);
          if (response == null) return;
          await decideHold(ref, request, approve: false, response: response);
          messenger.showSnackBar(SnackBar(content: Text(l.hrDeclined)));
        },
        child: Text(l.hrDecline),
      ),
    ]);
  }
}

class HoldsScreen extends ConsumerWidget {
  const HoldsScreen({super.key});

  String _label(AppLocalizations l, HoldStatus s) => switch (s) {
        HoldStatus.pending => l.holdPending,
        HoldStatus.approved => l.holdApproved,
        HoldStatus.rejected => l.holdRejected,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final holds = ref.watch(holdsProvider).whenData((h) => [...h]
      // Pending first, then newest.
      ..sort((a, b) {
        final p = (a.status == HoldStatus.pending ? 0 : 1).compareTo(b.status == HoldStatus.pending ? 0 : 1);
        return p != 0 ? p : b.originalDate.compareTo(a.originalDate);
      }));
    final details = holdDetails(ref, holds.value ?? const []);
    return Scaffold(
      appBar: ShellAppBar(title: Text(l.holdRequests)),
      body: AsyncList<HoldRequest>(
        items: holds,
        builder: (c, r) {
          final d = details[r.id] ?? const HoldDetails();
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (r.fromTenantApp)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: StatusChip(l.hrFromTenant, context.status.info, icon: Icons.phone_iphone),
                  ),
                if (d.tenantName.isNotEmpty || d.propertyName.isNotEmpty)
                  Text([d.tenantName, d.propertyName].where((s) => s.isNotEmpty).join(' · '),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                if (d.payment case final p?)
                  Text([formatAed(p.amount), if (p.chequeNo.isNotEmpty) '#${p.chequeNo}'].join(' · ')),
                Text('${l.originalDate}: ${formatDate(r.originalDate)}'),
                Text('${l.requestedDate}: ${formatDate(r.requestedDate)}'),
                if (r.reason.isNotEmpty) Text('${l.reason}: ${r.reason}'),
                if (r.note.isNotEmpty) Text(r.note),
                if (r.response.isNotEmpty) Text('${l.hrResponse}: ${r.response}'),
                const SizedBox(height: 8),
                if (r.status == HoldStatus.pending)
                  HoldDecisionButtons(request: r)
                else
                  r.status == HoldStatus.approved
                      ? StatusChip(_label(l, r.status), context.status.success, icon: Icons.check_circle_outline)
                      : StatusChip(_label(l, r.status), context.status.danger, icon: Icons.cancel_outlined),
              ]),
            ),
          );
        },
      ),
    );
  }
}
