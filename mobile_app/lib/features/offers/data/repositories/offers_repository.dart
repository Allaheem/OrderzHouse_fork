// ??? ????????
import 'package:dio/dio.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/config/app_config.dart';

class OffersRepository {
  OffersRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  /// Send offer for a bidding project
  /// Endpoint: POST /offers/:projectId/offers
  /// Body: { bid_amount: number, proposal?: string }
  Future<ApiResponse<Map<String, dynamic>>> sendOffer({
    required int projectId,
    required double bidAmount,
    String? proposal,
  }) async {
    try {
      if (AppConfig.isDevelopment) {
        // ignore: avoid_print
        print('📡 REQUEST[POST] => PATH: /offers/$projectId/offers');
        // ignore: avoid_print
        print(
          '📡 REQUEST[POST] => Body: { bid_amount: $bidAmount, proposal: ${proposal ?? "null"} }',
        );
      }

      final response = await _dio.post(
        '/offers/$projectId/offers',
        data: {
          'bid_amount': bidAmount,
          if (proposal != null && proposal.isNotEmpty) 'proposal': proposal,
        },
      );

      if (AppConfig.isDevelopment) {
        // ignore: avoid_print
        print(
          '✅ RESPONSE[${response.statusCode}] => PATH: /offers/$projectId/offers',
        );
        // ignore: avoid_print
        print('✅ RESPONSE[${response.statusCode}] => Data: ${response.data}');
      }

      return ApiResponse(
        success: true,
        data: response.data as Map<String, dynamic>? ?? {},
        message:
            (response.data as Map<String, dynamic>?)?['message'] as String? ??
            'Offer sent successfully',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        // ignore: avoid_print
        print(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /offers/$projectId/offers',
        );
        // ignore: avoid_print
        print('❌ ERROR => Response Data: ${e.response?.data}');
      }

      final errorMessage = e.response?.data?['message'] as String?;
      final statusCode = e.response?.statusCode;

      return ApiResponse(
        success: false,
        message: errorMessage ?? 'Failed to send offer',
        error: {
          'statusCode': statusCode,
          ...?e.response?.data as Map<String, dynamic>?,
        },
      );
    } catch (e) {
      if (AppConfig.isDevelopment) {
        // ignore: avoid_print
        print('❌ UNEXPECTED ERROR => /offers/$projectId/offers: $e');
      }

      return ApiResponse(
        success: false,
        message: 'Failed to send offer: ${e.toString()}',
      );
    }
  }

  /// Check if freelancer has pending offer for a project
  /// Endpoint: GET /offers/my/:projectId/pending
  /// Response: { success: true, hasPendingOffer: boolean }
  Future<ApiResponse<bool>> checkMyPendingOffer(int projectId) async {
    try {
      if (AppConfig.isDevelopment) {
        // ignore: avoid_print
        print('📡 REQUEST[GET] => PATH: /offers/my/$projectId/pending');
      }

      final response = await _dio.get('/offers/my/$projectId/pending');

      if (AppConfig.isDevelopment) {
        // ignore: avoid_print
        print(
          '✅ RESPONSE[${response.statusCode}] => PATH: /offers/my/$projectId/pending',
        );
        // ignore: avoid_print
        print('✅ RESPONSE[${response.statusCode}] => Data: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      final hasPendingOffer = data['hasPendingOffer'] as bool? ?? false;

      return ApiResponse(
        success: true,
        data: hasPendingOffer,
        message: 'Check completed',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        // ignore: avoid_print
        print(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /offers/my/$projectId/pending',
        );
        // ignore: avoid_print
        print('❌ ERROR => Response Data: ${e.response?.data}');
      }

      // If 404 or other error, assume no pending offer
      return ApiResponse(
        success: true,
        data: false,
        message: e.response?.data?['message'] as String?,
      );
    } catch (e) {
      if (AppConfig.isDevelopment) {
        // ignore: avoid_print
        print('❌ UNEXPECTED ERROR => /offers/my/$projectId/pending: $e');
      }

      return const ApiResponse(
        success: true,
        data: false,
        message: 'Failed to check pending offer',
      );
    }
  }
}
