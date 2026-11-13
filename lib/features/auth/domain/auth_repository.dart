/// Authentication contract (email, phone OTP, Google and Apple).
abstract class AuthRepository {
  Stream<String?> watchUserId();
  String? get currentUserId;
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String email, String password);

  /// LedGix ID (LedGix Hub single sign-on). On the web this leaves the page
  /// for the Hub and finishes when the browser comes back.
  Future<void> signInWithLedgix();

  /// Social sign-in. Completes without signing in if the user cancels.
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();

  /// Starts phone verification and returns a verification id.
  Future<String> sendOtp(String phoneNumber);
  Future<void> confirmOtp(String verificationId, String code);
  Future<void> signOut();

  /// Permanently deletes the account and all of its data. Returns false if
  /// the user backed out of a required re-authentication.
  Future<bool> deleteAccount();
}
