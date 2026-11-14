import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/dashboard/domain/dashboard_insights.dart';
import '../../features/leases/domain/lease.dart' show PaymentMethod;
import '../../features/account/account_providers.dart';
import '../../features/landlord/presentation/onboarding_screen.dart' show landlordProvider;
import '../../features/payments/domain/payment.dart' show PaymentStatus;
import '../../features/tenant_portal/domain/tenant_view.dart' show TvPayment;
import '../../features/tenant_portal/tenant_providers.dart';
import '../../features/holds/domain/hold_request.dart';
import '../providers.dart';
import '../utils/dates.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import 'navigation.dart';

/// What the app shell tells the pages inside it.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.size, required this.location, this.openDrawer, required super.child});
  final WindowSize size;
  final String location;

  /// Opens the navigation drawer; only set on phones.
  final VoidCallback? openDrawer;

  static ShellScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope old) =>
      old.size != size || old.location != location || (old.openDrawer == null) != (openDrawer == null);
}

/// Responsive frame around every signed-in page:
///  - phones: burger drawer plus a bottom bar for the four main sections;
///  - tablets: collapsible icon rail;
///  - desktop: permanent sidebar.
/// Page content is centred with a maximum width so nothing stretches edge to edge.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  static const sidebarWidth = 264.0;
  static const railWidth = 76.0;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffold = GlobalKey<ScaffoldState>();
  bool _railExpanded = false;

  void _go(String path) {
    if (_scaffold.currentState?.isDrawerOpen ?? false) _scaffold.currentState!.closeDrawer();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    // The shell route only sees the location it was entered with; pages
    // pushed on top (details, forms) are read from the router itself.
    final delegate = GoRouter.of(context).routerDelegate;
    return ListenableBuilder(
      listenable: delegate,
      builder: (context, _) =>
          _build(context, delegate.currentConfiguration.lastOrNull?.matchedLocation ?? widget.location),
    );
  }

  Widget _build(BuildContext context, String location) {
    final size = windowSizeOf(context);
    final current = navItemFor(location);
    final l = context.l;
    final content = _ContentFrame(maxWidth: isNarrowPage(location) ? 880 : 1200, child: widget.child);

    Widget body;
    switch (size) {
      case WindowSize.compact:
        body = content;
      case WindowSize.medium:
        body = Row(children: [
          SizedBox(
            width: _railExpanded ? AppShell.sidebarWidth : AppShell.railWidth,
            child: Sidebar(
              location: location,
              collapsed: !_railExpanded,
              onSelect: _go,
              onToggle: () => setState(() => _railExpanded = !_railExpanded),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ]);
      case WindowSize.expanded:
        body = Row(children: [
          SizedBox(width: AppShell.sidebarWidth, child: Sidebar(location: location, onSelect: _go)),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ]);
    }

    final primary = primaryItemsFor(location);
    final primaryIndex = primary.indexWhere((i) => i.owns(location));
    return Title(
      title: current == null ? 'LedGix Rent' : '${current.label(l)} · LedGix Rent',
      color: Theme.of(context).colorScheme.primary,
      child: ShellScope(
        size: size,
        location: location,
        openDrawer: size == WindowSize.compact ? () => _scaffold.currentState?.openDrawer() : null,
        child: Scaffold(
          key: _scaffold,
          drawer: size == WindowSize.compact
              ? Drawer(width: 300, child: Sidebar(location: location, onSelect: _go, inDrawer: true))
              : null,
          body: body,
          bottomNavigationBar: size == WindowSize.compact && primaryIndex >= 0
              ? NavigationBar(
                  selectedIndex: primaryIndex,
                  onDestinationSelected: (i) => _go(primary[i].path),
                  destinations: [
                    for (final i in primary)
                      NavigationDestination(icon: Icon(i.icon), selectedIcon: Icon(i.selectedIcon), label: i.label(l)),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

/// Centres the page and caps its width. Pages keep their own scaffold and
/// app bar; the margins share the page background so the bar reads as full width.
class _ContentFrame extends StatelessWidget {
  const _ContentFrame({required this.maxWidth, required this.child});
  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
        ),
      );
}

/// Grouped navigation used as the desktop sidebar, the tablet rail
/// ([collapsed]: icons with tooltips) and the phone drawer.
class Sidebar extends ConsumerWidget {
  const Sidebar({
    super.key,
    required this.location,
    required this.onSelect,
    this.collapsed = false,
    this.onToggle,
    this.inDrawer = false,
  });
  final String location;
  final ValueChanged<String> onSelect;
  final bool collapsed, inDrawer;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final current = navItemFor(location);

    Widget tile(NavItem item) {
      final selected = identical(item, current) || item.path == current?.path;
      final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
      final label = item.label(l);
      final row = Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: Key('nav-${item.path}'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelect(item.path),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12, vertical: 10),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(selected ? item.selectedIcon : item.icon, size: 22, color: fg),
                if (!collapsed) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(
                            color: fg, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Semantics(
          selected: selected,
          button: true,
          label: collapsed ? label : null,
          child: collapsed ? Tooltip(message: label, preferBelow: false, child: row) : row,
        ),
      );
    }

    final (name, email) = signedInIdentity(ref);
    final tenant = isTenantLocation(location);

    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Brand header (and the rail's expand/collapse toggle).
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(collapsed ? 0 : 20, 18, collapsed ? 0 : 12, 14),
            child: collapsed
                ? Column(children: [
                    const LogoMark(size: 30),
                    if (onToggle != null)
                      IconButton(
                        tooltip: l.openMenu,
                        icon: const Icon(Icons.menu),
                        onPressed: onToggle,
                      ),
                  ])
                : Row(children: [
                    const LogoMark(size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('LedGix Rent',
                          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                    ),
                    if (onToggle != null)
                      IconButton(icon: const Icon(Icons.menu_open), tooltip: l.openMenu, onPressed: onToggle),
                  ]),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 12),
              children: [
                for (final section in navSectionsFor(location)) ...[
                  if (!collapsed)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(12, 14, 12, 6),
                      child: Text(section.title(l).toUpperCase(),
                          style: text.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    )
                  else
                    const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1)),
                  for (final item in section.items) tile(item),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 12, vertical: 8),
            child: tile(settingsItemFor(location)),
          ),
          // Signed-in user.
          Padding(
            padding: EdgeInsets.fromLTRB(collapsed ? 10 : 16, 0, collapsed ? 10 : 8, 12),
            child: collapsed
                ? Center(child: _Avatar(name: name, email: email))
                : Row(children: [
                    _Avatar(name: name, email: email),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name.isEmpty ? (tenant ? l.tpRoleTenant : l.landlord) : name,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                        if (email.isNotEmpty)
                          Text(email,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ]),
                    ),
                    IconButton(
                      key: const Key('sidebar-sign-out'),
                      tooltip: l.signOut,
                      icon: const Icon(Icons.logout),
                      onPressed: () => ref.read(authRepositoryProvider).signOut(),
                    ),
                  ]),
          ),
        ]),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.email, this.radius = 18});
  final String name, email;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final source = name.isNotEmpty ? name : email;
    final initial = source.isEmpty ? '?' : source.characters.first.toUpperCase();
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

/// App bar for pages inside the shell: a burger on phones (when there is
/// nothing to go back to), plus notifications and the account menu.
/// Outside the shell it behaves like a plain [AppBar].
class ShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ShellAppBar({super.key, this.title, this.actions = const [], this.bottom});
  final Widget? title;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.maybeOf(context);
    if (shell == null) return AppBar(title: title, actions: actions, bottom: bottom);
    final canGoBack = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final wide = shell.size != WindowSize.compact;
    return AppBar(
      title: title,
      bottom: bottom,
      titleSpacing: wide && !canGoBack ? 24 : null,
      leading: !canGoBack && shell.openDrawer != null
          ? IconButton(
              key: const Key('open-drawer'),
              tooltip: context.l.openMenu,
              icon: const Icon(Icons.menu),
              onPressed: shell.openDrawer,
            )
          : null,
      actions: [
        ...actions,
        if (isTenantLocation(shell.location)) const TenantNotificationsButton() else const NotificationsButton(),
        if (wide) const AccountMenuButton(),
        SizedBox(width: wide ? 16 : 4),
      ],
    );
  }
}

/// Bell with a count of cheques due in the next 7 days and leases ending in
/// the next 30; the menu links to them.
class NotificationsButton extends ConsumerWidget {
  const NotificationsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final today = todayGst();
    final payments = ref.watch(paymentsProvider).value ?? const [];
    final leases = ref.watch(leasesProvider).value ?? const [];
    final properties = {for (final p in ref.watch(propertiesProvider).value ?? const []) p.id: p.name};
    final propertyOfLease = {for (final x in leases) x.id: properties[x.propertyId] ?? ''};
    final due = dueWithin(payments, today, 7);
    final ending = upcomingRenewals(leases, today, days: 30);
    final paymentById = {for (final p in payments) p.id: p};
    final holds = [
      for (final r in ref.watch(holdsProvider).value ?? const <HoldRequest>[])
        if (r.status == HoldStatus.pending) r,
    ];
    final count = due.length + ending.length + holds.length;

    return MenuAnchor(
      alignmentOffset: const Offset(-220, 4),
      menuChildren: [
        if (count == 0)
          MenuItemButton(onPressed: null, child: Text(l.noNotifications)),
        for (final r in holds.take(4))
          MenuItemButton(
            leadingIcon: const Icon(Icons.pause_circle_outline),
            onPressed: () => context.go('/holds'),
            child: SizedBox(
              width: 260,
              child: Text(
                '${l.hrNotif(formatAed(paymentById[r.paymentId]?.amount ?? 0))}\n'
                '${formatDate(r.originalDate)} → ${formatDate(r.requestedDate)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        for (final p in due.take(6))
          MenuItemButton(
            leadingIcon: const Icon(Icons.payments_outlined),
            onPressed: () => context.go(p.type == PaymentMethod.cheque ? '/cheques' : '/debits'),
            child: SizedBox(
              width: 260,
              child: Text('${formatDate(p.dueDate)} · ${formatAed(p.amount)}\n${propertyOfLease[p.leaseId] ?? ''}',
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ),
        for (final x in ending.take(4))
          MenuItemButton(
            leadingIcon: const Icon(Icons.event_repeat_outlined),
            onPressed: () => context.go('/leases'),
            child: SizedBox(
              width: 260,
              child: Text('${properties[x.propertyId] ?? ''}\n${l.endsInDays(x.endDate.difference(today).inDays)}',
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
      builder: (context, menu, _) => IconButton(
        key: const Key('notifications'),
        tooltip: l.notifications,
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: const Icon(Icons.notifications_none),
        ),
      ),
    );
  }
}

/// Avatar menu: who is signed in, Settings, Sign out.
class AccountMenuButton extends ConsumerWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final (name, email) = signedInIdentity(ref);
    final tenant = isTenantLocation(ShellScope.maybeOf(context)?.location ?? '');
    return MenuAnchor(
      alignmentOffset: const Offset(-180, 4),
      menuChildren: [
        MenuItemButton(
          onPressed: null,
          child: SizedBox(
            width: 200,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.isEmpty ? (tenant ? l.tpRoleTenant : l.landlord) : name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              if (email.isNotEmpty) Text(email, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.settings_outlined),
          onPressed: () => context.go(tenant ? '/t/settings' : '/settings'),
          child: Text(l.settings),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.logout),
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
          child: Text(l.signOut),
        ),
      ],
      builder: (context, menu, _) => IconButton(
        key: const Key('account-menu'),
        tooltip: l.account,
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        icon: _Avatar(name: name, email: email, radius: 16),
      ),
    );
  }
}

/// Name and email for the sidebar and account menu: the account record,
/// else the landlord profile.
(String, String) signedInIdentity(WidgetRef ref) {
  final user = ref.watch(appUserProvider).value;
  final landlord = ref.watch(landlordProvider).value;
  final name = (user?.name.trim().isNotEmpty ?? false) ? user!.name.trim() : (landlord?.name.trim() ?? '');
  final email = (landlord?.email.trim().isNotEmpty ?? false) ? landlord!.email.trim() : (user?.email.trim() ?? '');
  return (name, email);
}

/// Tenant bell: payments due in the next 7 days.
class TenantNotificationsButton extends ConsumerWidget {
  const TenantNotificationsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final today = todayGst();
    final due = [
      for (final TvPayment p in ref.watch(tenantPaymentsProvider).value ?? const <TvPayment>[])
        if (p.status == PaymentStatus.pending && !p.dueDate.isBefore(today) && p.dueDate.difference(today).inDays <= 7) p,
    ];
    return MenuAnchor(
      alignmentOffset: const Offset(-220, 4),
      menuChildren: [
        if (due.isEmpty) MenuItemButton(onPressed: null, child: Text(l.noNotifications)),
        for (final p in due.take(6))
          MenuItemButton(
            leadingIcon: const Icon(Icons.payments_outlined),
            onPressed: () => context.go('/t/payments'),
            child: SizedBox(
              width: 260,
              child: Text('${formatDate(p.dueDate)} · ${formatAed(p.amount)}\n${p.propertyName}',
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
      builder: (context, menu, _) => IconButton(
        key: const Key('notifications'),
        tooltip: l.notifications,
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        icon: Badge(isLabelVisible: due.isNotEmpty, label: Text('${due.length}'), child: const Icon(Icons.notifications_none)),
      ),
    );
  }
}
