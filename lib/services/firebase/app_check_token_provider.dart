import 'package:firebase_app_check/firebase_app_check.dart';

abstract final class AppCheckTokenProvider {
  static Future<String?> getToken() async {
    try {
      return await FirebaseAppCheck.instance.getToken();
    } catch (_) {
      return null;
    }
  }
}
