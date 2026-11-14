import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/common.dart';
import '../../documents/presentation/id_expiries_card.dart';
import '../../landlord/presentation/onboarding_screen.dart' show landlordProvider;
import '../../leases/domain/lease.dart';
import '../../maintenance/domain/maintenance_ticket.dart';
import '../../maintenance/presentation/maintenance_screen.dart' show ticketStatusLabel;
import '../../holds/domain/hold_request.dart';
import '../../holds/presentation/holds_screen.dart';
import '../../payments/domain/payment.dart';
import '../../payments/presentation/payments_screen.dart' show statusLabel;
import '../domain/dashboard_insights.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final s = ref.watch(dashboardProvider);
    final status = context.status;
    final today = todayGst();
    final payments = ref.watch(paymentsProvider).value ?? const <Payment>[];
    final leases = ref.watch(leasesProvider).value ?? const <Lease>[];
    final properties = ref.watch(propertiesProvider).value ?? const [];
    final tickets = ref.watch(ticketsProvider).value ?? const <MaintenanceTicket>[];
    final propertyName = {for (final p in properties) p.id: p.name};
    final leaseProperty = {for (final x in leases) x.id: propertyName[x.propertyId] ?? ''};

    final occ = occupancy(properties, leases, today);
    final due30 = dueWithin(payments, today, 30);
    final due30Sum = due30.fold(0.0, (a, p) => a + p.amount);
    final monthDue = s.collectedMonth + s.outstandingMonth;

    return Scaffold(
      appBar: ShellAppBar(title: Text(l.dashboard)),
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final pad = c.maxWidth >= 600 ? 24.0 : 16.0;
        final gap = wide ? 20.0 : 16.0;

        final kpis = [
          _Kpi(l.outstandingMonth, formatAed(s.outstandingMonth), Icons.schedule, status.warning),
          _Kpi(l.collectedYear, formatAed(s.collectedYear), Icons.check_circle_outline, status.success),
          _Kpi(l.outstandingYear, formatAed(s.outstandingYear), Icons.pending_actions_outlined, status.warning),
          _Kpi(l.dueNext30, formatAed(due30Sum), Icons.event_outlined, status.info, footnote: l.paymentsCount(due30.length)),
          _Kpi(
            l.occupancy,
            occ.total == 0 ? '—' : '${(occ.occupied * 100 / occ.total).round()}%',
            Icons.apartment_outlined,
            status.success,
            footnote: l.occupiedOf(occ.occupied, occ.total),
          ),
          _Kpi(l.openTickets, '${s.openTickets}', Icons.build_circle_outlined, status.neutral),
        ];

        final upcoming = _UpcomingCard(payments: s.upcoming, propertyOfLease: leaseProperty);
        final chart = _CollectionsCard(months: monthlyCollections(payments, today));
        final actions = const _QuickActionsCard();
        final renewals = _RenewalsCard(leases: upcomingRenewals(leases, today), propertyName: propertyName, today: today);
        final maintenance = _MaintenanceCard(tickets: tickets, propertyName: propertyName);
        final holds = const _HoldRequestsCard();

        return ListView(
          padding: EdgeInsets.fromLTRB(pad, 8, pad, 32),
          children: [
            _Greeting(name: ref.watch(landlordProvider).value?.name ?? ''),
            SizedBox(height: gap),
            if (properties.isEmpty) ...[const _GetStarted(), SizedBox(height: gap)],
            _Hero(label: l.collectedMonth, value: formatAed(s.collectedMonth), collected: s.collectedMonth, due: monthDue),
            SizedBox(height: gap),
            _KpiGrid(kpis: kpis, columns: c.maxWidth >= 560 ? 3 : 2, gap: wide ? 16 : 12),
            SizedBox(height: gap),
            IdExpiriesCard(gap: gap),
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: Column(children: [upcoming, SizedBox(height: gap), chart])),
                SizedBox(width: gap),
                Expanded(
                  flex: 2,
                  child: Column(children: [
                    holds, SizedBox(height: gap), actions, SizedBox(height: gap), renewals, SizedBox(height: gap), maintenance,
                  ]),
                ),
              ])
            else
              for (final w in <Widget>[holds, actions, upcoming, chart, renewals, maintenance]) ...[w, SizedBox(height: gap)],
          ],
        );
      }),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final first = name.trim().split(RegExp(r'\s+')).first;
    final who = first.isEmpty ? l.landlord : first;
    final hour = nowGst().hour;
    final greeting = hour < 12 ? l.goodMorning(who) : (hour < 17 ? l.goodAfternoon(who) : l.goodEvening(who));
    final text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(greeting, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(l.dashboardSubtitle, style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}

/// Amber gradient with this month's collections and how much of the month's
/// rent has cleared. Text stays on the light side of the gradient.
class _Hero extends StatelessWidget {
  const _Hero({required this.label, required this.value, required this.collected, required this.due});
  final String label, value;
  final double collected, due;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final share = due <= 0 ? 0.0 : (collected / due).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(22),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: text.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(value, style: text.headlineMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: share,
                  minHeight: 8,
                  backgroundColor: AppColors.white.withValues(alpha: 0.55),
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('${(share * 100).round()}% · ${formatAed(due)}',
                style: text.bodySmall?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(18)),
          child: const LogoMark(size: 44),
        ),
      ]),
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value, this.icon, this.color, {this.footnote});
  final String label, value;
  final IconData icon;
  final Color color;
  final String? footnote;
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis, required this.columns, required this.gap});
  final List<_Kpi> kpis;
  final int columns;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final k in kpis) SizedBox(width: w, child: _KpiCard(kpi: k)),
        ]);
      });
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});
  final _Kpi kpi;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: kpi.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(kpi.icon, size: 18, color: kpi.color),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(kpi.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: muted))),
          ]),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(kpi.value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 2),
          Text(kpi.footnote ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: muted)),
        ]),
      ),
    );
  }
}

/// Card with a title row (and optional "View all") used for every panel.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, this.subtitle, this.viewAll, this.badge = 0, required this.child, super.key});
  final String title;
  final String? subtitle, viewAll;
  final int badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                  if (badge > 0) ...[
                    const SizedBox(width: 8),
                    Badge(label: Text('$badge'), backgroundColor: context.status.warning),
                  ],
                ]),
                if (subtitle != null)
                  Text(subtitle!, style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ),
            if (viewAll != null) TextButton(onPressed: () => context.go(viewAll!), child: Text(context.l.viewAll)),
          ]),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: child),
        ]),
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

/// Small calendar tile: day number over the month name.
class _DateBadge extends StatelessWidget {
  const _DateBadge(this.date);
  final DateTime date;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text('${date.day}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: scheme.onSecondaryContainer)),
        Text(DateFormat.MMM(locale).format(date), style: TextStyle(fontSize: 11, color: scheme.onSecondaryContainer)),
      ]),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.payments, required this.propertyOfLease});
  final List<Payment> payments;
  final Map<String, String> propertyOfLease;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return _Panel(
      title: l.upcomingCheques,
      viewAll: '/cheques',
      child: payments.isEmpty
          ? _EmptyLine(l.noUpcoming)
          : Column(children: [
              for (var i = 0; i < payments.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _PaymentRow(payment: payments[i], property: propertyOfLease[payments[i].leaseId] ?? ''),
              ],
            ]),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, required this.property});
  final Payment payment;
  final String property;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final text = Theme.of(context).textTheme;
    final color = AppTheme.statusColor(context, payment.status);
    final detail = [
      payment.type == PaymentMethod.cheque ? l.cheque : l.directDebit,
      if (payment.chequeNo.isNotEmpty) '#${payment.chequeNo}',
      if (payment.bankName.isNotEmpty) payment.bankName,
    ].join(' · ');
    return InkWell(
      onTap: () => context.go(payment.type == PaymentMethod.cheque ? '/cheques' : '/debits'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          _DateBadge(payment.dueDate),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(property.isEmpty ? '—' : property,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
            ]),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatAed(payment.amount), style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            StatusChip(statusLabel(l, payment.status), color, icon: AppTheme.statusIcon(payment.status)),
          ]),
        ]),
      ),
    );
  }
}

/// Bar chart of the last six months: full bar = rent due, filled = collected.
class _CollectionsCard extends StatelessWidget {
  const _CollectionsCard({required this.months});
  final List<MonthTotal> months;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final total = months.fold(0.0, (a, m) => a + m.collected);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? AppColors.amber : AppColors.primaryDark;
    if (months.every((m) => m.due == 0)) {
      return _Panel(title: l.collections6m, child: _EmptyLine(l.nothingYet));
    }
    return _Panel(
      title: l.collections6m,
      subtitle: formatAed(total),
      child: Column(children: [
        SizedBox(
          height: 160,
          child: Semantics(
            label: [for (final m in months) '${DateFormat.MMMM(locale).format(m.month)} ${formatAed(m.collected)}'].join(', '),
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarsPainter(
                  months: months,
                  track: scheme.surfaceContainerHighest,
                  fill: fill,
                  rtl: Directionality.of(context) == TextDirection.rtl),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          for (final m in months)
            Expanded(
              child: Text(DateFormat.MMM(locale).format(m.month),
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ),
        ]),
      ]),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.months, required this.track, required this.fill, required this.rtl});
  final List<MonthTotal> months;
  final Color track, fill;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty) return;
    final maxV = months.map((m) => math.max(m.due, m.collected)).fold(0.0, math.max);
    final slot = size.width / months.length;
    final barW = math.min(36.0, slot * 0.5);
    for (var i = 0; i < months.length; i++) {
      final m = months[i];
      // Oldest month on the reading-start side, matching the labels row.
      final slotStart = rtl ? size.width - slot * (i + 1) : slot * i;
      final x = slotStart + (slot - barW) / 2;
      RRect bar(double v) {
        final h = maxV <= 0 ? 0.0 : (v / maxV) * size.height;
        return RRect.fromRectAndCorners(Rect.fromLTWH(x, size.height - h, barW, h),
            topLeft: const Radius.circular(6), topRight: const Radius.circular(6));
      }

      canvas.drawRRect(
          maxV <= 0
              ? RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - 4, barW, 4), const Radius.circular(2))
              : bar(m.due),
          Paint()..color = track);
      if (m.collected > 0) canvas.drawRRect(bar(m.collected), Paint()..color = fill);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.months != months || old.track != track || old.fill != fill || old.rtl != rtl;
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final actions = [
      (Icons.add_home_work_outlined, l.addProperty, '/property/new'),
      (Icons.person_add_alt_outlined, l.addTenant, '/tenants/new'),
      (Icons.note_add_outlined, l.newRentAgreement, '/leases/new'),
      (Icons.payments_outlined, l.recordPayment, '/cheques'),
      (Icons.build_outlined, l.newMaintenanceRequest, '/tickets/new'),
    ];
    return _Panel(
      title: l.quickActions,
      child: Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (icon, label, path) in actions)
          OutlinedButton.icon(
            key: Key('quick-$path'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            onPressed: () => path == '/cheques' ? context.go(path) : context.push(path),
            icon: Icon(icon, size: 18),
            label: Text(label),
          ),
      ]),
    );
  }
}

class _RenewalsCard extends StatelessWidget {
  const _RenewalsCard({required this.leases, required this.propertyName, required this.today});
  final List<Lease> leases;
  final Map<String, String> propertyName;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final status = context.status;
    return _Panel(
      title: l.leaseRenewals,
      subtitle: l.next90Days,
      viewAll: '/leases',
      child: leases.isEmpty
          ? _EmptyLine(l.noRenewals)
          : Column(children: [
              for (final x in leases.take(5))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.event_repeat_outlined),
                  title: Text(propertyName[x.propertyId] ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(formatDate(x.endDate)),
                  trailing: StatusChip(
                    l.endsInDays(x.endDate.difference(today).inDays),
                    x.endDate.difference(today).inDays <= 30 ? status.warning : status.info,
                  ),
                ),
            ]),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({required this.tickets, required this.propertyName});
  final List<MaintenanceTicket> tickets;
  final Map<String, String> propertyName;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final status = context.status;
    final open = tickets.where((t) => !t.isClosedOut).toList();
    const working = {TicketStatus.scheduled, TicketStatus.inProgress};
    final inProgress = open.where((t) => working.contains(t.status)).length;
    return _Panel(
      title: l.maintenance,
      viewAll: '/maintenance',
      child: open.isEmpty
          ? _EmptyLine(l.noOpenTickets)
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                StatusChip('${l.ticketOpen}: ${open.length - inProgress}', status.warning, icon: Icons.inbox_outlined),
                StatusChip('${l.ticketInProgress}: $inProgress', status.info, icon: Icons.engineering_outlined),
              ]),
              const SizedBox(height: 4),
              for (final t in open.take(4))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(Icons.build_circle_outlined,
                      color: t.priority == TicketPriority.urgent || t.priority == TicketPriority.high ? status.danger : null),
                  title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${propertyName[t.propertyId] ?? ''} · ${ticketStatusLabel(l, t.status)}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => context.push('/tickets/${t.id}'),
                ),
            ]),
    );
  }
}

class _GetStarted extends StatelessWidget {
  const _GetStarted();

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.getStartedTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer)),
                const SizedBox(height: 4),
                Text(l.getStartedBody, style: TextStyle(color: scheme.onPrimaryContainer)),
              ]),
            ),
            FilledButton.icon(
              onPressed: () => context.push('/property/new'),
              icon: const Icon(Icons.add_home_work_outlined),
              label: Text(l.addProperty),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pending hold requests (tenants asking to move a payment), with Approve /
/// Decline right on the dashboard.
class _HoldRequestsCard extends ConsumerWidget {
  const _HoldRequestsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final text = Theme.of(context).textTheme;
    final pending = [
      for (final r in ref.watch(holdsProvider).value ?? const <HoldRequest>[])
        if (r.status == HoldStatus.pending) r,
    ]..sort((a, b) => a.originalDate.compareTo(b.originalDate));
    final details = holdDetails(ref, pending);
    return _Panel(
      key: const Key('dashboard-holds'),
      title: l.holdRequests,
      subtitle: pending.isEmpty ? null : l.hrPendingCount(pending.length),
      badge: pending.length,
      viewAll: '/holds',
      child: pending.isEmpty
          ? _EmptyLine(l.hrNonePending)
          : Column(children: [
              for (final r in pending.take(4))
                Padding(
                  key: Key('dashboard-hold-${r.id}'),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          [details[r.id]?.tenantName ?? '', details[r.id]?.propertyName ?? '']
                              .where((s) => s.isNotEmpty)
                              .join(' · '),
                          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (details[r.id]?.payment case final p?)
                        Text(formatAed(p.amount), style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ]),
                    Text(
                      [
                        if (details[r.id]?.payment?.chequeNo case final c? when c.isNotEmpty) '#$c',
                        l.hrMoveTo(formatDate(r.originalDate), formatDate(r.requestedDate)),
                      ].join(' · '),
                      style: text.bodySmall,
                    ),
                    if (r.reason.isNotEmpty)
                      Text('${l.reason}: ${r.reason}', style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    HoldDecisionButtons(request: r, dense: true),
                  ]),
                ),
            ]),
    );
  }
}

