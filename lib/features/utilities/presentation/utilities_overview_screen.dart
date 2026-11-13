import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/utility_bill.dart';

/// Utility bills across the portfolio: one row per property, linking to its bills.
class UtilitiesOverviewScreen extends ConsumerWidget {
  const UtilitiesOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final properties = ref.watch(propertiesProvider);
    final bills = ref.watch(utilityBillsProvider).value ?? const <UtilityBill>[];
    return Scaffold(
      appBar: ShellAppBar(title: Text(l.utilityBills)),
      body: AsyncList(
        items: properties,
        builder: (c, p) {
          final unpaid = bills.where((b) => b.propertyId == p.id && b.status != BillStatus.paid).length;
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: const Icon(Icons.bolt_outlined),
              title: Text(p.name),
              subtitle: Text(l.unpaidBills(unpaid)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (unpaid > 0) StatusChip('$unpaid', c.status.warning, icon: Icons.schedule),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ]),
              onTap: () => c.push('/property/${p.id}/bills'),
            ),
          );
        },
      ),
    );
  }
}
