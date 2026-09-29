import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/showing_request.dart';
import '../../domain/repositories/showings_repository.dart';
import '../datasources/showings_remote_datasource.dart';

final showingsRepositoryProvider = Provider<ShowingsRepository>((Ref ref) {
  return ShowingsRepositoryImpl(
    ShowingsRemoteDataSource(ref.watch(dioProvider)),
  );
});

final class ShowingsRepositoryImpl implements ShowingsRepository {
  ShowingsRepositoryImpl(this._remote);

  final ShowingsRemoteDataSource _remote;

  @override
  Future<List<ShowingRequest>> list({ShowingStatus? status}) {
    return _guard(() => _remote.list(status: status));
  }

  @override
  Future<ShowingRequest> updateStatus({
    required String id,
    required ShowingStatus status,
    String? scheduledAt,
  }) {
    return _guard(
      () => _remote.updateStatus(
        id: id,
        status: status,
        scheduledAt: scheduledAt,
      ),
    );
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }
}
