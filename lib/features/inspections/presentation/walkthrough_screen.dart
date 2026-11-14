import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/domain/entity.dart';
import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../data/inspection_providers.dart';
import '../domain/comparison.dart';
import '../domain/inspection.dart';
import '../domain/templates.dart';
import 'inspection_actions.dart';
import 'inspection_editor.dart';
import 'inspection_ui.dart';
import 'inspection_view.dart';

/// `/inspections/:id`: the walkthrough while it's a draft, the read-only
/// report once it has been sent or completed.
class InspectionScreen extends ConsumerWidget {
  const InspectionScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(inspectionsProvider);
    final insp = all.value?.where((i) => i.id == id).firstOrNull;
    if (insp == null) {
      return Scaffold(
        appBar: ShellAppBar(title: Text(context.l.inspections)),
        body: all.isLoading ? const Center(child: CircularProgressIndicator()) : const EmptyState(),
      );
    }
    if (insp.isEditable) return WalkthroughScreen(key: ValueKey(insp.id), initial: insp);
    return _InspectionReportScreen(insp: insp);
  }
}

class _InspectionReportScreen extends ConsumerWidget {
  const _InspectionReportScreen({required this.insp});
  final Inspection insp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final moveIn = insp.isMoveOut
        ? moveInFor(ref.watch(inspectionsProvider).value ?? const [], insp.leaseId, preferId: insp.moveInId)
        : null;
    return Scaffold(
      appBar: ShellAppBar(title: Text(typeLabel(l, insp.type)), actions: [_DeleteButton(insp: insp)]),
      body: InspectionView(
        data: insp.toMap(),
        tenantMode: false,
        moveInData: moveIn?.toMap(),
        info: reportInfoFor(ref, insp),
        footer: insp.status == InspectionStatus.awaitingTenant
            ? Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(l.markCompletedHint, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('mark-completed'),
                      onPressed: () => markCompletedWithNote(context, ref, insp),
                      icon: const Icon(Icons.task_alt),
                      label: Text(l.markCompleted),
                    ),
                  ]),
                ),
              )
            : null,
      ),
    );
  }
}

Future<void> markCompletedWithNote(BuildContext context, WidgetRef ref, Inspection insp) async {
  final note = await askCompletionNote(context);
  if (note == null) return;
  await completeInspection(ref.read(inspectionRepositoryProvider), insp, note);
}

Future<String?> askCompletionNote(BuildContext context) =>
    askText(context, title: context.l.markCompleted, label: context.l.completionNoteLabel, maxLines: 3);

/// Completes without the tenant (e.g. they signed on paper).
Future<void> completeInspection(CrudRepository<Inspection> repo, Inspection insp, String note) {
  final now = nowGst();
  return repo.save(insp.copyWith(
    status: InspectionStatus.completed,
    completedAt: now,
    landlordSignedAt: insp.landlordSignedAt ?? now,
    completionNote: note,
  ));
}

class _DeleteButton extends ConsumerWidget {
  const _DeleteButton({required this.insp});
  final Inspection insp;
  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
        tooltip: context.l.deleteInspection,
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          final l = context.l;
          final ok = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(l.deleteInspection),
              content: Text(l.deleteInspectionConfirm),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
                FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.delete)),
              ],
            ),
          );
          if (ok != true || !context.mounted) return;
          context.go('/inspections');
          await ref.read(inspectionRepositoryProvider).delete(insp.id);
        },
      );
}

/// The draft walkthrough: rooms with progress, meters & keys, general notes,
/// then Review & send.
class WalkthroughScreen extends ConsumerStatefulWidget {
  const WalkthroughScreen({super.key, required this.initial});
  final Inspection initial;
  @override
  ConsumerState<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends ConsumerState<WalkthroughScreen> {
  late final InspectionEditor _ed = InspectionEditor(
    initial: widget.initial,
    repo: ref.read(inspectionRepositoryProvider),
    media: ref.read(inspectionMediaStoreProvider),
  );

  @override
  void initState() {
    super.initState();
    _ed.addListener(_showErrors);
  }

  void _showErrors() {
    final e = _ed.lastError;
    if (e == null || !mounted) return;
    _ed.lastError = null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l.uploadFailed('$e'))));
  }

  @override
  void dispose() {
    _ed.removeListener(_showErrors);
    _ed.dispose();
    super.dispose();
  }

  Inspection? _moveIn() => _ed.value.isMoveOut
      ? moveInFor(ref.read(inspectionsProvider).value ?? const [], _ed.value.leaseId, preferId: _ed.value.moveInId)
      : null;

  Future<void> _addRoom() async {
    final l = context.l;
    final lang = Localizations.localeOf(context).languageCode;
    final kind = await showModalBottomSheet<RoomKind?>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (final k in RoomKind.values)
            ListTile(leading: const Icon(Icons.meeting_room_outlined), title: Text(roomName(k, lang)), onTap: () => Navigator.pop(c, k)),
        ]),
      ),
    );
    if (kind == null || !mounted) return;
    final name = await askText(context, title: l.addRoom, label: l.roomNameLabel, initial: roomName(kind, lang));
    if (name == null) return;
    _ed.update((i) => i.copyWith(rooms: [
          ...i.rooms,
          InspectionRoom(id: newId(), name: name, items: defaultItemsFor(kind, lang: lang, newId: newId)),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context);
    return ListenableBuilder(
      listenable: _ed,
      builder: (context, _) {
        final insp = _ed.value;
        final info = reportInfoFor(ref, insp);
        final moveIn = _moveIn();
        return Scaffold(
          appBar: ShellAppBar(title: Text(typeLabel(l, insp.type)), actions: [
            IconButton(
              tooltip: l.downloadReport,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () async {
                await _ed.flush();
                if (context.mounted) await shareInspectionReport(context, _ed.value, info: info, moveIn: moveIn);
              },
            ),
            _DeleteButton(insp: insp),
          ]),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Text([info.propertyName, info.tenantName].where((s) => s.isNotEmpty).join(' · '),
                              style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(l.inspectionCreated(formatDate(insp.createdAt)), style: t.textTheme.bodySmall),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: insp.progress,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                            // The theme's dark-amber track reads as "full" at 0%.
                            backgroundColor: t.colorScheme.surfaceContainerHighest,
                          ),
                          const SizedBox(height: 6),
                          Text(l.itemsRated(insp.ratedCount, insp.itemCount), key: const Key('walkthrough-progress')),
                        ]),
                      ),
                    ),
                    if (moveIn != null) ...[const SizedBox(height: 12), _Banner(text: l.prefilledFromMoveIn, icon: Icons.compare_arrows)],
                    if (_ed.pending.isNotEmpty) ...[const SizedBox(height: 12), _UploadBanner(editor: _ed)],
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: Text(l.inspectionRooms, style: t.textTheme.titleMedium)),
                      TextButton.icon(key: const Key('add-room'), onPressed: _addRoom, icon: const Icon(Icons.add), label: Text(l.addRoom)),
                    ]),
                    for (final r in insp.rooms)
                      Card(
                        margin: const EdgeInsets.only(top: 8),
                        child: ListTile(
                          key: Key('room-${r.id}'),
                          leading: CircleAvatar(
                            backgroundColor: r.isDone ? context.status.success.withValues(alpha: 0.15) : t.colorScheme.surfaceContainerHighest,
                            child: Icon(r.isDone ? Icons.check : Icons.meeting_room_outlined,
                                color: r.isDone ? context.status.success : t.colorScheme.onSurfaceVariant),
                          ),
                          title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(l.itemsRated(r.ratedCount, r.items.length)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => RoomEditorScreen(editor: _ed, roomId: r.id, moveIn: moveIn),
                          )),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Card(
                      margin: const EdgeInsets.only(top: 8),
                      child: ListTile(
                        key: const Key('meters-keys'),
                        leading: const CircleAvatar(child: Icon(Icons.speed_outlined)),
                        title: Text(l.metersAndKeys, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text([
                          if (insp.meters.electricity.isNotEmpty) '${l.meterElectricity}: ${insp.meters.electricity}',
                          if (insp.meters.water.isNotEmpty) '${l.meterWater}: ${insp.meters.water}',
                        ].join(' · ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MetersKeysScreen(editor: _ed))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('general-notes'),
                      initialValue: insp.generalNotes,
                      maxLines: 4,
                      minLines: 2,
                      decoration: InputDecoration(labelText: l.generalNotes),
                      onChanged: (v) => _ed.update((i) => i.copyWith(generalNotes: v)),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _BottomBar(
            child: FilledButton.icon(
              key: const Key('review-and-send'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReviewScreen(editor: _ed, moveIn: moveIn))),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(l.reviewAndSend),
            ),
          ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.icon});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: s.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: s.onPrimaryContainer),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: s.onPrimaryContainer))),
      ]),
    );
  }
}

class _UploadBanner extends StatelessWidget {
  const _UploadBanner({required this.editor});
  final InspectionEditor editor;
  @override
  Widget build(BuildContext context) {
    final p = editor.pending;
    final avg = p.isEmpty ? 0.0 : p.fold<double>(0, (s, u) => s + u.progress) / p.length;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(context.l.uploadingMedia(p.length)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: avg == 0 ? null : avg),
        ]),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Material(
      color: s.surfaceContainer,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 880), child: SizedBox(width: double.infinity, child: child)),
          ),
        ),
      ),
    );
  }
}

Future<void> _pickAndUpload(BuildContext context, WidgetRef ref, InspectionEditor ed, MediaTarget target) async {
  final picked = await ref.read(inspectionMediaPickerProvider)(context);
  for (final (f, type) in picked) {
    ed.addMedia(target, f, type); // background; progress shows in the banner
  }
}

/// One room: every item with quick condition chips, notes and media.
class RoomEditorScreen extends ConsumerWidget {
  const RoomEditorScreen({super.key, required this.editor, required this.roomId, this.moveIn});
  final InspectionEditor editor;
  final String roomId;
  final Inspection? moveIn;

  void _updateRoom(InspectionRoom Function(InspectionRoom) f) =>
      editor.update((i) => i.copyWith(rooms: [for (final r in i.rooms) r.id == roomId ? f(r) : r]));

  void _updateItem(String itemId, InspectionItem Function(InspectionItem) f) =>
      _updateRoom((r) => r.copyWith(items: [for (final it in r.items) it.id == itemId ? f(it) : it]));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return ListenableBuilder(
      listenable: editor,
      builder: (context, _) {
        final room = editor.value.rooms.where((r) => r.id == roomId).firstOrNull;
        if (room == null) return const Scaffold(body: EmptyState());
        final cmp = moveIn == null
            ? const <String, ItemComparison>{}
            : {for (final c in compareInspections(moveIn!, editor.value)) if (c.moveOut != null) c.moveOut!.id: c};
        return Scaffold(
          appBar: AppBar(
            title: Text(room.name),
            actions: [
              IconButton(
                key: const Key('add-item'),
                tooltip: l.addItem,
                icon: const Icon(Icons.playlist_add),
                onPressed: () async {
                  final name = await askText(context, title: l.addItem, label: l.itemNameLabel);
                  if (name != null) _updateRoom((r) => r.copyWith(items: [...r.items, InspectionItem(id: newId(), name: name)]));
                },
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'rename') {
                    final name = await askText(context, title: l.renameRoom, label: l.roomNameLabel, initial: room.name);
                    if (name != null) _updateRoom((r) => r.copyWith(name: name));
                  } else if (v == 'delete') {
                    Navigator.of(context).pop();
                    editor.update((i) => i.copyWith(rooms: [for (final r in i.rooms) if (r.id != roomId) r]));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'rename', child: Text(l.renameRoom)),
                  PopupMenuItem(value: 'delete', child: Text(l.deleteRoom)),
                ],
              ),
            ],
          ),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (editor.pending.isNotEmpty) ...[_UploadBanner(editor: editor), const SizedBox(height: 12)],
                  for (final it in room.items) ...[
                    _ItemCard(
                      key: Key('item-${it.id}'),
                      item: it,
                      comparison: cmp[it.id],
                      onCondition: (c) => _updateItem(it.id, (x) => x.condition == c ? x.copyWith(clearCondition: true) : x.copyWith(condition: c)),
                      onNotes: (v) => _updateItem(it.id, (x) => x.copyWith(notes: v)),
                      onAddMedia: () => _pickAndUpload(context, ref, editor, ItemMedia(roomId, it.id)),
                      onRemoveMedia: (m) => editor.removeMedia(ItemMedia(roomId, it.id), m),
                      onRename: () async {
                        final name = await askText(context, title: l.renameItem, label: l.itemNameLabel, initial: it.name);
                        if (name != null) _updateItem(it.id, (x) => x.copyWith(name: name));
                      },
                      onDelete: () => _updateRoom((r) => r.copyWith(items: [for (final x in r.items) if (x.id != it.id) x])),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(l.roomPhotos, style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        MediaStrip(room.media, onRemove: (m) => editor.removeMedia(RoomMedia(roomId), m), trailing: [
                          _AddMediaTile(onTap: () => _pickAndUpload(context, ref, editor, RoomMedia(roomId))),
                        ]),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: room.notes,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(labelText: l.roomNotes),
                          onChanged: (v) => _updateRoom((r) => r.copyWith(notes: v)),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
          bottomNavigationBar: _BottomBar(
            child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.continueLabel)),
          ),
        );
      },
    );
  }
}

class _AddMediaTile extends StatelessWidget {
  const _AddMediaTile({super.key, required this.onTap, this.size = 72});
  final VoidCallback onTap;
  final double size;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: Material(
        color: s.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Tooltip(message: context.l.addPhotoOrVideo, child: Icon(Icons.add_a_photo_outlined, color: s.primary)),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.item,
    required this.onCondition,
    required this.onNotes,
    required this.onAddMedia,
    required this.onRemoveMedia,
    required this.onRename,
    required this.onDelete,
    this.comparison,
  });
  final InspectionItem item;
  final ItemComparison? comparison;
  final ValueChanged<Condition> onCondition;
  final ValueChanged<String> onNotes;
  final VoidCallback onAddMedia, onRename, onDelete;
  final ValueChanged<InspectionMedia> onRemoveMedia;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context);
    final worse = comparison?.worsened ?? false;
    return Card(
      margin: EdgeInsets.zero,
      shape: worse
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: context.status.danger, width: 1.5))
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(item.name, style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
            PopupMenuButton<String>(
              onSelected: (v) => v == 'rename' ? onRename() : onDelete(),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'rename', child: Text(l.renameItem)),
                PopupMenuItem(value: 'delete', child: Text(l.deleteItem)),
              ],
            ),
          ]),
          if (comparison?.moveIn != null) ...[
            Row(children: [
              Text('${l.atMoveIn}: ', style: t.textTheme.bodySmall),
              ConditionBadge(comparison!.moveIn!.condition),
              if (comparison!.moveIn!.notes.isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: Text(comparison!.moveIn!.notes, style: t.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                  ),
                ),
            ]),
            if (comparison!.moveIn!.media.isNotEmpty) ...[
              const SizedBox(height: 6),
              MediaStrip(comparison!.moveIn!.media, size: 48),
            ],
            const SizedBox(height: 8),
          ],
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (final c in Condition.values)
                ChoiceChip(
                  key: Key('cond-${item.id}-${c.name}'),
                  label: Text(conditionLabel(l, c)),
                  selected: item.condition == c,
                  selectedColor: conditionColor(context, c).withValues(alpha: 0.22),
                  side: BorderSide(color: item.condition == c ? conditionColor(context, c) : t.colorScheme.outlineVariant),
                  onSelected: (_) => onCondition(c),
                  visualDensity: VisualDensity.compact,
                ),
            ]),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: TextFormField(
              key: Key('notes-${item.id}'),
              initialValue: item.notes,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.notes, isDense: true),
              onChanged: onNotes,
            ),
          ),
          const SizedBox(height: 12),
          MediaStrip(item.media, size: 64, onRemove: onRemoveMedia, trailing: [
            _AddMediaTile(key: Key('add-media-${item.id}'), onTap: onAddMedia, size: 64),
          ]),
        ]),
      ),
    );
  }
}

/// Meter readings (with photos) and keys handed over.
class MetersKeysScreen extends ConsumerWidget {
  const MetersKeysScreen({super.key, required this.editor});
  final InspectionEditor editor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final m = editor.value.meters, k = editor.value.keys;
    Widget field(String key, String label, String initial, ValueChanged<String> on, {TextInputType? type}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            key: Key(key),
            initialValue: initial,
            keyboardType: type,
            decoration: InputDecoration(labelText: label),
            onChanged: on,
          ),
        );
    const number = TextInputType.numberWithOptions(decimal: true);
    return Scaffold(
      appBar: AppBar(title: Text(l.metersAndKeys)),
      body: ListenableBuilder(
        listenable: editor,
        builder: (context, _) => ListView(padding: const EdgeInsets.all(16), children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(l.meterReadings, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                field('meter-electricity', l.meterElectricity, m.electricity,
                    (v) => editor.update((i) => i.copyWith(meters: i.meters.copyWith(electricity: v))), type: number),
                field('meter-water', l.meterWater, m.water, (v) => editor.update((i) => i.copyWith(meters: i.meters.copyWith(water: v))),
                    type: number),
                field('meter-gas', l.meterGas, m.gas, (v) => editor.update((i) => i.copyWith(meters: i.meters.copyWith(gas: v))),
                    type: number),
                Text(l.meterPhotos, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                MediaStrip(editor.value.meters.photos, onRemove: (p) => editor.removeMedia(const MeterMedia(), p), trailing: [
                  _AddMediaTile(onTap: () => _pickAndUpload(context, ref, editor, const MeterMedia())),
                ]),
                const Divider(height: 32),
                Text(l.keysHandedOver, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                field('keys-main', l.keysMainDoor, k.mainDoor, (v) => editor.update((i) => i.copyWith(keys: i.keys.copyWith(mainDoor: v)))),
                field('keys-mailbox', l.keysMailbox, k.mailbox, (v) => editor.update((i) => i.copyWith(keys: i.keys.copyWith(mailbox: v)))),
                field('keys-parking', l.keysParking, k.parking, (v) => editor.update((i) => i.copyWith(keys: i.keys.copyWith(parking: v)))),
                field('keys-cards', l.keysAccessCards, k.accessCards,
                    (v) => editor.update((i) => i.copyWith(keys: i.keys.copyWith(accessCards: v)))),
                field('keys-remotes', l.keysRemotes, k.remotes, (v) => editor.update((i) => i.copyWith(keys: i.keys.copyWith(remotes: v)))),
                field('keys-other', l.keysOther, k.other, (v) => editor.update((i) => i.copyWith(keys: i.keys.copyWith(other: v)))),
              ]),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: _BottomBar(child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.continueLabel))),
    );
  }
}

/// Summary, move-out comparison, PDF, then Send to tenant or Mark completed.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key, required this.editor, this.moveIn});
  final InspectionEditor editor;
  final Inspection? moveIn;

  Future<void> _send(BuildContext context) async {
    final l = context.l;
    final unrated = editor.value.itemCount - editor.value.ratedCount;
    if (unrated > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(l.unratedItems(unrated)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
            FilledButton(key: const Key('send-anyway'), onPressed: () => Navigator.pop(c, true), child: Text(l.sendToTenant)),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    // Leave this page first: once the status changes the walkthrough is
    // replaced by the report and the editor goes away.
    Navigator.of(context).pop();
    editor.update((i) => i.copyWith(status: InspectionStatus.awaitingTenant, landlordSignedAt: nowGst()));
    await editor.flush();
    messenger.showSnackBar(SnackBar(content: Text(l.inspectionSent)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final t = Theme.of(context);
    return ListenableBuilder(
      listenable: editor,
      builder: (context, _) {
        final insp = editor.value;
        final counts = <Condition, int>{};
        for (final r in insp.rooms) {
          for (final i in r.items) {
            if (i.condition != null) counts[i.condition!] = (counts[i.condition!] ?? 0) + 1;
          }
        }
        final worse = moveIn == null ? const <ItemComparison>[] : worsenedItems(moveIn!, insp);
        return Scaffold(
          appBar: AppBar(title: Text(l.reviewAndSend)),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(l.itemsRated(insp.ratedCount, insp.itemCount), style: t.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                            value: insp.progress,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                            // The theme's dark-amber track reads as "full" at 0%.
                            backgroundColor: t.colorScheme.surfaceContainerHighest,
                          ),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final e in counts.entries)
                            StatusChip('${conditionLabel(l, e.key)} · ${e.value}', conditionColor(context, e.key), icon: conditionIcon(e.key)),
                        ]),
                      ]),
                    ),
                  ),
                  if (moveIn != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Text(l.worsenedItems, style: t.textTheme.titleMedium),
                          Text(l.worsenedHint, style: t.textTheme.bodySmall),
                          const SizedBox(height: 8),
                          if (worse.isEmpty) Text(l.noWorsenedItems, key: const Key('no-worsened')),
                          for (final c in worse)
                            ListTile(
                              key: const Key('worsened-item'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: Icon(Icons.trending_down, color: context.status.danger),
                              title: Text('${c.roomName} · ${c.itemName}'),
                              subtitle: c.moveOut!.notes.isEmpty ? null : Text(c.moveOut!.notes),
                              trailing: Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                                ConditionBadge(c.moveIn?.condition),
                                const Icon(Icons.arrow_forward, size: 14),
                                ConditionBadge(c.moveOut?.condition),
                              ]),
                            ),
                        ]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await editor.flush();
                      if (context.mounted) {
                        await shareInspectionReport(context, editor.value, info: reportInfoFor(ref, editor.value), moveIn: moveIn);
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(l.downloadReport),
                  ),
                  const SizedBox(height: 24),
                  Text(l.sendToTenantHint, style: t.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const Key('send-to-tenant'),
                    onPressed: () => _send(context),
                    icon: const Icon(Icons.send_outlined),
                    label: Text(l.sendToTenant),
                  ),
                  const SizedBox(height: 16),
                  Text(l.markCompletedHint, style: t.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('mark-completed'),
                    onPressed: () async {
                      final note = await askCompletionNote(context);
                      if (note == null || !context.mounted) return;
                      final repo = ref.read(inspectionRepositoryProvider);
                      Navigator.of(context).pop();
                      await editor.flush();
                      await completeInspection(repo, editor.value, note);
                    },
                    icon: const Icon(Icons.task_alt),
                    label: Text(l.markCompleted),
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }
}
