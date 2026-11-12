import 'package:material_ui/material_ui.dart';

import '../../features/payments/domain/payment.dart';

class AppTheme {
  static const brand = Color(0xFF0F5C4D);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: brand),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      );

  static Color statusColor(PaymentStatus s) => switch (s) {
        PaymentStatus.pending => const Color(0xFF9A6700),
        PaymentStatus.deposited => const Color(0xFF0969DA),
        PaymentStatus.cleared => const Color(0xFF1A7F37),
        PaymentStatus.bounced => const Color(0xFFCF222E),
        PaymentStatus.onHold => const Color(0xFF6E40C9),
      };
}
