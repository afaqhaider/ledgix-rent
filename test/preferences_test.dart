import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [preferencesProvider.overrideWithValue(prefs)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('defaults when nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await _container();
    expect(c.read(localeProvider), 'en');
    expect(c.read(themeModeProvider), ThemeMode.system);
  });

  test('language and theme are saved and restored on the next launch', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await _container();
    first.read(localeProvider.notifier).set('ar');
    first.read(themeModeProvider.notifier).set(ThemeMode.dark);

    final relaunch = await _container(); // same mock storage, fresh app state
    expect(relaunch.read(localeProvider), 'ar');
    expect(relaunch.read(themeModeProvider), ThemeMode.dark);
  });

  test('ignores unknown saved values', () async {
    SharedPreferences.setMockInitialValues({'locale': 'fr', 'themeMode': 'neon'});
    final c = await _container();
    expect(c.read(localeProvider), 'en');
    expect(c.read(themeModeProvider), ThemeMode.system);
  });

  test('without storage the app still works for the session', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(localeProvider.notifier).set('ar');
    expect(c.read(localeProvider), 'ar');
  });
}
