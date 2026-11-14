import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../account/account_providers.dart';
import '../../documents/presentation/documents_editor.dart' show documentKindLabel;
import '../../inspections/presentation/inspection_view.dart';
import '../../landlord/presentation/onboarding_screen.dart' show redeemErrorText;
import '../../payments/domain/payment.dart';
import '../../payments/presentation/payments_screen.dart' show statusLabel;
import '../data/tenant_portal.dart';
import '../domain/tenant_view.dart';
import '../tenant_providers.dart';

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

Map<String, TvLandlord> _landlordsById(WidgetRef ref) =>
    {for (final x in ref.watch(tenantLandlordsProvider).value ?? const <TvLandlord>[]) x.landlordUid: x};

Future<void> openTenantDocument(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// "Add landlord": enter an invite code. Returns true when linked.
Future<bool> showAddLandlordDialog(BuildContext context, WidgetRef ref) async {
  final added = await showDialog<bool>(context: context, builder: (_) => const _AddLandlordDialog());
  if (added == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l.tpLandlordAdded)));
  }
  return added == true;
}

class _AddLandlordDialog extends ConsumerStatefulWidget {
  const _AddLandlordDialog();
  @override
  ConsumerState<_AddLandlordDialog> createState() => _AddLandlordDialogState();
}

class _AddLandlordDialogState extends ConsumerState<_AddLandlordDialog> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(tenantPortalProvider).redeem(
            tenantUid: ref.read(userIdProvider).value ?? 'anon',
            code: _code.text,
          );
      if (mounted) Navigator.pop(context, true);
    } on RedeemException catch (e) {
      if (mounted) setState(() => _error = redeemErrorText(context.l, e.reason));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AlertDialog(
      key: const Key('add-landlord-dialog'),
      icon: const Icon(Icons.vpn_key_outlined),
      title: Text(l.tpAddLandlord),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.tpAddLandlordHint),
        const SizedBox(height: 16),
        TextField(
          key: const Key('add-landlord-code'),
          controller: _code,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: l.tpInviteCode, helperText: l.tpInviteCodeHint, errorText: _error, errorMaxLines: 3),
          onSubmitted: (_) => _submit(),
        ),
      ]),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(
          key: const Key('add-landlord-submit'),
          onPressed: _busy ? null : _submit,
          child: Text(l.tpAddLandlord),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.icon});
  final String label, value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[Icon(icon, size: 20, color: scheme.onSurfaceVariant), const SizedBox(width: 12)],
        SizedBox(width: 150, child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant))),
        Expanded(child: SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.children, this.icon});
  final String title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              if (icon != null) ...[Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8)],
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 8),
            ...children,
          ]),
        ),
      );
}

class _DocTile extends StatelessWidget {
  const _DocTile(this.doc, {this.subtitle});
  final TvDocument doc;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final pdf = doc.url.toLowerCase().contains('.pdf');
    return ListTile(
      key: Key('shared-doc-${doc.id}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(pdf ? Icons.picture_as_pdf_outlined : Icons.description_outlined),
      title: Text(documentKindLabel(l, doc.kind)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: TextButton.icon(
        icon: const Icon(Icons.download_outlined, size: 18),
        label: Text(l.tpOpenDocument),
        onPressed: () => openTenantDocument(doc.url),
      ),
    );
  }
}

/// Empty state, or a spinner while the tenant's data is still loading (so a
/// slow first load doesn't look like "nothing here").
Widget _empty(BuildContext context, String message, {Widget? action, bool loading = false}) => loading
    ? const Center(child: CircularProgressIndicator())
    : Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inbox_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          if (action != null) ...[const SizedBox(height: 16), action],
        ]),
      ),
    );

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

class TenantHomeScreen extends ConsumerWidget {
  const TenantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final today = todayGst();
    final user = ref.watch(appUserProvider).value;
    final landlords = _landlordsById(ref);
    final leases = ref.watch(tenantLeasesProvider).value ?? const <TvLease>[];
    final payments = ref.watch(tenantPaymentsProvider).value ?? const <TvPayment>[];
    final docs = ref.watch(tenantDocumentsProvider).value ?? const <TvDocument>[];
    final next = payments
        .where((p) => (p.status == PaymentStatus.pending || p.status == PaymentStatus.onHold) && !p.dueDate.isBefore(today))
        .firstOrNull;
    final current = leases.where((x) => x.isCurrent(today)).toList();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: ShellAppBar(title: Text(l.tpHome)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
        Text(
          (user?.name.isNotEmpty ?? false) ? greetingFor(l, user!.name) : l.tpTenantWelcome,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        if (landlords.isEmpty)
          _Panel(
            title: l.tpLandlords,
            icon: Icons.person_pin_outlined,
            children: [
              Text(l.tpNoLandlords),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  key: const Key('home-add-landlord'),
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: Text(l.tpAddLandlord),
                  onPressed: () => showAddLandlordDialog(context, ref),
                ),
              ),
            ],
          ),
        _Panel(
          title: l.tpNextPayment,
          icon: Icons.payments_outlined,
          children: [
            if (next == null)
              Text(l.tpNoUpcoming)
            else ...[
              Text(formatAed(next.amount), key: const Key('next-payment-amount'), style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${l.dueDate}: ${formatDate(next.dueDate)} · ${next.propertyName}'),
              if (landlords[next.landlordUid] case final ll?) Text(l.tpLeaseWith(ll.name)),
            ],
          ],
        ),
        _Panel(
          title: l.tpYourLeases,
          icon: Icons.description_outlined,
          children: [
            if (current.isEmpty) Text(l.tpNoProperties),
            for (final x in current)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.apartment_outlined),
                title: Text(x.propertyName),
                subtitle: Text([
                  if (landlords[x.landlordUid] case final ll?) l.tpLeaseWith(ll.name),
                  l.tpLeasePeriod(formatDate(x.startDate), formatDate(x.endDate)),
                ].join(' · ')),
                trailing: Text(formatAed(x.annualRent)),
                onTap: () => context.go('/t/properties'),
              ),
          ],
        ),
        _Panel(
          title: l.tpRecentDocuments,
          icon: Icons.folder_open_outlined,
          children: [
            if (docs.isEmpty) Text(l.tpNoSharedDocuments),
            for (final d in docs.reversed.take(5)) _DocTile(d, subtitle: landlords[d.landlordUid]?.name),
          ],
        ),
      ]),
    );
  }
}

String greetingFor(AppLocalizations l, String name) {
  final h = DateTime.now().hour;
  return h < 12 ? l.goodMorning(name) : (h < 18 ? l.goodAfternoon(name) : l.goodEvening(name));
}

// ---------------------------------------------------------------------------
// Landlords
// ---------------------------------------------------------------------------

class TenantLandlordsScreen extends ConsumerWidget {
  const TenantLandlordsScreen({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, TvLandlord ll) async {
    final l = context.l;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.tpRemoveTitle(ll.name)),
        content: Text(l.tpRemoveBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(key: const Key('confirm-remove-landlord'), onPressed: () => Navigator.pop(c, true), child: Text(l.tpRemove)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(tenantPortalProvider).removeLandlord(
          tenantUid: ref.read(userIdProvider).value ?? 'anon',
          landlordUid: ll.landlordUid,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final all = ref.watch(tenantLandlordsProvider).value ?? const <TvLandlord>[];
    final current = all.where((x) => x.status == LinkStatus.active).toList();
    final former = all.where((x) => x.status == LinkStatus.former).toList();

    Widget tile(TvLandlord ll, {required bool isFormer}) => Card(
          child: ListTile(
            key: Key('landlord-${ll.landlordUid}'),
            leading: CircleAvatar(child: Text(ll.name.isEmpty ? '?' : ll.name.characters.first.toUpperCase())),
            title: Text(ll.name.isEmpty ? l.landlord : ll.name),
            subtitle: Text([ll.email, if (isFormer) l.tpEnded].where((s) => s.isNotEmpty).join(' · ')),
            onTap: () => context.push('/t/landlords/${ll.landlordUid}'),
            trailing: isFormer
                ? TextButton(
                    key: Key('remove-landlord-${ll.landlordUid}'),
                    onPressed: () => _remove(context, ref, ll),
                    child: Text(l.tpRemove),
                  )
                : const Icon(Icons.chevron_right),
          ),
        );

    return Scaffold(
      appBar: ShellAppBar(title: Text(l.tpManageLandlords)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-landlord'),
        heroTag: null,
        icon: const Icon(Icons.vpn_key_outlined),
        label: Text(l.tpAddLandlord),
        onPressed: () => showAddLandlordDialog(context, ref),
      ),
      body: all.isEmpty
          ? _empty(context, l.tpNoLandlords, loading: ref.watch(tenantLandlordsProvider).isLoading)
          : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), children: [
              if (current.isNotEmpty) _Heading(l.tpCurrent),
              for (final x in current) tile(x, isFormer: false),
              if (former.isNotEmpty) _Heading(l.tpFormer),
              for (final x in former) tile(x, isFormer: true),
            ]),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(4, 16, 4, 8),
        child: Text(text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

class TenantLandlordDetailScreen extends ConsumerWidget {
  const TenantLandlordDetailScreen({super.key, required this.landlordUid});
  final String landlordUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final ll = _landlordsById(ref)[landlordUid];
    final leases = [for (final x in ref.watch(tenantLeasesProvider).value ?? const <TvLease>[]) if (x.landlordUid == landlordUid) x];
    final docs = [for (final d in ref.watch(tenantDocumentsProvider).value ?? const <TvDocument>[]) if (d.landlordUid == landlordUid) d];
    return Scaffold(
      appBar: ShellAppBar(title: Text(ll?.name ?? l.landlord)),
      body: ll == null
          ? _empty(context, l.nothingYet, loading: ref.watch(tenantLeasesProvider).isLoading)
          : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
              _Panel(title: l.tpLandlordDetails, icon: Icons.person_outline, children: [
                _InfoRow(l.landlord, ll.name, icon: Icons.badge_outlined),
                _InfoRow(l.email, ll.email, icon: Icons.mail_outline),
                _InfoRow(l.contactNo, ll.phone, icon: Icons.call_outlined),
                _InfoRow(l.emiratesIdNo, ll.emiratesIdNo, icon: Icons.credit_card_outlined),
                if (ll.since != null) _InfoRow(l.tpCurrent, l.tpSince(formatDate(ll.since!)), icon: Icons.event_outlined),
              ]),
              _Panel(title: l.tpYourLeases, icon: Icons.description_outlined, children: [
                for (final x in leases)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(x.propertyName),
                    subtitle: Text(l.tpLeasePeriod(formatDate(x.startDate), formatDate(x.endDate))),
                    trailing: Text(formatAed(x.annualRent)),
                  ),
              ]),
              _Panel(title: l.tpSharedDocuments, icon: Icons.folder_open_outlined, children: [
                if (docs.isEmpty) Text(l.tpNoSharedDocuments),
                for (final d in docs) _DocTile(d),
              ]),
            ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Properties
// ---------------------------------------------------------------------------

class TenantPropertiesScreen extends ConsumerWidget {
  const TenantPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final props = ref.watch(tenantPropertiesProvider).value ?? const <TvProperty>[];
    final leases = ref.watch(tenantLeasesProvider).value ?? const <TvLease>[];
    final docs = ref.watch(tenantDocumentsProvider).value ?? const <TvDocument>[];
    final landlords = _landlordsById(ref);
    return Scaffold(
      appBar: ShellAppBar(title: Text(l.properties)),
      body: props.isEmpty
          ? _empty(context, l.tpNoProperties, loading: ref.watch(tenantPropertiesProvider).isLoading)
          : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
              for (final p in props)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    key: Key('tenant-property-${p.id}'),
                    leading: const Icon(Icons.apartment_outlined),
                    title: Text(tenantPropertyTitle(p, formatAed, l.tpAgreement),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text([landlords[p.landlordUid]?.name ?? '', p.address].where((s) => s.isNotEmpty).join(' · ')),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Heading(l.tpPropertyDetails),
                      _InfoRow(l.address, p.address),
                      _InfoRow(l.community, p.community),
                      _InfoRow(l.titleDeedNo, p.titleDeedNo),
                      _InfoRow(l.dewaPremiseNo, p.dewaPremiseNo),
                      _InfoRow(l.dewaAccountNo, p.dewaAccountNo),
                      _InfoRow(l.mollakUnitRef, p.mollakUnitRef),
                      _InfoRow(l.hoaName, p.hoaName),
                      _InfoRow(l.hoaPhone, p.hoaPhone),
                      if (landlords[p.landlordUid] case final ll?) _InfoRow(l.landlord, ll.name),
                      for (final x in leases.where((x) => x.propertyId == p.id && x.landlordUid == p.landlordUid)) ...[
                        _Heading(l.tpAgreement),
                        _InfoRow(l.startDate, formatDate(x.startDate)),
                        _InfoRow(l.endDate, formatDate(x.endDate)),
                        _InfoRow(l.annualRent, formatAed(x.annualRent)),
                        if (x.securityDeposit > 0) _InfoRow(l.securityDeposit, formatAed(x.securityDeposit)),
                        _InfoRow(l.numberOfCheques, '${x.numberOfCheques}'),
                        _InfoRow(l.ejariNo, x.ejariNo),
                      ],
                      _Heading(l.tpSharedDocuments),
                      ...() {
                        final mine = [
                          for (final d in docs)
                            if (d.landlordUid == p.landlordUid && d.propertyId == p.id) d,
                        ];
                        return mine.isEmpty ? [Text(l.tpNoSharedDocuments)] : [for (final d in mine) _DocTile(d)];
                      }(),
                    ],
                  ),
                ),
            ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Payments (with cheque copies)
// ---------------------------------------------------------------------------

class TenantPaymentsScreen extends ConsumerWidget {
  const TenantPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final payments = ref.watch(tenantPaymentsProvider).value ?? const <TvPayment>[];
    final landlords = _landlordsById(ref);
    return Scaffold(
      appBar: ShellAppBar(title: Text(l.tpPayments)),
      body: payments.isEmpty
          ? _empty(context, l.tpNoUpcoming, loading: ref.watch(tenantPaymentsProvider).isLoading)
          : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
              for (final p in payments)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(formatAed(p.amount), style: Theme.of(context).textTheme.titleLarge)),
                        StatusChip(statusLabel(l, p.status), AppTheme.statusColor(context, p.status),
                            icon: AppTheme.statusIcon(p.status)),
                      ]),
                      const SizedBox(height: 4),
                      Text('${l.dueDate}: ${formatDate(p.dueDate)}'),
                      Text([p.propertyName, landlords[p.landlordUid]?.name ?? ''].where((s) => s.isNotEmpty).join(' · ')),
                      if (p.chequeNo.isNotEmpty || p.bankName.isNotEmpty) Text('${p.chequeNo} ${p.bankName}'.trim()),
                      if (p.imageUrl != null) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: Key('cheque-copy-${p.id}'),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: Text(l.tpViewChequeCopy),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (c) => Dialog(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Padding(padding: const EdgeInsets.all(12), child: Text(l.tpChequeCopy)),
                                Flexible(
                                  child: InteractiveViewer(
                                    child: Image.network(p.imageUrl!,
                                        errorBuilder: (_, _, _) => const Padding(
                                            padding: EdgeInsets.all(32), child: Icon(Icons.broken_image_outlined, size: 48))),
                                  ),
                                ),
                                TextButton(onPressed: () => Navigator.pop(c), child: Text(l.close)),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
            ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Inspections (rendered by the inspections feature's InspectionView)
// ---------------------------------------------------------------------------

String inspectionTitle(AppLocalizations l, Map<String, dynamic> m) => switch ('${m['type'] ?? ''}') {
      'moveIn' => l.tpMoveIn,
      'moveOut' => l.tpMoveOut,
      _ => l.tpInspection,
    };

class TenantInspectionsScreen extends ConsumerWidget {
  const TenantInspectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final list = ref.watch(tenantInspectionsProvider).value ?? const <Map<String, dynamic>>[];
    final props = {for (final p in ref.watch(tenantPropertiesProvider).value ?? const <TvProperty>[]) p.id: p.name};
    return Scaffold(
      appBar: ShellAppBar(title: Text(l.tpInspections)),
      body: list.isEmpty
          ? _empty(context, l.tpNoInspections, loading: ref.watch(tenantInspectionsProvider).isLoading)
          : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
              for (final m in list)
                Card(
                  child: ListTile(
                    leading: Icon(m['type'] == 'moveOut' ? Icons.logout : Icons.login),
                    title: Text(inspectionTitle(l, m)),
                    subtitle: Text([
                      '${m['propertyName'] ?? props[m['propertyId']] ?? ''}',
                      if (parseDateValue(m['date'] ?? m['createdAt']) case final d?) formatDate(d),
                    ].where((s) => s.isNotEmpty).join(' · ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/t/inspections/${m['landlordUid']}/${m['id']}'),
                  ),
                ),
            ]),
    );
  }
}

DateTime? parseDateValue(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  try {
    final dynamic d = v;
    return d.toDate() as DateTime;
  } catch (_) {
    return null;
  }
}

class TenantInspectionDetailScreen extends ConsumerWidget {
  const TenantInspectionDetailScreen({super.key, required this.landlordUid, required this.id});
  final String landlordUid, id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final m = (ref.watch(tenantInspectionsProvider).value ?? const <Map<String, dynamic>>[])
        .where((x) => '${x['id']}' == id && '${x['landlordUid']}' == landlordUid)
        .firstOrNull;
    return Scaffold(
      appBar: ShellAppBar(title: Text(m == null ? l.tpInspection : inspectionTitle(l, m))),
      body: m == null ? _empty(context, l.tpNoInspections, loading: ref.watch(tenantInspectionsProvider).isLoading) : InspectionView(data: m, tenantMode: true),
    );
  }
}

// ---------------------------------------------------------------------------
// Maintenance requests
// ---------------------------------------------------------------------------

class TenantMaintenanceScreen extends ConsumerWidget {
  const TenantMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final hasProperties = (ref.watch(tenantPropertiesProvider).value ?? const []).isNotEmpty;
    return Scaffold(
      appBar: ShellAppBar(title: Text(l.maintenance)),
      floatingActionButton: hasProperties
          ? FloatingActionButton.extended(
              key: const Key('tenant-new-request'),
              heroTag: null,
              icon: const Icon(Icons.add),
              label: Text(l.tpNewRequest),
              onPressed: () => context.push('/t/maintenance/new'),
            )
          : null,
      body: _empty(context, hasProperties ? l.tpMyRequests : l.tpNoProperties,
          loading: ref.watch(tenantPropertiesProvider).isLoading),
    );
  }
}

class TenantRequestFormScreen extends ConsumerStatefulWidget {
  const TenantRequestFormScreen({super.key});
  @override
  ConsumerState<TenantRequestFormScreen> createState() => _TenantRequestFormScreenState();
}

class _TenantRequestFormScreenState extends ConsumerState<TenantRequestFormScreen> {
  final _key = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _details = TextEditingController();
  final _photos = <XFile>[];
  String? _propertyKey; // landlordUid|propertyId
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) setState(() => _photos.addAll(picked));
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final parts = _propertyKey!.split('|');
      final storage = ref.read(tenantFileStorageProvider);
      final urls = [
        for (final f in _photos) await storage.uploadFile('maintenance/${newId()}_${f.name}', f),
      ];
      await ref.read(tenantPortalProvider).createMaintenanceRequest(
            tenantUid: ref.read(userIdProvider).value ?? 'anon',
            landlordUid: parts[0],
            propertyId: parts[1],
            title: _title.text.trim(),
            description: _details.text.trim(),
            photos: urls,
          );
      messenger.showSnackBar(SnackBar(content: Text(l.tpRequestSent)));
      if (mounted) context.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final props = ref.watch(tenantPropertiesProvider).value ?? const <TvProperty>[];
    _propertyKey ??= props.length == 1 ? '${props.first.landlordUid}|${props.first.id}' : null;
    return Scaffold(
      appBar: ShellAppBar(title: Text(l.tpNewRequest)),
      body: Form(
        key: _key,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          DropdownButtonFormField<String>(
            key: const Key('request-property'),
            initialValue: _propertyKey,
            decoration: InputDecoration(labelText: l.property),
            items: [
              for (final p in props) DropdownMenuItem(value: '${p.landlordUid}|${p.id}', child: Text(p.name)),
            ],
            onChanged: (v) => setState(() => _propertyKey = v),
            validator: (v) => v == null ? l.tpChoosePropertyFirst : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('request-title'),
            controller: _title,
            decoration: InputDecoration(labelText: l.tpRequestTitle),
            validator: (v) => requiredValidator(context, v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _details,
            decoration: InputDecoration(labelText: l.tpRequestDetails),
            minLines: 3,
            maxLines: 6,
          ),
          const SizedBox(height: 12),
          Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(_photos.isEmpty ? l.tpAddPhotos : l.tpPhotosAdded(_photos.length)),
                onPressed: _busy ? null : _addPhotos,
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('request-submit'),
            onPressed: _busy ? null : _submit,
            child: Text(l.tpNewRequest),
          ),
        ]),
      ),
    );
  }
}
