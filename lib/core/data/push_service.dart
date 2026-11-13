import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Registers this device for reminders. The Cloud Function reads
/// `landlords/{uid}.fcmTokens` to deliver them.
class PushService {
  /// Web Push (VAPID) public key, passed at build time:
  /// `--dart-define=WEB_VAPID_KEY=...` (see secrets/secrets.txt).
  static const _vapidKey = String.fromEnvironment('WEB_VAPID_KEY');

  static Future<void> register(String uid) async {
    if (kIsWeb && _vapidKey.isEmpty) return; // Web push not configured.
    final m = FirebaseMessaging.instance;
    await m.requestPermission();
    // ignore: deprecated_member_use
    final token = await m.getToken(vapidKey: kIsWeb ? _vapidKey : null);
    if (token == null) return;
    await FirebaseFirestore.instance
        .collection('landlords')
        .doc(uid)
        .set({'fcmTokens': FieldValue.arrayUnion([token])}, SetOptions(merge: true));
  }
}
