import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firestore_paths.dart';

abstract final class PushNotificationService {
  static StreamSubscription<User?>? _authSubscription;
  static StreamSubscription<String>? _tokenSubscription;

  static void start() {
    if (kIsWeb || _authSubscription != null || _tokenSubscription != null) {
      return;
    }
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        unawaited(_registerCurrentDevice(user.uid));
      }
    });
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        unawaited(_saveToken(uid: uid, token: token));
      }
    });
  }

  static Future<void> _registerCurrentDevice(String uid) async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.trim().isNotEmpty) {
        await _saveToken(uid: uid, token: token);
      }
    } catch (e, st) {
      debugPrint('Push notification registration skipped: $e');
      debugPrint('$st');
    }
  }

  static Future<void> _saveToken({
    required String uid,
    required String token,
  }) async {
    final deviceId = sha256.convert(utf8.encode(token)).toString();
    await FirebaseFirestore.instance
        .collection(FirestorePaths.notificationDevices)
        .doc(deviceId)
        .set({
          'userId': uid,
          'token': token,
          'platform': defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
