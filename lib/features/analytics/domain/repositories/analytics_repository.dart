import '../models/analytics_models.dart';

abstract interface class AnalyticsRepository {
  Future<List<AnalyticsClient>> listClients();

  Future<AnalyticsOverview> overview({
    required String buyerId,
    required int months,
  });

  Future<AiSummary> aiSummary({
    required String buyerId,
    required int months,
  });
}
