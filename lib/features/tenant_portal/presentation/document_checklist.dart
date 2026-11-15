import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../documents/domain/document_request.dart';
import '../data/tenant_portal.dart';
import '../domain/tenant_view.dart';
import '../tenant_providers.dart';
import 'tenant_screens.dart' show openTenantDocument;

/// Label for a requestable document.
String requestableDocLabel(AppLocalizations l, RequestableDoc d) => switch (d) {
      RequestableDoc.landlordEmiratesId => l.drLandlordEmiratesId,
      RequestableDoc.landlordPassport => l.drLandlordPassport,
      RequestableDoc.titleDeed => l.drTitleDeed,
      RequestableDoc.tenancyContract => l.drTenancyContract,
      RequestableDoc.ejari => l.drEjari,
      RequestableDoc.dewaBill => l.drDewaBill,
      RequestableDoc.other => l.drOther,
    };

/// Whether a shared document satisfies [d]. Older property records stored the
/// owner's ID as the generic emiratesId / passport kinds.
bool docMatches(TvDocument t, RequestableDoc d) =>
    d.kinds.contains(t.kind) ||
    (t.ownerType != 'tenant' &&
        ((d == RequestableDoc.landlordEmiratesId && t.kind == 'emiratesId') ||
            (d == RequestableDoc.landlordPassport && t.kind == 'passport')));

/// Checklist of standard documents for one of the tenant's properties:
/// available ones open, missing ones can be requested.
class TenantDocumentChecklist extends ConsumerWidget {
  const TenantDocumentChecklist({super.key, required this.landlordUid, required this.propertyId});
  final String landlordUid, propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final docs = [
      for (final d in ref.watch(tenantDocumentsProvider).value ?? const <TvDocument>[])
        if (d.landlordUid == landlordUid) d,
    ];
    final requests = [
      for (final r in ref.watch(tenantDocumentRequestsProvider).value ?? const <DocumentRequest>[])
        if (r.landlordUid == landlordUid && r.propertyId == propertyId) r,
    ]..sort((a, b) => (a.createdAt ?? DateTime(2000)).compareTo(b.createdAt ?? DateTime(2000)));
    final landlord = (ref.watch(tenantLandlordsProvider).value ?? const <TvLandlord>[])
        .where((x) => x.landlordUid == landlordUid)
        .firstOrNull;
    final active = landlord?.status != LinkStatus.former;

    final rows = <Widget>[];
    for (final d in RequestableDoc.values) {
      if (d == RequestableDoc.other) continue;
      // The landlord's ID can sit on any of their properties; others are per property.
      final match = docs
          .where((t) => docMatches(t, d) && (d.isPersonalId || t.propertyId == propertyId))
          .firstOrNull;
      final latest = requests.where((r) => r.doc == d).lastOrNull;
      final state = docAvailability(doc: d, available: match != null, linkActive: active, latest: latest);
      rows.add(_Row(
        doc: d,
        label: requestableDocLabel(l, d),
        state: state,
        response: latest?.response ?? '',
        onOpen: match == null ? null : () => openTenantDocument(match.url),
        onRequest: () => _request(context, ref, d),
        rowKey: '${d.name}-$propertyId',
      ));
    }
    for (final r in requests.where((r) => r.doc == RequestableDoc.other)) {
      rows.add(_Row(
        doc: RequestableDoc.other,
        label: r.note.isEmpty ? l.drOther : r.note,
        state: r.status == DocumentRequestStatus.declined
            ? DocAvailability.declined
            : r.status == DocumentRequestStatus.pending
                ? DocAvailability.requested
                : DocAvailability.notAvailable,
        response: r.response,
        onOpen: null,
        onRequest: () => _request(context, ref, RequestableDoc.other, note: r.note),
        rowKey: 'other-${r.id}',
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ...rows,
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: Key('doc-request-other-$propertyId'),
          icon: const Icon(Icons.add, size: 18),
          label: Text(l.drRequestOther),
          onPressed: () => _request(context, ref, RequestableDoc.other),
        ),
      ),
    ]);
  }

  Future<void> _request(BuildContext context, WidgetRef ref, RequestableDoc doc, {String note = ''}) async {
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    // The dialog owns its text field; null means cancelled.
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _RequestDialog(doc: doc, initialNote: doc == RequestableDoc.other ? note : ''),
    );
    if (text == null) return;
    try {
      await ref.read(tenantPortalProvider).requestDocument(
            tenantUid: ref.read(userIdProvider).value ?? 'anon',
            landlordUid: landlordUid,
            doc: doc,
            propertyId: propertyId,
            note: text,
          );
      messenger.showSnackBar(SnackBar(content: Text(l.drSent)));
    } on DocumentRequestException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(switch (e.reason) {
          DocumentRequestError.alreadyOpen => l.drErrAlreadyOpen,
          DocumentRequestError.noteRequired => l.drErrNoteRequired,
          DocumentRequestError.notAllowed => l.drErrNotAllowed,
        }),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _RequestDialog extends StatefulWidget {
  const _RequestDialog({required this.doc, required this.initialNote});
  final RequestableDoc doc;
  final String initialNote;

  @override
  State<_RequestDialog> createState() => _RequestDialogState();
}

class _RequestDialogState extends State<_RequestDialog> {
  late final _c = TextEditingController(text: widget.initialNote);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final other = widget.doc == RequestableDoc.other;
    return AlertDialog(
      title: Text(l.drRequestTitle(requestableDocLabel(l, widget.doc))),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 440),
        child: TextField(
          key: const Key('doc-request-note'),
          controller: _c,
          autofocus: other,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(labelText: other ? l.drOtherHint : l.drNoteHint),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          key: const Key('doc-request-send'),
          onPressed: () => Navigator.pop(context, _c.text.trim()),
          child: Text(l.drSend),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.doc,
    required this.label,
    required this.state,
    required this.response,
    required this.onOpen,
    required this.onRequest,
    required this.rowKey,
  });
  final RequestableDoc doc;
  final String label, response, rowKey;
  final DocAvailability state;
  final VoidCallback? onOpen;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, status) = switch (state) {
      DocAvailability.available => (Icons.check_circle_outline, Colors.green.shade700, l.drAvailable),
      DocAvailability.requested => (Icons.schedule, scheme.primary, l.drRequested),
      DocAvailability.declined =>
        (Icons.cancel_outlined, scheme.error, response.isEmpty ? l.drDeclined : l.drDeclinedWith(response)),
      DocAvailability.endedPersonalId => (Icons.lock_outline, scheme.onSurfaceVariant, l.drEndedPersonal),
      DocAvailability.notAvailable => (Icons.help_outline, scheme.onSurfaceVariant, l.drNotAvailable),
    };
    final Widget? action = switch (state) {
      DocAvailability.available => TextButton.icon(
          key: Key('doc-open-$rowKey'),
          icon: const Icon(Icons.download_outlined, size: 18),
          label: Text(l.drOpen),
          onPressed: onOpen,
        ),
      DocAvailability.notAvailable => FilledButton.tonal(
          key: Key('doc-request-$rowKey'),
          onPressed: onRequest,
          child: Text(l.drRequestNow),
        ),
      DocAvailability.declined => OutlinedButton(
          key: Key('doc-request-$rowKey'),
          onPressed: onRequest,
          child: Text(l.drAskAgain),
        ),
      DocAvailability.requested || DocAvailability.endedPersonalId => null,
    };
    return ListTile(
      key: Key('doc-row-$rowKey'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label),
      subtitle: Text(status, style: TextStyle(color: color)),
      trailing: action,
    );
  }
}
