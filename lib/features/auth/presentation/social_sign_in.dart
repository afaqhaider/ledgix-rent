import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/common.dart';

/// Continue with LedGix ID, then an "or" divider and Continue with Google /
/// Apple. Apple shows on iOS, macOS and web only (on Android it would need a
/// web redirect flow).
class SocialSignInButtons extends StatelessWidget {
  const SocialSignInButtons({super.key, required this.onLedgix, required this.onGoogle, required this.onApple});

  /// Null while busy, which disables the buttons.
  final VoidCallback? onLedgix, onGoogle, onApple;

  /// LedGix ID brand blue. White text on it is 6.4:1.
  static const ledgixBlue = Color(0xFF0050E6);

  static bool get showApple =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 8),
      FilledButton.icon(
        key: const Key('ledgix-sign-in'),
        onPressed: onLedgix,
        icon: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
          child: Image.asset('assets/ledgix-id-mark.png', width: 20, height: 20, excludeFromSemantics: true),
        ),
        label: Text(l.continueWithLedgix),
        style: FilledButton.styleFrom(backgroundColor: ledgixBlue, foregroundColor: Colors.white),
      ),
      const SizedBox(height: 8),
      Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(l.orDivider, style: Theme.of(context).textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ]),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const Key('google-sign-in'),
        onPressed: onGoogle,
        icon: const _GoogleMark(size: 18),
        label: Text(l.continueWithGoogle),
        style: OutlinedButton.styleFrom(
          // Google's guidelines: neutral button, not brand-coloured.
          foregroundColor: dark ? Colors.white : const Color(0xFF1F1F1F),
          backgroundColor: dark ? const Color(0xFF131314) : Colors.white,
          side: BorderSide(color: dark ? const Color(0xFF8E918F) : const Color(0xFF747775)),
        ),
      ),
      if (showApple) ...[
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('apple-sign-in'),
          onPressed: onApple,
          icon: const Icon(Icons.apple, size: 22),
          label: Text(l.continueWithApple),
          // Apple's guidelines: black button (white on dark backgrounds).
          style: FilledButton.styleFrom(
            backgroundColor: dark ? Colors.white : Colors.black,
            foregroundColor: dark ? Colors.black : Colors.white,
          ),
        ),
      ],
    ]);
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
