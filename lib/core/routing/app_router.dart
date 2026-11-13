import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/holds/presentation/holds_screen.dart';
import '../../features/landlord/presentation/onboarding_screen.dart';
import '../../features/leases/domain/lease.dart';
import '../../features/leases/presentation/leases_screen.dart';
import '../../features/leases/presentation/rent_agreement_form_screen.dart';
import '../../features/inspections/presentation/inspections_screen.dart';
import '../../features/inspections/presentation/walkthrough_screen.dart';
import '../../features/landlord/presentation/profile_screen.dart';
import '../../features/maintenance/presentation/maintenance_screen.dart';
import '../../features/maintenance/presentation/ticket_detail_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/utilities/presentation/utility_bills_screen.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/properties/presentation/portfolio_screen.dart';
import '../../features/properties/presentation/property_form_screen.dart';
import '../../features/tenants/presentation/tenants_screen.dart';
import '../../features/vendors/presentation/vendors_screen.dart';
import '../../features/servicecharges/presentation/service_charges_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/utilities/presentation/utilities_overview_screen.dart';
import '../layout/app_shell.dart';
import '../layout/auth_frame.dart';
import '../providers.dart';
import '../widgets/brand.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(userIdProvider, (_, _) => refresh.value++);
  ref.listen(landlordProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  // Pushed pages (details, forms) show in the browser address bar, so a
  // refresh or shared link on the web reopens the same page.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  return GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final uid = ref.read(userIdProvider);
      final landlord = uid.value == null ? null : ref.read(landlordProvider);
      // While sign-in state loads, show a splash (not the dashboard) and
      // remember where the user was going.
      if (uid.isLoading || (landlord?.isLoading ?? false)) {
        return loc == '/splash' ? null : '/splash?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (uid.value == null) return loc == '/login' ? null : '/login';
      if (landlord?.value == null) return loc == '/onboarding' ? null : '/onboarding';
      if (loc == '/splash') {
        final from = state.uri.queryParameters['from'];
        const entry = ['/splash', '/login', '/onboarding'];
        return from == null || entry.any(from.startsWith) ? '/' : from;
      }
      if (loc == '/login' || loc == '/onboarding') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const AuthFrame(child: OnboardingScreen())),
      GoRoute(path: '/more', redirect: (_, _) => '/settings'),
      // Every signed-in page renders inside the responsive shell (sidebar on
      // desktop, rail on tablets, drawer + bottom bar on phones).
      ShellRoute(
        builder: (c, s, child) => AppShell(location: s.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/', pageBuilder: (_, s) => _section(s, const DashboardScreen())),
          GoRoute(path: '/portfolio', pageBuilder: (_, s) => _section(s, const PortfolioScreen())),
          GoRoute(path: '/cheques', pageBuilder: (_, s) => _section(s, const PaymentsScreen(type: PaymentMethod.cheque))),
          GoRoute(path: '/maintenance', pageBuilder: (_, s) => _section(s, const MaintenanceScreen())),
          GoRoute(path: '/property/new', builder: (_, _) => const PropertyFormScreen()),
          GoRoute(path: '/property/:id', builder: (_, s) => PropertyDetailScreen(id: s.pathParameters['id']!)),
          GoRoute(path: '/property/:id/edit', builder: (_, s) => PropertyFormScreen(id: s.pathParameters['id']!)),
          GoRoute(path: '/tenants', pageBuilder: (_, s) => _section(s, const TenantsScreen())),
          GoRoute(
            path: '/tenants/new',
            builder: (_, s) => TenantFormScreen(prefill: (s.extra as Map?)?.cast<String, String>()),
          ),
          GoRoute(path: '/tenants/:id/edit', builder: (_, s) => TenantFormScreen(id: s.pathParameters['id']!)),
          GoRoute(path: '/leases', pageBuilder: (_, s) => _section(s, const LeasesScreen())),
          GoRoute(path: '/leases/new', builder: (_, _) => const RentAgreementFormScreen()),
          GoRoute(path: '/leases/:id/edit', builder: (_, s) => RentAgreementFormScreen(id: s.pathParameters['id']!)),
          GoRoute(path: '/inspections', pageBuilder: (_, s) => _section(s, const InspectionsScreen())),
          GoRoute(path: '/inspections/:id', builder: (_, s) => InspectionScreen(id: s.pathParameters['id']!)),
          GoRoute(path: '/debits', pageBuilder: (_, s) => _section(s, const PaymentsScreen(type: PaymentMethod.directDebit))),
          GoRoute(path: '/holds', pageBuilder: (_, s) => _section(s, const HoldsScreen())),
          GoRoute(path: '/tickets/new', builder: (_, _) => const TicketFormScreen()),
          GoRoute(path: '/tickets/:id', builder: (_, s) => TicketDetailScreen(id: s.pathParameters['id']!)),
          GoRoute(path: '/property/:id/bills', builder: (_, s) => UtilityBillsScreen(propertyId: s.pathParameters['id']!)),
          GoRoute(path: '/reports', pageBuilder: (_, s) => _section(s, const ReportsScreen())),
          GoRoute(path: '/vendors', pageBuilder: (_, s) => _section(s, const VendorsScreen())),
          GoRoute(path: '/vendors/new', builder: (_, _) => const VendorFormScreen()),
          GoRoute(path: '/utilities', pageBuilder: (_, s) => _section(s, const UtilitiesOverviewScreen())),
          GoRoute(path: '/service-charges', pageBuilder: (_, s) => _section(s, const ServiceChargesScreen())),
          GoRoute(path: '/settings', pageBuilder: (_, s) => _section(s, const SettingsScreen())),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        ],
      ),
    ],
  );
});

/// Sidebar sections switch with a quick fade instead of a page slide;
/// pages pushed on top (forms, details) keep the platform transition.
Page<void> _section(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 160),
      reverseTransitionDuration: const Duration(milliseconds: 120),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child),
    );

/// Shown while the sign-in state loads, so the dashboard never flashes.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            LogoMark(size: 72),
            SizedBox(height: 24),
            SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          ]),
        ),
      );
}
