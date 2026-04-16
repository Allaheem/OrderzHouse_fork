// ??? ????????
import 'package:dio/dio.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/network/dio_client.dart';

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
      final response = await _dio.post(
        '/offers/$projectId/offers',
        data: {
          'bid_amount': bidAmount,
          if (proposal != null && proposal.isNotEmpty) 'proposal': proposal,
        },
      );

      return ApiResponse(
        success: true,
        data: response.data as Map<String, dynamic>? ?? {},
        message:
            (response.data as Map<String, dynamic>?)?['message'] as String? ??
            'Offer sent successfully',
      );
    } on DioException catch (e) {
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
    } catch (_) {
      return ApiResponse(
        success: false,
        message: 'Failed to send offer',
      );
    }
  }

  /// Check if freelancer has pending offer for a project
  /// Endpoint: GET /offers/my/:projectId/pending
  /// Response: { success: true, hasPendingOffer: boolean }
  Future<ApiResponse<bool>> checkMyPendingOffer(int projectId) async {
    try {
      final response = await _dio.get('/offers/my/$projectId/pending');

      final data = response.data as Map<String, dynamic>;
      final hasPendingOffer = data['hasPendingOffer'] as bool? ?? false;

      return ApiResponse(
        success: true,
        data: hasPendingOffer,
        message: 'Check completed',
      );
    } on DioException catch (e) {
      // If 404 or other error, assume no pending offer
      return ApiResponse(
        success: true,
        data: false,
        message: e.response?.data?['message'] as String?,
      );
    } catch (_) {
      return const ApiResponse(
        success: true,
        data: false,
        message: 'Failed to check pending offer',
      );
    }
  }
}
