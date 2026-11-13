import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/auth/ledgix_hub.dart';
import '../../../core/l10n/gen/app_localizations.dart';

/// Turns a sign-in failure into a short, translated message for the user,
/// instead of showing raw exception text.
String authErrorMessage(Object error, AppLocalizations l) {
  if (error is LedgixSignInError || error is FirebaseFunctionsException) return l.errLedgix;
  if (error is FirebaseAuthException) return authCodeMessage(error.code, l);
  return l.errGeneric;
}

/// Firebase Auth error codes (both the SDK's `wrong-password` style and the
/// web SDK's `auth/wrong-password` style) to messages.
String authCodeMessage(String code, AppLocalizations l) {
  final c = code.startsWith('auth/') ? code.substring(5) : code;
  return switch (c) {
    'invalid-credential' ||
    'invalid-login-credentials' ||
    'wrong-password' ||
    'user-not-found' ||
    'INVALID_LOGIN_CREDENTIALS' =>
      l.errInvalidCredentials,
    'email-already-in-use' => l.errEmailInUse,
    'weak-password' => l.errWeakPassword,
    'invalid-email' || 'missing-email' => l.errInvalidEmail,
    'user-disabled' => l.errUserDisabled,
    'too-many-requests' || 'quota-exceeded' => l.errTooManyRequests,
    'network-request-failed' || 'web-network-request-failed' => l.errNetwork,
    'operation-not-allowed' || 'admin-restricted-operation' => l.errMethodDisabled,
    'popup-blocked' => l.errPopupBlocked,
    'account-exists-with-different-credential' || 'credential-already-in-use' => l.errAccountExists,
    'invalid-phone-number' || 'missing-phone-number' => l.errInvalidPhone,
    'invalid-verification-code' ||
    'invalid-verification-id' ||
    'session-expired' ||
    'code-expired' ||
    'missing-verification-code' =>
      l.errInvalidCode,
    _ => l.errGeneric,
  };
}
