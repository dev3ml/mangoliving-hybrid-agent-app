import '../models/agent_user.dart';
import '../signup_form.dart';

abstract interface class AuthRepository {
  Future<AgentSession?> restoreSession();

  Future<AgentSession> login({
    required String email,
    required String password,
  });

  Future<SignupOutcome> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String mobileNumber,
    required bool smsConsent,
    required String licenseNumber,
  });

  Future<AgentUser?> verifyEmail(String code);

  Future<({bool alreadyVerified, int? cooldownSeconds})> resendVerification();

  Future<void> logout();

  Future<void> persistUser(AgentUser user);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> forgotPassword(String email);
}
