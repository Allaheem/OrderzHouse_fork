// ??? ????????
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/models/referral_info.dart';

class ReferralsRepository {
  final Dio _dio = DioClient.instance;

  /// Get current user's referral information
  Future<ApiResponse<ReferralInfo>> getMyReferrals() async {
    try {
      final response = await _dio.get('/referrals/me');

      // Accept both 200 with success field OR 200 with data directly
      if (response.statusCode == 200) {
        final data = response.data;

        // Handle different response formats
        Map<String, dynamic> jsonData;
        if (data is Map<String, dynamic>) {
          jsonData = data;
        } else {
          return const ApiResponse(
            success: false,
            message: 'Invalid response format',
          );
        }

        // Check success field if present, otherwise assume success for 200 status
        final hasSuccess = jsonData['success'];
        if (hasSuccess != null && hasSuccess == false) {
          return ApiResponse(
            success: false,
            message:
                jsonData['message'] as String? ?? 'Failed to fetch referrals',
          );
        }

        // Parse referral info with safe defaults
        var referralInfo = ReferralInfo.fromJson(jsonData);

        // If code is null/empty, try to generate one via POST /referrals/code
        if (!referralInfo.hasValidCode) {
          try {
            final codeResponse = await _dio.post('/referrals/code');
            if (codeResponse.statusCode == 200) {
              final codeData = codeResponse.data;
              if (codeData is Map<String, dynamic>) {
                // Try to extract code from response
                final newCode =
                    (codeData['code'] ?? codeData['referralCode'] ?? '')
                        as String;
                if (newCode.isNotEmpty) {
                  // Re-parse with the new code
                  final updatedJson = Map<String, dynamic>.from(jsonData);
                  updatedJson['code'] = newCode.trim();
                  if (codeData['referralCode'] != null) {
                    updatedJson['referralCode'] = newCode.trim();
                  }
                  referralInfo = ReferralInfo.fromJson(updatedJson);

                }
              }
            }
          } catch (_) {
            // If code generation fails, continue with empty code (won't crash)
          }
        }

        return ApiResponse(success: true, data: referralInfo);
      }

      return ApiResponse(
        success: false,
        message:
            (response.data as Map<String, dynamic>?)?['message'] as String? ??
            'Failed to fetch referrals',
      );
    } on DioException catch (e) {
      String? errorMessage;
      if (e.response?.data is Map) {
        errorMessage =
            (e.response?.data as Map<String, dynamic>)['message'] as String?;
      }

      // Handle 401 - authentication required
      if (e.response?.statusCode == 401) {
        return const ApiResponse(
          success: false,
          message: 'Please log in to view referrals',
        );
      }

      // Handle 403 - forbidden (e.g., not allowed to view referrals)
      if (e.response?.statusCode == 403) {
        return ApiResponse(
          success: false,
          message: errorMessage ?? 'Access denied',
        );
      }

      return ApiResponse(
        success: false,
        message: errorMessage ?? 'Failed to fetch referrals',
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch referrals',
      );
    }
  }

  /// Apply referral code during signup
  Future<ApiResponse<void>> applyReferralCode(String code) async {
    try {
      final response = await _dio.post(
        '/referrals/apply',
        data: {'code': code},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return const ApiResponse(success: true, data: null);
      }

      return ApiResponse(
        success: false,
        message:
            response.data['message'] as String? ??
            'Failed to apply referral code',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            e.response?.data['message'] as String? ??
            'Failed to apply referral code',
      );
    }
  }

  /// Complete referral (called after first paid plan purchase)
  Future<ApiResponse<void>> completeReferral(int referredUserId) async {
    try {
      final response = await _dio.post(
        '/referrals/complete',
        data: {'referredUserId': referredUserId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return const ApiResponse(success: true, data: null);
      }

      return ApiResponse(
        success: false,
        message:
            response.data['message'] as String? ??
            'Failed to complete referral',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            e.response?.data['message'] as String? ??
            'Failed to complete referral',
      );
    }
  }
}
