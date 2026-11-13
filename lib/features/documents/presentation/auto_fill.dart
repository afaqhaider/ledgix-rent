import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/common.dart';
import '../../../core/widgets/forms.dart';

/// Text controllers for a form, plus which fields were filled from a scan.
///
/// [apply] fills empty fields straight away and asks before replacing
/// anything the landlord already typed. A highlighted field stops being
/// highlighted as soon as it is edited.
class AutoFillFields {
  AutoFillFields(Iterable<String> keys) {
    for (final k in keys) {
      final c = TextEditingController();
      c.addListener(() {
        if (_filled.containsKey(k) && c.text != _filled[k]) {
          _filled.remove(k);
          onChanged?.call();
        }
      });
      _c[k] = c;
    }
  }

  final _c = <String, TextEditingController>{};
  final _filled = <String, String>{};

  /// Called when highlights change, so the form can rebuild.
  VoidCallback? onChanged;

  TextEditingController operator [](String key) => _c[key]!;
  String text(String key) => _c[key]!.text.trim();
  bool isFilled(String key) => _filled.containsKey(key);

  /// Marks a non-text field (dropdown, date) as filled from a scan.
  void markFilled(String key, [String value = '']) => _filled[key] = value;
  void clearMark(String key) => _filled.remove(key);

  InputDecoration decoration(BuildContext context, String key, String label, {String? helper, String? suffix, IconData? icon}) =>
      autoFillDecoration(
        context,
        InputDecoration(labelText: label, helperText: helper, suffixText: suffix, prefixIcon: icon == null ? null : Icon(icon, size: 20)),
        isFilled(key),
      );

  /// Applies scanned [values]. [labels] names fields in the replace dialog.
  /// Returns how many fields were filled.
  Future<int> apply(BuildContext context, Map<String, String> values, Map<String, String> labels) async {
    final empty = <String, String>{}, conflicts = <String, String>{};
    values.forEach((k, v) {
      final c = _c[k];
      if (c == null || v.trim().isEmpty) return;
      if (c.text.trim().isEmpty) {
        empty[k] = v;
      } else if (c.text.trim() != v.trim()) {
        conflicts[k] = v;
      }
    });
    final replace = conflicts.isEmpty || !context.mounted
        ? <String>{}
        : await showDialog<Set<String>>(
              context: context,
              builder: (_) => ReplaceFieldsDialog(
                current: {for (final k in conflicts.keys) k: _c[k]!.text},
                scanned: conflicts,
                labels: labels,
              ),
            ) ??
            <String>{};
    for (final e in {...empty, for (final k in replace) k: conflicts[k]!}.entries) {
      _filled[e.key] = e.value;
      _c[e.key]!.text = e.value;
    }
    onChanged?.call();
    return empty.length + replace.length;
  }

  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
  }
}

/// Lists fields where the scan differs from what was typed; nothing is
/// replaced unless ticked.
class ReplaceFieldsDialog extends StatefulWidget {
  const ReplaceFieldsDialog({super.key, required this.current, required this.scanned, required this.labels});
  final Map<String, String> current, scanned, labels;

  @override
  State<ReplaceFieldsDialog> createState() => _ReplaceFieldsDialogState();
}

class _ReplaceFieldsDialogState extends State<ReplaceFieldsDialog> {
  final _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AlertDialog(
      title: Text(l.replaceTypedTitle),
      content: SizedBox(
        width: 480,
        child: ListView(shrinkWrap: true, children: [
          Text(l.replaceTypedBody),
          const SizedBox(height: 8),
          for (final k in widget.scanned.keys)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _picked.contains(k),
              onChanged: (v) => setState(() => v == true ? _picked.add(k) : _picked.remove(k)),
              title: Text(widget.labels[k] ?? k),
              subtitle: Text('${widget.current[k]}  →  ${widget.scanned[k]}'),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, <String>{}), child: Text(l.keepMine)),
        FilledButton(onPressed: () => Navigator.pop(context, _picked), child: Text(l.replaceSelected)),
      ],
    );
  }
}

/// Short summary shown after a scan.
String filledSummary(AppLocalizations l, int count, String docLabel) =>
    count == 0 ? l.scanNothingNew(docLabel) : l.scanFilled(count, docLabel);

/// Wraps [FormBanner] for the result of a scan.
Widget? scanResultBanner(String? message, {bool warning = false, Widget? action, VoidCallback? onClose}) =>
    message == null ? null : FormBanner(message: message, warning: warning, action: action, onClose: onClose, icon: warning ? Icons.info_outline : Icons.auto_awesome);
