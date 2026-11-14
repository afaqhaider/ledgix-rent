import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/forms.dart';
import '../domain/expiry.dart';

/// Optional expiry date with a picker and a clear button. A date that has
/// already passed is accepted but shown with a warning.
class ExpiryDateField extends StatelessWidget {
  const ExpiryDateField({super.key, required this.label, required this.value, required this.onChanged, this.highlighted = false});
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final today = todayGst();
    final expired = value != null && expiryStatus(value!, today) == ExpiryStatus.expired;
    final warn = context.status.warning;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? today,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          helpText: label,
        );
        if (d != null) onChanged(d);
      },
      child: InputDecorator(
        decoration: autoFillDecoration(
          context,
          InputDecoration(
            labelText: label,
            helperText: expired ? l.ixExpiryAlreadyPassed : null,
            helperStyle: expired ? TextStyle(color: warn, fontWeight: FontWeight.w600) : null,
            suffixIcon: value == null
                ? const Icon(Icons.event_outlined, size: 18)
                : IconButton(
                    tooltip: l.ixClearDate,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onChanged(null),
                  ),
          ),
          highlighted,
        ),
        isEmpty: value == null,
        child: Text(value == null ? '' : formatFormDate(value!)),
      ),
    );
  }
}

Color expiryColor(BuildContext context, ExpiryStatus s) => switch (s) {
      ExpiryStatus.expired => context.status.danger,
      ExpiryStatus.within30 => context.status.warning,
      ExpiryStatus.within60 => context.status.info,
      ExpiryStatus.ok => Theme.of(context).colorScheme.onSurfaceVariant,
    };

/// "Expires 12/03/2028" / "Expired 01/01/2025", coloured by how close it is.
String expiryText(AppLocalizations l, DateTime date, DateTime today) {
  final days = daysUntil(date, today);
  final d = formatFormDate(date);
  if (days < 0) return l.ixExpiredOn(d);
  if (days == 0) return l.ixExpiresToday;
  if (days <= 60) return l.ixExpiresInDays(d, days);
  return l.ixExpiresOn(d);
}

/// Small line under an ID document slot showing its expiry.
class ExpiryNote extends StatelessWidget {
  const ExpiryNote({super.key, required this.date});
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    if (date == null) {
      return Text(l.ixExpiryNotSet, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant));
    }
    final today = todayGst();
    final s = expiryStatus(date!, today);
    final c = expiryColor(context, s);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(s == ExpiryStatus.ok ? Icons.event_available_outlined : Icons.warning_amber_rounded, size: 14, color: c),
      const SizedBox(width: 4),
      Flexible(
        child: Text(expiryText(l, date!, today),
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c, fontWeight: s == ExpiryStatus.ok ? null : FontWeight.w600)),
      ),
    ]);
  }
}

/// Badge for a tenant whose Emirates ID or passport is expired or expiring.
class IdExpiryBadge extends StatelessWidget {
  const IdExpiryBadge({super.key, required this.status});
  final ExpiryStatus status;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = expiryColor(context, status);
    return Container(
      key: const Key('id-expiry-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        border: Border.all(color: c.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.badge_outlined, size: 14, color: c),
        const SizedBox(width: 4),
        Flexible(
          child: Text(status == ExpiryStatus.expired ? l.ixIdExpired : l.ixIdExpiringSoon,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
