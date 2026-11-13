import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/auth/ledgix_hub.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/privacy.dart';
import 'social_sign_in.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  String? _verificationId;
  bool _signUp = false, _busy = false;

  @override
  void initState() {
    super.initState();
    // A LedGix ID web sign-in that failed after returning from the Hub.
    final error = LedgixHub.webCallbackError;
    if (error != null) {
      LedgixHub.webCallbackError = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      });
    }
  }

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authRepositoryProvider);
    final l = context.l;
    final social = SocialSignInButtons(
      onLedgix: _busy ? null : () => _run(auth.signInWithLedgix),
      onGoogle: _busy ? null : () => _run(auth.signInWithGoogle),
      onApple: _busy ? null : () => _run(auth.signInWithApple),
    );
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: BrandTitle(l.appName),
          actions: [
            TextButton(
              onPressed: () => ref
                  .read(localeProvider.notifier)
                  .set(ref.read(localeProvider) == 'en' ? 'ar' : 'en'),
              child: Text(ref.watch(localeProvider) == 'en' ? l.arabic : l.english),
            ),
          ],
          bottom: TabBar(tabs: [Tab(text: l.emailTab), Tab(text: l.phoneTab)]),
        ),
        body: TabBarView(children: [
          ListView(padding: const EdgeInsets.all(16), children: [
            const Center(child: BrandLogo(height: 112)),
            const SizedBox(height: 24),
            TextField(controller: _email, decoration: InputDecoration(labelText: l.email), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: InputDecoration(labelText: l.password), obscureText: true),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(() => _signUp
                      ? auth.signUpWithEmail(_email.text.trim(), _password.text)
                      : auth.signInWithEmail(_email.text.trim(), _password.text)),
              child: Text(_signUp ? l.signUp : l.signIn),
            ),
            TextButton(
              onPressed: () => setState(() => _signUp = !_signUp),
              child: Text(_signUp ? l.signIn : l.signUp),
            ),
            social,
            const SizedBox(height: 8),
            const PrivacyPolicyLink(),
          ]),
          ListView(padding: const EdgeInsets.all(16), children: [
            const Center(child: BrandLogo(height: 112)),
            const SizedBox(height: 24),
            TextField(controller: _phone, decoration: InputDecoration(labelText: l.phone), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            if (_verificationId != null) ...[
              TextField(controller: _otp, decoration: InputDecoration(labelText: l.otpCode), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        if (_verificationId == null) {
                          final id = await auth.sendOtp(_phone.text.trim());
                          setState(() => _verificationId = id);
                        } else {
                          await auth.confirmOtp(_verificationId!, _otp.text.trim());
                        }
                      }),
              child: Text(_verificationId == null ? l.sendOtp : l.verify),
            ),
            const SizedBox(height: 8),
            social,
            const SizedBox(height: 8),
            const PrivacyPolicyLink(),
          ]),
        ]),
      ),
    );
  }
}
