// ??? ????????
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/models/payment.dart';

class PaymentsRepository {
  PaymentsRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  /// Get client payment history
  Future<ApiResponse<List<Payment>>> getClientPayments() async {
    try {
      final response = await _dio.get('/payments/client/history');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data;

        // Parse array from various possible keys
        List<dynamic> items = [];
        if (data['payments'] != null && data['payments'] is List) {
          items = data['payments'] as List;
        } else if (data['data'] != null && data['data'] is List) {
          items = data['data'] as List;
        } else if (data['transactions'] != null &&
            data['transactions'] is List) {
          items = data['transactions'] as List;
        } else if (data['items'] != null && data['items'] is List) {
          items = data['items'] as List;
        } else if (data is List) {
          items = data;
        }

        final payments = items
            .map((item) => Payment.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse(success: true, data: payments);
      }

      return ApiResponse(
        success: false,
        message:
            response.data['message'] as String? ?? 'Failed to fetch payments',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            e.response?.data['message'] as String? ??
            'Failed to fetch payments',
      );
    }
  }

  /// Get freelancer wallet transactions
  Future<ApiResponse<List<Payment>>> getFreelancerTransactions() async {
    try {
      final response = await _dio.get(
        '/payments/freelancer/wallet/transactions',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data;

        // Parse array from various possible keys
        List<dynamic> items = [];
        if (data['transactions'] != null && data['transactions'] is List) {
          items = data['transactions'] as List;
        } else if (data['data'] != null && data['data'] is List) {
          items = data['data'] as List;
        } else if (data['payments'] != null && data['payments'] is List) {
          items = data['payments'] as List;
        } else if (data['items'] != null && data['items'] is List) {
          items = data['items'] as List;
        } else if (data is List) {
          items = data;
        }

        final transactions = items
            .map((item) => Payment.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse(success: true, data: transactions);
      }

      return ApiResponse(
        success: false,
        message:
            response.data['message'] as String? ??
            'Failed to fetch transactions',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            e.response?.data['message'] as String? ??
            'Failed to fetch transactions',
      );
    }
  }

  /// Get freelancer wallet balance
  Future<ApiResponse<double>> getFreelancerBalance() async {
    try {
      final response = await _dio.get('/payments/freelancer/wallet');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final balance = (response.data['balance'] as num?)?.toDouble() ?? 0.0;
        return ApiResponse(success: true, data: balance);
      }

      return ApiResponse(
        success: false,
        message:
            response.data['message'] as String? ?? 'Failed to fetch balance',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            e.response?.data['message'] as String? ?? 'Failed to fetch balance',
      );
    }
  }

  /// Get unified payment history from wallet (real API: balance + wallet_transactions)
  /// Endpoint: GET /payments/history?page=1&limit=50
  Future<ApiResponse<Map<String, dynamic>>> getPaymentHistory({
    String type = 'all',
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/payments/history',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data as Map<String, dynamic>;

        // Backend returns: balance, totalAmount, availableToWithdraw, transactions
        List<dynamic> items = [];
        if (data['transactions'] != null && data['transactions'] is List) {
          items = data['transactions'] as List;
        }

        final transactions = items
            .map((item) => Payment.fromJson(item as Map<String, dynamic>))
            .toList();

        final balance =
            (data['balance'] as num?)?.toDouble() ??
            (data['availableToWithdraw'] as num?)?.toDouble() ??
            (data['totalAmount'] as num?)?.toDouble() ??
            0.0;

        return ApiResponse(
          success: true,
          data: {
            'balance': balance,
            'totalAmount': (data['totalAmount'] as num?)?.toDouble() ?? balance,
            'availableToWithdraw':
                (data['availableToWithdraw'] as num?)?.toDouble() ?? balance,
            'currency': data['currency'] as String? ?? 'JOD',
            'transactions': transactions,
          },
        );
      }

      return ApiResponse(
        success: false,
        message:
            response.data['message'] as String? ??
            'Failed to fetch payment history',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const ApiResponse(
          success: false,
          message:
              'Payment history endpoint is not available. Please try again later or contact support.',
        );
      }
      return ApiResponse(
        success: false,
        message:
            e.response?.data['message'] as String? ??
            'Failed to fetch payment history',
      );
    }
  }
}
