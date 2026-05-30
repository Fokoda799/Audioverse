// import 'package:flutter/foundation.dart';
// import 'package:Audioverse/features/auth/auth_service.dart';
//
// // State values for auth feature
// enum AuthStatus { initial, loading, success, error }
//
// // AuthProvider
// // Manages state for the auth feature.
// // Call methods from the UI, listen to status/data/errorMessage.
//
// class AuthProvider extends ChangeNotifier {
//   final AuthService _service;
//
//   AuthProvider({required AuthService service})
//       : _service = service;
//
//   AuthStatus _status = AuthStatus.initial;
//    _data;
//   String? _errorMessage;
//
//   AuthStatus get status => _status;
//    get data => _data;
//   String? get errorMessage => _errorMessage;
//   bool get isLoading => _status == AuthStatus.loading;
//
//   // TODO: add your methods here
//   // Example:
//   // Future<void> load(String id) async {
//   //   _setLoading();
//   //   try {
//   //     _data = await _service.fetchById(id);
//   //     _setSuccess();
//   //   } catch (e) {
//   //     _setError(e.toString());
//   //   }
//   // }
//
//   void _setLoading() {
//     _status = AuthStatus.loading;
//     _errorMessage = null;
//     notifyListeners();
//   }
//
//   void _setSuccess() {
//     _status = AuthStatus.success;
//     notifyListeners();
//   }
//
//   void _setError(String message) {
//     _status = AuthStatus.error;
//     _errorMessage = message;
//     notifyListeners();
//   }
// }
