import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/feature_flags.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../leases/domain/lease.dart';
import '../../tenants/domain/tenant.dart';
import '../../vendors/domain/vendor.dart';
import '../domain/maintenance_ticket.dart';
import '../domain/quote.dart';
import '../domain/work_order.dart';
import 'maintenance_screen.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  const TicketDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _note = TextEditingController();
  String? _vendorId;
  bool _share = false, _vendorTouched = false;

  Tenant? _tenantFor(MaintenanceTicket t) {
    final leases = ref.read(leasesProvider).value ?? const <Lease>[];
    final lease = leases.where((x) => x.propertyId == t.propertyId && x.status == LeaseStatus.active).firstOrNull;
    return (ref.read(tenantsProvider).value ?? []).where((x) => x.id == lease?.tenantId).firstOrNull;
  }

  Future<void> _forward(MaintenanceTicket t) async {
    final l = context.l;
    final vendors = ref.read(vendorsProvider).value ?? <Vendor>[];
    final vendor = vendors.where((v) => v.id == _vendorId).firstOrNull;
    final property = (ref.read(propertiesProvider).value ?? []).where((p) => p.id == t.propertyId).firstOrNull;
    if (vendor == null || property == null) return;
    final shared = t.copyWith(shareTenantContact: _share);
    final order = WorkOrderBuilder.build(
      id: newId(),
      token: '${newId()}${newId()}'.replaceAll('-', ''),
      ticket: shared,
      property: property,
      vendor: vendor,
      tenant: _tenantFor(t),
      note: _note.text,
      now: nowGst(),
    );
    // Cloud Functions deliver the order (push for app users, email with a
    // secure link otherwise); demo mode only stores it.
    await ref.read(workOrderRepositoryProvider).save(order);
    await ref.read(maintenanceRepositoryProvider).save(shared.copyWith(
          status: TicketStatus.requested,
          forwardedToVendorId: vendor.id,
          forwardChannel: order.channel,
          landlordNote: _note.text.trim(),
        ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(order.channel == ForwardChannel.app ? l.forwardedApp : l.forwardedEmail)));
  }

  Future<void> _save(MaintenanceTicket t) => ref.read(maintenanceRepositoryProvider).save(t);

  Future<void> _quoteDialog(MaintenanceTicket t) async {
    final l = context.l;
    final amount = TextEditingController(), vat = TextEditingController(), scope = TextEditingController();
    DateTime? visit;
    final vendorId = t.forwardedToVendorId ?? t.vendorId ?? _vendorId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(l.addQuote),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: amount, decoration: InputDecoration(labelText: l.amount), keyboardType: TextInputType.number),
              TextField(controller: vat, decoration: InputDecoration(labelText: l.vat), keyboardType: TextInputType.number),
              TextField(controller: scope, decoration: InputDecoration(labelText: l.scope), maxLines: 2),
              ListTile(
                title: Text(l.proposedVisit),
                trailing: Text(visit == null ? '-' : formatDate(visit!)),
                onTap: () async {
                  final d = await pickDate(c, todayGst());
                  if (d != null) set(() => visit = d);
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
    if (ok != true || a == null || vendorId == null) return;
    await ref.read(quoteRepositoryProvider).save(Quote(
          id: newId(),
          ticketId: t.id,
          vendorId: vendorId,
          amount: a,
          vat: double.tryParse(vat.text) ?? 0,
          scope: scope.text.trim(),
          proposedVisit: visit,
        ));
    await _save(QuoteFlow.onQuoteReceived(t));
  }

  Future<void> _decide(Quote q, MaintenanceTicket t, {required bool approve}) async {
    final r = approve ? QuoteFlow.approve(q, t) : QuoteFlow.reject(q, t);
    await ref.read(quoteRepositoryProvider).save(r.quote);
    await _save(r.ticket);
    if (!approve || !mounted) return;
    final notice = QuoteFlow.tenantVisitNotice(r.ticket, formatDateTime);
    if (notice != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notice)));
  }

  Future<void> _ask(Quote q, MaintenanceTicket t) async {
    final l = context.l;
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.askQuestion),
        content: TextField(controller: ctl, decoration: InputDecoration(labelText: l.question)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.save)),
        ],
      ),
    );
    if (ok == true && ctl.text.trim().isNotEmpty) {
      await ref.read(quoteRepositoryProvider).save(QuoteFlow.ask(q, t, ctl.text.trim()).quote);
    }
  }

  Future<void> _closeWithRating(MaintenanceTicket t) async {
    final l = context.l;
    final rating = await showDialog<int>(
      context: context,
      builder: (c) => SimpleDialog(title: Text(l.rating), children: [
        for (var i = 5; i >= 1; i--) SimpleDialogOption(onPressed: () => Navigator.pop(c, i), child: Text('★' * i)),
      ]),
    );
    if (rating != null) await _save(QuoteFlow.tenantConfirm(t, rating));
  }

  String _quoteLabel(AppLocalizations l, QuoteStatus s) => switch (s) {
        QuoteStatus.submitted => l.quoteSubmitted,
        QuoteStatus.approved => l.quoteApproved,
        QuoteStatus.rejected => l.quoteRejected,
        QuoteStatus.questionAsked => l.quoteQuestion,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = ref.watch(ticketsProvider).value?.where((x) => x.id == widget.id).firstOrNull;
    if (t == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final property = (ref.watch(propertiesProvider).value ?? []).where((p) => p.id == t.propertyId).firstOrNull;
    final vendors = ref.watch(vendorsProvider).value ?? <Vendor>[];
    final quotes = (ref.watch(quotesProvider).value ?? []).where((q) => q.ticketId == t.id).toList();
    final vendorNames = {for (final v in vendors) v.id: v.name};

    if (!_vendorTouched && _vendorId == null && property != null) {
      _vendorId = WorkOrderBuilder.defaultVendor(t, property, vendors)?.id;
    }

    return Scaffold(
      appBar: ShellAppBar(title: Text(l.ticketDetails)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(t.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          StatusChip(ticketStatusLabel(l, t.status), Theme.of(context).colorScheme.primary),
          StatusChip(priorityLabel(l, t.priority), t.priority.index >= 2 ? context.status.danger : context.status.neutral,
                icon: t.priority.index >= 2 ? Icons.priority_high : Icons.low_priority),
          StatusChip(categoryLabel(l, t.category), context.status.neutral),
        ]),
        if (property != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(property.name)),
        if (t.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(t.description)),
        if (t.visitRequired) ...[
          const SizedBox(height: 8),
          for (final s in t.timeSlots) Text('🗓 ${formatDateTime(s)}'),
          if (t.accessNotes.isNotEmpty) Text('🔑 ${t.accessNotes}'),
        ],
        if (t.photos.isNotEmpty || t.videos.isNotEmpty) Text('📎 ${t.photos.length} / ${t.videos.length}'),
        if (t.confirmedVisit != null) Text('✅ ${l.visitConfirmed}: ${formatDateTime(t.confirmedVisit!)}'),
        if (t.cost > 0) Text('${l.cost}: ${formatAed(t.cost)}'),
        if (t.tenantRating != null) Text('${l.rating}: ${'★' * t.tenantRating!}'),
        const Divider(height: 32),

        if (FeatureFlags.maintenanceForwarding && t.status == TicketStatus.open) ...[
          Text(l.maintenanceCompany, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _vendorId,
            decoration: InputDecoration(labelText: l.maintenanceCompany),
            items: [for (final v in vendors) DropdownMenuItem(value: v.id, child: Text(v.name))],
            onChanged: (v) => setState(() {
              _vendorId = v;
              _vendorTouched = true;
            }),
          ),
          const SizedBox(height: 8),
          TextField(controller: _note, decoration: InputDecoration(labelText: l.landlordNote), maxLines: 2),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l.shareTenantContact), value: _share, onChanged: (v) => setState(() => _share = v)),
          FilledButton.icon(
            icon: const Icon(Icons.send),
            label: Text(l.requestQuote),
            onPressed: _vendorId == null ? null : () => _forward(t),
          ),
          const Divider(height: 32),
        ],

        if (t.forwardedToVendorId != null)
          Text('${l.maintenanceCompany}: ${vendorNames[t.forwardedToVendorId] ?? '-'} · '
              '${t.forwardChannel == ForwardChannel.app ? l.forwardedApp : l.forwardedEmail}'),
        Row(children: [
          Expanded(child: Text(l.quotes, style: Theme.of(context).textTheme.titleMedium)),
          if (t.status != TicketStatus.open || quotes.isNotEmpty)
            TextButton.icon(icon: const Icon(Icons.add), label: Text(l.addQuote), onPressed: () => _quoteDialog(t)),
        ]),
        if (quotes.isEmpty) const SizedBox(height: 80, child: EmptyState()),
        for (final q in quotes)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${formatAed(q.total)}  (${l.vat} ${formatAed(q.vat)})', style: Theme.of(context).textTheme.titleMedium)),
                  StatusChip(_quoteLabel(l, q.status), q.status == QuoteStatus.approved ? context.status.success : context.status.neutral),
                ]),
                Text(vendorNames[q.vendorId] ?? ''),
                if (q.scope.isNotEmpty) Text(q.scope),
                if (q.proposedVisit != null) Text('${l.proposedVisit}: ${formatDate(q.proposedVisit!)}'),
                if (q.question.isNotEmpty) Text('❓ ${q.question}'),
                if (q.status == QuoteStatus.submitted || q.status == QuoteStatus.questionAsked)
                  Wrap(spacing: 8, children: [
                    FilledButton(onPressed: () => _decide(q, t, approve: true), child: Text(l.approve)),
                    OutlinedButton(onPressed: () => _decide(q, t, approve: false), child: Text(l.reject)),
                    TextButton(onPressed: () => _ask(q, t), child: Text(l.askQuestion)),
                  ]),
              ]),
            ),
          ),
        const SizedBox(height: 8),
        if (t.status == TicketStatus.approved || t.status == TicketStatus.scheduled)
          FilledButton(onPressed: () => _save(QuoteFlow.start(t)), child: Text(l.startJob)),
        if (t.status == TicketStatus.inProgress)
          FilledButton(onPressed: () => _save(QuoteFlow.complete(t)), child: Text(l.completeJob)),
        if (t.status == TicketStatus.completed)
          FilledButton(onPressed: () => _closeWithRating(t), child: Text(l.closeJob)),
        const SizedBox(height: 16),
        TextButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: Text(l.delete),
          onPressed: () async {
            await ref.read(maintenanceRepositoryProvider).delete(t.id);
            if (context.mounted) context.pop();
          },
        ),
      ]),
    );
  }
}
