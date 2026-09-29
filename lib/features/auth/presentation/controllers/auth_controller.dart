import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../../messages/data/chat_socket_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/agent_user.dart';
import '../../domain/repositories/auth_repository.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AgentSession?>(AuthController.new);

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

  Future<void> logout() async {
    ref.read(chatSocketServiceProvider).disconnect();
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
