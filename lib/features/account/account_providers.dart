import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../landlord/presentation/onboarding_screen.dart' show landlordProvider;
import 'data/account_repository.dart';
import 'domain/app_user.dart';

final accountRepositoryProvider =
    Provider<AccountRepository>((ref) => useFirebase ? FirestoreAccountRepository() : InMemoryAccountRepository());

/// The signed-in person's `users/{uid}` record (null until onboarding).
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(userIdProvider).value;
  if (uid == null) return Stream.value(null);
  return ref.watch(accountRepositoryProvider).watch(uid);
});

/// The signed-in role. Landlords who onboarded before roles existed have a
/// landlord profile but no `users` record: they are landlords.
final roleProvider = Provider<AsyncValue<UserRole?>>((ref) {
  final user = ref.watch(appUserProvider);
  final landlord = ref.watch(landlordProvider);
  if (user.isLoading || landlord.isLoading) return const AsyncLoading();
  final role = user.value?.role ?? (landlord.value != null ? UserRole.landlord : null);
  return AsyncData(role);
});

/// Which kind of account "Create account" makes. Chosen on the sign-up
/// screen, read by onboarding.
class SignupRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() => UserRole.landlord;
  void set(UserRole role) => state = role;
}

final signupRoleProvider = NotifierProvider<SignupRoleNotifier, UserRole>(SignupRoleNotifier.new);
