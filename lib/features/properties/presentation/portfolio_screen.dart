import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/feature_flags.dart';
import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../landlord/presentation/onboarding_screen.dart';
import '../../leases/domain/lease.dart';
import '../../payments/domain/payment.dart';
import '../../integrations/domain/integration_services.dart';
import '../../servicecharges/domain/service_charge.dart';
import '../../vendors/domain/vendor.dart';
import '../domain/property.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leases = ref.watch(leasesProvider).value ?? const <Lease>[];
    final payments = ref.watch(paymentsProvider).value ?? const <Payment>[];
    final today = todayGst();
    return Scaffold(
      appBar: AppBar(title: Text(context.l.portfolio)),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => context.push('/property/new'),
        icon: const Icon(Icons.add),
        label: Text(context.l.addProperty),
      ),
      body: AsyncList<Property>(
        items: ref.watch(propertiesProvider),
        builder: (c, p) {
          final active = leases.where((l) =>
              l.propertyId == p.id && l.status == LeaseStatus.active && !l.endDate.isBefore(today));
          final ids = active.map((l) => l.id).toSet();
          final next = (payments
                  .where((x) => ids.contains(x.leaseId) && !x.isSettled)
                  .toList()
                ..sort((a, b) => a.dueDate.compareTo(b.dueDate)))
              .firstOrNull;
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(p.name, style: Theme.of(c).textTheme.titleMedium),
              subtitle: Text([
                propertyTypeLabel(c.l, p.type),
                if (p.community.isNotEmpty) p.community,
                active.isEmpty ? c.l.vacant : c.l.occupied,
                if (next != null) '${c.l.nextDue}: ${formatDate(next.dueDate)} · ${formatAed(next.amount)}',
              ].join(' · ')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => c.push('/property/${p.id}'),
            ),
          );
        },
      ),
    );
  }
}

class PropertyFormScreen extends ConsumerStatefulWidget {
  const PropertyFormScreen({super.key});
  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends ConsumerState<PropertyFormScreen> {
  final _key = GlobalKey<FormState>();
  final _c = {for (final k in ['name', 'address', 'community', 'deed', 'dewa', 'chillerProvider', 'chillerNo', 'mollak']) k: TextEditingController()};
  PropertyType _type = PropertyType.apartment;
  bool _jointly = false;
  String? _defaultVendor;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    Widget f(String k, String label, {bool req = false}) => TextFormField(
        controller: _c[k], decoration: InputDecoration(labelText: label),
        validator: req ? (v) => requiredValidator(context, v) : null);
    return FormScaffold(
      title: l.addProperty,
      formKey: _key,
      onSave: () async {
        if (!_key.currentState!.validate()) return;
        await ref.read(propertyRepositoryProvider).save(Property(
              id: newId(),
              landlordId: ref.read(authRepositoryProvider).currentUserId ?? '',
              name: _c['name']!.text.trim(),
              type: _type,
              address: _c['address']!.text.trim(),
              community: _c['community']!.text.trim(),
              titleDeedNo: _c['deed']!.text.trim(),
              dewaAccountNo: _c['dewa']!.text.trim(),
              chillerProvider: _c['chillerProvider']!.text.trim(),
              chillerAccountNo: _c['chillerNo']!.text.trim(),
              isJointlyOwned: _jointly,
              mollakUnitRef: _jointly ? _c['mollak']!.text.trim() : '',
              defaultVendorId: _defaultVendor,
            ));
        if (context.mounted) context.pop();
      },
      children: [
        f('name', l.propertyName, req: true),
        DropdownButtonFormField<PropertyType>(
          initialValue: _type,
          decoration: InputDecoration(labelText: l.propertyType),
          items: [for (final t in PropertyType.values) DropdownMenuItem(value: t, child: Text(propertyTypeLabel(l, t)))],
          onChanged: (t) => setState(() => _type = t ?? _type),
        ),
        f('address', l.address),
        f('community', l.community),
        f('deed', l.titleDeedNo),
        f('dewa', l.dewaAccountNo),
        f('chillerProvider', l.chillerProvider),
        f('chillerNo', l.chillerAccountNo),
        if (FeatureFlags.mollak) ...[
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l.jointlyOwned), value: _jointly, onChanged: (v) => setState(() => _jointly = v)),
          if (_jointly) f('mollak', l.mollakUnitRef),
        ],
        DropdownButtonFormField<String>(
          initialValue: _defaultVendor,
          decoration: InputDecoration(labelText: l.defaultCompany),
          items: [
            for (final v in ref.watch(vendorsProvider).value ?? <Vendor>[]) DropdownMenuItem(value: v.id, child: Text(v.name)),
          ],
          onChanged: (v) => _defaultVendor = v,
        ),
      ],
    );
  }
}

class PropertyDetailScreen extends ConsumerWidget {
  const PropertyDetailScreen({super.key, required this.id});
  final String id;

  Future<void> _addDoc(BuildContext context, WidgetRef ref, Property p) async {
    final l = context.l;
    final kinds = {
      'lease': l.docLease,
      'ejari': l.docEjari,
      'titleDeed': l.docTitleDeed,
      'emiratesId': l.docEmiratesId,
    };
    final kind = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final e in kinds.entries) ListTile(title: Text(e.value), onTap: () => Navigator.pop(c, e.key)),
        ]),
      ),
    );
    if (kind == null) return;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final url = await ref.read(fileStorageProvider).upload('documents/${p.id}/${newId()}_${file.name}', file.path);
    await ref.read(propertyRepositoryProvider).save(p.copyWith(
        documents: [...p.documents, PropertyDocument(name: kinds[kind]!, url: url, kind: kind)]));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(propertiesProvider).value?.where((x) => x.id == id).firstOrNull;
    if (p == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(p.name), actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await ref.read(propertyRepositoryProvider).delete(p.id);
            if (context.mounted) context.pop();
          },
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => _addDoc(context, ref, p),
        icon: const Icon(Icons.upload_file),
        label: Text(l.addDocument),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final e in {
          l.propertyType: propertyTypeLabel(l, p.type),
          l.address: p.address,
          l.community: p.community,
          l.titleDeedNo: p.titleDeedNo,
          l.dewaAccountNo: p.dewaAccountNo,
        }.entries.where((e) => e.value.isNotEmpty))
          ListTile(dense: true, title: Text(e.key), trailing: Text(e.value)),
        if (FeatureFlags.utilityBills)
          ListTile(
            leading: const Icon(Icons.bolt_outlined),
            title: Text(l.utilityBills),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/property/${p.id}/bills'),
          ),
        if (FeatureFlags.mollak && p.isJointlyOwned) ServiceChargeCard(property: p),
        const Divider(),
        Text(l.documents, style: Theme.of(context).textTheme.titleMedium),
        if (p.documents.isEmpty) const EmptyState(),
        for (final d in p.documents)
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(d.name),
            onTap: () => showDialog<void>(
              context: context,
              builder: (c) => Dialog(
                child: d.url.startsWith('http')
                    ? Image.network(d.url, errorBuilder: (_, _, _) => const Icon(Icons.broken_image))
                    : Image.file(File(d.url), errorBuilder: (_, _, _) => const Icon(Icons.broken_image)),
              ),
            ),
          ),
      ]),
    );
  }
}


String chargeStatusLabel(AppLocalizations l, ChargeStatus s) =>
    switch (s) { ChargeStatus.due => l.dueStatus, ChargeStatus.paid => l.chargePaid, ChargeStatus.overdue => l.chargeOverdue };

/// Service charges of a jointly owned building, synced from Mollak.
class ServiceChargeCard extends ConsumerWidget {
  const ServiceChargeCard({super.key, required this.property});
  final Property property;

  Future<void> _sync(WidgetRef ref) async {
    final repo = ref.read(serviceChargeRepositoryProvider);
    final existing = (await repo.watchAll().first).where((c) => c.propertyId == property.id).toList();
    final MollakService mollak = ref.read(mollakServiceProvider);
    for (final c in await mollak.getServiceCharges(property.mollakUnitRef)) {
      final prev = existing.where((e) => e.period == c.period).firstOrNull;
      await repo.save(ServiceCharge(
        id: prev?.id ?? newId(),
        propertyId: property.id,
        period: c.period,
        amount: c.amount,
        dueDate: c.dueDate,
        status: c.paid ? ChargeStatus.paid : ChargeStatus.due,
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final today = todayGst();
    final charges = (ref.watch(serviceChargesProvider).value ?? [])
        .where((c) => c.propertyId == property.id)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final outstanding = charges.where((c) => c.status != ChargeStatus.paid).fold<double>(0, (a, c) => a + c.amount);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(l.serviceCharges, style: Theme.of(context).textTheme.titleMedium)),
            TextButton.icon(
              icon: const Icon(Icons.sync),
              label: Text(l.syncMollak),
              onPressed: property.mollakUnitRef.isEmpty ? null : () => _sync(ref),
            ),
          ]),
          if (charges.isNotEmpty) Text('${l.outstanding}: ${formatAed(outstanding)}'),
          for (final c in charges)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${c.period} · ${formatAed(c.amount)}'),
              subtitle: Text('${l.dueDate}: ${formatDate(c.dueDate)}'),
              trailing: StatusChip(
                chargeStatusLabel(l, c.effectiveStatus(today)),
                switch (c.effectiveStatus(today)) { ChargeStatus.paid => Colors.green, ChargeStatus.overdue => Colors.red, ChargeStatus.due => Colors.orange },
              ),
            ),
        ]),
      ),
    );
  }
}
