import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../leases/domain/lease.dart';
import '../domain/inspection.dart';
import 'inspection_actions.dart';
import 'inspection_ui.dart';

/// All inspections, newest first, with a "New inspection" action.
class InspectionsScreen extends ConsumerWidget {
  const InspectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final props = {for (final p in ref.watch(propertiesProvider).value ?? []) p.id: p.name};
    final tenants = {for (final t in ref.watch(tenantsProvider).value ?? []) t.id: t.name};
    final items = ref.watch(inspectionsProvider).whenData((l) => [...l]..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    return Scaffold(
      appBar: ShellAppBar(title: Text(l.inspections)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new-inspection'),
        heroTag: null,
        onPressed: () => newInspectionDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.newInspection),
      ),
      body: items.value?.isEmpty ?? false
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.noInspectionsYet, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              ),
            )
          : AsyncList<Inspection>(
              items: items,
              builder: (c, i) => InspectionTile(
                inspection: i,
                title: '${props[i.propertyId] ?? '-'} · ${tenants[i.tenantId] ?? '-'}',
              ),
            ),
    );
  }
}

class InspectionTile extends StatelessWidget {
  const InspectionTile({super.key, required this.inspection, required this.title});
  final Inspection inspection;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final i = inspection;
    return Card(
      child: ListTile(
        key: Key('inspection-${i.id}'),
        leading: CircleAvatar(child: Icon(typeIcon(i.type))),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${typeLabel(l, i.type)} · ${formatDate(i.createdAt)}\n${l.itemsRated(i.ratedCount, i.itemCount)}'),
        isThreeLine: true,
        trailing: StatusChip(statusLabel(l, i.status), statusColorOf(context, i.status), icon: statusIconOf(i.status)),
        onTap: () => context.push('/inspections/${i.id}'),
      ),
    );
  }
}

/// Pick a rent agreement and Move-in / Move-out, then start.
Future<void> newInspectionDialog(BuildContext context, WidgetRef ref) async {
  final l = context.l;
  final leases = ref.read(leasesProvider).value ?? const <Lease>[];
  if (leases.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.noAgreementsForInspection)));
    return;
  }
  final props = {for (final p in ref.read(propertiesProvider).value ?? []) p.id: p.name};
  final tenants = {for (final t in ref.read(tenantsProvider).value ?? []) t.id: t.name};
  var lease = leases.first;
  var type = InspectionType.moveIn;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => AlertDialog(
        title: Text(l.newInspection),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DropdownButtonFormField<Lease>(
              key: const Key('inspection-lease'),
              initialValue: lease,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.rentAgreementLabel),
              items: [
                for (final le in leases)
                  DropdownMenuItem(
                    value: le,
                    child: Text('${props[le.propertyId] ?? '-'} · ${tenants[le.tenantId] ?? '-'}', overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => set(() => lease = v ?? lease),
            ),
            const SizedBox(height: 16),
            SegmentedButton<InspectionType>(
              segments: [
                ButtonSegment(value: InspectionType.moveIn, icon: const Icon(Icons.login), label: Text(l.atMoveIn)),
                ButtonSegment(value: InspectionType.moveOut, icon: const Icon(Icons.logout), label: Text(l.atMoveOut)),
              ],
              selected: {type},
              onSelectionChanged: (s) => set(() => type = s.first),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(key: const Key('new-inspection-next'), onPressed: () => Navigator.pop(c, true), child: Text(l.continueLabel)),
        ],
      ),
    ),
  );
  if (ok == true && context.mounted) await startInspection(context, ref, lease, type);
}

/// Inspections section on a saved rent agreement: start move-in / move-out
/// and open existing ones.
class LeaseInspectionsSection extends ConsumerWidget {
  const LeaseInspectionsSection({super.key, required this.lease});
  final Lease lease;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final mine = (ref.watch(inspectionsProvider).value ?? const <Inspection>[]).where((i) => i.leaseId == lease.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(
          key: const Key('lease-move-in'),
          onPressed: () => startInspection(context, ref, lease, InspectionType.moveIn),
          icon: const Icon(Icons.login),
          label: Text(l.moveInInspection),
        ),
        OutlinedButton.icon(
          key: const Key('lease-move-out'),
          onPressed: () => startInspection(context, ref, lease, InspectionType.moveOut),
          icon: const Icon(Icons.logout),
          label: Text(l.moveOutInspection),
        ),
      ]),
      for (final i in mine)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(typeIcon(i.type)),
          title: Text(typeLabel(l, i.type)),
          subtitle: Text('${formatDate(i.createdAt)} · ${l.itemsRated(i.ratedCount, i.itemCount)}'),
          trailing: StatusChip(statusLabel(l, i.status), statusColorOf(context, i.status), icon: statusIconOf(i.status)),
          onTap: () => context.push('/inspections/${i.id}'),
        ),
    ]);
  }
}
