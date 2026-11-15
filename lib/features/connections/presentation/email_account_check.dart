import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../tenants/domain/tenant.dart';
import '../connection_providers.dart';
import '../domain/connection.dart';

/// Text for a refused connection request or lookup.
String connectionErrorText(AppLocalizations l, ConnectionError e) => switch (e) {
      ConnectionError.notFound => l.cxErrNotFound,
      ConnectionError.self => l.cxErrSelf,
      ConnectionError.duplicate => l.cxErrDuplicate,
      ConnectionError.alreadyLinked => l.cxErrAlreadyLinked,
      ConnectionError.rateLimited => l.cxErrRateLimited,
      ConnectionError.wrongRole => l.cxErrWrongRole,
      ConnectionError.notAllowed => l.cxErrNotAllowed,
      ConnectionError.invalid => l.cxErrInvalid,
    };

/// Background check under the tenant form's email field. Email is the source
/// of truth: when it belongs to an existing LedGix Rent account, offer to send
/// that person an invitation instead of a code to copy.
///
/// For a tenant that isn't saved yet the choice is "invite when I save"
/// ([inviteOnSave]); the form sends the invitation after saving.
class EmailAccountCheck extends ConsumerStatefulWidget {
  const EmailAccountCheck({super.key, required this.controller, required this.inviteOnSave, this.tenant});

  final TextEditingController controller;
  final ValueNotifier<bool> inviteOnSave;

  /// The saved tenant record, when editing.
  final Tenant? tenant;

  @override
  ConsumerState<EmailAccountCheck> createState() => _EmailAccountCheckState();
}

class _EmailAccountCheckState extends ConsumerState<EmailAccountCheck> {
  Timer? _debounce;
  String _checked = '';
  AccountLookup? _result;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _debounce?.cancel();
    super.dispose();
  }

  void _changed() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), _check);
  }

  Future<void> _check() async {
    final target = ConnectTarget.parse(widget.controller.text);
    final email = target is EmailTarget ? target.email : '';
    if (email == _checked) return;
    _checked = email;
    if (email.isEmpty) {
      if (mounted) setState(() => _result = null);
      widget.inviteOnSave.value = false;
      return;
    }
    try {
      final r = await ref.read(connectionsServiceProvider).lookup(ref.read(userIdProvider).value ?? 'anon', target!);
      if (!mounted || _checked != email) return;
      setState(() => _result = r);
      if (!r.exists || r.self || r.linked) widget.inviteOnSave.value = false;
    } catch (_) {
      // A failed or rate-limited check never gets in the way of saving.
      if (mounted && _checked == email) setState(() => _result = null);
    }
  }

  Future<void> _invite() async {
    final t = widget.tenant;
    final target = ConnectTarget.parse(widget.controller.text);
    if (t == null || target == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l;
    try {
      await ref.read(connectionsServiceProvider).inviteTenant(
            landlordUid: ref.read(userIdProvider).value ?? 'anon',
            tenantRecordId: t.id,
            target: target,
          );
      messenger.showSnackBar(SnackBar(content: Text(l.cxInvitationSent)));
    } on ConnectionException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(connectionErrorText(l, e.reason))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final r = _result;
    if (r == null || !r.exists) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final t = widget.tenant;
    final pending = t == null
        ? null
        : ref.watch(pendingOutgoingProvider).where((x) => x.tenantRecordId == t.id).firstOrNull;

    Widget banner({required IconData icon, required String title, String? body, Widget? action, Color? color}) => Container(
          key: const Key('email-account-check'),
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (color ?? scheme.primary).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (color ?? scheme.primary).withValues(alpha: 0.35)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color ?? scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (body != null) ...[const SizedBox(height: 4), Text(body)],
                if (action != null) ...[const SizedBox(height: 8), action],
              ]),
            ),
          ]),
        );

    if (r.self) return banner(icon: Icons.info_outline, title: l.cxThatsYou, color: scheme.secondary);
    if (r.linked || t?.appUid != null) {
      return banner(icon: Icons.verified_outlined, title: l.cxAlreadyConnected, color: context.status.success);
    }
    if (pending != null) {
      return banner(
        icon: Icons.mark_email_read_outlined,
        title: l.cxInvitationPending,
        action: TextButton(
          key: const Key('cancel-invitation'),
          onPressed: () => ref
              .read(connectionsServiceProvider)
              .cancel(uid: ref.read(userIdProvider).value ?? 'anon', requestId: pending.id),
          child: Text(l.cxCancelInvitation),
        ),
      );
    }
    return banner(
      icon: Icons.person_search_outlined,
      title: l.cxUsesAppTitle,
      body: l.cxUsesAppBody,
      action: t != null
          ? FilledButton.icon(
              key: const Key('send-invitation'),
              onPressed: _busy ? null : _invite,
              icon: const Icon(Icons.send_outlined),
              label: Text(l.cxSendInvitation),
            )
          : ValueListenableBuilder<bool>(
              valueListenable: widget.inviteOnSave,
              builder: (_, on, _) => CheckboxListTile(
                key: const Key('invite-on-save'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: on,
                onChanged: (v) => widget.inviteOnSave.value = v ?? false,
                title: Text(l.cxInviteOnSave),
              ),
            ),
    );
  }
}
