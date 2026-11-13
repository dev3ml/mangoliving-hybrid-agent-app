import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/env_config.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../clients/data/datasources/clients_remote_datasource.dart';
import '../../clients/domain/models/criteria_history.dart';
import '../../clients/domain/models/managed_client.dart';
import '../domain/property_search_logic.dart';
import '../domain/saved_listing.dart';

final propertySearchRepositoryProvider = Provider<PropertySearchRepository>((Ref ref) {
  final Dio dio = ref.watch(dioProvider);
  return PropertySearchRepository(
    dio: dio,
    clients: ClientsRemoteDataSource(dio),
    buyerAppUrl: EnvConfig.buyerAppUrl,
  );
});

final class ClientConversationPayload {
  const ClientConversationPayload({
    required this.messages,
    required this.meta,
  });

  final List<dynamic> messages;
  final Map<String, dynamic> meta;
}

final class PropertySearchRepository {
  PropertySearchRepository({
    required this._dio,
    required this._clients,
    required this.buyerAppUrl,
  });

  final Dio _dio;
  final ClientsRemoteDataSource _clients;
  final String buyerAppUrl;

  Future<List<ManagedClient>> listClients() {
    return _guard(() async {
      final List<ManagedClient> all = await _clients.listManaged();
      return all.where(isPropertySearchClient).toList();
    });
  }

  Future<List<CriteriaHistoryEntry>> criteriaHistory(String buyerId) {
    return _guard(() => _clients.criteriaHistory(buyerId));
  }

  Future<({int favorites, int hidden})> savedCounts(String buyerId) {
    return _guard(() async {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/v1/agent/analytics/$buyerId/overview',
        queryParameters: <String, dynamic>{'months': 1},
      );
      final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
      ApiEnvelope.ensureSuccess(body);
      final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
      return (
        favorites: favoritesCountFromOverview(data),
        hidden: hiddenCountFromOverview(data),
      );
    });
  }

  Future<List<SavedListing>> favorites(String buyerId) {
    return _listings(buyerId, 'favorites');
  }

  Future<List<SavedListing>> hidden(String buyerId) {
    return _listings(buyerId, 'hidden');
  }

  Future<ClientConversationPayload?> conversationForBuyer(String buyerId) {
    return _guard(() async {
      final Response<dynamic> listResponse =
          await _dio.get<dynamic>('/v1/agent/conversations');
      String? id;
      for (final Map<String, dynamic> row in ApiEnvelope.dataList(listResponse.data)) {
        final String? rowBuyer = _buyerId(row);
        if (rowBuyer == buyerId) {
          id = (row['_id'] ?? row['id'] ?? '').toString();
          break;
        }
      }
      if (id == null || id.isEmpty) return null;
      final Response<dynamic> detail = await _dio.get<dynamic>(
        '/v1/agent/conversations/${Uri.encodeComponent(id)}',
      );
      final Map<String, dynamic> body = ApiEnvelope.requireMap(detail.data);
      if (body['status'] != true) return null;
      final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
      if (data == null) return null;
      final Object? messages = data['messages'];
      final Object? meta = data['meta'];
      return ClientConversationPayload(
        messages: messages is List ? messages : const <dynamic>[],
        meta: meta is Map<String, dynamic>
            ? meta
            : meta is Map
                ? meta.map((dynamic key, dynamic value) => MapEntry(key.toString(), value))
                : const <String, dynamic>{},
      );
    });
  }

  Future<List<SavedListing>> _listings(String buyerId, String kind) {
    return _guard(() async {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/v1/agent/analytics/$buyerId/$kind',
        queryParameters: <String, dynamic>{'limit': 50},
      );
      final Map<String, dynamic> body = ApiEnvelope.requireMap(response.data);
      ApiEnvelope.ensureSuccess(body);
      final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
      final Object? raw = data?['properties'];
      if (raw is! List) return const <SavedListing>[];
      return raw.whereType<Map<String, dynamic>>().map((Map<String, dynamic> json) {
        return SavedListing.fromJson(json, buyerAppUrl: buyerAppUrl);
      }).toList();
    });
  }

  String? _buyerId(Map<String, dynamic> row) {
    final Object? user = row['userId'];
    if (user is String && user.isNotEmpty) return user;
    if (user is Map) {
      final Object? id = user['_id'] ?? user['id'];
      if (id != null && id.toString().isNotEmpty) return id.toString();
    }
    final Object? buyer = row['buyer'];
    if (buyer is Map) {
      final Object? id = buyer['_id'] ?? buyer['id'];
      if (id != null && id.toString().isNotEmpty) return id.toString();
    }
    return null;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      throw ExceptionMapper.fromDio(error);
    }
  }
}
