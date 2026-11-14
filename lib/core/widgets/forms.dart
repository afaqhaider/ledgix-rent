import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../layout/app_shell.dart';
import 'common.dart';

/// Width at which forms switch to two fields per row and a sticky Cancel/Save bar.
const wideFormBreakpoint = 720.0;

/// Widest a form's content gets on large screens.
const formMaxWidth = 880.0;

bool isWideForm(BuildContext context) => MediaQuery.sizeOf(context).width >= wideFormBreakpoint;

/// "Label *" for mandatory fields and documents; optional labels stay plain.
String req(String label) => '$label *';

/// Page shell for Add/Edit forms: centred content up to [formMaxWidth],
/// grouped [FormSection]s, and Save that validates, scrolls to the first
/// error, and disables itself while [onSave] runs.
class FormPage extends StatefulWidget {
  const FormPage({
    super.key,
    required this.title,
    required this.formKey,
    required this.onSave,
    required this.children,
    this.header,
    this.saveLabel,
  });

  final String title;
  final GlobalKey<FormState> formKey;

  /// Runs only when the form is valid.
  final Future<void> Function() onSave;
  final List<Widget> children;

  /// Shown above the sections (scan action, banners).
  final Widget? header;
  final String? saveLabel;

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  bool _saving = false;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!widget.formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _scrollToFirstError() {
    final formContext = widget.formKey.currentContext;
    if (formContext == null) return;
    Element? first;
    void visit(Element e) {
      if (first != null) return;
      if (e is StatefulElement && e.state is FormFieldState && (e.state as FormFieldState).hasError) {
        first = e;
        return;
      }
      e.visitChildren(visit);
    }

    formContext.visitChildElements(visit);
    if (first != null) {
      Scrollable.ensureVisible(first!, duration: const Duration(milliseconds: 300), alignment: 0.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final wide = isWideForm(context);
    final save = FilledButton(
      key: const Key('form-save'),
      onPressed: _saving ? null : _submit,
      child: _saving
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(widget.saveLabel ?? l.save),
    );
    return Scaffold(
      appBar: ShellAppBar(title: Text(widget.title)),
      body: Form(
        key: widget.formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 16, vertical: wide ? 24 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: formMaxWidth),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (widget.header != null) ...[widget.header!, const SizedBox(height: 16)],
                for (final c in widget.children) ...[c, const SizedBox(height: 16)],
              ]),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _ActionBar(
        wide: wide,
        save: save,
        cancel: OutlinedButton(onPressed: _saving ? null : () => Navigator.of(context).maybePop(), child: Text(l.cancel)),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.wide, required this.save, required this.cancel});
  final bool wide;
  final Widget save, cancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: scheme.outlineVariant))),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          // heightFactor: 1 keeps the bar as tall as its buttons. A plain Center
          // in a bottomNavigationBar expands to the full page height and leaves
          // the form body with zero height on wide screens.
          child: wide
              ? Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: formMaxWidth),
                    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      cancel,
                      const SizedBox(width: 12),
                      SizedBox(width: 160, child: save),
                    ]),
                  ),
                )
              : SizedBox(width: double.infinity, child: save),
        ),
      ),
    );
  }
}

/// A titled card grouping related fields.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.title, required this.children, this.icon, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final wide = isWideForm(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(wide ? 24 : 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            if (icon != null) ...[Icon(icon, size: 20, color: t.colorScheme.primary), const SizedBox(width: 8)],
            Expanded(child: Text(title, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            ?trailing,
          ]),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 16),
          ...children,
        ]),
      ),
    );
  }
}

/// Marks a [FieldGrid] child that should span the full row.
class FullRow extends StatelessWidget {
  const FullRow(this.child, {super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

/// Two fields per row on wide screens, one per row on phones.
class FieldGrid extends StatelessWidget {
  const FieldGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final wide = isWideForm(context);
    return LayoutBuilder(builder: (context, c) {
      const gap = 16.0;
      final half = wide ? (c.maxWidth - gap) / 2 : c.maxWidth;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final w in children) SizedBox(width: w is FullRow ? c.maxWidth : half, child: w),
      ]);
    });
  }
}

/// Money field input decoration bits: "AED" suffix and numeric keyboard.
const moneyKeyboard = TextInputType.numberWithOptions(decimal: true);
final moneyInput = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];

double? parseMoney(String s) => double.tryParse(s.replaceAll(',', '').trim());

/// Read-only field that opens a date picker.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.label, required this.value, required this.onChanged, this.highlighted = false, this.helper});
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool highlighted;
  final String? helper;

  @override
  Widget build(BuildContext context) => FormField<DateTime>(
        key: ValueKey('$label-${value?.toIso8601String()}'),
        initialValue: value,
        validator: (v) => label.endsWith('*') && v == null ? context.l.required : null,
        builder: (state) => InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final d = await pickDate(context, value ?? DateTime.now());
            if (d != null) {
              state.didChange(d);
              onChanged(d);
            }
          },
          child: InputDecorator(
            decoration: autoFillDecoration(
              context,
              InputDecoration(
                labelText: label,
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                errorText: state.errorText,
                helperText: helper,
              ),
              highlighted,
            ),
            child: Text(value == null ? '' : formatFormDate(value!)),
          ),
        ),
      );
}

String formatFormDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Tints fields that were filled from a scan until the landlord edits them.
InputDecoration autoFillDecoration(BuildContext context, InputDecoration base, bool highlighted) {
  if (!highlighted) return base;
  final scheme = Theme.of(context).colorScheme;
  return base.copyWith(
    filled: true,
    fillColor: scheme.primaryContainer.withValues(alpha: 0.55),
    helperText: base.helperText ?? context.l.filledFromScan,
    helperMaxLines: 2,
    prefixIcon: base.prefixIcon ?? Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
  );
}

/// Inline notice under the scan button ("12 fields filled from Ejari …").
class FormBanner extends StatelessWidget {
  const FormBanner({super.key, required this.message, this.icon = Icons.auto_awesome, this.warning = false, this.action, this.onClose});
  final String message;
  final IconData icon;
  final bool warning;
  final Widget? action;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = warning ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: warning ? scheme.errorContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: fg),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: TextStyle(color: fg))),
        ?action,
        if (onClose != null) IconButton(icon: Icon(Icons.close, color: fg, size: 18), onPressed: onClose, tooltip: context.l.close),
      ]),
    );
  }
}
