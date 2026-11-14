import 'package:material_ui/material_ui.dart';

import '../feature_flags.dart';
import '../l10n/gen/app_localizations.dart';

/// Window size classes (Material 3): phones, tablets/small windows, desktop.
enum WindowSize { compact, medium, expanded }

WindowSize windowSizeOf(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 600) return WindowSize.compact;
  if (w < 1024) return WindowSize.medium;
  return WindowSize.expanded;
}

class NavItem {
  const NavItem(this.path, this.icon, this.selectedIcon, this.label, {this.matches = const []});
  final String path;
  final IconData icon, selectedIcon;
  final String Function(AppLocalizations l) label;

  /// Other route prefixes that belong to this item (e.g. a detail page);
  /// entries starting with ^ are regular expressions.
  final List<String> matches;

  bool owns(String location) {
    if (path == '/' || path == '/t') return location == path; // home items match exactly
    bool under(String p) => location == p || location.startsWith('$p/');
    return under(path) || matches.any((m) => m.startsWith('^') ? RegExp(m).hasMatch(location) : under(m));
  }
}

class NavSection {
  const NavSection(this.title, this.items);
  final String Function(AppLocalizations l) title;
  final List<NavItem> items;
}

final dashboardItem = NavItem('/', Icons.space_dashboard_outlined, Icons.space_dashboard, (l) => l.dashboard);
final propertiesItem = NavItem('/portfolio', Icons.apartment_outlined, Icons.apartment, (l) => l.properties,
    matches: [r'^/property/[^/]+$', '/property/new']);
final chequesItem = NavItem('/cheques', Icons.payments_outlined, Icons.payments, (l) => l.cheques);
final maintenanceItem =
    NavItem('/maintenance', Icons.build_outlined, Icons.build, (l) => l.maintenance, matches: ['/tickets']);
final settingsItem =
    NavItem('/settings', Icons.settings_outlined, Icons.settings, (l) => l.settings, matches: ['/profile']);

/// Sidebar / drawer structure. Settings sits apart, at the bottom.
List<NavSection> get navSections => [
      NavSection((l) => l.overview, [dashboardItem]),
      NavSection((l) => l.portfolio, [
        propertiesItem,
        NavItem('/tenants', Icons.people_outline, Icons.people, (l) => l.tenants),
        NavItem('/leases', Icons.description_outlined, Icons.description, (l) => l.rentAgreements),
        chequesItem,
        NavItem('/debits', Icons.account_balance_outlined, Icons.account_balance, (l) => l.directDebits),
      ]),
      NavSection((l) => l.operations, [
        maintenanceItem,
        NavItem('/inspections', Icons.fact_check_outlined, Icons.fact_check, (l) => l.inspections),
        NavItem('/vendors', Icons.handyman_outlined, Icons.handyman, (l) => l.vendors),
        NavItem('/holds', Icons.pause_circle_outline, Icons.pause_circle, (l) => l.holdRequests),
        if (FeatureFlags.utilityBills)
          NavItem('/utilities', Icons.bolt_outlined, Icons.bolt, (l) => l.utilityBills, matches: [r'^/property/[^/]+/bills$']),
        if (FeatureFlags.mollak)
          NavItem('/service-charges', Icons.receipt_long_outlined, Icons.receipt_long, (l) => l.serviceCharges),
      ]),
      NavSection((l) => l.insights, [
        NavItem('/reports', Icons.bar_chart_outlined, Icons.bar_chart, (l) => l.reports),
      ]),
    ];

/// Bottom bar on phones: the four places landlords go most.
final primaryItems = [dashboardItem, propertiesItem, chequesItem, maintenanceItem];

// ---- Tenant app (every tenant route starts with /t) ----

bool isTenantLocation(String location) => location == '/t' || location.startsWith('/t/');

final tenantHomeItem = NavItem('/t', Icons.home_outlined, Icons.home, (l) => l.tpHome);
final tenantLandlordsItem = NavItem('/t/landlords', Icons.person_pin_outlined, Icons.person_pin, (l) => l.tpLandlords);
final tenantPropertiesItem = NavItem('/t/properties', Icons.apartment_outlined, Icons.apartment, (l) => l.properties);
final tenantPaymentsItem = NavItem('/t/payments', Icons.payments_outlined, Icons.payments, (l) => l.tpPayments);
final tenantInspectionsItem =
    NavItem('/t/inspections', Icons.fact_check_outlined, Icons.fact_check, (l) => l.tpInspections);
final tenantMaintenanceItem = NavItem('/t/maintenance', Icons.build_outlined, Icons.build, (l) => l.maintenance);
final tenantSettingsItem = NavItem('/t/settings', Icons.settings_outlined, Icons.settings, (l) => l.settings);

List<NavSection> get tenantNavSections => [
      NavSection((l) => l.overview, [tenantHomeItem]),
      NavSection((l) => l.tpYourLeases, [tenantLandlordsItem, tenantPropertiesItem, tenantPaymentsItem]),
      NavSection((l) => l.operations, [tenantInspectionsItem, tenantMaintenanceItem]),
    ];

final tenantPrimaryItems = [tenantHomeItem, tenantPropertiesItem, tenantPaymentsItem, tenantMaintenanceItem];

/// The landlord or tenant navigation, by route.
List<NavSection> navSectionsFor(String location) => isTenantLocation(location) ? tenantNavSections : navSections;
List<NavItem> primaryItemsFor(String location) => isTenantLocation(location) ? tenantPrimaryItems : primaryItems;
NavItem settingsItemFor(String location) => isTenantLocation(location) ? tenantSettingsItem : settingsItem;

Iterable<NavItem> get allNavItems => [for (final s in navSections) ...s.items, settingsItem];

NavItem? navItemFor(String location) {
  final items = isTenantLocation(location)
      ? [for (final s in tenantNavSections) ...s.items, tenantSettingsItem]
      : allNavItems;
  for (final i in items) {
    if (i.owns(location)) return i;
  }
  return null;
}

/// Detail and settings pages read better in a narrower column than lists.
bool isNarrowPage(String location) =>
    location == '/settings' ||
    location == '/profile' ||
    location == '/t/settings' ||
    RegExp(r'^/(property|tickets)/[^/]+$').hasMatch(location) ||
    RegExp(r'^/t/(landlords|inspections)/.+$').hasMatch(location);
