import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/common.dart';
import '../../payments/presentation/payments_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final s = ref.watch(dashboardProvider);
    final status = context.status;
    return Scaffold(
      appBar: AppBar(title: BrandTitle(l.dashboard)),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        _Header(label: l.collectedMonth, value: formatAed(s.collectedMonth)),
        const SizedBox(height: 8),
        IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SummaryTile(label: l.outstandingMonth, value: formatAed(s.outstandingMonth), color: status.warning, icon: Icons.schedule),
          _SummaryTile(label: l.collectedYear, value: formatAed(s.collectedYear), color: status.success, icon: Icons.check_circle_outline),
        ])),
        IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SummaryTile(label: l.outstandingYear, value: formatAed(s.outstandingYear), color: status.warning, icon: Icons.schedule),
          _SummaryTile(label: l.openTickets, value: '${s.openTickets}', color: status.neutral, icon: Icons.build_circle_outlined),
        ])),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text(l.upcomingCheques, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (s.upcoming.isEmpty) const SizedBox(height: 120, child: EmptyState()),
        for (final p in s.upcoming) PaymentCard(payment: p),
      ]),
    );
  }
}

/// Amber gradient hero with this month's collections. Text stays on the light
/// start side of the gradient (charcoal on #FCD34D–#F59E0B is 8:1 or more);
/// the darker end only carries the decorative logo mark.
class _Header extends StatelessWidget {
  const _Header({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: text.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(value, style: text.headlineMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const LogoMark(size: 44),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Summary card with a thin brand-gradient strip along the top.
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, required this.color, required this.icon});
  final String label, value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(height: 4, decoration: const BoxDecoration(gradient: AppTheme.gradient)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(label, style: text.bodySmall)),
              ]),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(value, style: text.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
