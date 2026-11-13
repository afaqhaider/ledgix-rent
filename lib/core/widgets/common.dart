import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/gen/app_localizations.dart';

export '../l10n/gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this)!;
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(context.l.nothingYet, style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
}

/// Renders an AsyncValue list or a spinner / empty state.
class AsyncList<T> extends StatelessWidget {
  const AsyncList({super.key, required this.items, required this.builder});
  final AsyncValue<List<T>> items;
  final Widget Function(BuildContext, T) builder;

  @override
  Widget build(BuildContext context) {
    final data = items.value;
    if (data == null) return const Center(child: CircularProgressIndicator());
    if (data.isEmpty) return const EmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (c, i) => builder(c, data[i]),
    );
  }
}

/// Coloured status label. Pass [icon] so the status is not shown by colour alone.
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, this.color, {super.key, this.icon});
  final String label;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 10, 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ]),
      );
}

String? requiredValidator(BuildContext c, String? v) =>
    (v == null || v.trim().isEmpty) ? c.l.required : null;

Future<DateTime?> pickDate(BuildContext c, DateTime initial) => showDatePicker(
      context: c,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

/// Shell for "add" forms.
class FormScaffold extends StatelessWidget {
  const FormScaffold({super.key, required this.title, required this.formKey, required this.children, required this.onSave});
  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final c in children) Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
              FilledButton(onPressed: onSave, child: Text(context.l.save)),
            ],
          ),
        ),
      );
}
