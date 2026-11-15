import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../account/account_providers.dart';
import '../../landlord/presentation/onboarding_screen.dart' show redeemErrorText;
import '../../tenant_portal/data/tenant_portal.dart';
import '../../tenant_portal/tenant_providers.dart';
import '../connection_providers.dart';
import '../domain/connection.dart';
import 'email_account_check.dart' show connectionErrorText;

String _uid(WidgetRef ref) => ref.read(userIdProvider).value ?? 'anon';

/// "{landlord} wants to connect you to {property}".
String invitationTitle(AppLocalizations l, ConnectionRequest r) {
  final name = r.fromName.isNotEmpty ? r.fromName : (r.fromEmail.isNotEmpty ? r.fromEmail : l.cxSomeone);
  return r.propertyName.isNotEmpty ? l.cxInvitationFrom(name, r.propertyName) : l.cxWantsToConnect(name);
}

/// Tenant accepts a landlord's invitation, optionally sharing "My details".
Future<void> acceptInvitation(BuildContext context, WidgetRef ref, ConnectionRequest r) async {
  final l = context.l;
  final me = ref.read(appUserProvider).value;
  final hasDetails = me != null && !SharedDetails.of(me).isEmpty;
  var share = hasDetails;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => AlertDialog(
        key: const Key('accept-invitation-dialog'),
        icon: const Icon(Icons.handshake_outlined),
        title: Text(invitationTitle(l, r)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CheckboxListTile(
            key: const Key('share-my-details'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: share,
            onChanged: hasDetails ? (v) => set(() => share = v ?? false) : null,
            title: Text(l.cxShareMyDetails),
            subtitle: Text(hasDetails ? l.cxShareMyDetailsHint : l.cxAddMyDetailsFirst),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(key: const Key('confirm-accept'), onPressed: () => Navigator.pop(c, true), child: Text(l.cxAccept)),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  await _run(context, () => ref.read(connectionsServiceProvider).accept(uid: _uid(ref), requestId: r.id, shareDetails: share),
      done: l.cxAcceptedLandlord);
}

Future<void> declineRequest(BuildContext context, WidgetRef ref, ConnectionRequest r) async {
  final l = context.l;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(l.cxDeclineConfirm),
      content: Text(invitationTitle(l, r)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
        FilledButton(key: const Key('confirm-decline'), onPressed: () => Navigator.pop(c, true), child: Text(l.cxDecline)),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await _run(context, () => ref.read(connectionsServiceProvider).decline(uid: _uid(ref), requestId: r.id), done: l.cxDeclined);
}

Future<void> _run(BuildContext context, Future<void> Function() job, {String? done}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l;
  try {
    await job();
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
  } on ConnectionException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(connectionErrorText(l, e.reason))));
  }
}

class _RequestTile extends ConsumerWidget {
  const _RequestTile(this.r);
  final ConnectionRequest r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return Card(
      key: Key('invitation-${r.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.mail_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(invitationTitle(l, r), style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
          if (r.createdAt != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 36, top: 2),
              child: Text(formatDate(r.createdAt!), style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.end, spacing: 8, children: [
            TextButton(key: Key('decline-${r.id}'), onPressed: () => declineRequest(context, ref, r), child: Text(l.cxDecline)),
            FilledButton(key: Key('accept-${r.id}'), onPressed: () => acceptInvitation(context, ref, r), child: Text(l.cxAccept)),
          ]),
        ]),
      ),
    );
  }
}

/// Tenant Home: pending invitations from landlords (nothing when none).
class IncomingInvitationsCard extends ConsumerWidget {
  const IncomingInvitationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingIncomingProvider);
    if (pending.isEmpty) return const SizedBox.shrink();
    final l = context.l;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(l.cxInvitations, style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final r in pending.take(3)) _RequestTile(r),
        if (pending.length > 3)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: () => context.push('/t/invitations'), child: Text(l.viewAll)),
          ),
      ]),
    );
  }
}

/// All pending invitations ('/t/invitations').
class TenantInvitationsScreen extends ConsumerWidget {
  const TenantInvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final pending = ref.watch(pendingIncomingProvider);
    final loading = ref.watch(incomingRequestsProvider).isLoading;
    return Scaffold(
      appBar: ShellAppBar(title: Text(l.cxInvitations)),
      body: pending.isEmpty
          ? Center(child: loading ? const CircularProgressIndicator() : Text(l.noNotifications))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [for (final r in pending) _RequestTile(r)],
            ),
    );
  }
}

/// Landlords page: requests this tenant sent that are still waiting.
class OutgoingRequestsSection extends ConsumerWidget {
  const OutgoingRequestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingOutgoingProvider);
    if (pending.isEmpty) return const SizedBox.shrink();
    final l = context.l;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
        child: Text(l.cxRequestsSent, style: Theme.of(context).textTheme.titleSmall),
      ),
      for (final r in pending)
        Card(
          key: Key('sent-${r.id}'),
          child: ListTile(
            leading: const Icon(Icons.outgoing_mail),
            title: Text(r.target.isNotEmpty ? r.target : l.landlord),
            subtitle: Text([l.cxWaiting, if (r.createdAt != null) formatDate(r.createdAt!)].join(' · ')),
            trailing: TextButton(
              key: Key('cancel-${r.id}'),
              onPressed: () => ref.read(connectionsServiceProvider).cancel(uid: _uid(ref), requestId: r.id),
              child: Text(l.cxCancelRequest),
            ),
          ),
        ),
    ]);
  }
}

enum _AddBy { email, code, invite }

/// Tenant "Add landlord": by the landlord's email, their LedGix code, or a
/// single-use invite code. Email and code send a request the landlord accepts;
/// an invite code links straight away (as before). Returns true when linked
/// or a request was sent.
Future<bool> showConnectLandlordDialog(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<String>(context: context, builder: (_) => const _ConnectLandlordDialog());
  if (result != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }
  return result != null;
}

class _ConnectLandlordDialog extends ConsumerStatefulWidget {
  const _ConnectLandlordDialog();
  @override
  ConsumerState<_ConnectLandlordDialog> createState() => _ConnectLandlordDialogState();
}

class _ConnectLandlordDialogState extends ConsumerState<_ConnectLandlordDialog> {
  final _input = TextEditingController();
  var _by = _AddBy.email;
  bool _busy = false, _share = true;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l;
    if (_input.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_by == _AddBy.invite) {
        await ref.read(tenantPortalProvider).redeem(tenantUid: _uid(ref), code: _input.text);
        if (mounted) Navigator.pop(context, l.tpLandlordAdded);
      } else {
        final target = ConnectTarget.parse(_input.text);
        final ok = switch (_by) {
          _AddBy.email => target is EmailTarget,
          _ => target is CodeTarget,
        };
        if (!ok) throw const ConnectionException(ConnectionError.invalid);
        await ref.read(connectionsServiceProvider).requestLandlord(tenantUid: _uid(ref), target: target!, shareDetails: _share);
        if (mounted) Navigator.pop(context, l.cxRequestSent);
      }
    } on RedeemException catch (e) {
      if (mounted) setState(() => _error = redeemErrorText(l, e.reason));
    } on ConnectionException catch (e) {
      if (mounted) setState(() => _error = connectionErrorText(l, e.reason));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final me = ref.watch(appUserProvider).value;
    final hasDetails = me != null && !SharedDetails.of(me).isEmpty;
    final (label, helper, keyboard) = switch (_by) {
      _AddBy.email => (l.cxLandlordEmail, null, TextInputType.emailAddress),
      _AddBy.code => (l.cxLandlordCode, l.cxCodeHint, TextInputType.text),
      _AddBy.invite => (l.tpInviteCode, l.tpInviteCodeHint, TextInputType.text),
    };
    return AlertDialog(
      key: const Key('add-landlord-dialog'),
      icon: const Icon(Icons.person_add_alt_outlined),
      title: Text(l.tpAddLandlord),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<_AddBy>(
            key: const Key('add-landlord-by'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: _AddBy.email, label: Text(l.cxByEmail, key: const Key('add-by-email'))),
              ButtonSegment(value: _AddBy.code, label: Text(l.cxByCode, key: const Key('add-by-code'))),
              ButtonSegment(value: _AddBy.invite, label: Text(l.cxByInvite, key: const Key('add-by-invite'))),
            ],
            selected: {_by},
            onSelectionChanged: (s) => setState(() {
              _by = s.first;
              _error = null;
            }),
          ),
          const SizedBox(height: 12),
          Text(_by == _AddBy.invite ? l.tpAddLandlordHint : l.cxAddLandlordHint),
          const SizedBox(height: 12),
          TextField(
            key: const Key('add-landlord-code'),
            controller: _input,
            autofocus: true,
            keyboardType: keyboard,
            textCapitalization: _by == _AddBy.email ? TextCapitalization.none : TextCapitalization.characters,
            decoration: InputDecoration(labelText: label, helperText: helper, errorText: _error, errorMaxLines: 3),
            onSubmitted: (_) => _submit(),
          ),
          if (_by != _AddBy.invite)
            CheckboxListTile(
              key: const Key('request-share-details'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _share && hasDetails,
              onChanged: hasDetails ? (v) => setState(() => _share = v ?? false) : null,
              title: Text(l.cxShareMyDetails),
              subtitle: Text(hasDetails ? l.cxShareMyDetailsHint : l.cxAddMyDetailsFirst),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          key: const Key('add-landlord-submit'),
          onPressed: _busy ? null : _submit,
          child: Text(_by == _AddBy.invite ? l.tpAddLandlord : l.cxSendRequest),
        ),
      ],
    );
  }
}
