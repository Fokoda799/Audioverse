import 'package:flutter/foundation.dart';

import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/auth/auth.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider({required AuthRepository repository}) : _repository = repository;

  bool _isLoading = false;
  User? _currentUser;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // ── LOGIN ──────────────────────────────────────────────────
  Future<void> login({required String email, required String password}) async {
    AppLogger.i('Login attempt → $email'); // i: important milestone
    _setLoading();
    try {
      _currentUser = await _repository.login(email: email, password: password);
      _clearError();
    } catch (e, st) {
      AppLogger.e('Login failed → $email', error: e, stackTrace: st);
      _setError(e);
    } finally {
      _stopLoading();
    }
  }

  // ── REGISTER ───────────────────────────────────────────────
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    AppLogger.i('Register attempt → $email');
    _setLoading();
    try {
      _currentUser = await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      AppLogger.i('Register success → user: ${_currentUser?.id}');
      _clearError();
    } catch (e, st) {
      AppLogger.e('Register failed → $email', error: e, stackTrace: st);
      _setError(e);
    } finally {
      _stopLoading();
    }
  }

  // ── LOGOUT ─────────────────────────────────────────────────
  Future<void> logout() async {
    AppLogger.i('Logout → user: ${_currentUser?.id}');
    _setLoading();
    try {
      await _repository.logout();
      _currentUser = null;
      _clearError();
      AppLogger.i('Logout success');
    } catch (e) {
      // w not e: logout errors are non-critical, we still clear locally
      AppLogger.w('Logout server call failed — clearing locally', error: e);
      _currentUser = null;
      _clearError();
    } finally {
      _stopLoading();
    }
  }

  Future<void> deleteAccount(String password) async {
    _setLoading();
    try {
      AppLogger.d("delete");
      final deleted = await _repository.deleteAccount(password);

      if (!deleted) {
        _setError("Password incorrect!");
        return;
      }
      _currentUser = null;
      _clearError();
      AppLogger.i('Logout success');
    } catch (e) {
      AppLogger.w('Delete account failed', error: e);
      _setError(e);
    } finally {
      _stopLoading();
    }
  }

  // ── SEND RESET CODE ────────────────────────────────────────
  // Future<void> sendResetCode({required String email}) async {
  //   AppLogger.d('Sending reset code → $email');  // d: dev detail, not critical
  //   _setLoading();
  //   try {
  //     await _repository.sendResetCode(email: email);
  //     AppLogger.i('Reset code sent → $email');
  //     _clearError();
  //   } catch (e, st) {
  //     AppLogger.e('Send reset code failed', error: e, stackTrace: st);
  //     _setError(e);
  //   } finally {
  //     _stopLoading();
  //   }
  // }

  // ── VERIFY RESET CODE ──────────────────────────────────────
  // Future<void> verifyResetCode({
  //   required String email,
  //   required String code,
  // }) async {
  //   AppLogger.d('Verifying reset code → $email');
  //   _setLoading();
  //   try {
  //     await _repository.verifyResetCode(email: email, code: code);
  //     AppLogger.i('Reset code verified → $email');
  //     _clearError();
  //   } catch (e, st) {
  //     // w not e: wrong code is expected user behavior, not a system error
  //     AppLogger.w('Reset code verification failed → $email', error: e);
  //     _setError(e);
  //   } finally {
  //     _stopLoading();
  //   }
  // }

  // ── RESET PASSWORD ─────────────────────────────────────────
  // Future<void> resetPassword({
  //   required String email,
  //   required String code,
  //   required String newPassword,
  // }) async {
  //   AppLogger.i('Password reset attempt → $email');
  //   _setLoading();
  //   try {
  //     await _repository.resetPassword(
  //         email: email, code: code, newPassword: newPassword);
  //     AppLogger.i('Password reset success → $email');
  //     _clearError();
  //   } catch (e, st) {
  //     AppLogger.e('Password reset failed', error: e, stackTrace: st);
  //     _setError(e);
  //   } finally {
  //     _stopLoading();
  //   }
  // }

  void clearError() {
    AppLogger.d('Error cleared manually');
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void _setError(Object e) {
    _errorMessage = e.toString().replaceAll('Exception: ', '');
  }

  void _clearError() {
    _errorMessage = null;
  }
}
