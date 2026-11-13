import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/privacy.dart';
import '../../landlord/presentation/onboarding_screen.dart' show landlordProvider;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final landlord = ref.watch(landlordProvider).value;
    final name = landlord?.name.trim() ?? '';
    final email = landlord?.email.trim() ?? '';
    final phone = landlord?.phone.trim() ?? '';

    return Scaffold(
      appBar: ShellAppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _Section(title: l.account, children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text((name.isNotEmpty ? name : (email.isNotEmpty ? email : '?')).characters.first.toUpperCase()),
              ),
              title: Text(name.isEmpty ? l.landlord : name),
              subtitle: Text([email, phone].where((e) => e.isNotEmpty).join(' · ')),
            ),
            ListTile(
              key: const Key('edit-profile'),
              leading: const Icon(Icons.person_outline),
              title: Text(l.editProfile),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile'),
            ),
          ]),
          _Section(title: l.preferences, children: [
            _SettingRow(
              icon: Icons.language,
              label: l.language,
              control: SegmentedButton<String>(
                key: const Key('language-switch'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'en', label: Text(l.english)),
                  ButtonSegment(value: 'ar', label: Text(l.arabic)),
                ],
                selected: {ref.watch(localeProvider)},
                onSelectionChanged: (s) => ref.read(localeProvider.notifier).set(s.first),
              ),
            ),
            _SettingRow(
              icon: Icons.contrast,
              label: l.theme,
              control: SegmentedButton<ThemeMode>(
                key: const Key('theme-switch'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: ThemeMode.system, label: Text(l.themeSystem)),
                  ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight)),
                  ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark)),
                ],
                selected: {ref.watch(themeModeProvider)},
                onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
              ),
            ),
          ]),
          _Section(title: l.notifications, children: [
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(l.remindersInfo),
              subtitle: Text(l.remindersDelivery),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.payments_outlined),
              title: Text(l.reminderDeposit),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.event_repeat_outlined),
              title: Text(l.reminderRenewal),
            ),
          ]),
          _Section(title: l.securitySignIn, children: [
            if (email.isNotEmpty)
              ListTile(leading: const Icon(Icons.verified_user_outlined), title: Text(l.signedInAs(email))),
            ListTile(
              key: const Key('sign-out'),
              leading: const Icon(Icons.logout),
              title: Text(l.signOut),
              onTap: () => ref.read(authRepositoryProvider).signOut(),
            ),
          ]),
          _Section(title: l.legal, children: [
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l.privacyPolicy),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => openPrivacyPolicy(context),
            ),
          ]),
          _Section(
            title: l.dangerZone,
            danger: true,
            children: [
              ListTile(
                key: const Key('delete-account'),
                leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
                title: Text(l.deleteAccount, style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600)),
                subtitle: Text(l.deleteAccountHint),
                onTap: () => confirmDeleteAccount(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.danger = false});
  final String title;
  final List<Widget> children;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Text(title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: danger ? scheme.error : scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: danger
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.error.withValues(alpha: 0.5)))
              : null,
          child: Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
              children[i],
            ],
          ]),
        ),
      ]),
    );
  }
}

/// Label on the start side, control on the end side; stacks on narrow screens.
class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.label, required this.control});
  final IconData icon;
  final String label;
  final Widget control;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final title = Row(children: [
          Icon(icon, color: Theme.of(context).listTileTheme.iconColor),
          const SizedBox(width: 16),
          Flexible(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
        ]);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: c.maxWidth < 520
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  title,
                  const SizedBox(height: 10),
                  Padding(padding: const EdgeInsetsDirectional.only(start: 40), child: control),
                ])
              : Row(children: [Expanded(child: title), control]),
        );
      });
}

/// Confirms, then permanently deletes the account (see AuthRepository.deleteAccount).
Future<void> confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final l = context.l;
  final error = Theme.of(context).colorScheme.error;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: error),
      title: Text(l.deleteAccountTitle),
      content: Text(l.deleteAccountBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
        FilledButton(
          key: const Key('confirm-delete-account'),
          style: FilledButton.styleFrom(backgroundColor: error, foregroundColor: Theme.of(context).colorScheme.onError),
          onPressed: () => Navigator.pop(c, true),
          child: Text(l.delete),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  final nav = Navigator.of(context, rootNavigator: true);
  try {
    final deleted = await ref.read(authRepositoryProvider).deleteAccount();
    nav.pop();
    if (deleted) messenger.showSnackBar(SnackBar(content: Text(l.accountDeleted)));
  } catch (e) {
    nav.pop();
    messenger.showSnackBar(SnackBar(content: Text('$e')));
  }
}
