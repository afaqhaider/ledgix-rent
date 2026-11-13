import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../properties/presentation/portfolio_screen.dart' show ServiceChargeCard;

/// Mollak service charges for every jointly owned property.
class ServiceChargesScreen extends ConsumerWidget {
  const ServiceChargesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final props = ref.watch(propertiesProvider).value;
    final joint = (props ?? const []).where((p) => p.isJointlyOwned).toList();
    return Scaffold(
      appBar: ShellAppBar(title: Text(l.serviceCharges)),
      body: props == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(12), children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                child: Text(l.serviceChargesHint, style: Theme.of(context).textTheme.bodyMedium),
              ),
              if (joint.isEmpty) const SizedBox(height: 160, child: EmptyState()),
              for (final p in joint)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                      child: Text(p.name, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ServiceChargeCard(property: p),
                  ]),
                ),
            ]),
    );
  }
}
