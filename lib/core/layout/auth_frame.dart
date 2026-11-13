import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';

/// Frame for the signed-out pages (login, onboarding). On wide screens the
/// page sits in a 480 px column beside an amber brand panel; on phones it is
/// the page alone.
class AuthFrame extends StatelessWidget {
  const AuthFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return child;
    final column = ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: child)),
    );
    if (width < 1000) return column;
    return Row(children: [
      const Expanded(flex: 5, child: _BrandPanel()),
      Expanded(flex: 6, child: column),
    ]);
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = context.l;
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.gradient),
      padding: const EdgeInsets.all(56),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
            child: const LogoMark(size: 36),
          ),
          const SizedBox(width: 14),
          Text('LedGix Rent', style: text.titleLarge?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800)),
        ]),
        const Spacer(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.authTagline,
                style: text.displaySmall?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800, height: 1.15)),
            const SizedBox(height: 16),
            Text(l.authSubtagline, style: text.titleMedium?.copyWith(color: AppColors.ink, height: 1.4)),
          ]),
        ),
        const Spacer(flex: 2),
      ]),
    );
  }
}
