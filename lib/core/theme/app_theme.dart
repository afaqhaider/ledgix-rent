import 'package:material_ui/material_ui.dart';

import '../../features/payments/domain/payment.dart';
import 'app_colors.dart';

/// Semantic status colours, kept apart from the brand so "pending" never
/// reads as "brand". Read with `context.status`.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.neutral,
    required this.info,
  });

  final Color success, warning, danger, neutral, info;

  static const light = StatusColors(
    success: AppColors.successLight,
    warning: AppColors.warningLight,
    danger: AppColors.dangerLight,
    neutral: AppColors.neutralLight,
    info: AppColors.infoLight,
  );

  static const dark = StatusColors(
    success: AppColors.successDark,
    warning: AppColors.warningDark,
    danger: AppColors.dangerDark,
    neutral: AppColors.neutralDark,
    info: AppColors.infoDark,
  );

  @override
  StatusColors copyWith({Color? success, Color? warning, Color? danger, Color? neutral, Color? info}) =>
      StatusColors(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        neutral: neutral ?? this.neutral,
        info: info ?? this.info,
      );

  @override
  StatusColors lerp(StatusColors? other, double t) => other == null
      ? this
      : StatusColors(
          success: Color.lerp(success, other.success, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
          danger: Color.lerp(danger, other.danger, t)!,
          neutral: Color.lerp(neutral, other.neutral, t)!,
          info: Color.lerp(info, other.info, t)!,
        );
}

extension StatusColorsX on BuildContext {
  StatusColors get status => Theme.of(this).extension<StatusColors>() ?? StatusColors.light;
}

class AppTheme {
  /// Amber gradient (start → end). Directional, so it mirrors in Arabic.
  static const gradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: AppColors.gradient,
  );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      // Text-bearing brand colour must pass AA on white, so primary is the dark amber.
      primary: AppColors.primaryDark,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.tint,
      onPrimaryContainer: AppColors.deepest,
      secondary: AppColors.primary,
      onSecondary: AppColors.ink,
      secondaryContainer: AppColors.tint,
      onSecondaryContainer: AppColors.deepest,
      tertiary: AppColors.amber,
      onTertiary: AppColors.ink,
      surface: AppColors.lightBackground,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      surfaceTint: AppColors.primary,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: AppColors.white,
      surfaceContainer: AppColors.white,
      surfaceContainerHigh: AppColors.tint,
      surfaceContainerHighest: AppColors.tint,
      outline: AppColors.inkMuted,
      outlineVariant: AppColors.outlineLight,
    );
    return _build(
      scheme: scheme,
      status: StatusColors.light,
      accent: AppColors.primary,
      textAccent: AppColors.primaryDark,
      navIndicator: AppColors.tint,
      navSelected: AppColors.deepest,
      cardBorder: AppColors.outlineLight,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark).copyWith(
      // On charcoal the lighter amber is the readable one (8.1:1).
      primary: AppColors.amber,
      onPrimary: AppColors.charcoal,
      primaryContainer: AppColors.deepest,
      onPrimaryContainer: AppColors.highlight,
      secondary: AppColors.amber,
      onSecondary: AppColors.charcoal,
      secondaryContainer: AppColors.deepest,
      onSecondaryContainer: AppColors.highlight,
      tertiary: AppColors.highlight,
      onTertiary: AppColors.charcoal,
      surface: AppColors.charcoal,
      onSurface: AppColors.onDark,
      onSurfaceVariant: AppColors.onDarkMuted,
      surfaceTint: AppColors.amber,
      surfaceContainerLowest: AppColors.charcoal,
      surfaceContainerLow: AppColors.charcoalRaised,
      surfaceContainer: AppColors.charcoalRaised,
      surfaceContainerHigh: AppColors.charcoalRaised,
      surfaceContainerHighest: AppColors.charcoalHigh,
      outline: AppColors.onDarkMuted,
      outlineVariant: AppColors.outlineDark,
    );
    return _build(
      scheme: scheme,
      status: StatusColors.dark,
      accent: AppColors.amber,
      textAccent: AppColors.amber,
      navIndicator: AppColors.deepest,
      navSelected: AppColors.highlight,
      cardBorder: AppColors.outlineDark,
    );
  }

  /// [accent] is for non-text UI (indicators, switches, progress: 3:1 is enough).
  /// [textAccent] is for brand-coloured text (must reach 4.5:1).
  static ThemeData _build({
    required ColorScheme scheme,
    required StatusColors status,
    required Color accent,
    required Color textAccent,
    required Color navIndicator,
    required Color navSelected,
    required Color cardBorder,
  }) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final selected = WidgetStateProperty.resolveWith<Color?>(
      (s) => s.contains(WidgetState.selected) ? accent : null,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [status],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorder),
        ),
      ),
      // Filled: dark amber + white in both themes (5.02:1). #D97706 + white fails AA.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.white,
          shape: shape,
          minimumSize: const Size(64, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textAccent,
          side: BorderSide(color: textAccent),
          shape: shape,
          minimumSize: const Size(64, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: textAccent)),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (s) => TextStyle(color: s.contains(WidgetState.error) ? scheme.error : textAccent),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionHandleColor: accent,
        selectionColor: accent.withValues(alpha: 0.3),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: cardBorder),
        labelStyle: TextStyle(color: scheme.onSurface),
        iconTheme: IconThemeData(color: textAccent, size: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.white : null),
        trackColor: selected,
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? accent : null),
      ),
      checkboxTheme: CheckboxThemeData(fillColor: selected),
      radioTheme: RadioThemeData(fillColor: selected),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: navIndicator,
        circularTrackColor: Colors.transparent,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: accent,
        labelColor: textAccent,
        unselectedLabelColor: scheme.onSurfaceVariant,
        dividerColor: cardBorder,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: navIndicator,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? navSelected : scheme.onSurfaceVariant),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? navSelected : scheme.onSurfaceVariant,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: textAccent,
        unselectedItemColor: scheme.onSurfaceVariant,
      ),
      listTileTheme: ListTileThemeData(iconColor: textAccent),
      dividerTheme: DividerThemeData(color: cardBorder),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  static Color statusColor(BuildContext context, PaymentStatus s) {
    final c = context.status;
    return switch (s) {
      PaymentStatus.pending => c.warning,
      PaymentStatus.deposited => c.info,
      PaymentStatus.cleared => c.success,
      PaymentStatus.bounced => c.danger,
      PaymentStatus.onHold => c.neutral,
    };
  }

  /// Icon per payment status, so status never relies on colour alone.
  static IconData statusIcon(PaymentStatus s) => switch (s) {
        PaymentStatus.pending => Icons.schedule,
        PaymentStatus.deposited => Icons.account_balance_outlined,
        PaymentStatus.cleared => Icons.check_circle_outline,
        PaymentStatus.bounced => Icons.error_outline,
        PaymentStatus.onHold => Icons.pause_circle_outline,
      };
}
