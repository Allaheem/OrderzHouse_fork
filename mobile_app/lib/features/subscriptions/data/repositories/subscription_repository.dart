// ??? ????????
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

/// Subscriptions: company survey (offline) + Apple IAP receipt verification.
class SubscriptionRepository {
  SubscriptionRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  /// Activates subscription from App Store receipt. [planId] optional for restore flows.
  Future<AppleReceiptVerifyResult> verifyAppleReceipt({
    required String receiptDataBase64,
    int? planId,
  }) async {
    try {
      final body = <String, dynamic>{'receiptData': receiptDataBase64};
      if (planId != null) {
        body['planId'] = planId;
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '/subscriptions/apple/verify-receipt',
        data: body,
      );
      final data = response.data ?? {};
      final ok = data['success'] == true;
      final message = data['message']?.toString() ?? (ok ? 'OK' : 'Verification failed');
      return AppleReceiptVerifyResult(
        success: ok,
        message: message,
        idempotent: data['idempotent'] == true,
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      return AppleReceiptVerifyResult(
        success: false,
        message: msg ?? e.message ?? 'Network error',
        idempotent: false,
      );
    } catch (e) {
      return AppleReceiptVerifyResult(
        success: false,
        message: e.toString(),
        idempotent: false,
      );
    }
  }
}

class AppleReceiptVerifyResult {
  const AppleReceiptVerifyResult({
    required this.success,
    required this.message,
    required this.idempotent,
  });

  final bool success;
  final String message;
  final bool idempotent;
}
