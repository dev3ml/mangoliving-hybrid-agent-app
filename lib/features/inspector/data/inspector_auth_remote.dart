import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../messages/domain/models/chat_message.dart';
import '../../messages/domain/models/chat_thread.dart';
import '../domain/models/inspector_session.dart';

final inspectorAuthRemoteProvider = Provider<InspectorAuthRemote>((Ref ref) {
  return InspectorAuthRemote(
    dio: ref.watch(inspectorDioProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

final class InspectorAuthRemote {
  InspectorAuthRemote({required Dio dio, required SecureStorageService storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final SecureStorageService _storage;

  Future<InspectorSession?> restore() async {
    final String? token = await _storage.getInspectorAccessToken();
    final String? cached = await _storage.getInspectorCachedSession();
    if (token == null || token.isEmpty || cached == null || cached.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> json =
          jsonDecode(cached) as Map<String, dynamic>;
      final InspectorSession session = InspectorSession.fromJson(<String, dynamic>{
        ...json,
        'token': token,
      });
      // Refresh profile; if token is dead, clear.
      await me();
      return session;
    } on Object {
      await _storage.clearInspectorSession();
      return null;
    }
  }

  Future<InspectorSession> login({
    required String email,
    required String password,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/v1/inspection-provider/auth/login',
      data: <String, dynamic>{'email': email.trim(), 'password': password},
    );
    return _persist(response.data);
  }

  Future<InspectorSession> persistOnboardSession(Map<String, dynamic> data) {
    return _persist(<String, dynamic>{'status': true, 'data': data});
  }

  Future<InspectorSession> me() async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/v1/inspection-provider/me');
    final Map<String, dynamic> envelope = ApiEnvelope.requireMap(response.data);
    ApiEnvelope.ensureSuccess(envelope);
    final Map<String, dynamic> data =
        ApiEnvelope.dataMap(envelope) ?? <String, dynamic>{};
    final String? token = await _storage.getInspectorAccessToken();
    final InspectorSession session = InspectorSession.fromJson(<String, dynamic>{
      'token': token ?? '',
      'user': data['user'],
      'inspector': data['inspector'],
    });
    await _storage.saveInspectorCachedSession(jsonEncode(session.toJson()));
    return session;
  }

  Future<Map<String, dynamic>> booking(String token) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/v1/inspection-provider/booking',
      options: _token(token),
    );
    return _data(response.data);
  }

  Future<Map<String, dynamic>> respond(
    String token,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/v1/inspection-provider/booking/respond',
      data: body,
      options: _token(token),
    );
    return _data(response.data);
  }

  Future<Map<String, dynamic>> complete(
    String token,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/v1/inspection-provider/booking/complete',
      data: body,
      options: _token(token),
    );
    return _data(response.data);
  }

  Future<Map<String, dynamic>> uploadReport(
    String token, {
    required String path,
    required String street,
    required String licenseNumber,
    required String inspectionDate,
  }) async {
    final FormData form = FormData.fromMap(<String, dynamic>{
      'propertyStreet': street,
      'inspectorLicenseNumber': licenseNumber,
      'inspectionDate': inspectionDate,
      'document': await MultipartFile.fromFile(path, filename: _basename(path)),
    });
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/v1/inspection-provider/booking/report',
      data: form,
      options: _token(token).copyWith(contentType: 'multipart/form-data'),
    );
    return _data(response.data);
  }

  Future<Map<String, dynamic>> paymentReceived(String token) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/v1/inspection-provider/booking/payment-received',
      options: _token(token),
    );
    return _data(response.data);
  }

  Future<Map<String, dynamic>> reviseReportDue(
    String token,
    DateTime revisedDueAt,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/v1/inspection-provider/booking/report-due',
      data: <String, dynamic>{
        'revisedDueAt': revisedDueAt.toUtc().toIso8601String(),
      },
      options: _token(token),
    );
    return _data(response.data);
  }

  Future<Map<String, dynamic>> cancel(String token, String reason) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/v1/inspection-provider/booking/cancel',
      data: <String, dynamic>{'reason': reason},
      options: _token(token),
    );
    return _data(response.data);
  }

  Options _token(String token) {
    return Options(headers: <String, dynamic>{'x-provider-token': token});
  }

  Map<String, dynamic> _data(dynamic raw) {
    final Map<String, dynamic> envelope = ApiEnvelope.requireMap(raw);
    ApiEnvelope.ensureSuccess(envelope);
    return ApiEnvelope.dataMap(envelope) ?? <String, dynamic>{};
  }

  static String _basename(String path) {
    final String normalized = path.replaceAll('\\', '/');
    final int slash = normalized.lastIndexOf('/');
    return slash < 0 ? normalized : normalized.substring(slash + 1);
  }

  Future<List<Map<String, dynamic>>> bookings() async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/v1/inspection-provider/bookings');
    final Map<String, dynamic> envelope = ApiEnvelope.requireMap(response.data);
    ApiEnvelope.ensureSuccess(envelope);
    final Map<String, dynamic> data =
        ApiEnvelope.dataMap(envelope) ?? <String, dynamic>{};
    final dynamic list = data['bookings'];
    if (list is! List) return <Map<String, dynamic>>[];
    return list
        .whereType<Map>()
        .map((Map row) => row.map((key, value) => MapEntry('$key', value)))
        .toList();
  }

  Future<List<ChatThread>> inspectionThreads() async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/v1/inspection-chat/threads');
    return ApiEnvelope.dataList(response.data)
        .map(ChatThread.inspectionFromJson)
        .toList();
  }

  Future<ChatThread> inspectionThreadForBooking(String bookingId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/v1/inspection-chat/by-booking/${Uri.encodeComponent(bookingId)}',
    );
    return ChatThread.inspectionFromJson(_data(response.data));
  }

  Future<List<ChatMessage>> inspectionMessages(String threadId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/v1/inspection-chat/threads/${Uri.encodeComponent(threadId)}/messages',
    );
    return ApiEnvelope.dataList(response.data)
        .map(ChatMessage.fromJson)
        .toList();
  }

  Future<ChatMessage> sendInspectionMessage(String threadId, String text) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/v1/inspection-chat/threads/${Uri.encodeComponent(threadId)}/messages',
      data: <String, dynamic>{'text': text},
    );
    return ChatMessage.fromJson(_data(response.data));
  }

  Future<void> markInspectionRead(String threadId) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/v1/inspection-chat/threads/${Uri.encodeComponent(threadId)}/read',
      data: <String, dynamic>{},
    );
    _data(response.data);
  }

  Future<void> logout() => _storage.clearInspectorSession();

  Future<InspectorSession> _persist(dynamic raw) async {
    final Map<String, dynamic> envelope = ApiEnvelope.requireMap(raw);
    ApiEnvelope.ensureSuccess(envelope);
    final Map<String, dynamic> data =
        ApiEnvelope.dataMap(envelope) ?? <String, dynamic>{};
    final InspectorSession session = InspectorSession.fromJson(data);
    if (session.token.isEmpty) {
      throw const FormatException('Missing inspector session token');
    }
    await _storage.saveInspectorAccessToken(session.token);
    await _storage.saveInspectorCachedSession(jsonEncode(session.toJson()));
    return session;
  }
}
