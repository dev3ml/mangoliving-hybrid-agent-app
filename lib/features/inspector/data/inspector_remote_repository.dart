import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/dio_client.dart';
import '../domain/inspector_quote.dart';
import '../domain/models/inspector_draft.dart';
import '../domain/repositories/inspector_onboarding_repository.dart';
import 'inspector_draft_mapper.dart';
import 'inspector_local_repository.dart';

/// Default wiring without session persistence (tests / offline).
/// Production overrides via [inspectorOnboardingRepositoryProvider] in auth.
final inspectorOnboardingRepositoryProvider =
    Provider<InspectorOnboardingRepository>((Ref ref) {
  return InspectorRemoteRepository(ref.watch(dioProvider));
});

final class InspectorRemoteRepository implements InspectorOnboardingRepository {
  InspectorRemoteRepository(
    this._dio, {
    Future<void> Function(Map<String, dynamic> data)? persistSession,
    InspectorDraft? initial,
  })  : _persistSession = persistSession,
        _local = InspectorLocalRepository(initial: initial);

  final Dio _dio;
  final Future<void> Function(Map<String, dynamic> data)? _persistSession;
  final InspectorLocalRepository _local;

  @override
  Future<InspectorDraft> load() => _local.load();

  @override
  Future<InspectorDraft> save(InspectorDraft draft) => _local.save(draft);

  @override
  Future<InspectorQuote> previewQuote(InspectorDraft draft) =>
      _local.previewQuote(draft);

  @override
  Future<InspectorDraft> submit(InspectorDraft draft) async {
    final Map<String, dynamic> payload =
        InspectorDraftMapper.toLiveOnboardJson(draft);
    final String photoPath = draft.photoPath?.trim() ?? '';
    final Object body = photoPath.isEmpty
        ? payload
        : FormData.fromMap(<String, dynamic>{
            'payload': jsonEncode(payload),
            'photo': await MultipartFile.fromFile(
              photoPath,
              filename: _basename(photoPath),
            ),
          });
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/v1/inspection-provider/live-onboard',
      data: body,
    );
    final Map<String, dynamic> envelope = ApiEnvelope.requireMap(response.data);
    ApiEnvelope.ensureSuccess(envelope);
    final Map<String, dynamic>? data = ApiEnvelope.dataMap(envelope);
    final Future<void> Function(Map<String, dynamic> data)? persist = _persistSession;
    if (data != null && data['token'] != null && persist != null) {
      await persist(data);
    }

    final InspectorDraft saved = draft.copyWith(
      status: ApplicationStatus.live,
      submittedAt: DateTime.now(),
      step: InspectorStep.submitted,
      confirmedAccurate: true,
      clearEditingAddOn: true,
      clearReturnTo: true,
    );
    return _local.save(saved);
  }

  static String _basename(String path) {
    final String normalized = path.replaceAll('\\', '/');
    final int slash = normalized.lastIndexOf('/');
    return slash < 0 ? normalized : normalized.substring(slash + 1);
  }
}
