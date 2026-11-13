import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../maintenance/domain/maintenance_ticket.dart';
import '../../maintenance/presentation/maintenance_screen.dart';
import '../domain/vendor.dart';

class VendorsScreen extends ConsumerWidget {
  const VendorsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: ShellAppBar(title: Text(context.l.vendors)),
        floatingActionButton: FloatingActionButton.extended(heroTag: null, 
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
              subtitle: Text([v.trade, v.phone, if (v.usesApp) 'LedGix'].where((s) => s.isNotEmpty).join(' · ')),
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
  final _licence = TextEditingController(), _contact = TextEditingController(), _email = TextEditingController();
  final _services = TextEditingController(), _areas = TextEditingController(), _linked = TextEditingController();
  final _defaults = <TicketCategory>{};

  List<String> _split(String s) => [for (final e in s.split(',')) if (e.trim().isNotEmpty) e.trim()];

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return FormScaffold(
      title: l.addVendor,
      formKey: _key,
      onSave: () async {
        if (!_key.currentState!.validate()) return;
        await ref.read(vendorRepositoryProvider).save(Vendor(
            id: newId(),
            name: _name.text.trim(),
            trade: _trade.text.trim(),
            phone: _phone.text.trim(),
            notes: _notes.text.trim(),
            tradeLicenceNo: _licence.text.trim(),
            contactPerson: _contact.text.trim(),
            email: _email.text.trim(),
            services: _split(_services.text),
            areasCovered: _split(_areas.text),
            linkedAccountId: _linked.text.trim().isEmpty ? null : _linked.text.trim(),
            defaultCategories: [for (final c in _defaults) c.name]));
        if (context.mounted) context.pop();
      },
      children: [
        TextFormField(controller: _name, decoration: InputDecoration(labelText: l.vendorName), validator: (v) => requiredValidator(context, v)),
        TextFormField(controller: _trade, decoration: InputDecoration(labelText: l.trade)),
        TextFormField(controller: _phone, decoration: InputDecoration(labelText: l.phone), keyboardType: TextInputType.phone),
        TextFormField(controller: _contact, decoration: InputDecoration(labelText: l.contactPerson)),
        TextFormField(controller: _email, decoration: InputDecoration(labelText: l.email), keyboardType: TextInputType.emailAddress),
        TextFormField(controller: _licence, decoration: InputDecoration(labelText: l.tradeLicenceNo)),
        TextFormField(controller: _services, decoration: InputDecoration(labelText: l.services)),
        TextFormField(controller: _areas, decoration: InputDecoration(labelText: l.areasCovered)),
        TextFormField(controller: _linked, decoration: InputDecoration(labelText: l.linkedAccount)),
        Text(l.defaultForCategories),
        Wrap(spacing: 8, children: [
          for (final c in TicketCategory.values)
            FilterChip(
              label: Text(categoryLabel(l, c)),
              selected: _defaults.contains(c),
              onSelected: (v) => setState(() => v ? _defaults.add(c) : _defaults.remove(c)),
            ),
        ]),
        TextFormField(controller: _notes, decoration: InputDecoration(labelText: l.notes), maxLines: 2),
      ],
    );
  }
}
