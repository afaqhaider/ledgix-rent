import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/data/push_service.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Reads google-services.json / GoogleService-Info.plist added by the owner.
  if (useFirebase) await Firebase.initializeApp();
  runApp(const ProviderScope(child: LedgixApp()));
}

class LedgixApp extends ConsumerWidget {
  const LedgixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (useFirebase) {
      ref.listen(userIdProvider, (_, next) {
        final uid = next.value;
        if (uid != null) PushService.register(uid);
      });
    }
    return MaterialApp.router(
      title: 'LedGix Rent',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
      locale: Locale(ref.watch(localeProvider)),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates, // from material_ui
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}
