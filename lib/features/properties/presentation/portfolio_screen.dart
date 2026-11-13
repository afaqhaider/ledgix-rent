import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/feature_flags.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../landlord/presentation/onboarding_screen.dart';
import '../../leases/domain/lease.dart';
import '../../payments/domain/payment.dart';
import '../../integrations/domain/integration_services.dart';
import '../../servicecharges/domain/service_charge.dart';
import '../../documents/presentation/documents_editor.dart';
import '../domain/property.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leases = ref.watch(leasesProvider).value ?? const <Lease>[];
    final payments = ref.watch(paymentsProvider).value ?? const <Payment>[];
    final today = todayGst();
    return Scaffold(
      appBar: ShellAppBar(title: Text(context.l.properties)),
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

class PropertyDetailScreen extends ConsumerWidget {
  const PropertyDetailScreen({super.key, required this.id});
  final String id;

  Future<void> _addDoc(BuildContext context, WidgetRef ref, Property p) async {
    final l = context.l;
    final kind = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (final k in DocumentKinds.property) ListTile(title: Text(documentKindLabel(l, k)), onTap: () => Navigator.pop(c, k)),
        ]),
      ),
    );
    if (kind == null || !context.mounted) return;
    final file = await pickDocumentFile(context);
    if (file == null) return;
    final url = await ref.read(fileStorageProvider).uploadFile('documents/${p.id}/${newId()}_${file.name}', file);
    await ref.read(propertyRepositoryProvider).save(p.copyWith(
        documents: [...p.documents, AppDocument(name: documentKindLabel(l, kind), url: url, kind: kind)]));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(propertiesProvider).value?.where((x) => x.id == id).firstOrNull;
    if (p == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final l = context.l;
    return Scaffold(
      appBar: ShellAppBar(title: Text(p.name), actions: [
        IconButton(
          tooltip: l.edit,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.push('/property/${p.id}/edit'),
        ),
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
          l.annualRentLabel: p.annualRent == null ? '' : formatAed(p.annualRent!),
          l.titleDeedNo: p.titleDeedNo,
          l.dewaPremiseNo: p.dewaPremiseNo,
          l.dewaAccountNo: p.dewaAccountNo,
          l.mollakRegistrationNo: p.mollakUnitRef,
          l.ownerEmiratesIdNo: p.ownerEmiratesIdNo,
          l.ownerPassportNo: p.ownerPassportNo,
          l.hoaName: p.hoaName,
          l.hoaPhone: p.hoaPhone,
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
            leading: Icon(d.url.toLowerCase().contains('.pdf') ? Icons.picture_as_pdf_outlined : Icons.description_outlined),
            title: Text(documentKindLabel(l, d.kind)),
            onTap: () => showDialog<void>(
              context: context,
              builder: (c) => Dialog(
                child: kIsWeb || d.url.startsWith('http')
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
                switch (c.effectiveStatus(today)) { ChargeStatus.paid => context.status.success, ChargeStatus.overdue => context.status.danger, ChargeStatus.due => context.status.warning },
                icon: switch (c.effectiveStatus(today)) { ChargeStatus.paid => Icons.check_circle_outline, ChargeStatus.overdue => Icons.error_outline, ChargeStatus.due => Icons.schedule },
              ),
            ),
        ]),
      ),
    );
  }
}
