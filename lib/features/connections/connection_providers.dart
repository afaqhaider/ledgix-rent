import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/connections_service.dart';
import 'domain/connection.dart';

final connectionsServiceProvider =
    Provider<ConnectionsService>((ref) => useFirebase ? FirebaseConnectionsService() : DemoConnectionsService());

String _uid(Ref ref) => ref.watch(userIdProvider).value ?? 'anon';

/// Requests sent to the signed-in person (any status, newest first).
final incomingRequestsProvider =
    StreamProvider<List<ConnectionRequest>>((ref) => ref.watch(connectionsServiceProvider).watchIncoming(_uid(ref)));

/// Requests the signed-in person sent (any status, newest first).
final outgoingRequestsProvider =
    StreamProvider<List<ConnectionRequest>>((ref) => ref.watch(connectionsServiceProvider).watchOutgoing(_uid(ref)));

/// Pending requests waiting for the signed-in person's answer.
final pendingIncomingProvider = Provider<List<ConnectionRequest>>(
    (ref) => [for (final r in ref.watch(incomingRequestsProvider).value ?? const <ConnectionRequest>[]) if (r.isPending) r]);

/// Pending requests the signed-in person is waiting on.
final pendingOutgoingProvider = Provider<List<ConnectionRequest>>(
    (ref) => [for (final r in ref.watch(outgoingRequestsProvider).value ?? const <ConnectionRequest>[]) if (r.isPending) r]);

/// The signed-in person's personal LedGix code.
final myShareCodeProvider = FutureProvider<String>((ref) => ref.watch(connectionsServiceProvider).myShareCode(_uid(ref)));
