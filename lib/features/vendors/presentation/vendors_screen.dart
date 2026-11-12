import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../domain/vendor.dart';

class VendorsScreen extends ConsumerWidget {
  const VendorsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: Text(context.l.vendors)),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/vendors/new'),
          icon: const Icon(Icons.add),
          label: Text(context.l.addVendor),
        ),
        body: AsyncList<Vendor>(
          items: ref.watch(vendorsProvider),
          builder: (c, v) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.handyman)),
              title: Text(v.name),
              subtitle: Text([v.trade, v.phone].where((s) => s.isNotEmpty).join(' · ')),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(vendorRepositoryProvider).delete(v.id),
              ),
            ),
          ),
        ),
      );
}

class VendorFormScreen extends ConsumerStatefulWidget {
  const VendorFormScreen({super.key});
  @override
  ConsumerState<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends ConsumerState<VendorFormScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController(), _trade = TextEditingController();
  final _phone = TextEditingController(), _notes = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return FormScaffold(
      title: l.addVendor,
      formKey: _key,
      onSave: () async {
        if (!_key.currentState!.validate()) return;
        await ref.read(vendorRepositoryProvider).save(Vendor(
            id: newId(), name: _name.text.trim(), trade: _trade.text.trim(), phone: _phone.text.trim(), notes: _notes.text.trim()));
        if (context.mounted) context.pop();
      },
      children: [
        TextFormField(controller: _name, decoration: InputDecoration(labelText: l.vendorName), validator: (v) => requiredValidator(context, v)),
        TextFormField(controller: _trade, decoration: InputDecoration(labelText: l.trade)),
        TextFormField(controller: _phone, decoration: InputDecoration(labelText: l.phone), keyboardType: TextInputType.phone),
        TextFormField(controller: _notes, decoration: InputDecoration(labelText: l.notes), maxLines: 2),
      ],
    );
  }
}
