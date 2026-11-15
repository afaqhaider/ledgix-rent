import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../tenants/domain/tenant.dart';
import '../connection_providers.dart';
import '../domain/connection.dart';
import 'email_account_check.dart' show connectionErrorText;
import 'tenant_connections.dart' show declineRequest, invitationTitle;

const _newTenant = '__new__';

/// Landlord accepts a tenant's request: link it to one of their tenant
/// records (same email first), or create a new tenant prefilled from the
/// details the tenant shared.
Future<void> acceptTenantRequest(BuildContext context, WidgetRef ref, ConnectionRequest r) async {
  final l = context.l;
  final email = (r.details?.email.isNotEmpty ?? false) ? r.details!.email : r.fromEmail;
  final tenants = [
    for (final t in ref.read(tenantsProvider).value ?? const <Tenant>[])
      if (t.appUid == null) t,
  ]..sort((a, b) {
      int m(Tenant t) => _sameEmail(t.email, email) ? 0 : 1;
      return m(a).compareTo(m(b)) != 0 ? m(a).compareTo(m(b)) : a.name.compareTo(b.name);
    });

  final choice = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      key: const Key('choose-tenant-dialog'),
      title: Text(l.cxChooseTenant),
      content: SizedBox(
        width: 440,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.cxChooseTenantHint),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              if (tenants.isEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(l.cxNoUnlinkedTenants)),
              for (final t in tenants)
                ListTile(
                  key: Key('pick-tenant-${t.id}'),
                  leading: const Icon(Icons.person_outline),
                  title: Text(t.name.isEmpty ? '-' : t.name),
                  subtitle: Text([t.email, t.phone].where((s) => s.isNotEmpty).join(' · ')),
                  trailing: _sameEmail(t.email, email)
                      ? Chip(
                          label: Text(l.cxEmailMatches),
                          backgroundColor: context.status.success.withValues(alpha: 0.12),
                          side: BorderSide.none,
                        )
                      : null,
                  onTap: () => Navigator.pop(c, t.id),
                ),
              const Divider(),
              ListTile(
                key: const Key('create-tenant-from-request'),
                leading: const Icon(Icons.person_add_alt_outlined),
                title: Text(l.cxCreateFromDetails),
                onTap: () => Navigator.pop(c, _newTenant),
              ),
            ]),
          ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel))],
    ),
  );
  if (choice == null || !context.mounted) return;

  var recordId = choice;
  if (choice == _newTenant) {
    final prefill = {...?r.details?.prefill, if (email.isNotEmpty) 'email': email};
    final created = await context.push<String>('/tenants/new?from=request', extra: prefill);
    if (created == null || !context.mounted) return;
    recordId = created;
  }
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(connectionsServiceProvider).accept(
          uid: ref.read(userIdProvider).value ?? 'anon',
          requestId: r.id,
          tenantRecordId: recordId,
        );
    messenger.showSnackBar(SnackBar(content: Text(l.cxConnectedTenant)));
  } on ConnectionException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(connectionErrorText(l, e.reason))));
  }
}

bool _sameEmail(String a, String b) => a.trim().isNotEmpty && a.trim().toLowerCase() == b.trim().toLowerCase();

/// Landlord dashboard: tenants asking to connect (nothing when none).
class ConnectionRequestsCard extends ConsumerWidget {
  const ConnectionRequestsCard({super.key, this.gap = 16});
  final double gap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = [
      for (final r in ref.watch(pendingIncomingProvider))
        if (r.direction == ConnectionDirection.tenantToLandlord) r,
    ];
    if (pending.isEmpty) return const SizedBox.shrink();
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Card(
        key: const Key('connection-requests-card'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(Icons.group_add_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(l.cxConnectionRequests, style: Theme.of(context).textTheme.titleMedium)),
              Badge(label: Text('${pending.length}')),
            ]),
            const SizedBox(height: 8),
            for (final r in pending.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(
                    radius: 18,
                    child: Text((r.fromName.isNotEmpty ? r.fromName : (r.fromEmail.isNotEmpty ? r.fromEmail : '?'))
                        .characters
                        .first
                        .toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(invitationTitle(l, r), style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        [r.fromEmail, if (r.details?.phone.isNotEmpty ?? false) r.details!.phone, if (r.createdAt != null) formatDate(r.createdAt!)]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Wrap(spacing: 4, children: [
                    TextButton(key: Key('decline-${r.id}'), onPressed: () => declineRequest(context, ref, r), child: Text(l.cxDecline)),
                    FilledButton(key: Key('accept-${r.id}'), onPressed: () => acceptTenantRequest(context, ref, r), child: Text(l.cxAccept)),
                  ]),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Opens the right place for a pending request from the bell.
void openRequest(BuildContext context, ConnectionRequest r) =>
    context.go(r.direction == ConnectionDirection.landlordToTenant ? '/t/invitations' : '/');
