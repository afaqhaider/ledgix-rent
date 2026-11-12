import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/feature_flags.dart';
import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../domain/maintenance_ticket.dart';

String priorityLabel(AppLocalizations l, TicketPriority p) => switch (p) {
      TicketPriority.low => l.low,
      TicketPriority.medium => l.normal,
      TicketPriority.high => l.high,
      TicketPriority.urgent => l.emergency,
    };

String ticketStatusLabel(AppLocalizations l, TicketStatus s) => switch (s) {
      TicketStatus.open => l.ticketOpen,
      TicketStatus.requested => l.ticketRequested,
      TicketStatus.quoted => l.ticketQuoted,
      TicketStatus.approved => l.ticketApproved,
      TicketStatus.scheduled => l.ticketScheduled,
      TicketStatus.inProgress => l.ticketInProgress,
      TicketStatus.completed => l.ticketCompleted,
      TicketStatus.closed => l.ticketClosed,
    };

String categoryLabel(AppLocalizations l, TicketCategory c) => switch (c) {
      TicketCategory.ac => l.catAc,
      TicketCategory.plumbing => l.catPlumbing,
      TicketCategory.electrical => l.catElectrical,
      TicketCategory.appliances => l.catAppliances,
      TicketCategory.pestControl => l.catPestControl,
      TicketCategory.painting => l.catPainting,
      TicketCategory.other => l.other,
    };

String formatDateTime(DateTime d) =>
    '${formatDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final props = {for (final p in ref.watch(propertiesProvider).value ?? []) p.id: p.name};
    return Scaffold(
      appBar: AppBar(title: Text(l.maintenance)),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => context.push('/tickets/new'),
        icon: const Icon(Icons.add),
        label: Text(l.newTicket),
      ),
      body: AsyncList<MaintenanceTicket>(
        items: ref.watch(ticketsProvider),
        builder: (c, t) => Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(t.title, style: Theme.of(c).textTheme.titleMedium),
            // Chips sit under the subtitle (not in `trailing`) so large system
            // font sizes don't overflow the tile height.
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text([props[t.propertyId] ?? '', categoryLabel(l, t.category), if (t.cost > 0) formatAed(t.cost)]
                  .where((s) => s.isNotEmpty)
                  .join(' · ')),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                StatusChip(ticketStatusLabel(l, t.status), Theme.of(c).colorScheme.primary),
                StatusChip(priorityLabel(l, t.priority), t.priority.index >= 2 ? Colors.red : Colors.blueGrey),
              ]),
            ]),
            onTap: () => c.push('/tickets/${t.id}'),
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
  final _title = TextEditingController(), _desc = TextEditingController(), _access = TextEditingController();
  String? _property;
  TicketPriority _priority = TicketPriority.medium;
  TicketCategory _category = TicketCategory.other;
  bool _visit = false;
  final _slots = <DateTime>[];
  final _photos = <String>[], _videos = <String>[];

  Future<void> _addSlot() async {
    final d = await pickDate(context, todayGst());
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
    if (t == null) return;
    setState(() => _slots.add(DateTime(d.year, d.month, d.day, t.hour, t.minute)));
  }

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
              category: _category,
              visitRequired: _visit,
              timeSlots: _visit ? _slots : const [],
              accessNotes: _visit ? _access.text.trim() : '',
              photos: _photos,
              videos: _videos,
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
        DropdownButtonFormField<TicketCategory>(
          initialValue: _category,
          decoration: InputDecoration(labelText: l.category),
          items: [for (final c in TicketCategory.values) DropdownMenuItem(value: c, child: Text(categoryLabel(l, c)))],
          onChanged: (v) => _category = v ?? _category,
        ),
        TextFormField(controller: _desc, decoration: InputDecoration(labelText: l.description), maxLines: 3),
        DropdownButtonFormField<TicketPriority>(
          initialValue: _priority,
          decoration: InputDecoration(labelText: l.urgency),
          items: [for (final p in TicketPriority.values.reversed) DropdownMenuItem(value: p, child: Text(priorityLabel(l, p)))],
          onChanged: (v) => _priority = v ?? _priority,
        ),
        SwitchListTile(title: Text(l.visitRequired), value: _visit, onChanged: (v) => setState(() => _visit = v)),
        if (_visit) ...[
          Wrap(spacing: 8, children: [
            for (final s in _slots)
              InputChip(label: Text(formatDateTime(s)), onDeleted: () => setState(() => _slots.remove(s))),
            if (_slots.length < 3) ActionChip(avatar: const Icon(Icons.add), label: Text(l.addTimeSlot), onPressed: _addSlot),
          ]),
          TextFormField(controller: _access, decoration: InputDecoration(labelText: l.accessNotes), maxLines: 2),
        ],
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
        OutlinedButton.icon(
          icon: const Icon(Icons.videocam_outlined),
          label: Text('${l.addVideo} (${_videos.length})'),
          onPressed: () async {
            final f = await ImagePicker().pickVideo(source: ImageSource.gallery);
            if (f == null) return;
            final url = await ref.read(fileStorageProvider).upload('tickets/${newId()}_${f.name}', f.path);
            setState(() => _videos.add(url));
          },
        ),
        if (!FeatureFlags.maintenanceForwarding) const SizedBox.shrink(),
      ],
    );
  }
}
