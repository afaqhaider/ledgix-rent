import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/auth/ledgix_hub.dart';
import 'core/data/push_service.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Native builds read google-services.json / GoogleService-Info.plist; the
  // web build needs its options from lib/firebase_options.dart. All three are
  // git-ignored and kept in secrets/.
  if (useFirebase) await Firebase.initializeApp(options: kIsWeb ? DefaultFirebaseOptions.web : null);
  if (useFirebase && kIsWeb) await _finishLedgixWebSignIn();
  runApp(const ProviderScope(child: LedgixApp()));
}

/// The browser comes back from LedGix ID to /hub-callback?code=…; redeem it
/// before the router starts so the user lands signed in.
Future<void> _finishLedgixWebSignIn() async {
  try {
    final code = LedgixHub.takeWebCallback();
    if (code != null) await FirebaseAuthRepository.completeLedgixSignIn(code);
  } catch (e) {
    LedgixHub.webCallbackError = '$e';
  }
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
