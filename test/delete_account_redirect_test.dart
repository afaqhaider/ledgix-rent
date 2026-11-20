import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/l10n/gen/app_localizations.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/core/routing/app_router.dart';
import 'package:ledgix_rent/features/account/account_providers.dart';
import 'package:material_ui/material_ui.dart';

/// Account deletion removes the profile a moment before sign-out. In that gap
/// the user must see the splash, not "Set up your account".
void main() {
  Future<String> landing(WidgetTester tester, {required bool deleting}) async {
    final container = ProviderContainer(overrides: [
      userIdProvider.overrideWith((ref) => Stream.value('u1')),
      roleProvider.overrideWith((ref) => const AsyncData(null)),
    ]);
    addTearDown(container.dispose);
    container.read(deletingAccountProvider.notifier).set(deleting);
    container.listen(userIdProvider, (_, _) {});
    await container.read(userIdProvider.future);
    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pump();
    final loc = router.routerDelegate.currentConfiguration.uri.path;
    await tester.pumpWidget(const SizedBox());
    return loc;
  }

  testWidgets('signed in without a profile goes to onboarding', (tester) async {
    expect(await landing(tester, deleting: false), '/onboarding');
  });

  testWidgets('while deleting the account it stays on the splash', (tester) async {
    expect(await landing(tester, deleting: true), '/splash');
  });
}
