import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/models/agent_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

final authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSource(ref.watch(dioProvider)),
    storage: ref.watch(secureStorageProvider),
  );
});

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._remote,
    required this._storage,
  });

  final AuthRemoteDataSource _remote;
  final SecureStorageService _storage;

  @override
  Future<AgentSession?> restoreSession() async {
    final String? token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) return null;

    final AgentUser? verified = await _remote.verifyToken(token);
    if (verified != null && verified.canAccessAgentPanel) {
      await _persistUser(verified);
      return AgentSession(token: token, user: verified);
    }

    final String? cached = await _storage.getCachedUser();
    if (cached != null) {
      try {
        final AgentUser user =
            AgentUser.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        if (user.canAccessAgentPanel) {
          return AgentSession(token: token, user: user);
        }
      } on Object {
        // Fall through and clear a corrupt cache.
      }
    }

    await _storage.clearSession();
    return null;
  }

  @override
  Future<AgentSession> login({
    required String email,
    required String password,
  }) async {
    final AgentSession session = await _remote.login(
      email: email,
      password: password,
    );
    await _storage.saveAccessToken(session.token);
    await _persistUser(session.user);
    return session;
  }

  @override
  Future<void> logout() {
    return _storage.clearSession();
  }

  @override
  Future<void> persistUser(AgentUser user) => _persistUser(user);

  @override
  Future<void> forgotPassword(String email) {
    return _remote.forgotPassword(email);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _remote.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> _persistUser(AgentUser user) {
    return _storage.saveCachedUser(jsonEncode(user.toJson()));
  }
}
