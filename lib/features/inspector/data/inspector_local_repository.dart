import '../domain/inspector_catalog.dart';
import '../domain/inspector_quote.dart';
import '../domain/models/inspector_draft.dart';
import '../domain/repositories/inspector_onboarding_repository.dart';

/// Session memory for the inspector application draft (no network).
final class InspectorLocalRepository implements InspectorOnboardingRepository {
  InspectorLocalRepository({InspectorDraft? initial})
      : _draft = initial ?? newInspectorDraft();

  InspectorDraft _draft;

  @override
  Future<InspectorDraft> load() {
    return Future<InspectorDraft>.value(_draft);
  }

  @override
  Future<InspectorDraft> save(InspectorDraft draft) {
    _draft = draft;
    return Future<InspectorDraft>.value(_draft);
  }

  @override
  Future<InspectorQuote> previewQuote(InspectorDraft draft) {
    final int? year = parseWholeNumber(draft.previewYear);
    final int? sqFt = parseWholeNumber(draft.previewSqFt);
    if (year == null || sqFt == null) {
      return Future<InspectorQuote>.value(const InspectorQuote.notReady());
    }

    final HomeType homeType = draft.selectedHomeTypes.contains(draft.previewHomeType)
        ? draft.previewHomeType
        : (draft.selectedHomeTypes.isEmpty
            ? draft.previewHomeType
            : draft.selectedHomeTypes.first);
    final HomeRateCard? card = draft.rateCards[homeType];
    if (card == null) {
      return Future<InspectorQuote>.value(const InspectorQuote.notReady());
    }

    final List<QuoteAddOnInput> addOns = <QuoteAddOnInput>[
      for (final AddOnOffer addOn in draft.addOns)
        if (addOn.enabled && draft.previewAddOnIds.contains(addOn.id))
          QuoteAddOnInput(
            name: addOn.name,
            method: addOn.method,
            priceUsd: addOn.priceUsd,
          ),
    ];

    return Future<InspectorQuote>.value(
      matchInspectionQuote(
        yearBuilt: year,
        sqFt: sqFt,
        before1965: card.before1965,
        from1965: card.from1965,
        addOns: addOns,
      ),
    );
  }

  @override
  Future<InspectorDraft> submit(InspectorDraft draft) {
    _draft = draft.copyWith(
      status: ApplicationStatus.live,
      submittedAt: DateTime.now(),
      step: InspectorStep.submitted,
      confirmedAccurate: true,
      clearEditingAddOn: true,
      clearReturnTo: true,
    );
    return Future<InspectorDraft>.value(_draft);
  }
}
