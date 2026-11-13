import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/auth/ledgix_hub.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/privacy.dart';
import 'auth_errors.dart';
import 'social_sign_in.dart';

/// Which sign-in is running, so only that button shows a spinner.
enum _Busy { ledgix, email, phone, google, apple }

/// Sign-in screen. Wide screens: brand panel + sign-in card. Phones: the card
/// alone. Order: LedGix ID, then email (or phone), then Google and Apple.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _passwordFocus = FocusNode();
  String? _verificationId;
  bool _signUp = false, _phoneMode = false, _obscure = true;
  _Busy? _busy;
  String? _error;

  /// Breakpoint for the two-panel layout.
  static const _wideFrom = 960.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The landing page links to /app/?lang=ar so Arabic visitors stay in Arabic.
      if (kIsWeb) {
        final lang = Uri.base.queryParameters['lang'];
        if (lang == 'ar' || lang == 'en') ref.read(localeProvider.notifier).set(lang!);
      }
      // A LedGix ID web sign-in that failed after returning from the Hub.
      if (LedgixHub.webCallbackError != null) {
        LedgixHub.webCallbackError = null;
        setState(() => _error = context.l.errLedgix);
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_email, _password, _phone, _otp]) {
      c.dispose();
    }
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _run(_Busy which, Future<void> Function() job) async {
    if (_busy != null) return;
    setState(() {
      _busy = which;
      _error = null;
    });
    try {
      await job();
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e, context.l));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _submitEmail() {
    // Demo mode accepts anything, including empty fields.
    if (useFirebase && !(_formKey.currentState?.validate() ?? true)) return;
    final auth = ref.read(authRepositoryProvider);
    final email = _email.text.trim();
    _run(_Busy.email, () {
      TextInput.finishAutofillContext();
      return _signUp ? auth.signUpWithEmail(email, _password.text) : auth.signInWithEmail(email, _password.text);
    });
  }

  void _submitPhone() {
    if (useFirebase && !(_formKey.currentState?.validate() ?? true)) return;
    final auth = ref.read(authRepositoryProvider);
    _run(_Busy.phone, () async {
      if (_verificationId == null) {
        final id = await auth.sendOtp(_phone.text.trim());
        if (mounted) setState(() => _verificationId = id);
      } else {
        await auth.confirmOtp(_verificationId!, _otp.text.trim());
      }
    });
  }

  Future<void> _forgotPassword() async {
    final l = context.l;
    final sent = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(initialEmail: _email.text.trim()),
    );
    if (sent != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.resetLinkSent(sent))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, box) {
        final wide = box.maxWidth >= _wideFrom;
        final card = _SignInCard(
          framed: box.maxWidth >= 520,
          showLogo: !wide,
          child: _form(context),
        );
        final scroller = SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: box.maxWidth < 520 ? 20 : 32, vertical: 32),
              child: card,
            ),
          ),
        );
        if (!wide) return _Backdrop(child: scroller);
        return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Expanded(flex: 5, child: _BrandPanel()),
          Expanded(flex: 6, child: _Backdrop(child: scroller)),
        ]);
      }),
    );
  }

  Widget _form(BuildContext context) {
    final l = context.l;
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    final auth = ref.read(authRepositoryProvider);
    final idle = _busy == null;

    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Text(
          _signUp ? l.signUpTitle : l.loginTitle,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.4),
        ),
        const SizedBox(height: 6),
        Text(l.loginSubtitle, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        if (_error != null) ...[
          _ErrorBanner(message: _error!, onClose: () => setState(() => _error = null)),
          const SizedBox(height: 16),
        ],
        LedgixIdButton(
          busy: _busy == _Busy.ledgix,
          onPressed: idle ? () => _run(_Busy.ledgix, auth.signInWithLedgix) : null,
        ),
        const SizedBox(height: 20),
        _LabeledDivider(_phoneMode ? l.orUsePhone : l.orUseEmail),
        const SizedBox(height: 20),
        if (_phoneMode) ..._phoneFields(l, idle) else ..._emailFields(l, idle),
        const SizedBox(height: 20),
        _LabeledDivider(l.otherOptions),
        const SizedBox(height: 16),
        GoogleSignInButton(
          busy: _busy == _Busy.google,
          onPressed: idle ? () => _run(_Busy.google, auth.signInWithGoogle) : null,
        ),
        if (showAppleSignIn) ...[
          const SizedBox(height: 10),
          AppleSignInButton(
            busy: _busy == _Busy.apple,
            onPressed: idle ? () => _run(_Busy.apple, auth.signInWithApple) : null,
          ),
        ],
        const SizedBox(height: 4),
        TextButton.icon(
          key: const Key('toggle-phone'),
          onPressed: idle
              ? () => setState(() {
                    _phoneMode = !_phoneMode;
                    _error = null;
                  })
              : null,
          icon: Icon(_phoneMode ? Icons.mail_outline : Icons.phone_iphone, size: 18),
          label: Text(_phoneMode ? l.useEmailInstead : l.usePhoneInstead),
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: scheme.outlineVariant),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
          TextButton.icon(
            key: const Key('toggle-language'),
            onPressed: () => ref
                .read(localeProvider.notifier)
                .set(ref.read(localeProvider) == 'en' ? 'ar' : 'en'),
            icon: const Icon(Icons.translate, size: 18),
            label: Text(ref.watch(localeProvider) == 'en' ? l.arabic : l.english),
            style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
          ),
          TextButton(
            onPressed: () => openPrivacyPolicy(context),
            style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
            child: Text(l.privacyPolicy),
          ),
        ]),
      ]),
    );
  }

  List<Widget> _emailFields(AppLocalizations l, bool idle) {
    final text = Theme.of(context).textTheme;
    return [
      AutofillGroup(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            key: const Key('email-field'),
            controller: _email,
            decoration: InputDecoration(labelText: l.email, prefixIcon: const Icon(Icons.mail_outline)),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return l.emailRequired;
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return l.emailInvalid;
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('password-field'),
            controller: _password,
            focusNode: _passwordFocus,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: l.password,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscure ? l.showPassword : l.hidePassword,
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            textInputAction: TextInputAction.done,
            autofillHints: [_signUp ? AutofillHints.newPassword : AutofillHints.password],
            onFieldSubmitted: (_) => _submitEmail(),
            validator: (v) {
              final s = v ?? '';
              if (s.isEmpty) return l.passwordRequired;
              if (_signUp && s.length < 6) return l.passwordTooShort;
              return null;
            },
          ),
        ]),
      ),
      if (!_signUp)
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            key: const Key('forgot-password'),
            onPressed: idle ? _forgotPassword : null,
            child: Text(l.forgotPassword),
          ),
        )
      else
        const SizedBox(height: 16),
      FilledButton(
        key: const Key('email-submit'),
        onPressed: idle ? _submitEmail : null,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        child: _busy == _Busy.email ? const ButtonSpinner(color: Colors.white) : Text(_signUp ? l.signUp : l.signIn),
      ),
      const SizedBox(height: 8),
      Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(_signUp ? l.haveAccount : l.noAccountYet, style: text.bodyMedium),
        TextButton(
          key: const Key('toggle-sign-up'),
          onPressed: idle
              ? () => setState(() {
                    _signUp = !_signUp;
                    _error = null;
                  })
              : null,
          child: Text(_signUp ? l.signIn : l.signUp),
        ),
      ]),
    ];
  }

  List<Widget> _phoneFields(AppLocalizations l, bool idle) => [
        TextFormField(
          key: const Key('phone-field'),
          controller: _phone,
          decoration: InputDecoration(labelText: l.phone, prefixIcon: const Icon(Icons.phone_iphone)),
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          textInputAction: _verificationId == null ? TextInputAction.done : TextInputAction.next,
          onFieldSubmitted: (_) => _verificationId == null ? _submitPhone() : null,
          validator: (v) => (v ?? '').trim().isEmpty ? l.phoneRequired : null,
        ),
        if (_verificationId != null) ...[
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('otp-field'),
            controller: _otp,
            decoration: InputDecoration(labelText: l.otpCode, prefixIcon: const Icon(Icons.pin_outlined)),
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            onFieldSubmitted: (_) => _submitPhone(),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('phone-submit'),
          onPressed: idle ? _submitPhone : null,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: _busy == _Busy.phone
              ? const ButtonSpinner(color: Colors.white)
              : Text(_verificationId == null ? l.sendOtp : l.verify),
        ),
      ];
}

/// Subtle amber wash behind the card (the LedGix "hero/auth" effect in the
/// Rent accent).
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -1.1),
          radius: 1.2,
          colors: [
            (dark ? AppColors.amber : AppColors.highlight).withValues(alpha: dark ? 0.10 : 0.28),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// The card around the form. On phones it's frameless so it uses the whole
/// width; from 520px it gets a surface, hairline border and padding.
class _SignInCard extends StatelessWidget {
  const _SignInCard({required this.child, required this.framed, required this.showLogo});
  final Widget child;
  final bool framed, showLogo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      if (showLogo) ...[
        Row(children: [
          const LogoMark(size: 34),
          const SizedBox(width: 10),
          Text('LedGix Rent', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 28),
      ],
      child,
    ]);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: framed
          ? Container(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: content,
            )
          : content,
    );
  }
}

/// Start-side brand panel on wide screens. Charcoal text stays on the light
/// part of the gradient: #1C1917 on #FCD34D–#D97706 is 5.7:1 or more.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    const ink = AppColors.ink;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.highlight, AppColors.amber, AppColors.primary],
          stops: [0, 0.6, 1],
        ),
      ),
      child: Stack(children: [
        // Large faded mark, decorative only.
        PositionedDirectional(
          end: -80,
          bottom: -60,
          child: ExcludeSemantics(child: Opacity(opacity: 0.16, child: LogoMark(size: 420))),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(56, 48, 56, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(12)),
                  child: const LogoMark(size: 30),
                ),
                const SizedBox(width: 12),
                const Text('LedGix Rent', style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w600)),
              ]),
              const Spacer(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Text(
                  l.brandHeadline,
                  style: const TextStyle(color: ink, fontSize: 40, height: 1.12, fontWeight: FontWeight.w600, letterSpacing: -1.2),
                ),
              ),
              const SizedBox(height: 32),
              for (final b in [l.brandBullet1, l.brandBullet2, l.brandBullet3])
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), shape: BoxShape.circle),
                      child: const Icon(Icons.check, size: 17, color: AppColors.deepest),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(b, style: const TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w500, height: 1.35)),
                    ),
                  ]),
                ),
              const Spacer(),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                  child: Image.asset('assets/ledgix-id-mark.png', width: 16, height: 16, excludeFromSemantics: true),
                ),
                const SizedBox(width: 8),
                Text(l.partOfLedgix, style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _LabeledDivider extends StatelessWidget {
  const _LabeledDivider(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Expanded(child: Divider(color: scheme.outlineVariant)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      ),
      Expanded(child: Divider(color: scheme.outlineVariant)),
    ]);
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onClose});
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('login-error'),
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 4, 10),
        decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline, size: 20, color: scheme.onErrorContainer),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(message, style: TextStyle(color: scheme.onErrorContainer, height: 1.4)),
            ),
          ),
          IconButton(
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 18, color: scheme.onErrorContainer),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ]),
      ),
    );
  }
}

/// Asks for the email and sends a reset link. Pops with the email on success.
class _ResetPasswordDialog extends ConsumerStatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});
  final String initialEmail;

  @override
  ConsumerState<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<_ResetPasswordDialog> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _key = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_key.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final email = _email.text.trim();
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (mounted) Navigator.of(context).pop(email);
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e, context.l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AlertDialog(
      key: const Key('reset-password-dialog'),
      title: Text(l.resetPasswordTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _key,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.resetPasswordBody),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('reset-email-field'),
              controller: _email,
              autofocus: widget.initialEmail.isEmpty,
              decoration: InputDecoration(labelText: l.email, prefixIcon: const Icon(Icons.mail_outline), errorText: _error),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _send(),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return l.emailRequired;
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return l.emailInvalid;
                return null;
              },
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l.cancel)),
        FilledButton(
          key: const Key('send-reset-link'),
          onPressed: _busy ? null : _send,
          child: _busy ? const ButtonSpinner(color: Colors.white) : Text(l.sendResetLink),
        ),
      ],
    );
  }
}
