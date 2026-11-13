import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'ledgix_hub_web.dart';

/// A LedGix ID sign-in failure with a message fit to show the user.
class LedgixSignInError implements Exception {
  const LedgixSignInError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A redeemable LedGix ID authorization code.
typedef HubCode = ({String code, String verifier, String redirectUri});

/// LedGix ID (LedGix Hub) sign-in: OIDC Authorization Code + PKCE (S256).
///
/// The app gets an authorization code; the `exchangeLedgixHubSession` Cloud
/// Function redeems it, verifies the identity and returns a Firebase custom
/// token. Client `ledgix-rent` and its redirect URIs are registered in the
/// Hub's LEDGIX_CLIENTS_JSON (LedGix-SSO service-auth.yaml).
abstract final class LedgixHub {
  static const issuer = 'https://auth.getledgix.com';
  static const clientId = 'ledgix-rent';
  static const scopes = 'openid profile email';
  static const mobileScheme = 'com.ledgix.rent';
  static const mobileRedirectUri = '$mobileScheme://oidc-callback';
  static const callbackPath = '/hub-callback';

  /// Web redirect on whichever registered host is serving the app.
  static String get webRedirectUri => Uri.base.host == 'rent.getledgix.com'
      ? 'https://rent.getledgix.com$callbackPath'
      : 'https://ledgix-rent.web.app$callbackPath';

  /// Set when a web callback fails, so the login screen can show it.
  static String? webCallbackError;

  static String _random(int bytes) =>
      base64Url.encode(List<int>.generate(bytes, (_) => Random.secure().nextInt(256))).replaceAll('=', '');

  static String _challenge(String verifier) =>
      base64Url.encode(sha256.convert(utf8.encode(verifier)).bytes).replaceAll('=', '');

  static Uri _authorizeUrl({required String verifier, required String state, required String redirectUri}) =>
      Uri.parse('$issuer/auth').replace(queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scopes,
        'code_challenge': _challenge(verifier),
        'code_challenge_method': 'S256',
        'state': state,
      });

  static HubCode _readCallback(Uri callback, {required String expectedState, required String verifier, required String redirectUri}) {
    if (callback.queryParameters['state'] != expectedState) {
      throw LedgixSignInError('LedGix ID sign-in did not match this request. Please try again.');
    }
    final error = callback.queryParameters['error'];
    if (error != null) throw LedgixSignInError(callback.queryParameters['error_description'] ?? error);
    final code = callback.queryParameters['code'];
    if (code == null || code.isEmpty) throw LedgixSignInError('LedGix ID did not return a sign-in code.');
    return (code: code, verifier: verifier, redirectUri: redirectUri);
  }

  /// iOS/Android: runs the flow in the system auth sheet. Null if cancelled.
  static Future<HubCode?> authorizeNative() async {
    final verifier = _random(32);
    final state = _random(16);
    final String result;
    try {
      result = await FlutterWebAuth2.authenticate(
        url: _authorizeUrl(verifier: verifier, state: state, redirectUri: mobileRedirectUri).toString(),
        callbackUrlScheme: mobileScheme,
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') return null;
      rethrow;
    }
    return _readCallback(Uri.parse(result), expectedState: state, verifier: verifier, redirectUri: mobileRedirectUri);
  }

  /// Web: remembers the PKCE values and leaves for the Hub. The Hub sends the
  /// browser back to [webRedirectUri], handled by [takeWebCallback].
  static void startWeb() {
    final verifier = _random(32);
    final state = _random(16);
    saveHubWebFlow(verifier, state);
    navigateTo(_authorizeUrl(verifier: verifier, state: state, redirectUri: webRedirectUri).toString());
  }

  /// Web: if this page load is the Hub callback, returns its code and cleans
  /// the address bar. Null on any other page load.
  static HubCode? takeWebCallback() {
    if (!kIsWeb || Uri.base.path != callbackPath) return null;
    final flow = readHubWebFlow();
    clearHubWebFlow();
    replaceUrlWithRoot();
    if (flow == null) throw LedgixSignInError('LedGix ID sign-in expired. Please try again.');
    return _readCallback(Uri.base, expectedState: flow.state, verifier: flow.verifier, redirectUri: webRedirectUri);
  }

  /// Redeems [code] server-side and returns a Firebase custom token.
  static Future<String> exchange(HubCode code) async {
    final result = await FirebaseFunctions.instance.httpsCallable('exchangeLedgixHubSession').call<Map<Object?, Object?>>({
      'code': code.code,
      'verifier': code.verifier,
      'redirectUri': code.redirectUri,
    });
    final token = result.data['customToken'];
    if (token is! String || token.isEmpty) throw LedgixSignInError('LedGix ID did not return a LedGix Rent session.');
    return token;
  }
}
