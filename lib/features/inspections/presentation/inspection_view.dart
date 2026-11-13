import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../data/inspection_pdf.dart';
import '../data/inspection_providers.dart';
import '../domain/comparison.dart';
import '../domain/inspection.dart';
import 'inspection_actions.dart';
import 'inspection_ui.dart';

/// Read-only rendering of an inspection from its raw Firestore map.
///
/// The landlord sees it once an inspection has been sent; the tenant app
/// renders its `tenantViews/{uid}/inspections/{id}` copies with it, with
/// [tenantMode] on: "Add comment", "Add photo or video" and "Confirm
/// inspection" then call the Cloud Functions (via
/// [tenantInspectionActionsProvider]) using the copy's `landlordUid`.
///
/// Optional extras: [moveInData] (the move-in, to compare a move-out),
/// [info] (names for the PDF; otherwise read from `propertyName`,
/// `address`, `tenantName`, `landlordName` in [data] when present),
/// [scrollable] (false to embed in another scroll view) and [footer]
/// (landlord actions).
class InspectionView extends ConsumerStatefulWidget {
  const InspectionView({
    super.key,
    required this.data,
    required this.tenantMode,
    this.moveInData,
    this.info,
    this.scrollable = true,
    this.footer,
  });

  final Map<String, dynamic> data;
  final bool tenantMode;
  final Map<String, dynamic>? moveInData;
  final InspectionReportInfo? info;
  final bool scrollable;
  final Widget? footer;

  @override
  ConsumerState<InspectionView> createState() => _InspectionViewState();
}

class _InspectionViewState extends ConsumerState<InspectionView> {
  bool _busy = false;
  double? _progress;

  Inspection get _insp => Inspection.fromMap(widget.data);
  Inspection? get _moveIn => widget.moveInData == null ? null : Inspection.fromMap(widget.moveInData!);
  String get _landlordUid => '${widget.data['landlordUid'] ?? ''}';

  InspectionReportInfo get _info =>
      widget.info ??
      InspectionReportInfo(
        propertyName: '${widget.data['propertyName'] ?? ''}',
        address: '${widget.data['address'] ?? ''}',
        tenantName: '${widget.data['tenantName'] ?? ''}',
        landlordName: '${widget.data['landlordName'] ?? ''}',
      );

  Future<void> _run(Future<void> Function() job, {String? done}) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await job();
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _comment({String? itemId}) async {
    final l = context.l;
    final text = await askText(context, title: l.addComment, label: l.commentLabel, maxLines: 4);
    if (text == null || !mounted) return;
    await _run(() => ref.read(tenantInspectionActionsProvider)
        .addComment(landlordUid: _landlordUid, inspectionId: _insp.id, text: text, itemId: itemId));
  }

  Future<void> _addMedia({String? itemId}) async {
    final picked = await ref.read(inspectionMediaPickerProvider)(context);
    if (picked.isEmpty || !mounted) return;
    await _run(() async {
      for (final (f, type) in picked) {
        await ref.read(tenantInspectionActionsProvider).attachMedia(
              landlordUid: _landlordUid,
              inspectionId: _insp.id,
              file: f,
              type: type,
              itemId: itemId,
              onProgress: (p) => mounted ? setState(() => _progress = p) : null,
            );
      }
    });
    if (mounted) setState(() => _progress = null);
  }

  Future<void> _confirm() async {
    final l = context.l;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.confirmInspection),
        content: Text(l.confirmInspectionBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(key: const Key('confirm-inspection-ok'), onPressed: () => Navigator.pop(c, true), child: Text(l.confirmInspection)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(() => ref.read(tenantInspectionActionsProvider).confirm(landlordUid: _landlordUid, inspectionId: _insp.id),
        done: l.inspectionConfirmed);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context);
    final insp = _insp;
    final moveIn = insp.isMoveOut ? _moveIn : null;
    final comparison = moveIn == null ? const <ItemComparison>[] : compareInspections(moveIn, insp);
    final byItem = {for (final c in comparison) if (c.moveOut != null) c.moveOut!.id: c};
    final worse = moveIn == null ? const <ItemComparison>[] : worsenedItems(moveIn, insp);
    final canAct = widget.tenantMode && insp.status == InspectionStatus.awaitingTenant && !_busy;

    Widget card(String title, IconData icon, List<Widget> children, {Widget? trailing}) => Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Icon(icon, size: 20, color: t.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                ?trailing,
              ]),
              const SizedBox(height: 12),
              ...children,
            ]),
          ),
        );

    Widget kv(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 150, child: Text(k, style: TextStyle(color: t.colorScheme.onSurfaceVariant))),
            Expanded(child: Text(v.isEmpty ? '—' : v)),
          ]),
        );

    String when(DateTime? d) => d == null ? l.notYet : formatDateTime(d);

    final keyRows = {
      l.keysMainDoor: insp.keys.mainDoor,
      l.keysMailbox: insp.keys.mailbox,
      l.keysParking: insp.keys.parking,
      l.keysAccessCards: insp.keys.accessCards,
      l.keysRemotes: insp.keys.remotes,
      l.keysOther: insp.keys.other,
    }..removeWhere((_, v) => v.isEmpty);

    final children = <Widget>[
      // Header
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(typeIcon(insp.type), color: t.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(typeLabel(l, insp.type), style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
              StatusChip(statusLabel(l, insp.status), statusColorOf(context, insp.status), icon: statusIconOf(insp.status)),
            ]),
            if (_info.propertyName.isNotEmpty || _info.tenantName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text([_info.propertyName, _info.tenantName].where((s) => s.isNotEmpty).join(' · '),
                  style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 12),
            kv(l.createdLabel, formatDateTime(insp.createdAt)),
            if (insp.completedAt != null) kv(l.completedLabel, formatDateTime(insp.completedAt!)),
            kv(l.inspectionRooms, '${insp.rooms.length} · ${l.itemsRated(insp.ratedCount, insp.itemCount)}'),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                key: const Key('inspection-pdf'),
                onPressed: () => shareInspectionReport(context, insp, info: _info, moveIn: moveIn),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(l.downloadReport),
              ),
            ]),
          ]),
        ),
      ),
      if (insp.generalNotes.isNotEmpty) card(l.generalNotes, Icons.notes, [Text(insp.generalNotes)]),
      card(l.metersAndKeys, Icons.speed_outlined, [
        kv(l.meterElectricity, insp.meters.electricity),
        kv(l.meterWater, insp.meters.water),
        if (insp.meters.gas.isNotEmpty) kv(l.meterGas, insp.meters.gas),
        if (insp.meters.photos.isNotEmpty) ...[const SizedBox(height: 8), MediaStrip(insp.meters.photos)],
        const Divider(height: 24),
        if (keyRows.isEmpty) kv(l.keysHandedOver, '') else for (final e in keyRows.entries) kv(e.key, e.value),
      ]),
      if (moveIn != null)
        card(l.worsenedItems, Icons.compare_arrows, [
          Text(l.worsenedHint, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          if (worse.isEmpty) Text(l.noWorsenedItems),
          for (final c in worse)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(Icons.trending_down, color: context.status.danger),
              title: Text('${c.roomName} · ${c.itemName}'),
              subtitle: Text(c.moveOut?.notes ?? ''),
              trailing: Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                ConditionBadge(c.moveIn?.condition),
                const Icon(Icons.arrow_forward, size: 14),
                ConditionBadge(c.moveOut?.condition),
              ]),
            ),
        ]),
      for (final r in insp.rooms)
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            key: PageStorageKey('room-${r.id}'),
            initiallyExpanded: insp.rooms.length <= 3,
            leading: Icon(r.isDone ? Icons.check_circle : Icons.meeting_room_outlined,
                color: r.isDone ? context.status.success : t.colorScheme.onSurfaceVariant),
            title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(l.itemsRated(r.ratedCount, r.items.length)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (r.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(r.notes)),
              if (r.media.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: MediaStrip(r.media, size: 64)),
              for (final i in r.items) _itemRow(context, i, byItem[i.id], insp, canAct),
            ],
          ),
        ),
      if (insp.tenantComments.isNotEmpty || insp.tenantMedia.isNotEmpty)
        card(l.tenantComments, Icons.forum_outlined, [
          for (final c in insp.tenantComments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(c.text),
              subtitle: Text([
                formatDateTime(c.at),
                if (c.itemId != null) _itemName(insp, c.itemId!),
              ].where((s) => s.isNotEmpty).join(' · ')),
            ),
          if (insp.tenantMedia.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l.tenantMedia, style: t.textTheme.labelLarge),
            const SizedBox(height: 8),
            MediaStrip(insp.tenantMedia),
          ],
        ]),
      card(l.confirmationsLabel, Icons.verified_user_outlined, [
        kv(l.landlordSigned, when(insp.landlordSignedAt)),
        kv(l.tenantConfirmed, when(insp.tenantConfirmedAt)),
        if (insp.completionNote.isNotEmpty) kv(l.completedWithoutTenant, insp.completionNote),
      ]),
      if (widget.tenantMode && insp.status == InspectionStatus.awaitingTenant)
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_progress != null) ...[
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 12),
              ],
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                  key: const Key('tenant-add-comment'),
                  onPressed: canAct ? () => _comment() : null,
                  icon: const Icon(Icons.add_comment_outlined),
                  label: Text(l.addComment),
                ),
                OutlinedButton.icon(
                  key: const Key('tenant-add-media'),
                  onPressed: canAct ? () => _addMedia() : null,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(l.addPhotoOrVideo),
                ),
              ]),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('tenant-confirm'),
                onPressed: canAct ? _confirm : null,
                icon: const Icon(Icons.verified_outlined),
                label: Text(l.confirmInspection),
              ),
            ]),
          ),
        ),
      ?widget.footer,
    ];

    final column = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final c in children) ...[c, const SizedBox(height: 12)],
    ]);
    if (!widget.scrollable) return column;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 880), child: column)),
    );
  }

  String _itemName(Inspection insp, String itemId) {
    for (final r in insp.rooms) {
      for (final i in r.items) {
        if (i.id == itemId) return '${r.name} · ${i.name}';
      }
    }
    return '';
  }

  Widget _itemRow(BuildContext context, InspectionItem i, ItemComparison? cmp, Inspection insp, bool canAct) {
    final t = Theme.of(context);
    final l = context.l;
    final tenantMedia = [for (final m in insp.tenantMedia) if (m.itemId == i.id) m];
    final worse = cmp?.worsened ?? false;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: worse ? context.status.danger : t.colorScheme.outlineVariant),
        color: worse ? context.status.danger.withValues(alpha: 0.06) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w600))),
          if (cmp?.moveIn != null) ...[
            Tooltip(message: l.atMoveIn, child: ConditionBadge(cmp!.moveIn!.condition)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward, size: 14)),
          ],
          ConditionBadge(i.condition),
          if (canAct)
            IconButton(
              tooltip: l.addComment,
              visualDensity: VisualDensity.compact,
              onPressed: () => _comment(itemId: i.id),
              icon: const Icon(Icons.add_comment_outlined, size: 20),
            ),
        ]),
        if (i.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(i.notes)),
        if (cmp?.moveIn != null && cmp!.moveIn!.media.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(l.atMoveIn, style: t.textTheme.labelSmall),
          const SizedBox(height: 4),
          MediaStrip(cmp.moveIn!.media, size: 52),
        ],
        if (i.media.isNotEmpty || tenantMedia.isNotEmpty) ...[
          const SizedBox(height: 8),
          MediaStrip([...i.media, ...tenantMedia], size: 64),
        ],
      ]),
    );
  }
}
