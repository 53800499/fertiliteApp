import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  final FlutterSecureStorage _storage;

  SecureStorageHelper({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const String _keyAccessToken = 'app_access_token';
  static const String _keyRefreshToken = 'app_refresh_token';
  static const String _keyUserId = 'app_user_id';
  static const String _keyUserEmail = 'app_user_email';
  static const String _keyInitialSubscriptionGateDone = 'app_initial_subscription_gate_done';
  static const String _keyDisplayedNotifIds = 'app_displayed_system_notif_ids';

  // --- Access Token ---
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  // --- Refresh Token ---
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  // --- User Info ---
  Future<void> saveUserData({required String userId, required String email}) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUserEmail, value: email);
  }

  Future<String?> getUserId() async {
    return _storage.read(key: _keyUserId);
  }

  Future<String?> getUserEmail() async {
    return _storage.read(key: _keyUserEmail);
  }

  // --- Clean all (Logout) ---
  Future<void> clearAllTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserEmail);
    await _storage.delete(key: _keyDisplayedNotifIds);
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // --- Offline Cache Storage ---
  Future<void> saveCache(String key, String jsonString) async {
    try {
      await _storage.write(key: 'cache_$key', value: jsonString);
    } catch (_) {}
  }

  Future<String?> getCache(String key) async {
    try {
      return await _storage.read(key: 'cache_$key');
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteCache(String key) async {
    try {
      await _storage.delete(key: 'cache_$key');
    } catch (_) {}
  }

  // --- Initial Installation Subscription Gate ---
  Future<bool> hasCompletedInitialSubscriptionGate() async {
    try {
      final val = await _storage.read(key: _keyInitialSubscriptionGateDone);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> markInitialSubscriptionGateCompleted() async {
    try {
      await _storage.write(key: _keyInitialSubscriptionGateDone, value: 'true');
    } catch (_) {}
  }

  // --- Displayed System Notifications Deduplication ---
  Future<Set<String>> getDisplayedNotificationIds() async {
    try {
      final raw = await _storage.read(key: _keyDisplayedNotifIds);
      if (raw == null || raw.isEmpty) return <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toSet();
      }
    } catch (_) {}
    return <String>{};
  }

  Future<void> markNotificationIdsDisplayed(Iterable<String> ids) async {
    try {
      final current = await getDisplayedNotificationIds();
      current.addAll(ids);
      // Conserver au maximum les 150 derniers identifiants
      final list = current.toList();
      final trimmed = list.length > 150 ? list.sublist(list.length - 150) : list;
      await _storage.write(
        key: _keyDisplayedNotifIds,
        value: jsonEncode(trimmed),
      );
    } catch (_) {}
  }
}
