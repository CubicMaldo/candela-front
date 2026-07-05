import 'package:google_sign_in/google_sign_in.dart';

import '../config.dart';

/// Wraps the native Google Sign-In flow and returns the ID token that
/// candela-api validates (POST /api/auth/google[/register]).
class GoogleSignInService {
  /// The button is only shown when the Cloud project is configured.
  static bool get isConfigured => googleServerClientId.isNotEmpty;

  static bool _initialized = false;

  /// Opens the native account picker and returns the Google ID token, or
  /// `null` if the user cancelled. Throws on real failures.
  static Future<String?> obtainIdToken() async {
    if (!isConfigured) return null;

    final signIn = GoogleSignIn.instance;
    if (!_initialized) {
      await signIn.initialize(serverClientId: googleServerClientId);
      _initialized = true;
    }

    try {
      final account = await signIn.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }
}
