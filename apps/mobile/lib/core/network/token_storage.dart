import 'dart:convert';                    // jsonEncode / jsonDecode

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/auth/auth_models.dart';

// ─────────────────────────────────────────────────────────────
// TokenStorage
//
// Stores three things persistently on the device:
//   1. access_token  → sent with every API request
//   2. refresh_token → used to get a new access token silently
//   3. user          → cached so the app restores instantly
//                      without waiting for GET /auth/me
//
// Primitive types (String) go directly into storage.
// Complex objects (User) are serialized to a JSON string first,
// then deserialized back when read.
//
// Platform:
//   Mobile → flutter_secure_storage (OS-level encryption)
//   Web    → SharedPreferences      (localStorage, dev only)
// ─────────────────────────────────────────────────────────────

class TokenStorage {
  static const _accessTokenKey  = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey         = 'cached_user';   // ← stores User as JSON string

  final FlutterSecureStorage? _secureStorage =
  kIsWeb ? null : const FlutterSecureStorage();

  // ── Internal read/write helpers ───────────────────────────
  // All read/write goes through these two methods so the
  // platform switch (web vs mobile) only lives in one place.

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage!.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    return await _secureStorage!.read(key: key);
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _secureStorage!.delete(key: key);
    }
  }

  // ── TOKENS ────────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await Future.wait([
        _write(_accessTokenKey,  accessToken),
        _write(_refreshTokenKey, refreshToken),
      ]);
      AppLogger.d('Tokens saved');
    } catch (e, st) {
      AppLogger.e('Failed to save tokens', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<String?> getAccessToken()  => _read(_accessTokenKey);
  Future<String?> getRefreshToken() => _read(_refreshTokenKey);

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── USER OBJECT ───────────────────────────────────────────
  // Storage only understands Strings — so we convert the User
  // object to a JSON string before saving, and parse it back
  // when reading. This is the standard pattern for storing
  // any object in key-value storage.

  Future<void> saveUser(User user) async {
    try {
      // Step 1: Convert User → Map  (toJson gives us a Map)
      final Map<String, dynamic> userMap = {
        'id':        user.id,
        'name':      user.name,
        'email':     user.email,
        'role':      user.role,
        'avatarUrl': user.avatarUrl,
        'createdAt': user.createdAt.toIso8601String(),
      };

      // Step 2: Convert Map → String  (jsonEncode serializes to JSON)
      final String userJson = jsonEncode(userMap);

      // Step 3: Store the String
      await _write(_userKey, userJson);

      AppLogger.d('User cached → ${user.id}');
    } catch (e, st) {
      AppLogger.e('Failed to cache user', error: e, stackTrace: st);
      // Don't rethrow — a failed user cache must never block login
    }
  }

  Future<User?> getUser() async {
    try {
      // Step 1: Read the String
      final String? userJson = await _read(_userKey);
      if (userJson == null) return null;

      // Step 2: Convert String → Map  (jsonDecode parses JSON)
      final Map<String, dynamic> userMap =
      jsonDecode(userJson) as Map<String, dynamic>;

      // Step 3: Convert Map → User  (fromJson builds the object)
      return User.fromJson(userMap);

    } catch (e, st) {
      AppLogger.e('Failed to read cached user', error: e, stackTrace: st);
      return null; // return null instead of crashing
    }
  }

  // ── CLEAR EVERYTHING (logout) ─────────────────────────────

  Future<void> clearAll() async {
    try {
      await Future.wait([
        _delete(_accessTokenKey),
        _delete(_refreshTokenKey),
        _delete(_userKey),          // ← clear user cache on logout too
      ]);
      AppLogger.d('Storage cleared');
    } catch (e, st) {
      AppLogger.e('Failed to clear storage', error: e, stackTrace: st);
      // Never rethrow — a failed clear must never block logout
    }
  }

  // Keep for backward compatibility with AuthInterceptor
  Future<void> clearTokens() => clearAll();
}
