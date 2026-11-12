import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/holds/presentation/holds_screen.dart';
import '../../features/landlord/presentation/onboarding_screen.dart';
import '../../features/leases/domain/lease.dart';
import '../../features/leases/presentation/leases_screen.dart';
import '../../features/maintenance/presentation/maintenance_screen.dart';
import '../../features/maintenance/presentation/ticket_detail_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/utilities/presentation/utility_bills_screen.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/properties/presentation/portfolio_screen.dart';
import '../../features/tenants/presentation/tenants_screen.dart';
import '../../features/vendors/presentation/vendors_screen.dart';
import '../providers.dart';
import '../widgets/common.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(userIdProvider, (_, _) => refresh.value++);
  ref.listen(landlordProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final uid = ref.read(userIdProvider);
      if (uid.isLoading) return null;
      final loc = state.matchedLocation;
      if (uid.value == null) return loc == '/login' ? null : '/login';
      final landlord = ref.read(landlordProvider);
      if (landlord.isLoading) return null;
      if (landlord.value == null) return loc == '/onboarding' ? null : '/onboarding';
      if (loc == '/login' || loc == '/onboarding') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => Scaffold(
          body: shell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.dashboard_outlined), label: c.l.dashboard),
              NavigationDestination(icon: const Icon(Icons.apartment), label: c.l.portfolio),
              NavigationDestination(icon: const Icon(Icons.payments_outlined), label: c.l.cheques),
              NavigationDestination(icon: const Icon(Icons.build_outlined), label: c.l.maintenance),
              NavigationDestination(icon: const Icon(Icons.menu), label: c.l.more),
            ],
          ),
        ),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const DashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/portfolio', builder: (_, _) => const PortfolioScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/cheques', builder: (_, _) => const PaymentsScreen(type: PaymentMethod.cheque))]),
          StatefulShellBranch(routes: [GoRoute(path: '/maintenance', builder: (_, _) => const MaintenanceScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/more', builder: (_, _) => const MoreScreen())]),
        ],
      ),
      GoRoute(path: '/property/new', builder: (_, _) => const PropertyFormScreen()),
      GoRoute(path: '/property/:id', builder: (_, s) => PropertyDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/tenants', builder: (_, _) => const TenantsScreen()),
      GoRoute(path: '/tenants/new', builder: (_, _) => const TenantFormScreen()),
      GoRoute(path: '/leases', builder: (_, _) => const LeasesScreen()),
      GoRoute(path: '/leases/new', builder: (_, _) => const LeaseFormScreen()),
      GoRoute(path: '/debits', builder: (_, _) => const PaymentsScreen(type: PaymentMethod.directDebit)),
      GoRoute(path: '/holds', builder: (_, _) => const HoldsScreen()),
      GoRoute(path: '/tickets/new', builder: (_, _) => const TicketFormScreen()),
      GoRoute(path: '/tickets/:id', builder: (_, s) => TicketDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/property/:id/bills', builder: (_, s) => UtilityBillsScreen(propertyId: s.pathParameters['id']!)),
      GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
      GoRoute(path: '/vendors', builder: (_, _) => const VendorsScreen()),
      GoRoute(path: '/vendors/new', builder: (_, _) => const VendorFormScreen()),
    ],
  );
});

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    Widget item(IconData i, String t, String path) =>
        ListTile(leading: Icon(i), title: Text(t), trailing: const Icon(Icons.chevron_right), onTap: () => context.push(path));
    return Scaffold(
      appBar: AppBar(title: Text(l.more)),
      body: ListView(children: [
        item(Icons.people_outline, l.tenants, '/tenants'),
        item(Icons.description_outlined, l.leases, '/leases'),
        item(Icons.account_balance_outlined, l.directDebits, '/debits'),
        item(Icons.pause_circle_outline, l.holdRequests, '/holds'),
        item(Icons.handyman_outlined, l.vendors, '/vendors'),
        item(Icons.bar_chart, l.reports, '/reports'),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l.language),
          trailing: SegmentedButton<String>(
            segments: [ButtonSegment(value: 'en', label: Text(l.english)), ButtonSegment(value: 'ar', label: Text(l.arabic))],
            selected: {ref.watch(localeProvider)},
            onSelectionChanged: (s) => ref.read(localeProvider.notifier).set(s.first),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(l.signOut),
          onTap: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ]),
    );
  }
}
