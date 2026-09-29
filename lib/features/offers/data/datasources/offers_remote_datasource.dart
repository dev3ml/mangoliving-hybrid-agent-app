import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/app_exception.dart';
import '../../domain/models/property_action.dart';

final class OffersRemoteDataSource {
  OffersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PropertyAction>> list({OfferBoardState? state}) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/v1/agent/property-actions',
      queryParameters: <String, dynamic>{
        if (state != null) 'state': state.apiValue,
      },
    );
    return ApiEnvelope.dataList(response.data)
        .map(PropertyAction.fromJson)
        .toList();
  }

  Future<PropertyAction> sendOffer({
    required String id,
    required Map<String, dynamic> body,
    String? documentPath,
  }) async {
    final Response<dynamic> response;
    if (documentPath != null && documentPath.isNotEmpty) {
      final Map<String, dynamic> fields = <String, dynamic>{
        for (final MapEntry<String, dynamic> e in body.entries)
          e.key: e.value.toString(),
      };
      fields['document'] = await MultipartFile.fromFile(
        documentPath,
        filename: _basename(documentPath),
      );
      response = await _dio.post<dynamic>(
        '/v1/agent/property-actions/$id/offers',
        data: FormData.fromMap(fields),
        options: Options(contentType: 'multipart/form-data'),
      );
    } else {
      response = await _dio.post<dynamic>(
        '/v1/agent/property-actions/$id/offers',
        data: body,
      );
    }
    return _requireAction(response.data, fallback: 'Offer was not sent');
  }

  Future<PropertyAction> applyAction({
    required String id,
    required String action,
  }) async {
    final Response<dynamic> response = await _dio.patch<dynamic>(
      '/v1/agent/property-actions/$id',
      data: <String, dynamic>{'action': action},
    );
    return _requireAction(response.data, fallback: 'Offer was not updated');
  }

  PropertyAction _requireAction(dynamic raw, {required String fallback}) {
    final Map<String, dynamic> body = ApiEnvelope.requireMap(raw);
    ApiEnvelope.ensureSuccess(body);
    final Map<String, dynamic>? data = ApiEnvelope.dataMap(body);
    if (data == null) throw UnknownException(fallback);
    return PropertyAction.fromJson(data);
  }

  static String _basename(String path) {
    final int slash = path.replaceAll('\\', '/').lastIndexOf('/');
    return slash < 0 ? path : path.substring(slash + 1);
  }
}
