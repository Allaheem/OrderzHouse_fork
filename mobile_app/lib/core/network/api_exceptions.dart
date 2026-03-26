// ??? ????????
import 'package:dio/dio.dart';
import '../utils/failure.dart';

/// Maps Dio errors to domain [Failure]. Use in data layer only.
abstract final class ApiExceptions {
  ApiExceptions._();

  static Failure fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final body = e.response?.data;
    final message =
        _extractMessage(body) ?? _messageFromType(e.type, statusCode);
    return Failure(
      message: message,
      statusCode: statusCode,
      code: body is Map ? body['code'] as String? : null,
    );
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }

  static String _messageFromType(DioExceptionType type, int? statusCode) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Check your internet connection.';
      case DioExceptionType.badResponse:
        return _statusMessage(statusCode);
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.unknown:
        return 'Network error. Check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static String _statusMessage(int? code) {
    switch (code) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Please sign in again.';
      case 403:
        return 'Access denied. Please verify your account.';
      case 404:
        return 'Not found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
