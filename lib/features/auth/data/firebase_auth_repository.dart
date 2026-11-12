import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final _auth = FirebaseAuth.instance;

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
  Future<void> signOut() => _auth.signOut();
}
