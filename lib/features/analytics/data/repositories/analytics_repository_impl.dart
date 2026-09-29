import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/analytics_models.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_datasource.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((Ref ref) {
  return AnalyticsRepositoryImpl(
    AnalyticsRemoteDataSource(ref.watch(dioProvider)),
  );
});

final class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl(this._remote);

  final AnalyticsRemoteDataSource _remote;

  @override
  Future<List<AnalyticsClient>> listClients() {
    return _guard(_remote.listClients);
  }

  @override
  Future<AnalyticsOverview> overview({
    required String buyerId,
    required int months,
  }) {
    return _guard(() => _remote.overview(buyerId: buyerId, months: months));
  }

  @override
  Future<AiSummary> aiSummary({
    required String buyerId,
    required int months,
  }) {
    return _guard(() => _remote.aiSummary(buyerId: buyerId, months: months));
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }
}
