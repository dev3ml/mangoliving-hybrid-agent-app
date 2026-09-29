import 'package:dio/dio.dart';

import '../../utils/app_logger.dart';

/// Logs HTTP request / response details.
final class LoggingInterceptor extends Interceptor {
  LoggingInterceptor(this._logger);

  final AppLogger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.debug('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.debug('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final dynamic data = err.response?.data;
    final String detail = data == null ? '' : ' body=$data';
    _logger.error(
      '✕ ${err.response?.statusCode} ${err.requestOptions.uri}$detail',
      err,
      err.stackTrace,
    );
    handler.next(err);
  }
}
