import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/forms.dart' show req;
import '../../auth/presentation/social_sign_in.dart' show ButtonSpinner;
import '../../account/account_providers.dart';
import '../../account/domain/app_user.dart';
import '../../properties/domain/property.dart';
import '../../tenant_portal/data/tenant_portal.dart';
import '../../tenant_portal/tenant_providers.dart';
import '../domain/landlord.dart';

final landlordProvider = StreamProvider<Landlord?>(
    (ref) => ref.watch(landlordRepositoryProvider).watchAll().map((l) => l.isEmpty ? null : l.first));

/// First run after sign-up. Landlords and property managers give their name,
/// number of units and role; tenants give their name and, optionally, the
/// invite code their landlord shared.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _units = TextEditingController();
  final _code = TextEditingController();
  late bool _tenant = ref.read(signupRoleProvider).isTenant;
  UserRole _role = UserRole.landlord;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _units, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _uid => ref.read(authRepositoryProvider).currentUserId ?? 'anon';

  Future<void> _run(Future<void> Function() job) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await job();
    } on RedeemException catch (e) {
      if (mounted) setState(() => _error = redeemErrorText(context.l, e.reason));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveLandlord() async {
    if (!_key.currentState!.validate()) return;
    await _run(() async {
      final uid = _uid;
      final name = _name.text.trim();
      await ref.read(accountRepositoryProvider).save(
            AppUser(id: uid, role: _role, name: name, unitCount: int.tryParse(_units.text.trim())),
          );
      await ref.read(landlordRepositoryProvider).save(Landlord(id: uid, name: name, language: ref.read(localeProvider)));
    });
  }

  Future<void> _saveTenant({required bool withCode}) async {
    if (!_key.currentState!.validate()) return;
    await _run(() async {
      final uid = _uid;
      final code = _code.text.trim();
      if (withCode && code.isNotEmpty) {
        await ref.read(tenantPortalProvider).redeem(tenantUid: uid, code: code);
      }
      await ref.read(accountRepositoryProvider).save(AppUser(id: uid, role: UserRole.tenant, name: _name.text.trim()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final lang = ref.watch(localeProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: BrandTitle(_tenant ? l.tpTenantWelcome : l.tpSetupTitle)),
      body: Form(
        key: _key,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(_tenant ? l.tpTenantWelcomeSub : l.tpSetupSub, style: text.bodyLarge),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: Text(l.english)),
              ButtonSegment(value: 'ar', label: Text(l.arabic)),
            ],
            selected: {lang},
            onSelectionChanged: (s) => ref.read(localeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Container(
              key: const Key('onboarding-error'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            key: const Key('onboarding-name'),
            controller: _name,
            decoration: InputDecoration(labelText: req(l.yourName), prefixIcon: const Icon(Icons.person_outline)),
            textInputAction: TextInputAction.next,
            validator: (v) => requiredValidator(context, v),
          ),
          const SizedBox(height: 12),
          if (_tenant) ...[
            TextFormField(
              key: const Key('onboarding-code'),
              controller: _code,
              decoration: InputDecoration(
                labelText: l.tpInviteCode,
                helperText: l.tpInviteCodeHint,
                prefixIcon: const Icon(Icons.vpn_key_outlined),
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [LengthLimitingTextInputFormatter(12)],
              onFieldSubmitted: (_) => _saveTenant(withCode: true),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('onboarding-continue'),
              onPressed: _busy ? null : () => _saveTenant(withCode: true),
              child: _busy ? const ButtonSpinner(color: Colors.white) : Text(l.continueLabel),
            ),
            TextButton(
              key: const Key('onboarding-skip'),
              onPressed: _busy ? null : () => _saveTenant(withCode: false),
              child: Text(l.tpSkip),
            ),
          ] else ...[
            TextFormField(
              key: const Key('onboarding-units'),
              controller: _units,
              decoration: InputDecoration(
                labelText: req(l.tpUnits),
                helperText: l.tpUnitsHelper,
                prefixIcon: const Icon(Icons.apartment_outlined),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => (int.tryParse((v ?? '').trim()) ?? 0) >= 1 ? null : l.tpInvalidNumber,
            ),
            const SizedBox(height: 16),
            Text(req(l.tpRole), style: text.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<UserRole>(
              key: const Key('onboarding-role'),
              segments: [
                ButtonSegment(value: UserRole.landlord, label: Text(l.tpRoleLandlord), icon: const Icon(Icons.key_outlined)),
                ButtonSegment(
                    value: UserRole.propertyManager,
                    label: Text(l.tpRolePropertyManager),
                    icon: const Icon(Icons.business_center_outlined)),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('onboarding-continue'),
              onPressed: _busy ? null : _saveLandlord,
              child: _busy ? const ButtonSpinner(color: Colors.white) : Text(l.continueLabel),
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              key: const Key('onboarding-switch-role'),
              icon: Icon(_tenant ? Icons.key_outlined : Icons.person_pin_outlined, size: 18),
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _tenant = !_tenant;
                        _error = null;
                      }),
              label: Text(_tenant ? l.tpImLandlord : l.tpImTenant),
            ),
          ),
        ]),
      ),
    );
  }
}

String redeemErrorText(AppLocalizations l, RedeemError e) => switch (e) {
      RedeemError.invalid => l.tpCodeInvalid,
      RedeemError.expired => l.tpCodeExpired,
      RedeemError.used => l.tpCodeUsed,
      RedeemError.ownCode => l.tpCodeOwn,
      RedeemError.alreadyLinked => l.tpCodeAlreadyLinked,
    };

String propertyTypeLabel(AppLocalizations l, PropertyType t) => switch (t) {
      PropertyType.villa => l.villa,
      PropertyType.apartment => l.apartment,
      PropertyType.studio => l.studio,
      PropertyType.other => l.other,
    };
