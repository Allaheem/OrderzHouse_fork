// ??? ????????
import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/models/plan.dart';
import '../../../../core/network/dio_client.dart';

class PlansRepository {
  final Dio _dio = DioClient.instance;

  /// Fetches all subscription plans.
  /// Endpoint: GET /plans
  /// Response: { "success": true, "plans": [ { ...planData... } ] }
  /// Matches web behavior: res.data.plans (NOT res.data.data)
  Future<ApiResponse<List<Plan>>> fetchPlans() async {
    try {
      final response = await _dio.get('/plans');

      final data = response.data as Map<String, dynamic>;

      // Match web behavior: Array.isArray(res.data.plans) ? res.data.plans : []
      final List<dynamic>? plansList = data['plans'] as List<dynamic>?;

      if (plansList == null || plansList.isEmpty) {
        return const ApiResponse(
          success: true,
          data: [],
          message: 'No plans available',
        );
      }

      final plans = <Plan>[];
      for (var i = 0; i < plansList.length; i++) {
        try {
          final json = plansList[i] as Map<String, dynamic>;

          // Pre-process features if it's a JSON string (before Plan.fromJson handles it)
          if (json['features'] is String) {
            try {
              final decoded = jsonDecode(json['features'] as String);
              json['features'] = decoded;
            } catch (_) {
              // Leave as null - _featuresFromJson will handle it
              json['features'] = null;
            }
          }

          final plan = Plan.fromJson(json);
          plans.add(plan);
        } catch (_, __) {
          // Skip invalid plans but continue processing others
        }
      }

      return ApiResponse(
        success: true,
        data: plans,
        message: 'Plans fetched successfully',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message:
            e.response?.data?['message'] as String? ?? 'Failed to fetch plans',
        error: e.response?.data as Map<String, dynamic>?,
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch plans',
      );
    }
  }
}
