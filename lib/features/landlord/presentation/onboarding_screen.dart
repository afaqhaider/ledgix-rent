import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../properties/domain/property.dart';
import '../domain/landlord.dart';

final landlordProvider = StreamProvider<Landlord?>(
    (ref) => ref.watch(landlordRepositoryProvider).watchAll().map((l) => l.isEmpty ? null : l.first));

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _property = TextEditingController();
  PropertyType _type = PropertyType.apartment;

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final uid = ref.read(authRepositoryProvider).currentUserId ?? 'anon';
    final lang = ref.read(localeProvider);
    await ref.read(propertyRepositoryProvider).save(
        Property(id: newId(), landlordId: uid, name: _property.text.trim(), type: _type));
    await ref.read(landlordRepositoryProvider).save(Landlord(id: uid, name: _name.text.trim(), language: lang));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final lang = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.welcomeTitle)),
      body: Form(
        key: _key,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(l.welcomeSub),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: Text(l.english)),
              ButtonSegment(value: 'ar', label: Text(l.arabic)),
            ],
            selected: {lang},
            onSelectionChanged: (s) => ref.read(localeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _name, decoration: InputDecoration(labelText: l.yourName), validator: (v) => requiredValidator(context, v)),
          const SizedBox(height: 12),
          TextFormField(controller: _property, decoration: InputDecoration(labelText: l.propertyName), validator: (v) => requiredValidator(context, v)),
          const SizedBox(height: 12),
          DropdownButtonFormField<PropertyType>(
            initialValue: _type,
            decoration: InputDecoration(labelText: l.propertyType),
            items: [for (final t in PropertyType.values) DropdownMenuItem(value: t, child: Text(propertyTypeLabel(l, t)))],
            onChanged: (t) => setState(() => _type = t ?? _type),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: Text(l.continueLabel)),
        ]),
      ),
    );
  }
}

String propertyTypeLabel(AppLocalizations l, PropertyType t) => switch (t) {
      PropertyType.villa => l.villa,
      PropertyType.apartment => l.apartment,
      PropertyType.studio => l.studio,
      PropertyType.other => l.other,
    };
