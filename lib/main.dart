import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/backend_config.dart';
import 'features/auth/services/google_sign_in_initializer.dart';
import 'services/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.ensureInitialized();
  if (BackendConfig.useFirebase) {
    await GoogleSignInInitializer.ensureInitialized();
  }
  runApp(const ProviderScope(child: LunoraApp()));
}
