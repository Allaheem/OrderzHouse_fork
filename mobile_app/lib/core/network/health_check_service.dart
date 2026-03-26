// ??? ????????
import 'package:dio/dio.dart';
import '../config/app_config.dart';

class HealthCheckService {
  HealthCheckService._();
  static const Duration _healthTimeout = Duration(seconds: 10);

  /// Create a lightweight Dio instance for health checks with short timeout
  static Dio _createHealthCheckDio() {
    return Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: _healthTimeout,
        receiveTimeout: _healthTimeout,
        sendTimeout: _healthTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Ping the API server to check connectivity
  /// Tries /health, /api/health, /, and /api/stats in order
  static Future<HealthCheckResult> ping() async {
    final dio = _createHealthCheckDio();
    final baseUrl = AppConfig.baseUrl;

    // List of endpoints to try
    final endpoints = ['/health', '/api/health', '/', '/api/stats'];

    for (final endpoint in endpoints) {
      try {
        final response = await dio.get(endpoint);

        // ignore: avoid_print
        print(
          '✅ Health check SUCCESS: $baseUrl$endpoint - Status: ${response.statusCode}',
        );
        return HealthCheckResult(
          success: true,
          endpoint: endpoint,
          statusCode: response.statusCode,
          message: 'API is reachable at $baseUrl$endpoint',
        );
      } on DioException catch (e) {
        // If we get a response (even error), server is reachable
        if (e.response != null) {
          // ignore: avoid_print
          print(
            '⚠️ Health check PARTIAL: $baseUrl$endpoint - Status: ${e.response?.statusCode}',
          );
          return HealthCheckResult(
            success: true,
            endpoint: endpoint,
            statusCode: e.response?.statusCode,
            message:
                'API is reachable but returned error: ${e.response?.statusCode}',
          );
        }
        // Continue to next endpoint if connection failed
        // ignore: avoid_print
        print(
          '❌ Health check FAILED: $baseUrl$endpoint - ${e.type}: ${e.message}',
        );
      } catch (e) {
        // ignore: avoid_print
        print('❌ Health check ERROR: $baseUrl$endpoint - $e');
      }
    }

    // All endpoints failed
    // ignore: avoid_print
    print('❌ Health check FAILED: Could not reach API at $baseUrl');
    return HealthCheckResult(
      success: false,
      endpoint: null,
      statusCode: null,
      message:
          'Could not reach API at $baseUrl. Check if server is running and baseUrl is correct.',
    );
  }
}

class HealthCheckResult {
  final bool success;
  final String? endpoint;
  final int? statusCode;
  final String message;

  HealthCheckResult({
    required this.success,
    this.endpoint,
    this.statusCode,
    required this.message,
  });
}
