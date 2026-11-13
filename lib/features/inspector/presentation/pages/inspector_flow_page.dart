import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/inspector_draft.dart';
import '../controllers/inspector_flow_controller.dart';
import '../inspector_navigation.dart';
import '../steps/addon_steps.dart';
import '../steps/onboarding_steps.dart';
import '../steps/pricing_steps.dart';
import '../steps/scope_step.dart';
import '../steps/submit_steps.dart';

class InspectorFlowPage extends ConsumerWidget {
  const InspectorFlowPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<InspectorDraft> draft = ref.watch(
      inspectorFlowControllerProvider,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Theme(
        data: AppTheme.light,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) return;
            if (ModalRoute.of(context)?.isCurrent == false) return;
            inspectorBack(context, ref);
          },
          child: draft.when(
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (Object error, StackTrace stackTrace) =>
                Scaffold(body: Center(child: Text('$error'))),
            data: (InspectorDraft current) {
              final String? addOnId = current.editingAddOnId;
              if (addOnId != null) {
                return AddOnSettingsStep(addOnId: addOnId);
              }
              return switch (current.step) {
                InspectorStep.join => const JoinAccountStep(),
                InspectorStep.business => const BusinessProfileStep(),
                InspectorStep.qualifications => const QualificationsStep(),
                InspectorStep.coverage => const CoverageStep(),
                InspectorStep.scopeStructure => const ScopeReviewStep(
                  groupIndex: 0,
                ),
                InspectorStep.scopeInterior => const ScopeReviewStep(
                  groupIndex: 1,
                ),
                InspectorStep.scopeSystems => const ScopeReviewStep(
                  groupIndex: 2,
                ),
                InspectorStep.scopeAppliances => const ScopeReviewStep(
                  groupIndex: 3,
                ),
                InspectorStep.pricingTypes => const PricingTypesStep(),
                InspectorStep.pricingBefore1965 => PricingYearStep(
                  key: ValueKey<String>(
                    '${current.activeHomeType.name}-before-1965',
                  ),
                  from1965: false,
                ),
                InspectorStep.pricingFrom1965 => PricingYearStep(
                  key: ValueKey<String>(
                    '${current.activeHomeType.name}-from-1965',
                  ),
                  from1965: true,
                ),
                InspectorStep.pricingSummary => const PricingSummaryStep(),
                InspectorStep.addonsPest => const AddOnListStep(pageIndex: 0),
                InspectorStep.addonsFoundation => const AddOnListStep(
                  pageIndex: 1,
                ),
                InspectorStep.addonsMold => const AddOnListStep(pageIndex: 2),
                InspectorStep.quote => const QuotePreviewStep(),
                InspectorStep.availability => const AvailabilityStep(),
                InspectorStep.review => const ReviewSubmitStep(),
                InspectorStep.submitted => const ApplicationStatusStep(),
              };
            },
          ),
        ),
      ),
    );
  }
}
