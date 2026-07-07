import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize(
      // Only needed if you don't set it via platform config (Android/iOS)
      serverClientId: dotenv.env['CLIENT_ID'],
    );
    _initialized = true;
  }

  Future<String?> signInAndGetIdToken() async {
    await _ensureInitialized();

    final account = await _googleSignIn.authenticate();
    // authenticate() throws GoogleSignInException if cancelled/failed,
    // rather than returning null like signIn() used to.

    final auth = account.authentication;
    return auth.idToken;
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }
}
