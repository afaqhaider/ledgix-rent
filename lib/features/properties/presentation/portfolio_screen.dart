import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../landlord/presentation/onboarding_screen.dart';
import '../../leases/domain/lease.dart';
import '../../payments/domain/payment.dart';
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
      floatingActionButton: FloatingActionButton.extended(
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
  final _c = {for (final k in ['name', 'address', 'community', 'deed', 'dewa']) k: TextEditingController()};
  PropertyType _type = PropertyType.apartment;

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
      floatingActionButton: FloatingActionButton.extended(
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
