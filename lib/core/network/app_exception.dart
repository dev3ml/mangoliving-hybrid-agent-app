import 'package:dio/dio.dart';

/// Normalized network / API failure types.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

final class TimeoutException extends AppException {
  const TimeoutException([
    super.message = 'This is taking longer than usual. Try again.',
  ]);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found']);
}

final class ServerException extends AppException {
  const ServerException([super.message = 'Server error']);
}

final class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong']);
}

/// Maps [DioException] into domain [AppException]s.
abstract final class ExceptionMapper {
  static AppException fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final int? status = error.response?.statusCode;
        if (status == 401) return const UnauthorizedException();
        if (status == 404) return const NotFoundException();
        if (status != null && status >= 500) return const ServerException();
        final dynamic data = error.response?.data;
        if (data is Map && data['message'] is String) {
          return UnknownException(data['message'] as String);
        }
        return UnknownException(
          error.response?.statusMessage ?? 'Request failed',
        );
      case DioExceptionType.cancel:
        return const UnknownException('Request cancelled');
      case DioExceptionType.badCertificate:
        return const NetworkException('Invalid certificate');
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return UnknownException(error.message ?? 'Something went wrong');
    }
  }
}
