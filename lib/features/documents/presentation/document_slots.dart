import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/common.dart';
import '../../../core/widgets/forms.dart';
import 'documents_editor.dart';

/// Documents as fixed upload slots (e.g. Title deed *, DEWA bill, Owner's
/// Emirates ID) plus an "Other documents" list with free names.
///
/// [notes] adds a line under a slot, e.g. the ID's expiry date.
class DocumentSlotsEditor extends ConsumerWidget {
  const DocumentSlotsEditor({super.key, required this.controller, this.notes = const {}});
  final DocumentsController controller;
  final Map<String, Widget> notes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    Future<void> pick(FormFieldState<void> state, Future<void> Function(XFile file) use) async {
      final f = await ref.read(documentPickerProvider)(context);
      if (f != null) await use(f);
      state.didChange(null);
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => FormField<void>(
        validator: (_) => controller.missing.isEmpty
            ? null
            : l.documentsMissing(controller.missing.map((k) => documentKindLabel(l, k)).join(', ')),
        builder: (state) {
          final scheme = Theme.of(context).colorScheme;
          final others = controller.others;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final kind in controller.slots)
              _SlotRow(
                controller: controller,
                kind: kind,
                note: notes[kind],
                onPick: () => pick(state, (f) => controller.setSlotFile(kind, f)),
              ),
            const SizedBox(height: 12),
            Text(l.ixOtherDocuments, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (others.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(l.ixNoOtherDocuments, style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            for (final d in others) _OtherRow(key: ObjectKey(d), controller: controller, draft: d),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                key: const Key('add-other-document'),
                icon: const Icon(Icons.add),
                label: Text(l.ixAddOtherDocument),
                onPressed: () => pick(state, (f) => controller.add(f, kind: controller.otherKinds.last)),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(state.errorText!, style: TextStyle(color: scheme.error, fontSize: 12)),
              ),
          ]);
        },
      ),
    );
  }
}

String _sizeLabel(int? bytes) {
  if (bytes == null) return '';
  final kb = bytes / 1024;
  return kb >= 1024 ? '${(kb / 1024).toStringAsFixed(1)} MB' : '${kb.toStringAsFixed(0)} KB';
}

BoxDecoration _rowBox(ColorScheme scheme, {bool filled = false}) => BoxDecoration(
      color: filled ? scheme.primaryContainer.withValues(alpha: 0.25) : null,
      border: Border.all(color: scheme.outlineVariant),
      borderRadius: BorderRadius.circular(12),
    );

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.controller, required this.kind, required this.onPick, this.note});
  final DocumentsController controller;
  final String kind;
  final VoidCallback onPick;
  final Widget? note;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final d = controller.slot(kind);
    final label = documentKindLabel(l, kind);
    final details = d == null
        ? l.ixNotAttached
        : [d.fileName, _sizeLabel(d.size), if (d.file != null) l.notUploadedYet].where((s) => s.isNotEmpty).join(' · ');
    return Container(
      key: Key('slot-row-$kind'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
      decoration: _rowBox(scheme, filled: d != null),
      child: Row(children: [
        Icon(d == null ? Icons.upload_file_outlined : (d.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined),
            color: d == null ? scheme.onSurfaceVariant : scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(controller.required.contains(kind) ? req(label) : label, style: text.titleSmall),
            Text(details, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            if (note != null) Padding(padding: const EdgeInsets.only(top: 2), child: note),
          ]),
        ),
        if (d == null)
          TextButton.icon(key: Key('slot-$kind'), onPressed: onPick, icon: const Icon(Icons.upload_outlined, size: 18), label: Text(l.ixUpload))
        else ...[
          IconButton(
            key: Key('slot-share-$kind'),
            visualDensity: VisualDensity.compact,
            tooltip: d.shared ? l.tpSharedWithTenant : l.tpShareWithTenant,
            isSelected: d.shared,
            icon: const Icon(Icons.person_add_alt_outlined),
            selectedIcon: Icon(Icons.how_to_reg, color: scheme.primary),
            onPressed: () => controller.setShared(d, !d.shared),
          ),
          if (!d.isPdf)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l.preview,
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () => showDocumentPreview(context, d),
            ),
          IconButton(
            key: Key('slot-$kind'),
            visualDensity: VisualDensity.compact,
            tooltip: l.ixReplace,
            icon: const Icon(Icons.swap_horiz),
            onPressed: onPick,
          ),
          IconButton(
            key: Key('slot-remove-$kind'),
            visualDensity: VisualDensity.compact,
            tooltip: l.remove,
            icon: const Icon(Icons.close),
            onPressed: () => controller.remove(d),
          ),
        ],
      ]),
    );
  }
}

class _OtherRow extends StatelessWidget {
  const _OtherRow({super.key, required this.controller, required this.draft});
  final DocumentsController controller;
  final DocumentDraft draft;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final kinds = controller.otherKinds;
    final initialName = draft.label ?? draft.saved?.name ?? draft.fileName.replaceAll(RegExp(r'\.[A-Za-z0-9]+$'), '');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
      decoration: _rowBox(scheme),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Icon(draft.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(
              initialValue: initialName,
              decoration: InputDecoration(labelText: l.ixDocumentName, isDense: true),
              onChanged: (v) => controller.setLabel(draft, v),
            ),
            if (kinds.length > 1)
              DropdownButton<String>(
                value: kinds.contains(draft.kind) ? draft.kind : kinds.last,
                isDense: true,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: [for (final k in kinds) DropdownMenuItem(value: k, child: Text(documentKindLabel(l, k)))],
                onChanged: (k) => k == null ? null : controller.setKind(draft, k),
              ),
            Text(
              [draft.fileName, _sizeLabel(draft.size), if (draft.file != null) l.notUploadedYet].where((s) => s.isNotEmpty).join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ]),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: draft.shared ? l.tpSharedWithTenant : l.tpShareWithTenant,
          isSelected: draft.shared,
          icon: const Icon(Icons.person_add_alt_outlined),
          selectedIcon: Icon(Icons.how_to_reg, color: scheme.primary),
          onPressed: () => controller.setShared(draft, !draft.shared),
        ),
        if (!draft.isPdf)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: l.preview,
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () => showDocumentPreview(context, draft),
          ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: l.remove,
          icon: const Icon(Icons.close),
          onPressed: () => controller.remove(draft),
        ),
      ]),
    );
  }
}
