import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/inspector_quote.dart';
import '../../domain/models/inspector_draft.dart';
import '../../domain/repositories/inspector_onboarding_repository.dart';
import 'inspector_auth_controller.dart';

final inspectorFlowControllerProvider =
    AsyncNotifierProvider<InspectorFlowController, InspectorDraft>(
  InspectorFlowController.new,
);

final inspectorQuoteProvider = FutureProvider<InspectorQuote>((Ref ref) async {
  final InspectorDraft? draft =
      ref.watch(inspectorFlowControllerProvider).valueOrNull;
  if (draft == null) return const InspectorQuote.notReady();
  return ref.read(inspectorOnboardingWithAuthProvider).previewQuote(draft);
});

class InspectorFlowController extends AsyncNotifier<InspectorDraft> {
  Future<void> _tail = Future<void>.value();

  InspectorOnboardingRepository get _repo =>
      ref.read(inspectorOnboardingWithAuthProvider);

  @override
  Future<InspectorDraft> build() => _repo.load();

  void patch(InspectorDraft Function(InspectorDraft current) update) {
    final InspectorDraft? current = state.valueOrNull;
    if (current == null) return;
    commit(update(current));
  }

  void commit(InspectorDraft next) {
    state = AsyncData<InspectorDraft>(next);
    _tail = _tail.then((_) => _repo.save(next));
  }

  void go(InspectorStep step) {
    patch(
      (InspectorDraft current) => current.copyWith(
        step: step,
        clearEditingAddOn: true,
        clearReturnTo: step == InspectorStep.review ||
            step == InspectorStep.submitted,
      ),
    );
  }

  Future<void> submit() {
    final InspectorDraft? current = state.valueOrNull;
    if (current == null) return Future<void>.value();
    final Future<void> done = _tail.then((_) async {
      final InspectorDraft saved = await _repo.submit(current);
      state = AsyncData<InspectorDraft>(saved);
    });
    _tail = done;
    return done;
  }
}
