import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Registers this device for reminders. The Cloud Function reads
/// `landlords/{uid}.fcmTokens` to deliver them.
class PushService {
  static Future<void> register(String uid) async {
    final m = FirebaseMessaging.instance;
    await m.requestPermission();
    // ignore: deprecated_member_use
    final token = await m.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance
        .collection('landlords')
        .doc(uid)
        .set({'fcmTokens': FieldValue.arrayUnion([token])}, SetOptions(merge: true));
  }
}
