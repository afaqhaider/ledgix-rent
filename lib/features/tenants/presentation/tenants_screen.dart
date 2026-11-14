import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/forms.dart';
import '../../documents/domain/app_document.dart';
import '../../documents/domain/expiry.dart';
import '../../documents/domain/form_fill.dart';
import '../../documents/domain/scanned_document.dart';
import '../../documents/presentation/auto_fill.dart';
import '../../documents/presentation/document_slots.dart';
import '../../documents/presentation/documents_editor.dart';
import '../../documents/presentation/expiry_widgets.dart';
import '../../documents/presentation/scan_to_fill.dart';
import '../../landlord/presentation/onboarding_screen.dart';
import '../../tenant_portal/presentation/invite_dialog.dart';
import '../domain/tenant.dart';

class TenantsScreen extends ConsumerWidget {
  const TenantsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: ShellAppBar(title: Text(context.l.tenants)),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => context.push('/tenants/new'),
          icon: const Icon(Icons.person_add),
          label: Text(context.l.addTenant),
        ),
        body: AsyncList<Tenant>(
          items: ref.watch(tenantsProvider),
          builder: (c, t) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(t.name),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text([t.phone, t.email].where((s) => s.isNotEmpty).join(' · ')),
                const SizedBox(height: 2),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  TenantInviteStatusChip(tenant: t),
                  if (tenantIdStatus(t, todayGst()) case final s?) IdExpiryBadge(status: s),
                ]),
              ]),
              onTap: () => c.push('/tenants/${t.id}/edit'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (t.appUid == null)
                  IconButton(
                    key: Key('invite-${t.id}'),
                    tooltip: c.l.tpInviteToApp,
                    icon: const Icon(Icons.forward_to_inbox_outlined),
                    onPressed: () => showTenantInviteDialog(c, ref, t),
                  ),
                IconButton(
                  tooltip: c.l.delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref.read(tenantRepositoryProvider).delete(t.id),
                ),
              ]),
            ),
          ),
        ),
      );
}

final _eidFormat = RegExp(r'^784-?\d{4}-?\d{7}-?\d$');
final _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Add a tenant, or edit one when [id] is given. Pops with the tenant's id,
/// so a Rent Agreement can select a tenant it just created. [prefill] holds
/// form values (see [FormKeys]) from a scan made elsewhere.
class TenantFormScreen extends ConsumerStatefulWidget {
  const TenantFormScreen({super.key, this.id, this.prefill, this.inviteAfterSave = true});
  final String? id;
  final Map<String, String>? prefill;

  /// Offer the app invite code after adding a tenant. Off when the form was
  /// opened from a rent agreement, which offers it after the agreement is saved.
  final bool inviteAfterSave;
  @override
  ConsumerState<TenantFormScreen> createState() => _TenantFormScreenState();
}

class _TenantFormScreenState extends ConsumerState<TenantFormScreen> {
  final _key = GlobalKey<FormState>();
  final _f = AutoFillFields(const [
    FormKeys.firstName, FormKeys.middleName, FormKeys.lastName, FormKeys.email, FormKeys.phone, FormKeys.emiratesId, FormKeys.passport,
  ]);
  late final DocumentsController _docs;
  Tenant? _existing;
  String? _banner;
  bool _bannerWarning = false;
  DateTime? _eidExpiry, _passportExpiry;
  final _datesFromScan = <String>{};

  @override
  void initState() {
    super.initState();
    _f.onChanged = () => setState(() {});
    _existing = widget.id == null ? null : ref.read(tenantsProvider).value?.where((t) => t.id == widget.id).firstOrNull;
    final t = _existing;
    _docs = DocumentsController(
      kinds: DocumentKinds.tenant,
      required: DocumentKinds.tenantRequired,
      slots: DocumentKinds.tenantSlots,
      existing: t?.documents ?? const [],
    );
    if (t != null) {
      _eidExpiry = t.emiratesIdExpiry;
      _passportExpiry = t.passportExpiry;
      for (final (k, v) in [
        (FormKeys.firstName, t.firstName), (FormKeys.middleName, t.middleName), (FormKeys.lastName, t.lastName),
        (FormKeys.email, t.email), (FormKeys.phone, t.phone), (FormKeys.emiratesId, t.emiratesIdNo), (FormKeys.passport, t.passportNo),
      ]) {
        _f[k].text = v;
      }
    }
    final pre = widget.prefill;
    if (pre != null && pre.isNotEmpty) {
      final dates = newScannedDates(pre, {FormKeys.eidExpiry: _eidExpiry, FormKeys.passportExpiry: _passportExpiry});
      _eidExpiry = dates[FormKeys.eidExpiry] ?? _eidExpiry;
      _passportExpiry = dates[FormKeys.passportExpiry] ?? _passportExpiry;
      _datesFromScan.addAll(dates.keys);
      pre.forEach((k, v) {
        if (dates.containsKey(k) || k == FormKeys.eidExpiry || k == FormKeys.passportExpiry) return;
        _f[k].text = v;
        _f.markFilled(k, v);
      });
    }
  }

  @override
  void dispose() {
    _f.dispose();
    _docs.dispose();
    super.dispose();
  }

  Map<String, String> _labels(AppLocalizations l) => {
        FormKeys.firstName: l.firstName, FormKeys.middleName: l.middleName, FormKeys.lastName: l.lastName,
        FormKeys.email: l.email, FormKeys.phone: l.contactNo, FormKeys.emiratesId: l.emiratesIdNo, FormKeys.passport: l.passportNo,
      };

  Future<void> _onScanned(ScannedDocument doc, XFile file) async {
    final l = context.l;
    final docLabel = scannedKindLabel(l, doc.kind);
    if (isLandlordsOwnId(doc, ref.read(ownIdentityProvider))) {
      // Never fill the landlord's own details in as a tenant.
      await showOwnIdDialog(context, ref, doc);
      if (mounted) {
        setState(() {
          _banner = l.ownIdBody;
          _bannerWarning = true;
        });
      }
      return;
    }
    final values = tenantValues(doc);
    final dates = newScannedDates(values, {FormKeys.eidExpiry: _eidExpiry, FormKeys.passportExpiry: _passportExpiry});
    if (dates.isNotEmpty) {
      setState(() {
        _eidExpiry = dates[FormKeys.eidExpiry] ?? _eidExpiry;
        _passportExpiry = dates[FormKeys.passportExpiry] ?? _passportExpiry;
        _datesFromScan.addAll(dates.keys);
      });
    }
    if (!mounted) return;
    final count = dates.length + await _f.apply(context, values, _labels(l));
    final kind = doc.kind.documentKind;
    if (DocumentKinds.tenant.contains(kind)) await _docs.add(file, kind: kind);
    if (mounted) {
      setState(() {
        _banner = filledSummary(l, count, docLabel);
        _bannerWarning = false;
      });
    }
  }

  String? _idValidator(String? v, {required bool eid}) {
    final l = context.l;
    final s = (v ?? '').trim();
    if (eid && s.isEmpty) return l.required;
    if (eid && !_eidFormat.hasMatch(s.replaceAll(' ', ''))) return l.invalidEmiratesId;
    if (s.isNotEmpty && ref.read(ownIdentityProvider).matches(s)) return l.ownIdTenantError;
    return null;
  }

  Future<void> _save() async {
    final l = context.l;
    final id = _existing?.id ?? newId();
    final docs = await _docs.uploadAll(ref.read(fileStorageProvider), 'tenants/$id', l);
    final details = (
      firstName: _f.text(FormKeys.firstName),
      middleName: _f.text(FormKeys.middleName),
      lastName: _f.text(FormKeys.lastName),
      email: _f.text(FormKeys.email),
      phone: _f.text(FormKeys.phone),
      emiratesIdNo: _f.text(FormKeys.emiratesId),
      passportNo: _f.text(FormKeys.passport),
    );
    // Editing keeps the app link and any invite code.
    final tenant = _existing?.copyDetails(
          firstName: details.firstName,
          middleName: details.middleName,
          lastName: details.lastName,
          email: details.email,
          phone: details.phone,
          emiratesIdNo: details.emiratesIdNo,
          passportNo: details.passportNo,
          documents: docs,
          emiratesIdExpiry: _eidExpiry,
          passportExpiry: _passportExpiry,
        ) ??
        Tenant(
          id: id,
          firstName: details.firstName,
          middleName: details.middleName,
          lastName: details.lastName,
          email: details.email,
          phone: details.phone,
          emiratesIdNo: details.emiratesIdNo,
          passportNo: details.passportNo,
          emiratesIdExpiry: _eidExpiry,
          passportExpiry: _passportExpiry,
          documents: docs,
        );
    await ref.read(tenantRepositoryProvider).save(tenant);
    if (!mounted) return;
    final root = Navigator.of(context, rootNavigator: true).context;
    context.pop(id);
    // Offer the app invite once the form has closed.
    if (_existing == null && widget.inviteAfterSave && root.mounted) unawaited(showTenantInviteDialog(root, ref, tenant));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    Widget text(String k, String label,
            {bool required = false, String? helper, TextInputType? keyboard, String? Function(String?)? validator, IconData? icon}) =>
        TextFormField(
          key: ValueKey('field-$k'),
          controller: _f[k],
          decoration: _f.decoration(context, k, required ? req(label) : label, helper: helper, icon: icon),
          keyboardType: keyboard,
          textInputAction: TextInputAction.next,
          validator: validator ?? (required ? (v) => requiredValidator(context, v) : null),
        );
    return FormPage(
      title: _existing == null ? l.addTenant : l.editTenant,
      formKey: _key,
      onSave: _save,
      header: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ScanToFillButton(hint: l.scanHintTenant, onScanned: _onScanned),
        if (_banner != null) ...[
          const SizedBox(height: 12),
          scanResultBanner(_banner, warning: _bannerWarning, onClose: () => setState(() => _banner = null))!,
        ],
      ]),
      children: [
        FormSection(title: l.sectionPersonal, icon: Icons.person_outline, children: [
          FieldGrid(children: [
            text(FormKeys.firstName, l.firstName, required: true),
            text(FormKeys.middleName, l.middleName),
            text(FormKeys.lastName, l.lastName, required: true),
          ]),
        ]),
        FormSection(title: l.sectionContact, icon: Icons.call_outlined, children: [
          FieldGrid(children: [
            text(FormKeys.phone, l.contactNo, required: true, keyboard: TextInputType.phone, helper: '05X XXX XXXX'),
            text(FormKeys.email, l.email,
                keyboard: TextInputType.emailAddress,
                validator: (v) => (v ?? '').trim().isEmpty || _emailFormat.hasMatch(v!.trim()) ? null : l.invalidEmail),
          ]),
        ]),
        FormSection(title: l.sectionIdentity, icon: Icons.badge_outlined, children: [
          FieldGrid(children: [
            text(FormKeys.emiratesId, l.emiratesIdNo, required: true, helper: '784-XXXX-XXXXXXX-X', validator: (v) => _idValidator(v, eid: true)),
            ExpiryDateField(
              key: const ValueKey('field-eidExpiry'),
              label: l.ixEmiratesIdExpiry,
              value: _eidExpiry,
              highlighted: _datesFromScan.contains(FormKeys.eidExpiry),
              onChanged: (d) => setState(() {
                _eidExpiry = d;
                _datesFromScan.remove(FormKeys.eidExpiry);
              }),
            ),
            text(FormKeys.passport, l.passportNo, validator: (v) => _idValidator(v, eid: false)),
            ExpiryDateField(
              key: const ValueKey('field-passportExpiry'),
              label: l.ixPassportExpiry,
              value: _passportExpiry,
              highlighted: _datesFromScan.contains(FormKeys.passportExpiry),
              onChanged: (d) => setState(() {
                _passportExpiry = d;
                _datesFromScan.remove(FormKeys.passportExpiry);
              }),
            ),
          ]),
        ]),
        FormSection(title: l.sectionDocuments, icon: Icons.folder_open_outlined, children: [
          DocumentSlotsEditor(controller: _docs, notes: {
            DocumentKinds.emiratesId: ExpiryNote(date: _eidExpiry),
            DocumentKinds.passport: ExpiryNote(date: _passportExpiry),
          }),
        ]),
      ],
    );
  }
}

/// "This looks like your own Emirates ID": explains why nothing was filled
/// in as a tenant and offers to keep the numbers on the landlord's profile.
Future<void> showOwnIdDialog(BuildContext context, WidgetRef ref, ScannedDocument doc) async {
  final l = context.l;
  final me = ref.read(landlordProvider).value;
  final eid = doc[ScanField.personEmiratesId] ?? doc[ScanField.tenantEmiratesId];
  final passport = doc[ScanField.personPassport] ?? doc[ScanField.tenantPassport];
  final canSave = me != null && ((eid != null && me.emiratesIdNo.isEmpty) || (passport != null && me.passportNo.isEmpty));
  final save = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.badge_outlined),
      title: Text(l.ownIdTitle),
      content: Text(l.ownIdBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.close)),
        if (canSave) FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.useForMyProfile)),
      ],
    ),
  );
  if (save == true && me != null) {
    await ref.read(landlordRepositoryProvider).save(me.copyWith(
          emiratesIdNo: me.emiratesIdNo.isEmpty ? eid : null,
          passportNo: me.passportNo.isEmpty ? passport : null,
        ));
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.ownIdSaved)));
  }
}
