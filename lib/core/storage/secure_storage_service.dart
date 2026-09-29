import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

final secureStorageProvider = Provider<SecureStorageService>((Ref ref) {
  return SecureStorageService();
});

/// Thin wrapper around [FlutterSecureStorage] for tokens and the cached user.
final class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }

  Future<void> saveAccessToken(String token) {
    return write(key: StorageKeys.accessToken, value: token);
  }

  Future<String?> getAccessToken() {
    return read(key: StorageKeys.accessToken);
  }

  Future<void> saveCachedUser(String json) {
    return write(key: StorageKeys.cachedUser, value: json);
  }

  Future<String?> getCachedUser() {
    return read(key: StorageKeys.cachedUser);
  }

  Future<void> saveNotificationsLastReadAt(String iso) {
    return write(key: StorageKeys.notificationsLastReadAt, value: iso);
  }

  Future<String?> getNotificationsLastReadAt() {
    return read(key: StorageKeys.notificationsLastReadAt);
  }

  Future<void> clearSession() async {
    await delete(key: StorageKeys.accessToken);
    await delete(key: StorageKeys.cachedUser);
  }
}
