/// Authentication contract (email + phone OTP).
abstract class AuthRepository {
  Stream<String?> watchUserId();
  String? get currentUserId;
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String email, String password);

  /// Starts phone verification and returns a verification id.
  Future<String> sendOtp(String phoneNumber);
  Future<void> confirmOtp(String verificationId, String code);
  Future<void> signOut();
}
