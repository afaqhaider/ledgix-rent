import '../../landlord/domain/landlord.dart';
import '../../properties/domain/property.dart';
import '../../tenants/domain/tenant.dart';

/// How close an ID document is to expiring.
enum ExpiryStatus { expired, within30, within60, ok }

/// Which ID document a date belongs to.
enum IdDocType { emiratesId, passport }

/// Whose ID it is.
enum ExpiryHolder { tenant, propertyOwner, me }

/// Days from [today] to [date], counting calendar days only.
int daysUntil(DateTime date, DateTime today) =>
    DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(today.year, today.month, today.day)).inDays;

ExpiryStatus expiryStatus(DateTime date, DateTime today) {
  final d = daysUntil(date, today);
  if (d < 0) return ExpiryStatus.expired;
  if (d <= 30) return ExpiryStatus.within30;
  if (d <= 60) return ExpiryStatus.within60;
  return ExpiryStatus.ok;
}

/// One tracked Emirates ID or passport expiry.
class TrackedExpiry {
  const TrackedExpiry({required this.holder, required this.doc, required this.who, required this.refId, required this.date});
  final ExpiryHolder holder;
  final IdDocType doc;

  /// Tenant name, property name (for an owner) or the landlord's own name.
  final String who;

  /// Tenant id, property id, or the landlord's id.
  final String refId;
  final DateTime date;

  ExpiryStatus status(DateTime today) => expiryStatus(date, today);
  int daysLeft(DateTime today) => daysUntil(date, today);

  /// Where to update it.
  String get route => switch (holder) {
        ExpiryHolder.tenant => '/tenants/$refId/edit',
        ExpiryHolder.propertyOwner => '/property/$refId/edit',
        ExpiryHolder.me => '/profile',
      };
}

/// Every Emirates ID / passport expiry the landlord has recorded: tenants,
/// property owners and the landlord's own, soonest first.
List<TrackedExpiry> trackedExpiries({
  Iterable<Tenant> tenants = const [],
  Iterable<Property> properties = const [],
  Landlord? me,
}) {
  final out = <TrackedExpiry>[
    for (final t in tenants) ...[
      if (t.emiratesIdExpiry != null)
        TrackedExpiry(holder: ExpiryHolder.tenant, doc: IdDocType.emiratesId, who: t.name, refId: t.id, date: t.emiratesIdExpiry!),
      if (t.passportExpiry != null)
        TrackedExpiry(holder: ExpiryHolder.tenant, doc: IdDocType.passport, who: t.name, refId: t.id, date: t.passportExpiry!),
    ],
    for (final p in properties) ...[
      if (p.ownerEmiratesIdExpiry != null)
        TrackedExpiry(holder: ExpiryHolder.propertyOwner, doc: IdDocType.emiratesId, who: p.name, refId: p.id, date: p.ownerEmiratesIdExpiry!),
      if (p.ownerPassportExpiry != null)
        TrackedExpiry(holder: ExpiryHolder.propertyOwner, doc: IdDocType.passport, who: p.name, refId: p.id, date: p.ownerPassportExpiry!),
    ],
    if (me != null) ...[
      if (me.emiratesIdExpiry != null)
        TrackedExpiry(holder: ExpiryHolder.me, doc: IdDocType.emiratesId, who: me.name, refId: me.id, date: me.emiratesIdExpiry!),
      if (me.passportExpiry != null)
        TrackedExpiry(holder: ExpiryHolder.me, doc: IdDocType.passport, who: me.name, refId: me.id, date: me.passportExpiry!),
    ],
  ];
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
}

/// The ones that need attention: expired or expiring within 60 days.
List<TrackedExpiry> expiryAlerts(Iterable<TrackedExpiry> all, DateTime today) =>
    [for (final e in all) if (e.status(today) != ExpiryStatus.ok) e];

/// Worst status among a tenant's own ID documents, or null when both are fine
/// or not recorded. Used for the badge on the tenants list.
ExpiryStatus? tenantIdStatus(Tenant t, DateTime today) {
  final statuses = [
    if (t.emiratesIdExpiry != null) expiryStatus(t.emiratesIdExpiry!, today),
    if (t.passportExpiry != null) expiryStatus(t.passportExpiry!, today),
  ]..sort((a, b) => a.index.compareTo(b.index));
  return statuses.isEmpty || statuses.first == ExpiryStatus.ok ? null : statuses.first;
}
