import '../inspector_quote.dart';
import '../models/inspector_draft.dart';

/// Inspector onboarding port. Screens depend on this, not on a data source.
///
/// The current binding is in-memory. A later Dio implementation can replace
/// it without changing the wizard.
abstract interface class InspectorOnboardingRepository {
  Future<InspectorDraft> load();

  Future<InspectorDraft> save(InspectorDraft draft);

  Future<InspectorQuote> previewQuote(InspectorDraft draft);

  Future<InspectorDraft> submit(InspectorDraft draft);
}
