import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../leases/domain/lease.dart';
import '../../properties/domain/property.dart';
import '../../tenant_portal/presentation/document_checklist.dart' show requestableDocLabel;
import '../../tenants/domain/tenant.dart';
import '../data/document_request_actions.dart';
import '../domain/document_request.dart';
import 'documents_editor.dart' show documentPickerProvider;

/// Open document requests from tenants, newest first.
final pendingDocumentRequestsProvider = Provider<List<DocumentRequest>>((ref) => [
      for (final r in ref.watch(documentRequestsProvider).value ?? const <DocumentRequest>[])
        if (r.isOpen) r,
    ]..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000))));

/// "{tenant} asked for: {doc}" (bell and card titles).
String documentRequestTitle(AppLocalizations l, DocumentRequest r, String tenantName) =>
    l.drNotif(tenantName.isEmpty ? l.tenant : tenantName, r.doc == RequestableDoc.other && r.note.isNotEmpty ? r.note : requestableDocLabel(l, r.doc));

/// Dashboard card (and, with [tenantId], the tenant's page): tenants' open
/// document requests with Share / Upload & share / Decline.
class DocumentRequestsCard extends ConsumerWidget {
  const DocumentRequestsCard({super.key, this.gap = 16, this.tenantId});
  final double gap;
  final String? tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = [
      for (final r in ref.watch(pendingDocumentRequestsProvider))
        if (tenantId == null || r.tenantId == tenantId) r,
    ];
    if (pending.isEmpty) return const SizedBox.shrink();
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final tenants = {for (final t in ref.watch(tenantsProvider).value ?? const <Tenant>[]) t.id: t.name};
    final properties = ref.watch(propertiesProvider).value ?? const <Property>[];
    final leases = ref.watch(leasesProvider).value ?? const <Lease>[];
    final propertyName = {for (final p in properties) p.id: p.name};
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Card(
        key: Key(tenantId == null ? 'document-requests-card' : 'document-requests-$tenantId'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(Icons.folder_shared_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tenantId == null ? l.drCardTitle : l.drTenantRequests,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Badge(label: Text('${pending.length}')),
            ]),
            const SizedBox(height: 8),
            for (final r in pending.take(tenantId == null ? 5 : 20))
              _RequestTile(
                request: r,
                title: documentRequestTitle(l, r, tenants[r.tenantId] ?? ''),
                subtitle: [
                  if (propertyName[r.propertyId] case final n? when n.isNotEmpty) n,
                  if (r.createdAt != null) formatDate(r.createdAt!),
                  if (r.doc != RequestableDoc.other && r.note.isNotEmpty) '“${r.note}”',
                ].join(' · '),
                target: requestTarget(r, properties, leases),
              ),
          ]),
        ),
      ),
    );
  }
}

class _RequestTile extends ConsumerStatefulWidget {
  const _RequestTile({required this.request, required this.title, required this.subtitle, required this.target});
  final DocumentRequest request;
  final String title, subtitle;
  final RequestTarget target;

  @override
  ConsumerState<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends ConsumerState<_RequestTile> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() job, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await job();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    final l = context.l;
    final reason = await showDialog<String>(context: context, builder: (_) => const _DeclineDialog());
    if (reason == null) return;
    await _run(() => DocumentRequestActions(ref).decline(widget.request, reason), l.drDeclinedDone);
  }

  Future<void> _upload() async {
    final l = context.l;
    final file = await ref.read(documentPickerProvider)(context);
    if (file == null) return;
    await _run(
      () => DocumentRequestActions(ref)
          .uploadAndShare(widget.request, widget.target, file, label: requestableDocLabel(l, widget.request.doc)),
      l.drShared,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final r = widget.request;
    final existing = unsharedMatch(r, widget.target);
    final id = r.id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (widget.subtitle.isNotEmpty)
          Text(widget.subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: [
          if (existing != null)
            FilledButton.tonal(
              key: Key('docreq-share-$id'),
              onPressed: _busy || widget.target.isEmpty
                  ? null
                  : () => _run(() => DocumentRequestActions(ref).shareExisting(r, widget.target, existing), l.drShared),
              child: Text(l.drShareExisting),
            ),
          FilledButton.icon(
            key: Key('docreq-upload-$id'),
            onPressed: _busy || widget.target.isEmpty ? null : _upload,
            icon: const Icon(Icons.upload_file, size: 18),
            label: Text(l.drUploadShare),
          ),
          OutlinedButton(
            key: Key('docreq-decline-$id'),
            onPressed: _busy ? null : _decline,
            child: Text(l.drDecline),
          ),
        ]),
      ]),
    );
  }
}

/// Asks for a short reason; owns its text controller.
class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog();
  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AlertDialog(
      title: Text(l.drDeclineTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 440),
        child: TextField(
          key: const Key('docreq-decline-reason'),
          controller: _c,
          autofocus: true,
          decoration: InputDecoration(labelText: l.drDeclineReason),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          key: const Key('docreq-decline-confirm'),
          onPressed: () => Navigator.pop(context, _c.text),
          child: Text(l.drDecline),
        ),
      ],
    );
  }
}
