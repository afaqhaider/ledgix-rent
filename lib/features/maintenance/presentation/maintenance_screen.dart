import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../domain/maintenance_ticket.dart';

String priorityLabel(AppLocalizations l, TicketPriority p) =>
    switch (p) { TicketPriority.low => l.low, TicketPriority.medium => l.medium, TicketPriority.high => l.high, TicketPriority.urgent => l.urgent };

String ticketStatusLabel(AppLocalizations l, TicketStatus s) =>
    switch (s) { TicketStatus.open => l.ticketOpen, TicketStatus.inProgress => l.ticketInProgress, TicketStatus.resolved => l.ticketResolved };

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final props = {for (final p in ref.watch(propertiesProvider).value ?? []) p.id: p.name};
    final vendors = ref.watch(vendorsProvider).value ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(l.maintenance)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tickets/new'),
        icon: const Icon(Icons.add),
        label: Text(l.newTicket),
      ),
      body: AsyncList<MaintenanceTicket>(
        items: ref.watch(ticketsProvider),
        builder: (c, t) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(t.title, style: Theme.of(c).textTheme.titleMedium)),
                StatusChip(priorityLabel(l, t.priority), t.priority.index >= 2 ? Colors.red : Colors.blueGrey),
              ]),
              Text(props[t.propertyId] ?? ''),
              if (t.description.isNotEmpty) Text(t.description),
              if (t.photos.isNotEmpty) Text('📎 ${t.photos.length}'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                DropdownButton<TicketStatus>(
                  value: t.status,
                  items: [for (final s in TicketStatus.values) DropdownMenuItem(value: s, child: Text(ticketStatusLabel(l, s)))],
                  onChanged: (s) => ref.read(maintenanceRepositoryProvider).save(t.copyWith(status: s)),
                ),
                DropdownButton<String>(
                  value: vendors.any((v) => v.id == t.vendorId) ? t.vendorId : null,
                  hint: Text(l.vendor),
                  items: [for (final v in vendors) DropdownMenuItem(value: v.id, child: Text(v.name))],
                  onChanged: (v) => ref.read(maintenanceRepositoryProvider).save(t.copyWith(vendorId: v)),
                ),
                ActionChip(
                  label: Text(t.cost == 0 ? l.cost : formatAed(t.cost)),
                  onPressed: () async {
                    final ctl = TextEditingController(text: t.cost == 0 ? '' : '${t.cost}');
                    final ok = await showDialog<bool>(
                      context: c,
                      builder: (d) => AlertDialog(
                        title: Text(l.cost),
                        content: TextField(controller: ctl, keyboardType: TextInputType.number),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
                          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l.save)),
                        ],
                      ),
                    );
                    final v = double.tryParse(ctl.text);
                    if (ok == true && v != null) await ref.read(maintenanceRepositoryProvider).save(t.copyWith(cost: v));
                  },
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class TicketFormScreen extends ConsumerStatefulWidget {
  const TicketFormScreen({super.key});
  @override
  ConsumerState<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends ConsumerState<TicketFormScreen> {
  final _key = GlobalKey<FormState>();
  final _title = TextEditingController(), _desc = TextEditingController();
  String? _property;
  TicketPriority _priority = TicketPriority.medium;
  final _photos = <String>[];

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final props = ref.watch(propertiesProvider).value ?? [];
    return FormScaffold(
      title: l.newTicket,
      formKey: _key,
      onSave: () async {
        if (!_key.currentState!.validate()) return;
        await ref.read(maintenanceRepositoryProvider).save(MaintenanceTicket(
              id: newId(),
              propertyId: _property!,
              title: _title.text.trim(),
              description: _desc.text.trim(),
              priority: _priority,
              photos: _photos,
            ));
        if (context.mounted) context.pop();
      },
      children: [
        DropdownButtonFormField<String>(
          initialValue: _property,
          decoration: InputDecoration(labelText: l.property),
          items: [for (final p in props) DropdownMenuItem(value: p.id, child: Text(p.name))],
          validator: (v) => v == null ? l.required : null,
          onChanged: (v) => _property = v,
        ),
        TextFormField(controller: _title, decoration: InputDecoration(labelText: l.title), validator: (v) => requiredValidator(context, v)),
        TextFormField(controller: _desc, decoration: InputDecoration(labelText: l.description), maxLines: 3),
        DropdownButtonFormField<TicketPriority>(
          initialValue: _priority,
          decoration: InputDecoration(labelText: l.priority),
          items: [for (final p in TicketPriority.values) DropdownMenuItem(value: p, child: Text(priorityLabel(l, p)))],
          onChanged: (v) => _priority = v ?? _priority,
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text('${l.addPhoto} (${_photos.length})'),
          onPressed: () async {
            final f = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (f == null) return;
            final url = await ref.read(fileStorageProvider).upload('tickets/${newId()}_${f.name}', f.path);
            setState(() => _photos.add(url));
          },
        ),
      ],
    );
  }
}
