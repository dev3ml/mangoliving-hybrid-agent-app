import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../role/domain/app_role.dart';
import '../../role/presentation/app_role_controller.dart';
import '../domain/models/inspector_draft.dart';
import 'controllers/inspector_flow_controller.dart';

void inspectorSaveAndExit(BuildContext context, WidgetRef ref) {
  ref.read(appRoleProvider.notifier).state = AppRole.none;
  context.go(AppRoutes.role);
}

void inspectorBack(BuildContext context, WidgetRef ref) {
  final InspectorDraft? draft =
      ref.read(inspectorFlowControllerProvider).valueOrNull;
  final InspectorFlowController notifier =
      ref.read(inspectorFlowControllerProvider.notifier);
  if (draft == null) {
    inspectorSaveAndExit(context, ref);
    return;
  }
  if (draft.editingAddOnId != null) {
    notifier.patch(
      (InspectorDraft current) => current.copyWith(clearEditingAddOn: true),
    );
    return;
  }
  if (draft.step == InspectorStep.submitted) {
    inspectorSaveAndExit(context, ref);
    return;
  }
  if (draft.returnTo != null && draft.step == draft.returnAnchor) {
    notifier.go(draft.returnTo ?? InspectorStep.review);
    return;
  }
  if ((draft.status == ApplicationStatus.underReview ||
          draft.status == ApplicationStatus.live) &&
      draft.step == InspectorStep.review) {
    notifier.go(InspectorStep.submitted);
    return;
  }
  final InspectorStep? previous = previousInspectorStep(draft.step);
  if (previous == null) {
    context.go(AppRoutes.inspectorLogin);
    return;
  }
  notifier.go(previous);
}

InspectorStep? previousInspectorStep(InspectorStep step) {
  final int index = InspectorStep.values.indexOf(step);
  if (index <= 0) return null;
  return InspectorStep.values[index - 1];
}

void inspectorReturnToReview(WidgetRef ref) {
  final InspectorDraft? draft =
      ref.read(inspectorFlowControllerProvider).valueOrNull;
  final InspectorStep? target = draft?.returnTo;
  if (target == null) return;
  ref.read(inspectorFlowControllerProvider.notifier).go(target);
}

void editSection(
  WidgetRef ref, {
  required InspectorStep step,
}) {
  ref.read(inspectorFlowControllerProvider.notifier).patch(
        (InspectorDraft current) => current.copyWith(
          step: step,
          returnTo: InspectorStep.review,
          returnAnchor: step,
          clearEditingAddOn: true,
        ),
      );
}
