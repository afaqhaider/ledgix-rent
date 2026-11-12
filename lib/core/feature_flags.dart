/// Per-environment switches, set at build time, e.g.
/// `flutter run --dart-define=FF_EJARI=false`.
/// Integrations only ever run server-side (Cloud Functions); the app talks to
/// them through the services in lib/features/integrations, which fall back to
/// mock implementations when Firebase is not configured.
class FeatureFlags {
  const FeatureFlags._();

  static const maintenanceForwarding = bool.fromEnvironment('FF_FORWARDING', defaultValue: true);
  static const utilityBills = bool.fromEnvironment('FF_UTILITY_BILLS', defaultValue: true);
  static const ejari = bool.fromEnvironment('FF_EJARI', defaultValue: true);
  static const mollak = bool.fromEnvironment('FF_MOLLAK', defaultValue: true);
}
