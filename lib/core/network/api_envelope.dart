import 'app_exception.dart';

/// Parses the project-wide API envelope `{ status, message, data }`.
abstract final class ApiEnvelope {
  static Map<String, dynamic> requireMap(dynamic body) {
    final Map<String, dynamic>? map = _asStringMap(body);
    if (map != null) return map;
    throw const UnknownException('Unexpected server response');
  }

  static void ensureSuccess(Map<String, dynamic> body) {
    if (body['status'] == true) return;
    final String message = (body['message'] as String?)?.trim().isNotEmpty == true
        ? body['message'] as String
        : 'Something went wrong';
    throw UnknownException(message);
  }

  static Map<String, dynamic>? dataMap(Map<String, dynamic> body) {
    return _asStringMap(body['data']);
  }

  /// `data` as a list, or `data.list` from paginated payloads.
  static List<Map<String, dynamic>> dataList(dynamic body) {
    final Map<String, dynamic> envelope = requireMap(body);
    ensureSuccess(envelope);
    final dynamic data = envelope['data'];
    if (data is List) return _maps(data);
    final Map<String, dynamic>? nested = _asStringMap(data);
    if (nested != null) {
      final dynamic list = nested['list'] ?? nested['items'];
      if (list is List) return _maps(list);
    }
    return <Map<String, dynamic>>[];
  }

  static Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (dynamic key, dynamic val) => MapEntry<String, dynamic>('$key', val),
      );
    }
    return null;
  }

  static List<Map<String, dynamic>> _maps(List<dynamic> list) {
    return list
        .map(_asStringMap)
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
