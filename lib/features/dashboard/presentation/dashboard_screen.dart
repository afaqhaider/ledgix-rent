import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../payments/presentation/payments_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final s = ref.watch(dashboardProvider);
    Widget tile(String label, String value, Color color) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        );
    const green = Color(0xFF1A7F37), amber = Color(0xFF9A6700);
    return Scaffold(
      appBar: AppBar(title: Text(l.dashboard)),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Row(children: [tile(l.collectedMonth, formatAed(s.collectedMonth), green), tile(l.outstandingMonth, formatAed(s.outstandingMonth), amber)]),
        Row(children: [tile(l.collectedYear, formatAed(s.collectedYear), green), tile(l.outstandingYear, formatAed(s.outstandingYear), amber)]),
        Card(
          child: ListTile(
            leading: const Icon(Icons.build_circle_outlined),
            title: Text(l.openTickets),
            trailing: Text('${s.openTickets}', style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
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
