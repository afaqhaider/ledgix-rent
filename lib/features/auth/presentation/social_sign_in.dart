import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/common.dart';

/// Apple sign-in shows on iOS, macOS and web only (on Android it would need a
/// web redirect flow).
bool get showAppleSignIn =>
    kIsWeb || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

/// Small spinner that replaces a button's icon while that action runs.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: color ?? IconTheme.of(context).color),
      );
}

/// Primary option: Continue with LedGix ID (one account for every LedGix app).
class LedgixIdButton extends StatelessWidget {
  const LedgixIdButton({super.key, required this.onPressed, this.busy = false});

  /// Null while any sign-in runs, which disables the button.
  final VoidCallback? onPressed;
  final bool busy;

  /// LedGix ID brand blue. White text on it is 6.4:1.
  static const ledgixBlue = Color(0xFF0050E6);

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        key: const Key('ledgix-sign-in'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: ledgixBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ledgixBlue.withValues(alpha: busy ? 1 : 0.45),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        icon: busy
            ? const ButtonSpinner(color: Colors.white)
            : Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                child: Image.asset('assets/ledgix-id-mark.png', width: 18, height: 18, excludeFromSemantics: true),
              ),
        label: Text(context.l.continueWithLedgix),
      );
}

/// Neutral outlined button, per Google's branding guidelines.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed, this.busy = false});
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      key: const Key('google-sign-in'),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: dark ? Colors.white : const Color(0xFF1F1F1F),
        backgroundColor: dark ? const Color(0xFF131314) : Colors.white,
        side: BorderSide(color: dark ? const Color(0xFF8E918F) : const Color(0xFF747775)),
        minimumSize: const Size.fromHeight(46),
      ),
      icon: busy ? const ButtonSpinner() : const _GoogleMark(size: 18),
      label: Text(context.l.continueWithGoogle),
    );
  }
}

/// Apple's "white with outline" style on light backgrounds and the black
/// style on dark ones (both allowed by Apple's Human Interface Guidelines).
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({super.key, required this.onPressed, this.busy = false});
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      key: const Key('apple-sign-in'),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: dark ? Colors.white : Colors.black,
        backgroundColor: dark ? Colors.black : Colors.white,
        side: BorderSide(color: dark ? const Color(0xFF8E918F) : Colors.black),
        minimumSize: const Size.fromHeight(46),
      ),
      icon: busy ? const ButtonSpinner() : const Icon(Icons.apple, size: 22),
      label: Text(context.l.continueWithApple),
    );
  }
}

/// The four-colour Google "G", drawn so no image asset is needed.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: size, child: CustomPaint(painter: _GooglePainter()));
}

class _GooglePainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4), _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05), _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final rect = Rect.fromCircle(center: Offset(s / 2, s / 2), radius: (s - stroke) / 2);
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double deg(double d) => d * math.pi / 180;
    // Angles clockwise from 3 o'clock.
    canvas.drawArc(rect, deg(-40), deg(-95), false, arc(_red)); // top
    canvas.drawArc(rect, deg(-135), deg(-90), false, arc(_yellow)); // left
    canvas.drawArc(rect, deg(135), deg(-100), false, arc(_green)); // bottom
    canvas.drawArc(rect, deg(35), deg(-35), false, arc(_blue)); // lower right
    // Crossbar.
    canvas.drawRect(Rect.fromLTWH(s / 2, s / 2 - stroke / 2, s / 2, stroke), Paint()..color = _blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
