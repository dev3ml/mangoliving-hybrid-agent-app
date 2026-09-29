import '../models/agent_user.dart';

abstract interface class AuthRepository {
  Future<AgentSession?> restoreSession();

  Future<AgentSession> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<void> persistUser(AgentUser user);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> forgotPassword(String email);
}
