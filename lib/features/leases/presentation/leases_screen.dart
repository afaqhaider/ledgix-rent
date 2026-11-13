import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/feature_flags.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../domain/lease.dart';

String ejariLabel(AppLocalizations l, EjariStatus s) => switch (s) {
      EjariStatus.active => l.ejariActive,
      EjariStatus.expiring => l.ejariExpiring,
      EjariStatus.expired => l.ejariExpired,
      EjariStatus.unknown => l.ejariUnknown,
    };

Color ejariColor(BuildContext context, EjariStatus s) => switch (s) {
      EjariStatus.active => context.status.success,
      EjariStatus.expiring => context.status.warning,
      EjariStatus.expired => context.status.danger,
      EjariStatus.unknown => context.status.neutral,
    };

IconData ejariIcon(EjariStatus s) => switch (s) {
      EjariStatus.active => Icons.verified_outlined,
      EjariStatus.expiring => Icons.schedule,
      EjariStatus.expired => Icons.error_outline,
      EjariStatus.unknown => Icons.help_outline,
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
      appBar: ShellAppBar(title: Text(context.l.rentAgreements)),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => context.push('/leases/new'),
        icon: const Icon(Icons.add),
        label: Text(context.l.addRentAgreement),
      ),
      body: AsyncList<Lease>(
        items: ref.watch(leasesProvider),
        builder: (c, le) => Card(
          child: ListTile(
            title: Text('${props[le.propertyId] ?? '-'} · ${tenants[le.tenantId] ?? '-'}'),
            subtitle: Text('${formatDate(le.startDate)} → ${formatDate(le.endDate)}\n'
                '${formatAed(le.annualRent)} · ${le.numberOfCheques} × ${methodLabel(c.l, le.paymentMethod)}'),
            isThreeLine: true,
            onTap: () => c.push('/leases/${le.id}/edit'),
            trailing: FeatureFlags.ejari && le.ejariNo.isNotEmpty
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    StatusChip(ejariLabel(c.l, le.ejariStatus), ejariColor(c, le.ejariStatus), icon: ejariIcon(le.ejariStatus)),
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

