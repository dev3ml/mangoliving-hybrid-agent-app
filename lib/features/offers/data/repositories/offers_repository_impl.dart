import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/property_action.dart';
import '../../domain/repositories/offers_repository.dart';
import '../datasources/offers_remote_datasource.dart';

final offersRepositoryProvider = Provider<OffersRepository>((Ref ref) {
  return OffersRepositoryImpl(OffersRemoteDataSource(ref.watch(dioProvider)));
});

final class OffersRepositoryImpl implements OffersRepository {
  OffersRepositoryImpl(this._remote);

  final OffersRemoteDataSource _remote;

  @override
  Future<List<PropertyAction>> list({OfferBoardState? state}) async {
    try {
      return await _remote.list(state: state);
    } on DioException catch (error) {
      final AppException mapped = ExceptionMapper.fromDio(error);
      if (_isMissing(mapped)) return const <PropertyAction>[];
      throw mapped;
    } on AppException catch (error) {
      if (_isMissing(error)) return const <PropertyAction>[];
      rethrow;
    }
  }

  @override
  Future<PropertyAction> sendOffer({
    required String id,
    required Map<String, dynamic> body,
    String? documentPath,
  }) {
    return _guard(
      () => _remote.sendOffer(id: id, body: body, documentPath: documentPath),
    );
  }

  @override
  Future<PropertyAction> applyAction({
    required String id,
    required String action,
  }) {
    return _guard(() => _remote.applyAction(id: id, action: action));
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  static bool _isMissing(AppException error) {
    if (error is NotFoundException) return true;
    final String compact = error.message.toLowerCase().replaceAll(' ', '');
    return compact.contains('notfound') || compact == '404';
  }
}
