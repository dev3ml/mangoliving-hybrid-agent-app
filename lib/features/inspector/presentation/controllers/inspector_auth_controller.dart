import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/inspector_auth_remote.dart';
import '../../data/inspector_remote_repository.dart';
import '../../domain/models/inspector_session.dart';
import '../../domain/repositories/inspector_onboarding_repository.dart';

final inspectorAuthControllerProvider =
    AsyncNotifierProvider<InspectorAuthController, InspectorSession?>(
  InspectorAuthController.new,
);

/// Live onboard persists the returned JWT into the inspector session.
final inspectorOnboardingWithAuthProvider =
    Provider<InspectorOnboardingRepository>((Ref ref) {
  return InspectorRemoteRepository(
    ref.watch(dioProvider),
    persistSession: (Map<String, dynamic> data) {
      return ref
          .read(inspectorAuthControllerProvider.notifier)
          .acceptOnboardSession(data);
    },
  );
});

class InspectorAuthController extends AsyncNotifier<InspectorSession?> {
  InspectorAuthRemote get _remote => ref.read(inspectorAuthRemoteProvider);

  @override
  Future<InspectorSession?> build() => _remote.restore();

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading<InspectorSession?>();
    state = await AsyncValue.guard(
      () => _remote.login(email: email, password: password),
    );
  }

  Future<void> acceptOnboardSession(Map<String, dynamic> data) async {
    state = const AsyncLoading<InspectorSession?>();
    state = await AsyncValue.guard(() => _remote.persistOnboardSession(data));
  }

  Future<void> refresh() async {
    try {
      final InspectorSession session = await _remote.me();
      state = AsyncData<InspectorSession?>(session);
    } on Object {
      // Keep the signed-in session if the profile refresh fails.
    }
  }

  Future<void> logout() async {
    await _remote.logout();
    state = const AsyncData<InspectorSession?>(null);
  }
}
