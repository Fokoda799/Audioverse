// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'auth.dart';
//
// // AuthService
// // Handles all API calls for the auth feature.
//
// class AuthService {
//   final String _baseUrl;
//   final http.Client _client;
//
//   AuthService({
//     required String baseUrl,
//     http.Client? client,
//   })  : _baseUrl = baseUrl,
//         _client = client ?? http.Client();
//
//   // TODO: add your API methods here
//   // Example:
//   // Future<Auth> fetchById(String id) async {
//   //   final res = await _client.get(Uri.parse('\/auth/\'));
//   //   _throwIfError(res);
//   //   return Auth.fromJson(jsonDecode(res.body));
//   // }
//
//   void _throwIfError(http.Response response) {
//     if (response.statusCode < 200 || response.statusCode >= 300) {
//       final body = jsonDecode(response.body);
//       throw Exception('\: \');
//     }
//   }
// }
