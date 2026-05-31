import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:elunai_v00/firebase_options.dart';

import '../../core/config/backend_config.dart';
import '../../core/config/firebase_emulator_config.dart';
import 'push_notification_service.dart';

abstract final class FirebaseBootstrap {
  static Future<void> ensureInitialized() async {
    if (!BackendConfig.useFirebase) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      if (FirebaseEmulatorConfig.enabled) {
        await FirebaseAuth.instance.useAuthEmulator(
          FirebaseEmulatorConfig.host,
          FirebaseEmulatorConfig.authPort,
        );
        FirebaseFirestore.instance.useFirestoreEmulator(
          FirebaseEmulatorConfig.host,
          FirebaseEmulatorConfig.firestorePort,
        );
      }
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: kDebugMode
              ? AndroidProvider.debug
              : AndroidProvider.playIntegrity,
          appleProvider: kDebugMode
              ? AppleProvider.debug
              : AppleProvider.appAttestWithDeviceCheckFallback,
        );
      } catch (e, st) {
        // Firestore and Auth remain usable while App Check configuration is
        // completed in Firebase Console.
        debugPrint('FirebaseAppCheck activation skipped: $e');
        debugPrint('$st');
      }
      PushNotificationService.start();
    } catch (e, st) {
      debugPrint('FirebaseBootstrap: $e');
      debugPrint('$st');
      rethrow;
    }
  }
}
