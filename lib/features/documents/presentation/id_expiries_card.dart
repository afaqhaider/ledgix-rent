import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../landlord/presentation/onboarding_screen.dart' show landlordProvider;
import '../domain/expiry.dart';
import 'expiry_widgets.dart';

/// Every recorded Emirates ID / passport expiry (tenants, property owners and
/// the landlord's own), soonest first.
final trackedExpiriesProvider = Provider<List<TrackedExpiry>>((ref) => trackedExpiries(
      tenants: ref.watch(tenantsProvider).value ?? const [],
      properties: ref.watch(propertiesProvider).value ?? const [],
      me: ref.watch(landlordProvider).value,
    ));

/// Expired or expiring within 60 days: shown on the dashboard and in the bell.
final idExpiryAlertsProvider = Provider<List<TrackedExpiry>>((ref) => expiryAlerts(ref.watch(trackedExpiriesProvider), todayGst()));

String idDocLabel(AppLocalizations l, IdDocType d) => d == IdDocType.emiratesId ? l.ixEmiratesId : l.ixPassport;

/// "Sara Khan" / "Owner · Marina Heights 1203" / "You".
String expiryWho(AppLocalizations l, TrackedExpiry e) => switch (e.holder) {
      ExpiryHolder.tenant => e.who,
      ExpiryHolder.propertyOwner => l.ixOwnerOfProperty(e.who),
      ExpiryHolder.me => l.ixYou,
    };

/// Dashboard card listing expired and soon-to-expire IDs. Takes no space
/// when there is nothing to show. [gap] is the space below it.
class IdExpiriesCard extends ConsumerWidget {
  const IdExpiriesCard({super.key, this.gap = 16});
  final double gap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(idExpiryAlertsProvider);
    if (alerts.isEmpty) return const SizedBox.shrink();
    final l = context.l;
    final today = todayGst();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final expired = alerts.where((e) => e.status(today) == ExpiryStatus.expired).length;
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Card(
        key: const Key('id-expiries-card'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(Icons.badge_outlined, color: expiryColor(context, alerts.first.status(today))),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.ixIdExpiriesTitle, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(l.ixIdExpiriesSubtitle(expired, alerts.length - expired),
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ]),
              ),
            ]),
            const SizedBox(height: 4),
            for (final e in alerts.take(6))
              ListTile(
                key: Key('id-expiry-${e.holder.name}-${e.refId}-${e.doc.name}'),
                contentPadding: const EdgeInsetsDirectional.only(start: 0, end: 4),
                dense: true,
                leading: Icon(e.doc == IdDocType.emiratesId ? Icons.badge_outlined : Icons.flight_takeoff_outlined,
                    color: expiryColor(context, e.status(today))),
                title: Text('${expiryWho(l, e)} · ${idDocLabel(l, e.doc)}', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(expiryText(l, e.date, today),
                    style: TextStyle(color: expiryColor(context, e.status(today)), fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(e.route),
              ),
            if (alerts.length > 6)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(l.ixAndMore(alerts.length - 6), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ),
          ]),
        ),
      ),
    );
  }
}
