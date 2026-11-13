import 'package:material_ui/material_ui.dart';

/// Every colour the app uses. Nothing outside lib/core/theme should create a
/// Color directly: use these constants or the theme.
///
/// Contrast notes (WCAG AA = 4.5:1 for body text, 3:1 for large text/UI):
/// - White on [primary] (#D97706) is 3.19:1, so it fails for text. Filled
///   buttons use [primaryDark] (#B45309, 5.02:1 with white) instead, and
///   [primary] is kept for non-text accents (indicators, switches, progress).
/// - Text in brand colour on white uses [primaryDark] (5.02:1).
/// - On dark surfaces, brand text uses [amber] (#F59E0B, 8.1:1 on [charcoal]).
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFFD97706);
  static const primaryDark = Color(0xFFB45309);
  static const deepest = Color(0xFF78350F);
  static const amber = Color(0xFFF59E0B);
  static const highlight = Color(0xFFFCD34D);
  static const tint = Color(0xFFFEF3C7);

  /// Logo gradient, start → end (follows text direction, so it flips in RTL).
  static const gradient = [highlight, amber, primaryDark];

  // Neutrals
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const lightBackground = Color(0xFFFFFBF5);
  static const ink = Color(0xFF1C1917); // body text in light mode
  static const inkMuted = Color(0xFF57534E);
  static const outlineLight = Color(0xFFE7E5E4);

  // Dark mode surfaces
  static const charcoal = Color(0xFF1C1917);
  static const charcoalRaised = Color(0xFF292524);
  static const charcoalHigh = Color(0xFF3A3532);
  static const onDark = Color(0xFFF5F5F4);
  static const onDarkMuted = Color(0xFFA8A29E);
  static const outlineDark = Color(0xFF44403C);

  // Status: light mode (all ≥ 4.5:1 on white)
  static const successLight = Color(0xFF166534); // cleared / paid / approved
  static const warningLight = Color(0xFF92400E); // pending / due (browner than the brand)
  static const dangerLight = Color(0xFFB91C1C); // bounced / overdue / rejected
  static const neutralLight = Color(0xFF475569); // on hold / unknown / low priority
  static const infoLight = Color(0xFF1D4ED8); // deposited

  // Status: dark mode (all ≥ 4.5:1 on charcoalRaised)
  static const successDark = Color(0xFF4ADE80);
  static const warningDark = Color(0xFFFBBF24);
  static const dangerDark = Color(0xFFF87171);
  static const neutralDark = Color(0xFF94A3B8);
  static const infoDark = Color(0xFF60A5FA);
}
