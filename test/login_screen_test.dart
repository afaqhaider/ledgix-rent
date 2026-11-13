import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/l10n/gen/app_localizations_ar.dart';
import 'package:ledgix_rent/core/l10n/gen/app_localizations_en.dart';
import 'package:ledgix_rent/features/auth/presentation/auth_errors.dart';
import 'package:ledgix_rent/main.dart';
import 'package:material_ui/material_ui.dart';

/// Login screen in demo mode (no Firebase): any credentials sign in.
Future<void> pumpLogin(WidgetTester tester, {Size size = const Size(800, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ProviderScope(child: LedgixApp()));
  await tester.pumpAndSettle();
}

Future<void> tapShown(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('LedGix ID comes first, then email, then Google', (tester) async {
    await pumpLogin(tester);
    expect(find.text('Sign in to LedGix Rent'), findsOneWidget);
    final ledgix = tester.getTopLeft(find.byKey(const Key('ledgix-sign-in'))).dy;
    final email = tester.getTopLeft(find.byKey(const Key('email-field'))).dy;
    final google = tester.getTopLeft(find.byKey(const Key('google-sign-in'))).dy;
    expect(ledgix < email && email < google, isTrue);
    // The old Email/Phone tabs are gone.
    expect(find.byType(TabBar), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('email sign-in leaves the login screen', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(find.byKey(const Key('email-field')), 'landlord@example.com');
    await tester.enterText(find.byKey(const Key('password-field')), 'secret123');
    await tapShown(tester, find.byKey(const Key('email-submit')));
    expect(find.byKey(const Key('email-submit')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('password visibility toggles', (tester) async {
    await pumpLogin(tester);
    TextField field() => tester.widget<TextField>(
        find.descendant(of: find.byKey(const Key('password-field')), matching: find.byType(TextField)));
    expect(field().obscureText, isTrue);
    await tapShown(tester, find.byTooltip('Show password'));
    expect(field().obscureText, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('forgot password sends a reset link', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(find.byKey(const Key('email-field')), 'landlord@example.com');
    await tapShown(tester, find.byKey(const Key('forgot-password')));
    expect(find.byKey(const Key('reset-password-dialog')), findsOneWidget);
    // Prefilled from the email field.
    expect(find.descendant(of: find.byKey(const Key('reset-email-field')), matching: find.text('landlord@example.com')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('send-reset-link')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reset-password-dialog')), findsNothing);
    expect(find.text('If an account exists for landlord@example.com, a reset link is on its way.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reset dialog validates the email', (tester) async {
    await pumpLogin(tester);
    await tapShown(tester, find.byKey(const Key('forgot-password')));
    await tester.tap(find.byKey(const Key('send-reset-link')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.byKey(const Key('reset-password-dialog')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('phone toggle swaps in phone sign-in and back', (tester) async {
    await pumpLogin(tester);
    await tapShown(tester, find.byKey(const Key('toggle-phone')));
    expect(find.byKey(const Key('phone-field')), findsOneWidget);
    expect(find.byKey(const Key('email-field')), findsNothing);
    await tester.enterText(find.byKey(const Key('phone-field')), '+971501234567');
    await tapShown(tester, find.byKey(const Key('phone-submit')));
    expect(find.byKey(const Key('otp-field')), findsOneWidget);
    await tapShown(tester, find.byKey(const Key('toggle-phone')));
    expect(find.byKey(const Key('email-field')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('create account toggle changes the title and button', (tester) async {
    await pumpLogin(tester);
    await tapShown(tester, find.byKey(const Key('toggle-sign-up')));
    expect(find.text('Create your LedGix Rent account'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create account'), findsOneWidget);
    expect(find.byKey(const Key('forgot-password')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('wide screens show the brand panel, phones do not', (tester) async {
    await pumpLogin(tester, size: const Size(1440, 900));
    expect(find.text('Rent, cheques and maintenance. One calm place.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    await pumpLogin(tester, size: const Size(390, 844));
    expect(find.text('Rent, cheques and maintenance. One calm place.'), findsNothing);
    expect(find.byKey(const Key('ledgix-sign-in')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Arabic login lays out right-to-left without overflow', (tester) async {
    await pumpLogin(tester, size: const Size(1280, 860));
    await tapShown(tester, find.byKey(const Key('toggle-language')));
    expect(find.text('تسجيل الدخول إلى LedGix Rent'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byKey(const Key('email-field')))), TextDirection.rtl);
    expect(tester.takeException(), isNull);
    await tapShown(tester, find.byKey(const Key('toggle-language'))); // back to English for later tests
    await tester.pumpWidget(const SizedBox());
  });

  group('auth error messages', () {
    final en = AppLocalizationsEn();
    final ar = AppLocalizationsAr();

    test('map Firebase codes, with or without the auth/ prefix', () {
      expect(authCodeMessage('wrong-password', en), en.errInvalidCredentials);
      expect(authCodeMessage('auth/invalid-credential', en), en.errInvalidCredentials);
      expect(authCodeMessage('email-already-in-use', en), en.errEmailInUse);
      expect(authCodeMessage('auth/network-request-failed', en), en.errNetwork);
      expect(authCodeMessage('too-many-requests', ar), ar.errTooManyRequests);
      expect(authCodeMessage('something-new', en), en.errGeneric);
    });

    test('unknown errors never leak raw text', () {
      expect(authErrorMessage(Exception('boom: stack trace'), en), en.errGeneric);
    });
  });
}
