import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize(
      serverClientId: "501882629900-2j61ngt5h1vfqka8r06dllc0iornn7i2.apps.googleusercontent.com"
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
