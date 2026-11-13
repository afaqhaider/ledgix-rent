import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/feature_flags.dart';
import '../../inspections/presentation/inspections_screen.dart';
import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/forms.dart';
import '../../documents/domain/form_fill.dart';
import '../../documents/domain/scanned_document.dart';
import '../../documents/presentation/auto_fill.dart';
import '../../documents/presentation/documents_editor.dart';
import '../../documents/presentation/scan_to_fill.dart';
import '../../payments/domain/payment_scheduler.dart';
import '../../properties/domain/property.dart';
import '../../tenants/domain/tenant.dart';
import '../domain/lease.dart';
import 'leases_screen.dart';

const _chequeOptions = [1, 2, 3, 4, 6, 12];

/// Add a rent agreement (lease) for a unit, or edit one when [id] is given.
/// A new agreement also creates its cheque / direct-debit schedule.
class RentAgreementFormScreen extends ConsumerStatefulWidget {
  const RentAgreementFormScreen({super.key, this.id});
  final String? id;
  @override
  ConsumerState<RentAgreementFormScreen> createState() => _RentAgreementFormScreenState();
}

class _RentAgreementFormScreenState extends ConsumerState<RentAgreementFormScreen> {
  final _key = GlobalKey<FormState>();
  final _f = AutoFillFields(const [FormKeys.ejariNo, FormKeys.annualRent, FormKeys.deposit]);
  late final DocumentsController _docs;
  Lease? _existing;
  String? _property, _tenant;
  DateTime? _start, _end;
  int _cheques = 4;
  PaymentMethod _method = PaymentMethod.cheque;
  EjariStatus _ejariStatus = EjariStatus.unknown;
  DateTime? _ejariExpiry, _ejariSynced;

  String? _banner;
  bool _bannerWarning = false;

  /// Tenant details from a scan whose tenant isn't in the app yet.
  Map<String, String>? _scannedTenant;

  @override
  void initState() {
    super.initState();
    _f.onChanged = () => setState(() {});
    _existing = widget.id == null ? null : ref.read(leasesProvider).value?.where((x) => x.id == widget.id).firstOrNull;
    final e = _existing;
    _docs = DocumentsController(kinds: DocumentKinds.agreement, required: DocumentKinds.agreementRequired, existing: e?.documents ?? const []);
    if (e != null) {
      _property = e.propertyId;
      _tenant = e.tenantId;
      _start = e.startDate;
      _end = e.endDate;
      _cheques = e.numberOfCheques;
      _method = e.paymentMethod;
      _ejariStatus = e.ejariStatus;
      _ejariExpiry = e.ejariExpiry;
      _ejariSynced = e.ejariLastSynced;
      _f[FormKeys.ejariNo].text = e.ejariNo;
      _f[FormKeys.annualRent].text = _num(e.annualRent);
      _f[FormKeys.deposit].text = e.securityDeposit == 0 ? '' : _num(e.securityDeposit);
    } else {
      _start = todayGst();
      _end = addMonths(_start!, 12).subtract(const Duration(days: 1));
    }
  }

  static String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _f.dispose();
    _docs.dispose();
    super.dispose();
  }

  Future<void> _addTenant([Map<String, String>? prefill]) async {
    final id = await context.push<String>('/tenants/new', extra: prefill);
    if (id != null && mounted) {
      setState(() {
        _tenant = id;
        if (prefill != null) _scannedTenant = null;
      });
    }
  }

  Future<void> _onScanned(ScannedDocument doc, XFile file) async {
    final l = context.l;
    var count = await _f.apply(context, agreementValues(doc), {
      FormKeys.ejariNo: l.ejariNo, FormKeys.annualRent: l.annualRentLabel, FormKeys.deposit: l.depositLabel,
    });
    final values = agreementValues(doc);
    DateTime? date(String? s) => s == null ? null : DateTime.tryParse(s);
    final start = date(values[FormKeys.start]), end = date(values[FormKeys.end]);
    final cheques = int.tryParse(values[FormKeys.cheques] ?? '');
    setState(() {
      if (start != null && start != _start) {
        _start = start;
        _f.markFilled(FormKeys.start);
        count++;
      }
      if (end != null && end != _end) {
        _end = end;
        _f.markFilled(FormKeys.end);
        count++;
      }
      if (cheques != null && _chequeOptions.contains(cheques) && cheques != _cheques) {
        _cheques = cheques;
        _f.markFilled(FormKeys.cheques);
        count++;
      }
    });

    // Unit: match on DEWA premise number, else on the unit number in the name.
    final props = ref.read(propertiesProvider).value ?? const <Property>[];
    final premise = doc[ScanField.dewaPremiseNo], unit = doc[ScanField.unitNo];
    final match = props.where((p) => premise != null && normalizeId(p.dewaPremiseNo) == normalizeId(premise)).firstOrNull ??
        props.where((p) => unit != null && RegExp('\\b${RegExp.escape(unit)}\\b', caseSensitive: false).hasMatch(p.name)).firstOrNull;
    if (_property == null && match != null) {
      setState(() {
        _property = match.id;
        _f.markFilled('property');
      });
      count++;
    }

    // Tenant: never the landlord; match an existing tenant by ID, else offer to add.
    var warning = false;
    Map<String, String>? scannedTenant;
    if (isLandlordsOwnId(doc, ref.read(ownIdentityProvider))) {
      warning = true;
    } else {
      final ids = tenantIds(doc).map(normalizeId).toSet();
      final tenants = ref.read(tenantsProvider).value ?? const <Tenant>[];
      final existing = tenants
          .where((t) => ids.contains(normalizeId(t.emiratesIdNo)) || (t.passportNo.isNotEmpty && ids.contains(normalizeId(t.passportNo))))
          .firstOrNull;
      if (existing != null) {
        if (_tenant == null) {
          setState(() {
            _tenant = existing.id;
            _f.markFilled('tenant');
          });
          count++;
        }
      } else {
        final t = tenantValues(doc);
        if (t[FormKeys.firstName] != null || t[FormKeys.emiratesId] != null) scannedTenant = t;
      }
    }

    final kind = doc.kind.documentKind;
    if (DocumentKinds.agreement.contains(kind) && kind != DocumentKinds.other) await _docs.add(file, kind: kind);
    if (!mounted) return;
    setState(() {
      _scannedTenant = scannedTenant;
      _bannerWarning = warning;
      _banner = warning
          ? '${filledSummary(l, count, scannedKindLabel(l, doc.kind))} ${l.ownIdAgreementBody}'
          : filledSummary(l, count, scannedKindLabel(l, doc.kind));
    });
  }

  Future<void> _save() async {
    final l = context.l;
    final e = _existing;
    final id = e?.id ?? newId();
    final docs = await _docs.uploadAll(ref.read(fileStorageProvider), 'agreements/$id', l);
    final lease = Lease(
      id: id,
      propertyId: _property!,
      tenantId: _tenant!,
      startDate: _start!,
      endDate: _end!,
      annualRent: parseMoney(_f.text(FormKeys.annualRent))!,
      securityDeposit: parseMoney(_f.text(FormKeys.deposit)) ?? 0,
      ejariNo: _f.text(FormKeys.ejariNo),
      numberOfCheques: _cheques,
      paymentMethod: _method,
      status: e?.status ?? LeaseStatus.active,
      ejariStatus: _ejariStatus,
      ejariExpiry: _ejariExpiry,
      ejariLastSynced: _ejariSynced,
      documents: docs,
    );
    await ref.read(leaseRepositoryProvider).save(lease);
    if (e == null) {
      final payments = ref.read(paymentRepositoryProvider);
      for (final p in PaymentScheduler.generate(lease, newId)) {
        await payments.save(p);
      }
    }
    if (!mounted) return;
    if (e == null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.scheduleGenerated)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final props = ref.watch(propertiesProvider).value ?? const <Property>[];
    final tenants = ref.watch(tenantsProvider).value ?? const <Tenant>[];
    final wide = isWideForm(context);
    InputDecoration deco(String key, String label, {String? suffix, String? helper}) =>
        _f.decoration(context, key, label, suffix: suffix, helper: helper);

    final tenantPicker = DropdownButtonFormField<String>(
      key: ValueKey('tenant-${_tenant ?? ''}-${tenants.length}'),
      initialValue: tenants.any((t) => t.id == _tenant) ? _tenant : null,
      isExpanded: true,
      decoration: autoFillDecoration(
        context,
        InputDecoration(labelText: req(l.tenant), helperText: tenants.isEmpty ? l.noTenantsYet : null),
        _f.isFilled('tenant'),
      ),
      items: [for (final t in tenants) DropdownMenuItem(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis))],
      validator: (v) => v == null ? l.tenantRequired : null,
      onChanged: (v) => setState(() {
        _tenant = v;
        _f.clearMark('tenant');
      }),
    );
    final addTenant = OutlinedButton.icon(
      key: const Key('agreement-add-tenant'),
      onPressed: () => _addTenant(),
      icon: const Icon(Icons.person_add_alt),
      label: Text(l.newTenant),
    );

    return FormPage(
      title: _existing == null ? l.addRentAgreement : l.editRentAgreement,
      formKey: _key,
      onSave: _save,
      header: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ScanToFillButton(hint: l.scanHintAgreement, onScanned: _onScanned),
        if (_banner != null) ...[
          const SizedBox(height: 12),
          scanResultBanner(
            _banner,
            warning: _bannerWarning,
            onClose: () => setState(() => _banner = null),
          )!,
        ],
        if (_scannedTenant != null) ...[
          const SizedBox(height: 12),
          FormBanner(
            icon: Icons.person_add_alt,
            message: l.addScannedTenant([_scannedTenant![FormKeys.firstName], _scannedTenant![FormKeys.lastName]].whereType<String>().join(' ')),
            action: FilledButton(onPressed: () => _addTenant(_scannedTenant), child: Text(l.addTenant)),
            onClose: () => setState(() => _scannedTenant = null),
          ),
        ],
      ]),
      children: [
        FormSection(title: l.sectionUnitTenant, icon: Icons.apartment_outlined, children: [
          FieldGrid(children: [
            DropdownButtonFormField<String>(
              key: ValueKey('property-${_property ?? ''}'),
              initialValue: props.any((p) => p.id == _property) ? _property : null,
              isExpanded: true,
              decoration: autoFillDecoration(context, InputDecoration(labelText: req(l.property)), _f.isFilled('property')),
              items: [for (final p in props) DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))],
              validator: (v) => v == null ? l.required : null,
              onChanged: (v) => setState(() {
                _property = v;
                _f.clearMark('property');
              }),
            ),
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: tenantPicker),
                const SizedBox(width: 8),
                Padding(padding: const EdgeInsets.only(top: 4), child: addTenant),
              ])
            else
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                tenantPicker,
                const SizedBox(height: 8),
                Align(alignment: AlignmentDirectional.centerStart, child: addTenant),
              ]),
          ]),
        ]),
        FormSection(title: l.sectionTermRent, icon: Icons.event_note_outlined, children: [
          FieldGrid(children: [
            TextFormField(key: const ValueKey('field-ejariNo'), controller: _f[FormKeys.ejariNo], decoration: deco(FormKeys.ejariNo, l.ejariNo)),
            if (FeatureFlags.ejari) _ejariCheck(l) else const SizedBox.shrink(),
            DateField(
              label: req(l.startDate),
              value: _start,
              highlighted: _f.isFilled(FormKeys.start),
              onChanged: (d) => setState(() {
                _start = d;
                _f.clearMark(FormKeys.start);
              }),
            ),
            DateField(
              label: req(l.endDate),
              value: _end,
              highlighted: _f.isFilled(FormKeys.end),
              onChanged: (d) => setState(() {
                _end = d;
                _f.clearMark(FormKeys.end);
              }),
            ),
            TextFormField(
              key: const ValueKey('field-annualRent'),
              controller: _f[FormKeys.annualRent],
              decoration: deco(FormKeys.annualRent, req(l.annualRentLabel), suffix: l.aed),
              keyboardType: moneyKeyboard,
              inputFormatters: moneyInput,
              validator: (v) => (parseMoney(v ?? '') ?? 0) <= 0 ? l.required : null,
            ),
            TextFormField(
              key: const ValueKey('field-deposit'),
              controller: _f[FormKeys.deposit],
              decoration: deco(FormKeys.deposit, l.depositLabel, suffix: l.aed),
              keyboardType: moneyKeyboard,
              inputFormatters: moneyInput,
            ),
          ]),
        ]),
        FormSection(
          title: l.sectionPayment,
          icon: Icons.payments_outlined,
          subtitle: _existing == null ? l.scheduleNote : null,
          children: [
            FieldGrid(children: [
              DropdownButtonFormField<int>(
                key: ValueKey('cheques-$_cheques'),
                initialValue: _cheques,
                decoration: autoFillDecoration(context, InputDecoration(labelText: l.numberOfCheques), _f.isFilled(FormKeys.cheques)),
                items: [for (final n in _chequeOptions) DropdownMenuItem(value: n, child: Text('$n'))],
                onChanged: (v) => setState(() {
                  _cheques = v ?? _cheques;
                  _f.clearMark(FormKeys.cheques);
                }),
              ),
              InputDecorator(
                decoration: InputDecoration(labelText: l.paymentMethod, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                child: SegmentedButton<PaymentMethod>(
                  segments: [for (final m in PaymentMethod.values) ButtonSegment(value: m, label: Text(methodLabel(l, m)))],
                  selected: {_method},
                  onSelectionChanged: (s) => setState(() => _method = s.first),
                ),
              ),
            ]),
          ],
        ),
        FormSection(title: l.sectionDocuments, icon: Icons.folder_open_outlined, children: [DocumentsEditor(controller: _docs)]),
        if (_existing != null)
          FormSection(
            title: l.inspections,
            icon: Icons.fact_check_outlined,
            children: [LeaseInspectionsSection(lease: _existing!)],
          ),
      ],
    );
  }

  Widget _ejariCheck(AppLocalizations l) => Row(children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.verified_outlined),
          label: Text(l.verifyEjari),
          onPressed: () async {
            if (_f.text(FormKeys.ejariNo).isEmpty) return;
            final r = await ref.read(ejariServiceProvider).lookupContract(_f.text(FormKeys.ejariNo));
            setState(() {
              _ejariExpiry = r.expiry;
              _ejariStatus = EjariStatus.fromExpiry(r.expiry, todayGst());
              _ejariSynced = nowGst();
            });
          },
        ),
        if (_ejariExpiry != null) ...[
          const SizedBox(width: 8),
          Flexible(child: StatusChip(ejariLabel(l, _ejariStatus), ejariColor(context, _ejariStatus), icon: ejariIcon(_ejariStatus))),
        ],
      ]);
}
