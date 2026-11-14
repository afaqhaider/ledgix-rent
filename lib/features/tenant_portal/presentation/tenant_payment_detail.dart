import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../holds/domain/hold_request.dart';
import '../../payments/domain/payment.dart';
import '../../payments/presentation/payments_screen.dart' show statusLabel;
import '../data/tenant_portal.dart';
import '../domain/tenant_view.dart';
import '../tenant_providers.dart';

/// Full-size cheque copy the landlord shared.
Future<void> showChequeCopy(BuildContext context, String url) {
  final l = context.l;
  return showDialog<void>(
    context: context,
    builder: (c) => Dialog(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(12), child: Text(l.tpChequeCopy)),
        Flexible(
          child: InteractiveViewer(
            child: Image.network(url,
                errorBuilder: (_, _, _) =>
                    const Padding(padding: EdgeInsets.all(32), child: Icon(Icons.broken_image_outlined, size: 48))),
          ),
        ),
        TextButton(onPressed: () => Navigator.pop(c), child: Text(l.close)),
      ]),
    ),
  );
}

/// Latest hold request for [paymentId] (newest first by createdAt, then dates).
TvHoldRequest? latestHoldRequest(List<TvHoldRequest> all, String landlordUid, String paymentId) {
  final mine = [
    for (final r in all)
      if (r.paymentId == paymentId && r.landlordUid == landlordUid) r,
  ]..sort((a, b) => (b.createdAt ?? b.requestedDate).compareTo(a.createdAt ?? a.requestedDate));
  return mine.firstOrNull;
}

String holdErrorText(AppLocalizations l, HoldRequestError e) => switch (e) {
      HoldRequestError.reasonRequired => l.hrErrReason,
      HoldRequestError.dateNotAfterDue => l.hrErrDate,
      HoldRequestError.dateTooFar => l.hrErrTooFar(maxHoldDays),
      HoldRequestError.alreadyOpen => l.hrErrOpen,
      HoldRequestError.notAllowed => l.hrErrNotAllowed,
    };

/// Opens the payment detail: a dialog on wide screens, a bottom sheet on phones.
Future<void> showTenantPaymentDetail(BuildContext context, TvPayment payment) {
  final wide = MediaQuery.sizeOf(context).width >= 720;
  final body = TenantPaymentDetail(landlordUid: payment.landlordUid, paymentId: payment.id);
  if (wide) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720), child: body),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (c) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom), child: body),
  );
}

/// One payment, its cheque copy, and the tenant's hold request (status or form).
/// Reads live from the tenant's view, so the landlord's answer appears here.
class TenantPaymentDetail extends ConsumerStatefulWidget {
  const TenantPaymentDetail({super.key, required this.landlordUid, required this.paymentId});
  final String landlordUid, paymentId;

  @override
  ConsumerState<TenantPaymentDetail> createState() => _TenantPaymentDetailState();
}

class _TenantPaymentDetailState extends ConsumerState<TenantPaymentDetail> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _note = TextEditingController();
  bool _asking = false, _sending = false;
  DateTime? _date;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TvPayment p) async {
    final first = DateUtils.dateOnly(p.dueDate).add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? first.add(const Duration(days: 6)),
      firstDate: first,
      lastDate: DateUtils.dateOnly(p.dueDate).add(const Duration(days: maxHoldDays)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _send(TvPayment p, List<TvHoldRequest> holds) async {
    final l = context.l;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final date = _date ?? DateUtils.dateOnly(p.dueDate).add(const Duration(days: 7));
    final local = checkTenantHoldRequest(
      status: p.status,
      dueDate: p.dueDate,
      requestedDate: date,
      reason: _reason.text,
      existing: [for (final h in holds) h.asHoldRequest()],
      paymentId: p.id,
    );
    if (local != null) {
      setState(() => _error = holdErrorText(l, local));
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(tenantPortalProvider).createHoldRequest(
            tenantUid: ref.read(userIdProvider).value ?? 'anon',
            landlordUid: p.landlordUid,
            paymentId: p.id,
            requestedDate: date,
            reason: _reason.text.trim(),
            note: _note.text.trim(),
          );
      if (!mounted) return;
      setState(() => _asking = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.hrSent)));
    } on HoldRequestException catch (e) {
      if (mounted) setState(() => _error = holdErrorText(l, e.reason));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final text = Theme.of(context).textTheme;
    final payments = ref.watch(tenantPaymentsProvider).value ?? const <TvPayment>[];
    final p = payments.where((x) => x.id == widget.paymentId && x.landlordUid == widget.landlordUid).firstOrNull;
    if (p == null) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    final holds = ref.watch(tenantHoldRequestsProvider).value ?? const <TvHoldRequest>[];
    final landlords = {for (final x in ref.watch(tenantLandlordsProvider).value ?? const <TvLandlord>[]) x.landlordUid: x};
    final hold = latestHoldRequest(holds, p.landlordUid, p.id);
    final open = hold?.status == HoldStatus.pending;
    final canAsk = !open &&
        (p.status == PaymentStatus.pending || p.status == PaymentStatus.onHold) &&
        landlords[p.landlordUid]?.status != LinkStatus.former;

    Widget row(String label, String value) => value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 120, child: Text(label, style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
              Expanded(child: Text(value, style: text.bodyMedium)),
            ]),
          );

    return SingleChildScrollView(
      key: const Key('tenant-payment-detail'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text(l.hrPaymentDetails, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text(formatAed(p.amount), style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
            StatusChip(statusLabel(l, p.status), AppTheme.statusColor(context, p.status), icon: AppTheme.statusIcon(p.status)),
          ]),
          const SizedBox(height: 8),
          row(l.dueDate, formatDate(p.dueDate)),
          row(l.property, p.propertyName),
          row(l.landlord, landlords[p.landlordUid]?.name ?? ''),
          row(l.chequeNo, p.chequeNo),
          row(l.bankName, p.bankName),
          if (p.imageUrl != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: Key('detail-cheque-copy-${p.id}'),
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(l.tpViewChequeCopy),
              onPressed: () => showChequeCopy(context, p.imageUrl!),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (hold != null) ...[
            _HoldStatusCard(hold: hold),
            const SizedBox(height: 12),
          ],
          if (canAsk && !_asking)
            FilledButton.icon(
              key: const Key('request-hold'),
              icon: const Icon(Icons.pause_circle_outline),
              label: Text(l.hrRequestHold),
              onPressed: () => setState(() {
                _asking = true;
                _date ??= DateUtils.dateOnly(p.dueDate).add(const Duration(days: 7));
              }),
            ),
          if (canAsk && _asking) ...[
            Text(l.hrRequestHold, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(l.hrRequestHoldSub, style: text.bodySmall),
            const SizedBox(height: 12),
            InkWell(
              key: const Key('hold-date'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickDate(p),
              child: InputDecorator(
                decoration: InputDecoration(labelText: l.hrNewDate, prefixIcon: const Icon(Icons.event_outlined)),
                child: Text(_date == null ? l.hrPickDate : formatDate(_date!)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('hold-reason'),
              controller: _reason,
              maxLines: 2,
              decoration: InputDecoration(labelText: l.hrReason, hintText: l.hrReasonHint),
              validator: (v) => (v ?? '').trim().isEmpty ? l.hrErrReason : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('hold-note'),
              controller: _note,
              maxLines: 2,
              decoration: InputDecoration(labelText: l.hrNote),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, key: const Key('hold-error'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _sending ? null : () => setState(() => _asking = false),
                  child: Text(l.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('hold-send'),
                  onPressed: _sending ? null : () => _send(p, holds),
                  child: _sending
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l.hrSend),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _HoldStatusCard extends StatelessWidget {
  const _HoldStatusCard({required this.hold});
  final TvHoldRequest hold;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final status = context.status;
    final (label, color, icon) = switch (hold.status) {
      HoldStatus.pending => (l.hrStatusPending, status.warning, Icons.hourglass_top),
      HoldStatus.approved => (l.hrStatusApproved(formatDate(hold.requestedDate)), status.success, Icons.check_circle_outline),
      HoldStatus.rejected => (l.hrStatusDeclined, status.danger, Icons.cancel_outlined),
    };
    final text = Theme.of(context).textTheme;
    return Container(
      key: const Key('hold-status'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: color))),
        ]),
        const SizedBox(height: 6),
        Text(l.hrMoveTo(formatDate(hold.originalDate), formatDate(hold.requestedDate)), style: text.bodySmall),
        if (hold.reason.isNotEmpty) Text('${l.hrYourReason}: ${hold.reason}', style: text.bodySmall),
        if (hold.status == HoldStatus.rejected && hold.response.isNotEmpty)
          Text('${l.hrLandlordResponse}: ${hold.response}', style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
