import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../showings/data/repositories/showings_repository_impl.dart';
import '../../../showings/domain/models/showing_request.dart';
import '../../../showings/domain/repositories/showings_repository.dart';
import '../../domain/models/client_conversation.dart';
import '../../domain/models/client_interest.dart';
import '../../domain/models/criteria_history.dart';
import '../../domain/models/managed_client.dart';
import '../../domain/repositories/clients_repository.dart';
import '../../domain/roster_merge.dart';
import '../datasources/clients_remote_datasource.dart';

final clientsRepositoryProvider = Provider<ClientsRepository>((Ref ref) {
  return ClientsRepositoryImpl(
    remote: ClientsRemoteDataSource(ref.watch(dioProvider)),
    showings: ref.watch(showingsRepositoryProvider),
  );
});

final class ClientsRepositoryImpl implements ClientsRepository {
  ClientsRepositoryImpl({
    required this._remote,
    required this._showings,
  });

  final ClientsRemoteDataSource _remote;
  final ShowingsRepository _showings;

  @override
  Future<ClientRoster> load() async {
    try {
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        _try(_remote.listInterests(), const <ClientInterest>[]),
        _try(_remote.listConversations(), const <ClientConversation>[]),
        _try(_remote.listManaged(), const <ManagedClient>[]),
        _try(_showings.list(), const <ShowingRequest>[]),
      ]);
      return ClientRosterMerger.merge(
        interests: results[0] as List<ClientInterest>,
        conversations: results[1] as List<ClientConversation>,
        managed: results[2] as List<ManagedClient>,
        showings: results[3] as List<ShowingRequest>,
      );
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  @override
  Future<ManagedClient> create({
    required String email,
    String? name,
    String? phone,
    bool sendInvitation = true,
  }) {
    return _guard(
      () => _remote.create(
        email: email,
        name: name,
        phone: phone,
        sendInvitation: sendInvitation,
      ),
    );
  }

  @override
  Future<void> delete(String managedId) => _guard(() => _remote.delete(managedId));

  @override
  Future<void> resendInvite(String managedId) {
    return _guard(() => _remote.resendInvite(managedId));
  }

  @override
  Future<void> accept(String managedId) => _guard(() => _remote.accept(managedId));

  @override
  Future<void> decline(String managedId) {
    return _guard(() => _remote.decline(managedId));
  }

  @override
  Future<ClientConversation?> conversation(String id) {
    return _guard(() => _remote.conversation(id));
  }

  @override
  Future<List<CriteriaHistoryEntry>> criteriaHistory(String buyerId) {
    return _guard(() => _remote.criteriaHistory(buyerId));
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }

  Future<T> _try<T>(Future<T> future, T fallback) async {
    try {
      return await future;
    } on Object {
      return fallback;
    }
  }
}
