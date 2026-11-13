import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/layout/app_shell.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../domain/tenant.dart';

class TenantsScreen extends ConsumerWidget {
  const TenantsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: ShellAppBar(title: Text(context.l.tenants)),
        floatingActionButton: FloatingActionButton.extended(heroTag: null, 
          onPressed: () => context.push('/tenants/new'),
          icon: const Icon(Icons.person_add),
          label: Text(context.l.addTenant),
        ),
        body: AsyncList<Tenant>(
          items: ref.watch(tenantsProvider),
          builder: (c, t) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(t.name),
              subtitle: Text([t.phone, t.email].where((s) => s.isNotEmpty).join(' · ')),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(tenantRepositoryProvider).delete(t.id),
              ),
            ),
          ),
        ),
      );
}

class TenantFormScreen extends ConsumerStatefulWidget {
  const TenantFormScreen({super.key});
  @override
  ConsumerState<TenantFormScreen> createState() => _TenantFormScreenState();
}

class _TenantFormScreenState extends ConsumerState<TenantFormScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController(), _phone = TextEditingController();
  final _email = TextEditingController(), _eid = TextEditingController();
  String? _passport, _emiratesId;

  Future<String?> _pick(String folder) async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f == null) return null;
    return ref.read(fileStorageProvider).upload('tenants/$folder/${newId()}_${f.name}', f.path);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return FormScaffold(
      title: l.addTenant,
      formKey: _key,
      onSave: () async {
        if (!_key.currentState!.validate()) return;
        await ref.read(tenantRepositoryProvider).save(Tenant(
              id: newId(),
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              email: _email.text.trim(),
              emiratesIdNo: _eid.text.trim(),
              passportCopyUrl: _passport,
              emiratesIdCopyUrl: _emiratesId,
            ));
        if (context.mounted) context.pop();
      },
      children: [
        TextFormField(controller: _name, decoration: InputDecoration(labelText: l.tenantName), validator: (v) => requiredValidator(context, v)),
        TextFormField(controller: _phone, decoration: InputDecoration(labelText: l.phone), keyboardType: TextInputType.phone),
        TextFormField(controller: _email, decoration: InputDecoration(labelText: l.email), keyboardType: TextInputType.emailAddress),
        TextFormField(controller: _eid, decoration: InputDecoration(labelText: l.emiratesIdNo)),
        OutlinedButton.icon(
          icon: Icon(_passport == null ? Icons.attach_file : Icons.check),
          label: Text(_passport == null ? l.attachPassport : l.attached),
          onPressed: () async {
            final u = await _pick('passport');
            if (u != null) setState(() => _passport = u);
          },
        ),
        OutlinedButton.icon(
          icon: Icon(_emiratesId == null ? Icons.attach_file : Icons.check),
          label: Text(_emiratesId == null ? l.attachEmiratesId : l.attached),
          onPressed: () async {
            final u = await _pick('emirates_id');
            if (u != null) setState(() => _emiratesId = u);
          },
        ),
      ],
    );
  }
}
