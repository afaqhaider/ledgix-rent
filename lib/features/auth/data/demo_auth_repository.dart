import 'dart:async';

import '../domain/auth_repository.dart';

/// Offline demo auth: any credentials work, OTP is accepted as-is.
class DemoAuthRepository implements AuthRepository {
  String? _uid;
  final _c = StreamController<String?>.broadcast();

  void _set(String? v) {
    _uid = v;
    _c.add(v);
  }

  @override
  String? get currentUserId => _uid;

  @override
  Stream<String?> watchUserId() async* {
    yield _uid;
    yield* _c.stream;
  }

  @override
  Future<void> signInWithEmail(String email, String password) async => _set('demo');

  @override
  Future<void> signUpWithEmail(String email, String password) async => _set('demo');

  @override
  Future<String> sendOtp(String phoneNumber) async => 'demo-verification';

  @override
  Future<void> confirmOtp(String verificationId, String code) async => _set('demo');

  @override
  Future<void> signOut() async => _set(null);
}
