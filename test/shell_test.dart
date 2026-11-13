import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/layout/app_shell.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/features/landlord/domain/landlord.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';
import 'package:ledgix_rent/main.dart';
import 'package:material_ui/material_ui.dart';

/// Signed-in demo app at a given window size.
Future<ProviderContainer> pumpSignedIn(WidgetTester tester, Size size, {String locale = 'en'}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.listen(userIdProvider, (_, _) {});
  container.read(localeProvider.notifier).set(locale);
  await tester.runAsync(() async {
    await container.read(authRepositoryProvider).signInWithEmail('a@b.c', 'x');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await container.read(landlordRepositoryProvider).save(const Landlord(id: 'demo', name: 'Afaq Haider', email: 'a@b.c'));
  });
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const LedgixApp()));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('phone: burger opens the drawer and navigates; bottom bar for main sections', (tester) async {
    await pumpSignedIn(tester, const Size(375, 812));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(Sidebar), findsNothing); // no permanent sidebar on phones

    await tester.tap(find.byKey(const Key('open-drawer')));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('Rent agreements'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-/tenants')));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
    expect(find.widgetWithText(AppBar, 'Tenants'), findsOneWidget);
    // Not a main section, so the bottom bar steps aside.
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('desktop: permanent sidebar, no burger, content width capped', (tester) async {
    await pumpSignedIn(tester, const Size(1920, 1000));
    expect(find.byType(Sidebar), findsOneWidget);
    expect(find.byKey(const Key('open-drawer')), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Rent agreements'), findsOneWidget);

    // Dashboard content is centred and at most 1200 px wide.
    final appBar = tester.getRect(find.byType(AppBar).first);
    expect(appBar.width, lessThanOrEqualTo(1200));

    await tester.tap(find.byKey(const Key('nav-/reports')));
    await tester.pumpAndSettle();
    expect(find.byType(Sidebar), findsOneWidget); // sidebar stays on secondary pages
  });

  testWidgets('desktop: pushed detail pages use the narrow column', (tester) async {
    final container = await pumpSignedIn(tester, const Size(1920, 1000));
    await tester.runAsync(() => container
        .read(propertyRepositoryProvider)
        .save(const Property(id: 'narrow', landlordId: 'demo', name: 'Narrow Test')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-/portfolio')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Narrow Test'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.widgetWithText(AppBar, 'Narrow Test')).width, lessThanOrEqualTo(880));
    expect(find.byType(Sidebar), findsOneWidget);
  });

  testWidgets('desktop RTL: sidebar moves to the right in Arabic', (tester) async {
    await pumpSignedIn(tester, const Size(1440, 900), locale: 'ar');
    final sidebar = tester.getRect(find.byType(Sidebar));
    expect(sidebar.left, greaterThan(1440 / 2));
    expect(find.text('عقود الإيجار'), findsOneWidget);
  });

  testWidgets('tablet: collapsed rail expands on demand', (tester) async {
    await pumpSignedIn(tester, const Size(800, 1000));
    expect(tester.getSize(find.byType(Sidebar)).width, AppShell.railWidth);
    expect(find.text('Rent agreements'), findsNothing); // icons only
    await tester.tap(find.byTooltip('Open menu').first);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Sidebar)).width, AppShell.sidebarWidth);
    expect(find.text('Rent agreements'), findsOneWidget);
  });

  testWidgets('settings: theme and language switches', (tester) async {
    final container = await pumpSignedIn(tester, const Size(1440, 1200));
    await tester.tap(find.byKey(const Key('nav-/settings')));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(of: find.byKey(const Key('theme-switch')), matching: find.text('Dark')));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(Theme.of(tester.element(find.byKey(const Key('theme-switch')))).brightness, Brightness.dark);

    await tester.tap(find.descendant(of: find.byKey(const Key('language-switch')), matching: find.text('العربية')));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider), 'ar');
    expect(find.text('الإعدادات'), findsWidgets);
  });
}
