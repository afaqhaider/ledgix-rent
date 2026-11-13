import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/auth/ledgix_hub.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final _auth = FirebaseAuth.instance;
  Future<void>? _googleInit;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Stream<String?> watchUserId() => _auth.authStateChanges().map((u) => u?.uid);

  @override
  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> signUpWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Don't reveal whether an address has an account.
      if (e.code != 'user-not-found') rethrow;
    }
  }

  @override
  Future<void> signInWithLedgix() async {
    if (kIsWeb) return LedgixHub.startWeb();
    final code = await LedgixHub.authorizeNative();
    if (code == null) return; // cancelled
    await completeLedgixSignIn(code);
  }

  /// Redeems a LedGix ID code and signs in to Firebase with the result.
  static Future<void> completeLedgixSignIn(HubCode code) async {
    try {
      await FirebaseAuth.instance.signInWithCustomToken(await LedgixHub.exchange(code));
    } on FirebaseFunctionsException catch (e) {
      throw LedgixSignInError(e.message ?? 'LedGix ID sign-in failed. Please try again.');
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) return _popup(GoogleAuthProvider());
    // Native account picker. Client IDs come from google-services.json
    // (Android) and GoogleService-Info.plist (iOS).
    final google = GoogleSignIn.instance;
    await (_googleInit ??= google.initialize());
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      rethrow;
    }
    final idToken = account.authentication.idToken;
    await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
  }

  @override
  Future<void> signInWithApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    if (kIsWeb) return _popup(provider);
    try {
      // Native Sign in with Apple sheet on iOS.
      await _auth.signInWithProvider(provider);
    } on FirebaseAuthException catch (e) {
      if (_cancelled(e)) return;
      rethrow;
    }
  }

  Future<void> _popup(AuthProvider provider) async {
    try {
      await _auth.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      if (_cancelled(e)) return;
      rethrow;
    }
  }

  static bool _cancelled(FirebaseAuthException e) => const {
        'canceled',
        'web-context-canceled',
        'popup-closed-by-user',
        'cancelled-popup-request',
      }.contains(e.code);

  @override
  Future<String> sendOtp(String phoneNumber) {
    final done = Completer<String>();
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (cred) => _auth.signInWithCredential(cred),
      verificationFailed: (e) => done.isCompleted ? null : done.completeError(e),
      codeSent: (id, _) => done.isCompleted ? null : done.complete(id),
      codeAutoRetrievalTimeout: (id) => done.isCompleted ? null : done.complete(id),
    );
    return done.future;
  }

  @override
  Future<void> confirmOtp(String verificationId, String code) => _auth.signInWithCredential(
      PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code));

  @override
  Future<void> signOut() async {
    if (!kIsWeb) {
      // Forget the Google account so the picker shows next time.
      try {
        await (_googleInit ??= GoogleSignIn.instance.initialize());
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  @override
  Future<bool> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return true;
    // Apple requires apps to revoke the Sign in with Apple token when the
    // account is deleted, which needs a fresh authorization code.
    if (!kIsWeb && user.providerData.any((p) => p.providerId == 'apple.com')) {
      try {
        final cred = await user.reauthenticateWithProvider(AppleAuthProvider());
        final code = cred.additionalUserInfo?.authorizationCode;
        if (code != null) await _auth.revokeTokenWithAuthorizationCode(code);
      } on FirebaseAuthException catch (e) {
        if (_cancelled(e)) return false;
        // Revoking needs the Apple key configured in Firebase; don't let a
        // failure there block deleting the user's data.
      }
    }
    // Server side: deletes landlords/{uid} (Firestore + Storage) and the user.
    await FirebaseFunctions.instance.httpsCallable('deleteAccount').call<void>();
    await signOut();
    return true;
  }
}
