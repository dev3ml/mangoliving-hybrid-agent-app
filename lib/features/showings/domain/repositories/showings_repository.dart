import '../models/showing_request.dart';

abstract interface class ShowingsRepository {
  Future<List<ShowingRequest>> list({ShowingStatus? status});

  Future<ShowingRequest> updateStatus({
    required String id,
    required ShowingStatus status,
    String? scheduledAt,
  });
}
