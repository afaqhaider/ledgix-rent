import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/file_storage.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/forms.dart';
import '../domain/app_document.dart';

String documentKindLabel(AppLocalizations l, String kind) => switch (kind) {
      DocumentKinds.dewaBill => l.docDewaBill,
      DocumentKinds.titleDeed => l.docTitleDeed,
      DocumentKinds.ownerEmiratesId => l.docOwnerEmiratesId,
      DocumentKinds.ownerPassport => l.docOwnerPassport,
      DocumentKinds.mollak => l.docMollak,
      DocumentKinds.ejari => l.docEjari,
      DocumentKinds.tenancyContract => l.docTenancyContract,
      DocumentKinds.emiratesId => l.docEmiratesIdCopy,
      DocumentKinds.passport => l.docPassportCopy,
      DocumentKinds.lease => l.docLease,
      _ => l.docOther,
    };

enum PickSource { camera, gallery, pdf }

/// How forms pick a file; swappable in tests.
final documentPickerProvider = Provider<Future<XFile?> Function(BuildContext)>((ref) => pickDocumentFile);

/// Asks camera / photo / PDF, then picks one file (max 20 MB).
Future<XFile?> pickDocumentFile(BuildContext context, {bool allowCamera = true}) async {
  final l = context.l;
  final source = await showModalBottomSheet<PickSource>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (allowCamera && !kIsWeb)
          ListTile(leading: const Icon(Icons.photo_camera_outlined), title: Text(l.takePhoto), onTap: () => Navigator.pop(c, PickSource.camera)),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: Text(l.chooseImage), onTap: () => Navigator.pop(c, PickSource.gallery)),
        ListTile(leading: const Icon(Icons.picture_as_pdf_outlined), title: Text(l.choosePdf), onTap: () => Navigator.pop(c, PickSource.pdf)),
      ]),
    ),
  );
  if (source == null) return null;
  final XFile? file = switch (source) {
    PickSource.camera => await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90),
    PickSource.gallery => await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90),
    PickSource.pdf => (await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['pdf']))?.xFile,
  };
  if (file == null) return null;
  if (await file.length() > maxUploadBytes) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.fileTooLarge)));
    return null;
  }
  return file;
}

/// One row in a documents list: either already saved ([saved]) or picked and
/// waiting to upload ([file]).
class DocumentDraft {
  DocumentDraft({required this.kind, this.saved, this.file, this.size, bool? shared})
      : shared = shared ?? saved?.sharedWithTenant ?? false;
  String kind;

  /// Visible to the linked tenant in their app.
  bool shared;
  final AppDocument? saved;
  final XFile? file;
  final int? size;

  String get fileName => file?.name ?? saved?.name ?? '';
  bool get isPdf => fileName.toLowerCase().endsWith('.pdf') || (saved?.url.toLowerCase().contains('.pdf') ?? false);
}

/// Holds a form's documents until Save, then uploads the new ones.
class DocumentsController extends ChangeNotifier {
  DocumentsController({required this.kinds, this.required = const {}, List<AppDocument> existing = const []})
      : drafts = [for (final d in existing) DocumentDraft(kind: kinds.contains(d.kind) ? d.kind : _legacy(d.kind, kinds), saved: d)];

  final List<String> kinds;
  final Set<String> required;
  final List<DocumentDraft> drafts;

  static String _legacy(String kind, List<String> kinds) =>
      kind == DocumentKinds.emiratesId && kinds.contains(DocumentKinds.ownerEmiratesId) ? DocumentKinds.ownerEmiratesId : DocumentKinds.other;

  Set<String> get missing => required.difference(drafts.map((d) => d.kind).toSet());

  /// First required type not attached yet, else "other".
  String get suggestedKind => missing.isNotEmpty ? missing.first : (kinds.contains(DocumentKinds.other) ? DocumentKinds.other : kinds.first);

  Future<void> add(XFile file, {String? kind}) async {
    drafts.add(DocumentDraft(kind: kind != null && kinds.contains(kind) ? kind : suggestedKind, file: file, size: await file.length()));
    notifyListeners();
  }

  void setKind(DocumentDraft d, String kind) {
    d.kind = kind;
    notifyListeners();
  }

  void setShared(DocumentDraft d, bool shared) {
    d.shared = shared;
    notifyListeners();
  }

  void remove(DocumentDraft d) {
    drafts.remove(d);
    notifyListeners();
  }

  /// Uploads new files under [folder] and returns the full list to save.
  Future<List<AppDocument>> uploadAll(FileStorage storage, String folder, AppLocalizations l) async => [
        for (final d in drafts)
          if (d.saved != null && d.file == null)
            AppDocument(name: d.saved!.name, url: d.saved!.url, kind: d.kind, sharedWithTenant: d.shared)
          else if (d.file != null)
            AppDocument(
              name: documentKindLabel(l, d.kind),
              url: await storage.uploadFile('$folder/${newId()}_${_safe(d.file!.name)}', d.file!),
              kind: d.kind,
              sharedWithTenant: d.shared,
            ),
      ];

  static String _safe(String name) => name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
}

/// Tidy list of attached documents with type, file name, size, preview and
/// remove, an "Add document" button, and a check for required types.
class DocumentsEditor extends ConsumerWidget {
  const DocumentsEditor({super.key, required this.controller});
  final DocumentsController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => FormField<void>(
        validator: (_) => controller.missing.isEmpty
            ? null
            : l.documentsMissing(controller.missing.map((k) => documentKindLabel(l, k)).join(', ')),
        builder: (state) {
          final scheme = Theme.of(context).colorScheme;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (controller.required.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final k in controller.required)
                    Chip(
                      avatar: Icon(controller.missing.contains(k) ? Icons.radio_button_unchecked : Icons.check_circle,
                          size: 18, color: controller.missing.contains(k) ? scheme.onSurfaceVariant : scheme.primary),
                      label: Text(req(documentKindLabel(l, k))),
                    ),
                ]),
              ),
            if (controller.drafts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l.noDocumentsYet, style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            for (final d in controller.drafts) _DocumentRow(controller: controller, draft: d),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                key: const Key('add-document'),
                icon: const Icon(Icons.add),
                label: Text(l.addDocument),
                onPressed: () async {
                  final f = await ref.read(documentPickerProvider)(context);
                  if (f != null) await controller.add(f);
                  state.didChange(null);
                },
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

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.controller, required this.draft});
  final DocumentsController controller;
  final DocumentDraft draft;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final kb = draft.size == null ? null : (draft.size! / 1024);
    final sizeLabel = kb == null ? null : (kb >= 1024 ? '${(kb / 1024).toStringAsFixed(1)} MB' : '${kb.toStringAsFixed(0)} KB');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
      decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(draft.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DropdownButton<String>(
              value: draft.kind,
              isDense: true,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              style: Theme.of(context).textTheme.titleSmall,
              items: [
                for (final k in controller.kinds)
                  DropdownMenuItem(value: k, child: Text(controller.required.contains(k) ? req(documentKindLabel(l, k)) : documentKindLabel(l, k))),
              ],
              onChanged: (k) => k == null ? null : controller.setKind(draft, k),
            ),
            Text(
              [draft.fileName, ?sizeLabel, if (draft.file != null) l.notUploadedYet].where((s) => s.isNotEmpty).join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ]),
        ),
        IconButton(
          key: Key('share-doc-${controller.drafts.indexOf(draft)}'),
          tooltip: draft.shared ? l.tpSharedWithTenant : l.tpShareWithTenant,
          isSelected: draft.shared,
          icon: const Icon(Icons.person_add_alt_outlined),
          selectedIcon: Icon(Icons.how_to_reg, color: scheme.primary),
          onPressed: () => controller.setShared(draft, !draft.shared),
        ),
        if (!draft.isPdf)
          IconButton(tooltip: l.preview, icon: const Icon(Icons.visibility_outlined), onPressed: () => showDocumentPreview(context, draft)),
        IconButton(tooltip: l.remove, icon: const Icon(Icons.close), onPressed: () => controller.remove(draft)),
      ]),
    );
  }
}

void showDocumentPreview(BuildContext context, DocumentDraft d) {
  final url = d.saved?.url;
  final Widget image = d.file != null
      ? (kIsWeb ? Image.network(d.file!.path) : Image.file(File(d.file!.path)))
      : (url != null && (kIsWeb || url.startsWith('http')) ? Image.network(url) : Image.file(File(url ?? '')));
  showDialog<void>(
    context: context,
    builder: (c) => Dialog(child: InteractiveViewer(child: image)),
  );
}
