import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../tenants/domain/tenant.dart';
import '../data/tenant_portal.dart';
import '../tenant_providers.dart';

/// Creates (or regenerates) an invite code for [tenant] and shows it with
/// Copy and Share. Shown right after adding a tenant or a rent agreement,
/// and from "Invite to app" on the tenant list.
Future<void> showTenantInviteDialog(BuildContext context, WidgetRef? ref, Tenant tenant, {String? leaseId}) =>
    showDialog<void>(context: context, builder: (_) => _InviteDialog(tenant: tenant, leaseId: leaseId));

class _InviteDialog extends ConsumerStatefulWidget {
  const _InviteDialog({required this.tenant, this.leaseId});
  final Tenant tenant;
  final String? leaseId;
  @override
  ConsumerState<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<_InviteDialog> {
  TenantInvite? _invite;
  String? _error;

  @override
  void initState() {
    super.initState();
    final t = widget.tenant;
    // Reuse a still-valid code; otherwise make one.
    if (t.inviteStatus(DateTime.now()) == TenantInviteStatus.invited) {
      _invite = TenantInvite(code: t.inviteCode!, expiresAt: t.inviteExpiresAt ?? DateTime.now().add(const Duration(days: 30)));
    } else {
      _create(initial: true);
    }
  }

  Future<void> _create({bool initial = false}) async {
    if (!initial) {
      setState(() {
        _invite = null;
        _error = null;
      });
    }
    try {
      final inv = await ref.read(tenantPortalProvider).createInvite(
            landlordUid: ref.read(userIdProvider).value ?? 'anon',
            tenantId: widget.tenant.id,
            leaseId: widget.leaseId,
          );
      if (mounted) setState(() => _invite = inv);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final inv = _invite;
    final grouped = inv == null ? '' : '${inv.code.substring(0, 4)} ${inv.code.substring(4)}';
    return AlertDialog(
      key: const Key('tenant-invite-dialog'),
      icon: const Icon(Icons.mark_email_read_outlined),
      title: Text(l.tpInviteTitle(widget.tenant.name)),
      scrollable: true,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_error != null)
            Text(_error!, style: TextStyle(color: scheme.error))
          else if (inv == null)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(16)),
              child: SelectableText(
                grouped,
                key: const Key('invite-code'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: 4, color: scheme.onSecondaryContainer, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 14),
            Text(l.tpInviteBody(formatDate(inv.expiresAt))),
          ],
        ]),
      ),
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.tpLater)),
        if (inv != null) ...[
          TextButton.icon(
            key: const Key('invite-new-code'),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l.tpNewCode),
            onPressed: _create,
          ),
          OutlinedButton.icon(
            key: const Key('invite-copy'),
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l.tpCopyCode),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: inv.code));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.tpCodeCopied)));
            },
          ),
          FilledButton.icon(
            key: const Key('invite-share'),
            icon: const Icon(Icons.ios_share, size: 18),
            label: Text(l.tpShare),
            onPressed: () {
              final box = context.findRenderObject() as RenderBox?;
              SharePlus.instance.share(ShareParams(
                text: l.tpInviteShareText(inv.code),
                subject: 'LedGix Rent',
                sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
              ));
            },
          ),
        ],
      ],
    );
  }
}

/// Small chip with the tenant's app status.
class TenantInviteStatusChip extends StatelessWidget {
  const TenantInviteStatusChip({super.key, required this.tenant});
  final Tenant tenant;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final (label, icon, color) = switch (tenant.inviteStatus(DateTime.now())) {
      TenantInviteStatus.joined => (l.tpJoined, Icons.check_circle, scheme.primary),
      TenantInviteStatus.invited => (l.tpInvited, Icons.schedule, scheme.tertiary),
      TenantInviteStatus.notInvited => (l.tpNotInvited, Icons.person_outline, scheme.onSurfaceVariant),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}
