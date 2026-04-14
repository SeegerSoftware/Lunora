import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:lunora_v00/firebase_options.dart';

import '../../core/config/backend_config.dart';

abstract final class FirebaseBootstrap {
  static Future<void> ensureInitialized() async {
    if (!BackendConfig.useFirebase) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e, st) {
      debugPrint('FirebaseBootstrap: $e');
      debugPrint('$st');
      rethrow;
    }
  }
}
