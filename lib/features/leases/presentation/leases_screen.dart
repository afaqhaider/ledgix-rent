import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/feature_flags.dart';
import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../payments/domain/payment_scheduler.dart';
import '../domain/lease.dart';

String ejariLabel(AppLocalizations l, EjariStatus s) => switch (s) {
      EjariStatus.active => l.ejariActive,
      EjariStatus.expiring => l.ejariExpiring,
      EjariStatus.expired => l.ejariExpired,
      EjariStatus.unknown => l.ejariUnknown,
    };

Color ejariColor(EjariStatus s) => switch (s) {
      EjariStatus.active => const Color(0xFF1A7F37),
      EjariStatus.expiring => const Color(0xFF9A6700),
      EjariStatus.expired => const Color(0xFFCF222E),
      EjariStatus.unknown => Colors.blueGrey,
    };

String methodLabel(AppLocalizations l, PaymentMethod m) =>
    m == PaymentMethod.cheque ? l.cheque : l.directDebit;

class LeasesScreen extends ConsumerWidget {
  const LeasesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final props = {for (final p in ref.watch(propertiesProvider).value ?? []) p.id: p.name};
    final tenants = {for (final t in ref.watch(tenantsProvider).value ?? []) t.id: t.name};
    return Scaffold(
      appBar: AppBar(title: Text(context.l.leases)),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => context.push('/leases/new'),
        icon: const Icon(Icons.add),
        label: Text(context.l.addLease),
      ),
      body: AsyncList<Lease>(
        items: ref.watch(leasesProvider),
        builder: (c, le) => Card(
          child: ListTile(
            title: Text('${props[le.propertyId] ?? '-'} · ${tenants[le.tenantId] ?? '-'}'),
            subtitle: Text('${formatDate(le.startDate)} → ${formatDate(le.endDate)}\n'
                '${formatAed(le.annualRent)} · ${le.numberOfCheques} × ${methodLabel(c.l, le.paymentMethod)}'),
            isThreeLine: true,
            trailing: FeatureFlags.ejari && le.ejariNo.isNotEmpty
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    StatusChip(ejariLabel(c.l, le.ejariStatus), ejariColor(le.ejariStatus)),
                    GestureDetector(
                      onTap: () async {
                        final r = await ref.read(ejariServiceProvider).lookupContract(le.ejariNo);
                        final now = todayGst();
                        await ref.read(leaseRepositoryProvider).save(le.withEjari(
                            status: EjariStatus.fromExpiry(r.expiry, now), expiry: r.expiry, syncedAt: nowGst()));
                      },
                      child: Text(c.l.verifyEjari, style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
                    ),
                  ])
                : null,
          ),
        ),
      ),
    );
  }
}

class LeaseFormScreen extends ConsumerStatefulWidget {
  const LeaseFormScreen({super.key});
  @override
  ConsumerState<LeaseFormScreen> createState() => _LeaseFormScreenState();
}

class _LeaseFormScreenState extends ConsumerState<LeaseFormScreen> {
  final _key = GlobalKey<FormState>();
  final _rent = TextEditingController(), _deposit = TextEditingController(), _ejari = TextEditingController();
  String? _property, _tenant;
  DateTime _start = todayGst();
  late DateTime _end = addMonths(_start, 12).subtract(const Duration(days: 1));
  int _cheques = 4;
  PaymentMethod _method = PaymentMethod.cheque;
  EjariStatus _ejariStatus = EjariStatus.unknown;
  DateTime? _ejariExpiry, _ejariSynced;

  Future<void> _save() async {
    if (!_key.currentState!.validate() || _property == null || _tenant == null) return;
    final lease = Lease(
      id: newId(),
      propertyId: _property!,
      tenantId: _tenant!,
      startDate: _start,
      endDate: _end,
      annualRent: double.parse(_rent.text),
      securityDeposit: double.tryParse(_deposit.text) ?? 0,
      ejariNo: _ejari.text.trim(),
      numberOfCheques: _cheques,
      paymentMethod: _method,
      ejariStatus: _ejariStatus,
      ejariExpiry: _ejariExpiry,
      ejariLastSynced: _ejariSynced,
    );
    await ref.read(leaseRepositoryProvider).save(lease);
    final payments = ref.read(paymentRepositoryProvider);
    for (final p in PaymentScheduler.generate(lease, newId)) {
      await payments.save(p);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l.scheduleGenerated)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final props = ref.watch(propertiesProvider).value ?? [];
    final tenants = ref.watch(tenantsProvider).value ?? [];
    Widget dateField(String label, DateTime v, ValueChanged<DateTime> set) => ListTile(
          shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.black26), borderRadius: BorderRadius.circular(4)),
          title: Text(label),
          trailing: Text(formatDate(v)),
          onTap: () async {
            final d = await pickDate(context, v);
            if (d != null) setState(() => set(d));
          },
        );
    return FormScaffold(
      title: l.addLease,
      formKey: _key,
      onSave: _save,
      children: [
        if (props.isEmpty || tenants.isEmpty) Text(l.addPropertyFirst),
        DropdownButtonFormField<String>(
          initialValue: _property,
          decoration: InputDecoration(labelText: l.property),
          items: [for (final p in props) DropdownMenuItem(value: p.id, child: Text(p.name))],
          validator: (v) => v == null ? l.required : null,
          onChanged: (v) => _property = v,
        ),
        DropdownButtonFormField<String>(
          initialValue: _tenant,
          decoration: InputDecoration(labelText: l.tenant),
          items: [for (final t in tenants) DropdownMenuItem(value: t.id, child: Text(t.name))],
          validator: (v) => v == null ? l.required : null,
          onChanged: (v) => _tenant = v,
        ),
        dateField(l.startDate, _start, (d) => _start = d),
        dateField(l.endDate, _end, (d) => _end = d),
        TextFormField(
          controller: _rent,
          decoration: InputDecoration(labelText: l.annualRent),
          keyboardType: TextInputType.number,
          validator: (v) => double.tryParse(v ?? '') == null ? l.required : null,
        ),
        TextFormField(controller: _deposit, decoration: InputDecoration(labelText: l.securityDeposit), keyboardType: TextInputType.number),
        TextFormField(controller: _ejari, decoration: InputDecoration(labelText: l.ejariNo)),
        if (FeatureFlags.ejari)
          Row(children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.verified_outlined),
              label: Text(l.verifyEjari),
              onPressed: () async {
                if (_ejari.text.trim().isEmpty) return;
                final r = await ref.read(ejariServiceProvider).lookupContract(_ejari.text.trim());
                setState(() {
                  _ejariExpiry = r.expiry;
                  _ejariStatus = EjariStatus.fromExpiry(r.expiry, todayGst());
                  _ejariSynced = nowGst();
                });
              },
            ),
            const SizedBox(width: 12),
            if (_ejariExpiry != null) ...[
              StatusChip(ejariLabel(l, _ejariStatus), ejariColor(_ejariStatus)),
              const SizedBox(width: 8),
              Flexible(child: Text('${l.ejariExpiry}: ${formatDate(_ejariExpiry!)}', style: const TextStyle(fontSize: 12))),
            ],
          ]),
        DropdownButtonFormField<int>(
          initialValue: _cheques,
          decoration: InputDecoration(labelText: l.numberOfCheques),
          items: [for (final n in [1, 2, 3, 4, 6, 12]) DropdownMenuItem(value: n, child: Text('$n'))],
          onChanged: (v) => _cheques = v ?? _cheques,
        ),
        SegmentedButton<PaymentMethod>(
          segments: [for (final m in PaymentMethod.values) ButtonSegment(value: m, label: Text(methodLabel(l, m)))],
          selected: {_method},
          onSelectionChanged: (s) => setState(() => _method = s.first),
        ),
      ],
    );
  }
}
