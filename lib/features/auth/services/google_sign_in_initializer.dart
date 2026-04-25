import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/social_auth_config.dart';

/// [GoogleSignIn] v7 : [initialize] doit être appelé une fois avant [authenticate].
abstract final class GoogleSignInInitializer {
  static var _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized || !SocialAuthConfig.googleSignInConfigured) return;
    try {
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb ? SocialAuthConfig.googleWebClientId : null,
        serverClientId: SocialAuthConfig.googleServerClientId,
      );
      _initialized = true;
    } catch (e, st) {
      debugPrint('GoogleSignInInitializer: $e\n$st');
    }
  }
}
