import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/forms.dart';
import '../../documents/presentation/expiry_widgets.dart';
import '../domain/landlord.dart';
import 'onboarding_screen.dart';

/// The landlord's own details. The Emirates ID and passport numbers let the
/// scanner recognise the landlord's documents and never add them as a tenant.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController(), _phone = TextEditingController(), _email = TextEditingController();
  final _eid = TextEditingController(), _passport = TextEditingController();
  Landlord? _me;
  DateTime? _eidExpiry, _passportExpiry;

  @override
  void initState() {
    super.initState();
    _load(ref.read(landlordProvider).value);
  }

  void _load(Landlord? me) {
    if (me == null || _me != null) return;
    _me = me;
    _name.text = me.name;
    _phone.text = me.phone;
    _email.text = me.email;
    _eid.text = me.emiratesIdNo;
    _passport.text = me.passportNo;
    _eidExpiry = me.emiratesIdExpiry;
    _passportExpiry = me.passportExpiry;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _eid, _passport]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l;
    final me = _me ?? Landlord(id: ref.read(authRepositoryProvider).currentUserId ?? 'anon', name: '', language: ref.read(localeProvider));
    await ref.read(landlordRepositoryProvider).save(me
        .copyWith(name: _name.text.trim(), phone: _phone.text.trim(), email: _email.text.trim())
        .withIdentity(
          emiratesIdNo: _eid.text.trim(),
          passportNo: _passport.text.trim(),
          emiratesIdExpiry: _eidExpiry,
          passportExpiry: _passportExpiry,
        ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.profileSaved)));
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    ref.listen(landlordProvider, (_, next) => setState(() => _load(next.value)));
    return FormPage(
      title: l.myProfile,
      formKey: _key,
      onSave: _save,
      children: [
        FormSection(title: l.sectionPersonal, icon: Icons.person_outline, children: [
          FieldGrid(children: [
            TextFormField(controller: _name, decoration: InputDecoration(labelText: req(l.yourName)), validator: (v) => requiredValidator(context, v)),
            TextFormField(controller: _phone, decoration: InputDecoration(labelText: l.contactNo), keyboardType: TextInputType.phone),
            TextFormField(controller: _email, decoration: InputDecoration(labelText: l.email), keyboardType: TextInputType.emailAddress),
          ]),
        ]),
        FormSection(title: l.sectionIdentity, icon: Icons.badge_outlined, subtitle: l.ownIdHelper, children: [
          FieldGrid(children: [
            TextFormField(
              key: const ValueKey('profile-eid'),
              controller: _eid,
              decoration: InputDecoration(labelText: l.myEmiratesIdNo, helperText: '784-XXXX-XXXXXXX-X'),
              validator: (v) {
                final s = (v ?? '').replaceAll(' ', '').trim();
                return s.isEmpty || RegExp(r'^784-?\d{4}-?\d{7}-?\d$').hasMatch(s) ? null : l.invalidEmiratesId;
              },
            ),
            ExpiryDateField(
              key: const ValueKey('profile-eidExpiry'),
              label: l.ixMyEmiratesIdExpiry,
              value: _eidExpiry,
              onChanged: (d) => setState(() => _eidExpiry = d),
            ),
            TextFormField(key: const ValueKey('profile-passport'), controller: _passport, decoration: InputDecoration(labelText: l.myPassportNo)),
            ExpiryDateField(
              key: const ValueKey('profile-passportExpiry'),
              label: l.ixMyPassportExpiry,
              value: _passportExpiry,
              onChanged: (d) => setState(() => _passportExpiry = d),
            ),
          ]),
        ]),
      ],
    );
  }
}
