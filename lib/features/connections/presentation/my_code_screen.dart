import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/widgets/common.dart';
import '../connection_providers.dart';

/// "My LedGix code": a personal code (and QR) landlords and tenants share
/// instead of typing each other's details. Entering it sends a connection
/// request; nothing links until the other side accepts.
class MyCodeScreen extends ConsumerWidget {
  const MyCodeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final code = ref.watch(myShareCodeProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ShellAppBar(title: Text(l.cxMyCode)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(padding: const EdgeInsets.all(24), shrinkWrap: true, children: [
            Text(l.cxMyCodeHint, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            code.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())),
              error: (e, _) => Text('$e', textAlign: TextAlign.center, style: TextStyle(color: scheme.error)),
              data: (c) => Column(children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: QrImageView(
                    key: const Key('my-code-qr'),
                    data: c,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 20),
                SelectableText(
                  c,
                  key: const Key('my-code-text'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 2),
                ),
                const SizedBox(height: 16),
                Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 8, children: [
                  OutlinedButton.icon(
                    key: const Key('copy-my-code'),
                    icon: const Icon(Icons.copy),
                    label: Text(l.cxCopy),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: c));
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.cxCopied)));
                    },
                  ),
                  FilledButton.icon(
                    key: const Key('share-my-code'),
                    icon: const Icon(Icons.ios_share),
                    label: Text(l.cxShare),
                    onPressed: () => SharePlus.instance.share(ShareParams(text: l.cxShareText(c))),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
