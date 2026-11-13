import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../landlord/presentation/onboarding_screen.dart';
import '../data/document_scanner.dart';
import '../domain/form_fill.dart';
import '../domain/scanned_document.dart';
import 'documents_editor.dart';

/// Swappable in tests.
final documentScannerProvider = Provider<DocumentScanner>((ref) => DeviceDocumentScanner());

/// The landlord's own ID numbers: profile plus owner details on their properties.
final ownIdentityProvider = Provider<OwnIdentity>((ref) {
  final me = ref.watch(landlordProvider).value;
  final props = ref.watch(propertiesProvider).value ?? const [];
  return OwnIdentity([
    ?me?.emiratesIdNo,
    ?me?.passportNo,
    for (final p in props) ...[p.ownerEmiratesIdNo, p.ownerPassportNo],
  ]);
});

String scannedKindLabel(AppLocalizations l, ScannedKind k) => switch (k) {
      ScannedKind.dewaBill => l.docDewaBill,
      ScannedKind.ejari => l.docEjari,
      ScannedKind.tenancyContract => l.docTenancyContract,
      ScannedKind.titleDeed => l.docTitleDeed,
      ScannedKind.emiratesId => l.docEmiratesIdCopy,
      ScannedKind.passport => l.docPassportCopy,
      ScannedKind.unknown => l.docOther,
    };

/// "Scan to fill": pick a photo or PDF, read it on the device, and hand the
/// result and the file to [onScanned]. Disabled with a note on the web.
class ScanToFillButton extends ConsumerStatefulWidget {
  const ScanToFillButton({super.key, required this.onScanned, required this.hint});
  final Future<void> Function(ScannedDocument doc, XFile file) onScanned;

  /// What this form can read, e.g. "Title deed, DEWA bill, Ejari".
  final String hint;

  @override
  ConsumerState<ScanToFillButton> createState() => _ScanToFillButtonState();
}

class _ScanToFillButtonState extends ConsumerState<ScanToFillButton> {
  bool _busy = false;

  Future<void> _scan() async {
    final l = context.l;
    final file = await ref.read(documentPickerProvider)(context);
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final doc = await ref.read(documentScannerProvider).scan(file);
      if (!mounted) return;
      if (doc.kind == ScannedKind.unknown && doc.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.scanNotRecognised)));
        return;
      }
      setState(() => _busy = false);
      await widget.onScanned(doc, file);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.scanFailed)));
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final supported = ref.watch(documentScannerProvider).isSupported;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerLow,
      ),
      child: Row(children: [
        Icon(Icons.document_scanner_outlined, color: scheme.primary, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.scanToFill, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(supported ? widget.hint : l.scanWebNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          key: const Key('scan-to-fill'),
          onPressed: supported && !_busy ? _scan : null,
          icon: _busy
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.document_scanner_outlined),
          label: Text(_busy ? l.scanning : l.scan),
        ),
      ]),
    );
  }
}
