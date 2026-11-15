import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/common.dart';
import '../../../core/widgets/forms.dart';
import '../../account/account_providers.dart';
import '../../account/domain/app_user.dart';
import '../../documents/presentation/expiry_widgets.dart';

/// Tenant "My details": their own name, phone, Emirates ID and passport (with
/// expiries), kept on users/{uid}. Shared with a landlord only when the tenant
/// ticks "Share my details" while accepting or sending a request.
class MyDetailsScreen extends ConsumerStatefulWidget {
  const MyDetailsScreen({super.key});
  @override
  ConsumerState<MyDetailsScreen> createState() => _MyDetailsScreenState();
}

class _MyDetailsScreenState extends ConsumerState<MyDetailsScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _eid = TextEditingController();
  final _passport = TextEditingController();
  DateTime? _eidExpiry, _passportExpiry;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    final u = ref.read(appUserProvider).value;
    if (u != null) _load(u);
  }

  void _load(AppUser u) {
    _user = u;
    _name.text = u.name;
    _phone.text = u.phone;
    _eid.text = u.emiratesIdNo;
    _passport.text = u.passportNo;
    _eidExpiry = u.emiratesIdExpiry;
    _passportExpiry = u.passportExpiry;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _eid, _passport]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final u = _user ?? ref.read(appUserProvider).value;
    if (u == null) return;
    await ref.read(accountRepositoryProvider).save(u.copyWith(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          emiratesIdNo: _eid.text.trim(),
          passportNo: _passport.text.trim(),
          emiratesIdExpiry: _eidExpiry,
          passportExpiry: _passportExpiry,
          clearEmiratesIdExpiry: _eidExpiry == null,
          clearPassportExpiry: _passportExpiry == null,
        ));
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l;
    context.pop();
    messenger.showSnackBar(SnackBar(content: Text(l.cxDetailsSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    // The account record can arrive after the screen opens.
    final u = ref.watch(appUserProvider).value;
    if (_user == null && u != null) _load(u);

    Widget field(TextEditingController c, String label, String key, {TextInputType? keyboard, String? helper, bool required = false}) =>
        TextFormField(
          key: ValueKey('my-$key'),
          controller: c,
          keyboardType: keyboard,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: required ? req(label) : label, helperText: helper),
          validator: required ? (v) => requiredValidator(context, v) : null,
        );

    return FormPage(
      title: l.cxMyDetails,
      formKey: _key,
      onSave: _save,
      header: Text(l.cxMyDetailsHint),
      children: [
        FormSection(title: l.sectionPersonal, icon: Icons.person_outline, children: [
          FieldGrid(children: [
            field(_name, l.yourName, 'name', required: true),
            field(_phone, l.contactNo, 'phone', keyboard: TextInputType.phone, helper: '05X XXX XXXX'),
          ]),
        ]),
        FormSection(title: l.sectionIdentity, icon: Icons.badge_outlined, children: [
          FieldGrid(children: [
            field(_eid, l.emiratesIdNo, 'eid', helper: '784-XXXX-XXXXXXX-X'),
            ExpiryDateField(
              key: const ValueKey('my-eidExpiry'),
              label: l.ixEmiratesIdExpiry,
              value: _eidExpiry,
              onChanged: (d) => setState(() => _eidExpiry = d),
            ),
            field(_passport, l.passportNo, 'passport'),
            ExpiryDateField(
              key: const ValueKey('my-passportExpiry'),
              label: l.ixPassportExpiry,
              value: _passportExpiry,
              onChanged: (d) => setState(() => _passportExpiry = d),
            ),
          ]),
        ]),
      ],
    );
  }
}
