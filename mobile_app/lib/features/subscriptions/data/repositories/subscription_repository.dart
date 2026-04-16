// ??? ????????
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

/// Subscriptions: company survey (offline) + Apple IAP receipt verification.
class SubscriptionRepository {
  SubscriptionRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  /// `GET /subscriptions/status` — current plan, remaining days, etc. (authenticated).
  Future<SubscriptionStatusSnapshot> fetchSubscriptionStatus() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/subscriptions/status',
      );
      final data = response.data ?? {};
      if (data['success'] != true) {
        return SubscriptionStatusSnapshot.failure(
          data['error']?.toString() ?? 'Could not load subscription status',
        );
      }
      return SubscriptionStatusSnapshot.fromJson(data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data as Map)['error']?.toString()
          : null;
      return SubscriptionStatusSnapshot.failure(
        msg ?? e.message ?? 'Network error',
      );
    } catch (_) {
      return SubscriptionStatusSnapshot.failure(
        'Could not load subscription status. Please try again.',
      );
    }
  }

  /// Whether the API has PayPal plan checkout enabled (`PAYPAL_ENABLED=true`). Used to show the PayPal button.
  ///
  /// Tries `GET /paypal/checkout-available` first, then `GET /subscriptions/paypal-checkout-available`
  /// (same payload) so older deploys without `/paypal` still work after a minimal backend update.
  /// Uses [validateStatus] so 404 does not throw (avoids noisy Dio errors when a route is missing).
  Future<bool> isPayPalCheckoutAvailable() async {
    const paths = [
      '/paypal/checkout-available',
      '/subscriptions/paypal-checkout-available',
    ];
    for (final path in paths) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          path,
          options: Options(
            validateStatus: (code) => code != null && code < 500,
          ),
        );
        if (response.statusCode == 404) {
          continue;
        }
        if (response.statusCode != 200) {
          return false;
        }
        final data = response.data ?? {};
        return data['available'] == true;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          continue;
        }
        return false;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

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
        message: 'Could not verify App Store receipt. Please try again.',
        idempotent: false,
      );
    }
  }

  /// Creates a PayPal order and returns the approval URL (freelancers only; backend enforces).
  Future<PayPalPlanOrderResult> createPayPalPlanOrder({required int planId}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/paypal/plan/create-order',
        data: {'planId': planId},
      );
      final data = response.data ?? {};
      final ok = data['success'] == true;
      return PayPalPlanOrderResult(
        success: ok,
        message: data['message']?.toString() ?? (ok ? 'OK' : 'Failed'),
        orderId: data['orderId']?.toString(),
        approvalUrl: data['approvalUrl']?.toString(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      return PayPalPlanOrderResult(
        success: false,
        message: msg ?? e.message ?? 'Network error',
        orderId: null,
        approvalUrl: null,
      );
    } catch (_) {
      return PayPalPlanOrderResult(
        success: false,
        message: 'Could not create PayPal order. Please try again.',
        orderId: null,
        approvalUrl: null,
      );
    }
  }

  /// Captures payment after the user approves the order in PayPal (browser / app).
  Future<PayPalCaptureResult> capturePayPalPlanOrder({required String orderId}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/paypal/plan/capture',
        data: {'orderId': orderId},
      );
      final data = response.data ?? {};
      final ok = data['success'] == true;
      return PayPalCaptureResult(
        success: ok,
        message: data['message']?.toString() ?? (ok ? 'OK' : 'Capture failed'),
        idempotent: data['idempotent'] == true,
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      return PayPalCaptureResult(
        success: false,
        message: msg ?? e.message ?? 'Network error',
        idempotent: false,
      );
    } catch (e) {
      return PayPalCaptureResult(
        success: false,
        message: 'Could not complete PayPal payment. Please try again.',
        idempotent: false,
      );
    }
  }
}

/// Parsed `GET /subscriptions/status` body (partial).
class SubscriptionStatusSnapshot {
  const SubscriptionStatusSnapshot({
    required this.success,
    this.errorMessage,
    this.overallStatus = 'none',
    this.remainingDays = 0,
    this.statusMessage = '',
    this.planName,
    this.subscriptionRowStatus,
    this.endDateRaw,
  });

  final bool success;
  final String? errorMessage;

  /// Top-level `status`: none | pending_start | active | cancelled
  final String overallStatus;
  final int remainingDays;
  final String statusMessage;
  final String? planName;
  final String? subscriptionRowStatus;
  final String? endDateRaw;

  /// Mirrors backend rules for new plan checkout (Stripe/PayPal): block duplicate while pending or active period.
  /// Cancelled / expired rows can subscribe again (even if an old end_date is still in the future).
  bool get blocksNewPlanPurchase {
    if (!success) return false;
    if (overallStatus == 'none') return false;
    final s = overallStatus.toLowerCase();
    if (s == 'cancelled' || s == 'expired') return false;
    if (s == 'pending_start') return true;
    if (s == 'active' && remainingDays > 0) return true;
    return false;
  }

  factory SubscriptionStatusSnapshot.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'];
    String? planName;
    String? rowStatus;
    String? endRaw;
    if (sub is Map<String, dynamic>) {
      planName = sub['plan_name']?.toString();
      rowStatus = sub['status']?.toString();
      endRaw = sub['end_date']?.toString();
    }
    return SubscriptionStatusSnapshot(
      success: true,
      overallStatus: json['status']?.toString() ?? 'none',
      remainingDays: (json['remaining_days'] as num?)?.toInt() ?? 0,
      statusMessage: json['status_message']?.toString() ?? '',
      planName: planName,
      subscriptionRowStatus: rowStatus,
      endDateRaw: endRaw,
    );
  }

  factory SubscriptionStatusSnapshot.failure(String msg) => SubscriptionStatusSnapshot(
        success: false,
        errorMessage: msg,
      );
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

class PayPalPlanOrderResult {
  const PayPalPlanOrderResult({
    required this.success,
    required this.message,
    required this.orderId,
    required this.approvalUrl,
  });

  final bool success;
  final String message;
  final String? orderId;
  final String? approvalUrl;
}

class PayPalCaptureResult {
  const PayPalCaptureResult({
    required this.success,
    required this.message,
    required this.idempotent,
  });

  final bool success;
  final String message;
  final bool idempotent;
}
