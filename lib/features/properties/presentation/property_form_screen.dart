import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/forms.dart';
import '../../documents/domain/form_fill.dart';
import '../../documents/domain/scanned_document.dart';
import '../../documents/presentation/auto_fill.dart';
import '../../documents/presentation/document_slots.dart';
import '../../documents/presentation/documents_editor.dart';
import '../../documents/presentation/expiry_widgets.dart';
import '../../documents/presentation/scan_to_fill.dart';
import '../../landlord/presentation/onboarding_screen.dart';
import '../../vendors/domain/vendor.dart';
import '../domain/property.dart';

/// Add a property, or edit one when [id] is given.
class PropertyFormScreen extends ConsumerStatefulWidget {
  const PropertyFormScreen({super.key, this.id});
  final String? id;
  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends ConsumerState<PropertyFormScreen> {
  static const _k = FormKeys.type;
  final _key = GlobalKey<FormState>();
  final _f = AutoFillFields(const [
    FormKeys.name, FormKeys.address, FormKeys.community, FormKeys.annualRent,
    FormKeys.dewaPremise, FormKeys.dewaAccount, FormKeys.mollak, 'chillerProvider', 'chillerNo',
    FormKeys.titleDeed, FormKeys.ownerEid, FormKeys.ownerPassport, 'hoaName', 'hoaPhone',
  ]);
  late final DocumentsController _docs;
  PropertyType? _type;
  String? _defaultVendor;
  Property? _existing;
  String? _banner;
  DateTime? _ownerEidExpiry, _ownerPassportExpiry;
  final _datesFromScan = <String>{};

  @override
  void initState() {
    super.initState();
    _f.onChanged = () => setState(() {});
    _existing = widget.id == null ? null : ref.read(propertiesProvider).value?.where((p) => p.id == widget.id).firstOrNull;
    final p = _existing;
    _docs = DocumentsController(
      kinds: DocumentKinds.property,
      required: DocumentKinds.propertyRequired,
      slots: DocumentKinds.propertySlots,
      existing: p?.documents ?? const [],
    );
    if (p != null) {
      _type = p.type;
      _ownerEidExpiry = p.ownerEmiratesIdExpiry;
      _ownerPassportExpiry = p.ownerPassportExpiry;
      _defaultVendor = p.defaultVendorId;
      for (final (k, v) in [
        (FormKeys.name, p.name), (FormKeys.address, p.address), (FormKeys.community, p.community),
        (FormKeys.annualRent, p.annualRent == null ? '' : _num(p.annualRent!)),
        (FormKeys.dewaPremise, p.dewaPremiseNo), (FormKeys.dewaAccount, p.dewaAccountNo), (FormKeys.mollak, p.mollakUnitRef),
        ('chillerProvider', p.chillerProvider), ('chillerNo', p.chillerAccountNo), (FormKeys.titleDeed, p.titleDeedNo),
        (FormKeys.ownerEid, p.ownerEmiratesIdNo), (FormKeys.ownerPassport, p.ownerPassportNo), ('hoaName', p.hoaName), ('hoaPhone', p.hoaPhone),
      ]) {
        _f[k].text = v;
      }
    }
  }

  static String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _f.dispose();
    _docs.dispose();
    super.dispose();
  }

  Map<String, String> _labels(AppLocalizations l) => {
        FormKeys.name: l.propertyName, FormKeys.address: l.address, FormKeys.community: l.community,
        FormKeys.annualRent: l.annualRentLabel, FormKeys.dewaPremise: l.dewaPremiseNo, FormKeys.dewaAccount: l.dewaAccountNo,
        FormKeys.mollak: l.mollakRegistrationNo, FormKeys.titleDeed: l.titleDeedNo, FormKeys.ownerEid: l.ownerEmiratesIdNo,
        FormKeys.ownerPassport: l.ownerPassportNo,
      };

  Future<void> _onScanned(ScannedDocument doc, XFile file) async {
    final l = context.l;
    final values = propertyValues(doc);
    var count = 0;
    final type = PropertyType.values.where((t) => t.name == values[_k]).firstOrNull;
    if (type != null && type != _type) {
      setState(() => _type = type);
      _f.markFilled(_k, type.name);
      count++;
    }
    values.remove(_k);
    final dates = newScannedDates(values, {
      FormKeys.ownerEidExpiry: _ownerEidExpiry,
      FormKeys.ownerPassportExpiry: _ownerPassportExpiry,
    });
    if (dates.isNotEmpty) {
      setState(() {
        _ownerEidExpiry = dates[FormKeys.ownerEidExpiry] ?? _ownerEidExpiry;
        _ownerPassportExpiry = dates[FormKeys.ownerPassportExpiry] ?? _ownerPassportExpiry;
        _datesFromScan.addAll(dates.keys);
      });
      count += dates.length;
    }
    if (!mounted) return;
    count += await _f.apply(context, values, _labels(l));
    // Keep the scanned file: a standalone ID or passport here is the owner's.
    final kind = switch (doc.kind) {
      ScannedKind.emiratesId => DocumentKinds.ownerEmiratesId,
      ScannedKind.passport => DocumentKinds.ownerPassport,
      _ => doc.kind.documentKind,
    };
    if (!_docs.drafts.any((d) => d.file?.path == file.path && file.path.isNotEmpty)) await _docs.add(file, kind: kind);
    if (mounted) setState(() => _banner = filledSummary(l, count, scannedKindLabel(l, doc.kind)));
  }

  Future<void> _save() async {
    final l = context.l;
    final id = _existing?.id ?? newId();
    final docs = await _docs.uploadAll(ref.read(fileStorageProvider), 'documents/$id', l);
    final mollak = _f.text(FormKeys.mollak);
    final e = _existing;
    await ref.read(propertyRepositoryProvider).save(Property(
          id: id,
          landlordId: e?.landlordId ?? ref.read(authRepositoryProvider).currentUserId ?? '',
          name: _f.text(FormKeys.name),
          type: _type!,
          address: _f.text(FormKeys.address),
          community: _f.text(FormKeys.community),
          annualRent: parseMoney(_f.text(FormKeys.annualRent)),
          dewaPremiseNo: _f.text(FormKeys.dewaPremise),
          dewaAccountNo: _f.text(FormKeys.dewaAccount),
          mollakUnitRef: mollak,
          isJointlyOwned: mollak.isNotEmpty || (e?.isJointlyOwned ?? false),
          chillerProvider: _f.text('chillerProvider'),
          chillerAccountNo: _f.text('chillerNo'),
          titleDeedNo: _f.text(FormKeys.titleDeed),
          ownerEmiratesIdNo: _f.text(FormKeys.ownerEid),
          ownerPassportNo: _f.text(FormKeys.ownerPassport),
          ownerEmiratesIdExpiry: _ownerEidExpiry,
          ownerPassportExpiry: _ownerPassportExpiry,
          hoaName: _f.text('hoaName'),
          hoaPhone: _f.text('hoaPhone'),
          documents: docs,
          defaultVendorId: _defaultVendor,
          utilityPaidBy: e?.utilityPaidBy ?? PaidBy.tenant,
        ));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    Widget text(String k, String label, {bool required = false, String? helper, String? suffix, TextInputType? keyboard, IconData? icon}) =>
        TextFormField(
          key: ValueKey('field-$k'),
          controller: _f[k],
          decoration: _f.decoration(context, k, required ? req(label) : label, helper: helper, suffix: suffix, icon: icon),
          keyboardType: keyboard,
          inputFormatters: suffix == null ? null : moneyInput,
          validator: required ? (v) => requiredValidator(context, v) : null,
          textInputAction: TextInputAction.next,
        );
    return FormPage(
      title: _existing == null ? l.addProperty : l.editProperty,
      formKey: _key,
      onSave: _save,
      header: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ScanToFillButton(hint: l.scanHintProperty, onScanned: _onScanned),
        if (_banner != null) ...[const SizedBox(height: 12), scanResultBanner(_banner, onClose: () => setState(() => _banner = null))!],
      ]),
      children: [
        FormSection(title: l.sectionBasicInfo, icon: Icons.home_work_outlined, children: [
          FieldGrid(children: [
            DropdownButtonFormField<PropertyType>(
              key: const ValueKey('field-type'),
              initialValue: _type,
              decoration: autoFillDecoration(context, InputDecoration(labelText: req(l.propertyType)), _f.isFilled(_k)),
              items: [for (final t in PropertyType.values) DropdownMenuItem(value: t, child: Text(propertyTypeLabel(l, t)))],
              validator: (v) => v == null ? l.required : null,
              onChanged: (t) => setState(() {
                _type = t;
                _f.clearMark(_k);
              }),
            ),
            text(FormKeys.name, l.propertyName, required: true, helper: l.propertyNameHelper),
            FullRow(text(FormKeys.address, l.address, required: true, icon: Icons.place_outlined)),
            text(FormKeys.community, l.community),
            text(FormKeys.annualRent, l.annualRentLabel, suffix: l.aed, keyboard: moneyKeyboard),
          ]),
        ]),
        FormSection(title: l.sectionDewaMollak, icon: Icons.bolt_outlined, children: [
          FieldGrid(children: [
            text(FormKeys.dewaPremise, l.dewaPremiseNo, helper: l.premiseHelper, keyboard: TextInputType.number),
            text(FormKeys.dewaAccount, l.dewaAccountNo, keyboard: TextInputType.number),
            text(FormKeys.mollak, l.mollakRegistrationNo),
            text('chillerProvider', l.chillerProvider),
            text('chillerNo', l.chillerAccountNo),
          ]),
        ]),
        FormSection(title: l.sectionOwnership, icon: Icons.badge_outlined, children: [
          FieldGrid(children: [
            text(FormKeys.titleDeed, l.titleDeedNo),
            text(FormKeys.ownerEid, l.ownerEmiratesIdNo),
            ExpiryDateField(
              key: const ValueKey('field-ownerEidExpiry'),
              label: l.ixOwnerEmiratesIdExpiry,
              value: _ownerEidExpiry,
              highlighted: _datesFromScan.contains(FormKeys.ownerEidExpiry),
              onChanged: (d) => setState(() {
                _ownerEidExpiry = d;
                _datesFromScan.remove(FormKeys.ownerEidExpiry);
              }),
            ),
            text(FormKeys.ownerPassport, l.ownerPassportNo),
            ExpiryDateField(
              key: const ValueKey('field-ownerPassportExpiry'),
              label: l.ixOwnerPassportExpiry,
              value: _ownerPassportExpiry,
              highlighted: _datesFromScan.contains(FormKeys.ownerPassportExpiry),
              onChanged: (d) => setState(() {
                _ownerPassportExpiry = d;
                _datesFromScan.remove(FormKeys.ownerPassportExpiry);
              }),
            ),
          ]),
        ]),
        FormSection(title: l.sectionHoa, icon: Icons.groups_outlined, children: [
          FieldGrid(children: [
            text('hoaName', l.hoaName),
            text('hoaPhone', l.hoaPhone, keyboard: TextInputType.phone),
          ]),
        ]),
        FormSection(title: l.sectionMaintenance, icon: Icons.handyman_outlined, children: [
          FieldGrid(children: [
            DropdownButtonFormField<String>(
              initialValue: _defaultVendor,
              decoration: InputDecoration(labelText: l.defaultCompany),
              items: [
                for (final v in ref.watch(vendorsProvider).value ?? <Vendor>[]) DropdownMenuItem(value: v.id, child: Text(v.name)),
              ],
              onChanged: (v) => _defaultVendor = v,
            ),
          ]),
        ]),
        FormSection(title: l.sectionDocuments, icon: Icons.folder_open_outlined, children: [
          DocumentSlotsEditor(controller: _docs, notes: {
            DocumentKinds.ownerEmiratesId: ExpiryNote(date: _ownerEidExpiry),
            DocumentKinds.ownerPassport: ExpiryNote(date: _ownerPassportExpiry),
          }),
        ]),
      ],
    );
  }
}
