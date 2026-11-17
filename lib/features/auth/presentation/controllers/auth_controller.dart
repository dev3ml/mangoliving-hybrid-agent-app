import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../../messages/data/chat_socket_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/agent_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/signup_form.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AgentSession?>(AuthController.new);

/// Keeps a new account on the in-app verification screen until they verify
/// or choose to continue. Existing sessions are not sent there.
final pendingEmailVerificationProvider = StateProvider<bool>((Ref ref) => false);

/// License-save warning carried from signup onto the verification screen.
final signupNoticeProvider = StateProvider<String?>((Ref ref) => null);

class AuthController extends AsyncNotifier<AgentSession?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AgentSession?> build() async {
    final AgentSession? session = await _repo.restoreSession();
    syncDashboardUser(ref, session?.user);
    return session;
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading<AgentSession?>();
    state = await AsyncValue.guard(() {
      return _repo.login(email: email, password: password);
    });
    syncDashboardUser(ref, state.valueOrNull?.user);
  }

  Future<SignupOutcome?> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String mobileNumber,
    required bool smsConsent,
    required String licenseNumber,
  }) async {
    state = const AsyncLoading<AgentSession?>();
    try {
      final SignupOutcome outcome = await _repo.signup(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        mobileNumber: mobileNumber,
        smsConsent: smsConsent,
        licenseNumber: licenseNumber,
      );
      ref.read(signupNoticeProvider.notifier).state = outcome.licenseWarning;
      if (!outcome.session.user.isEmailVerified) {
        ref.read(pendingEmailVerificationProvider.notifier).state = true;
      }
      syncDashboardUser(ref, outcome.session.user);
      state = AsyncData<AgentSession?>(outcome.session);
      return outcome;
    } on Object catch (error, stackTrace) {
      state = const AsyncData<AgentSession?>(null);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> finishEmailVerification() async {
    ref.read(pendingEmailVerificationProvider.notifier).state = false;
    ref.read(signupNoticeProvider.notifier).state = null;
  }

  Future<AgentUser?> verifyEmail(String code) async {
    final AgentUser? user = await _repo.verifyEmail(code);
    if (user != null) await applyUser(user);
    await finishEmailVerification();
    return user;
  }

  Future<({bool alreadyVerified, int? cooldownSeconds})> resendVerification() {
    return _repo.resendVerification();
  }

  Future<void> logout() async {
    ref.read(chatSocketServiceProvider).disconnect();
    ref.read(pendingEmailVerificationProvider.notifier).state = false;
    ref.read(signupNoticeProvider.notifier).state = null;
    await _repo.logout();
    syncDashboardUser(ref, null);
    syncDashboardUnread(ref, 0);
    state = const AsyncData<AgentSession?>(null);
  }

  Future<void> applyUser(AgentUser user) async {
    final AgentSession? session = state.valueOrNull;
    if (session == null) return;
    await _repo.persistUser(user);
    syncDashboardUser(ref, user);
    state = AsyncData<AgentSession?>(
      AgentSession(token: session.token, user: user),
    );
  }

  Future<void> forgotPassword(String email) {
    return _repo.forgotPassword(email);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
