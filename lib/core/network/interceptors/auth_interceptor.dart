import 'package:dio/dio.dart';

/// Attaches the Authorization header when a token is available.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor({this.tokenProvider});

  final Future<String?> Function()? tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token = await tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
