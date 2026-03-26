// ??? ????????
import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/models/plan.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/config/app_config.dart';

class PlansRepository {
  final Dio _dio = DioClient.instance;

  /// Fetches all subscription plans.
  /// Endpoint: GET /plans
  /// Response: { "success": true, "plans": [ { ...planData... } ] }
  /// Matches web behavior: res.data.plans (NOT res.data.data)
  Future<ApiResponse<List<Plan>>> fetchPlans() async {
    try {
      if (AppConfig.isDevelopment) {
        // ignore: avoid_print
        print('📡 REQUEST[GET] => PATH: /plans');
      }

      final response = await _dio.get('/plans');

      if (AppConfig.isDevelopment) {
        // ignore: avoid_print
        print('✅ RESPONSE[${response.statusCode}] => PATH: /plans');
        // ignore: avoid_print
        print(
          '✅ RESPONSE[${response.statusCode}] => Final URL: ${response.requestOptions.uri}',
        );
        // ignore: avoid_print
        print(
          '✅ RESPONSE[${response.statusCode}] => Response data length: ${response.data?.toString().length ?? 0} chars',
        );

        // Debug: Print response.data keys and plans array length
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          // ignore: avoid_print
          print('🔍 DEBUG => Response data keys: ${data.keys.toList()}');
          if (data.containsKey('plans')) {
            final plansList = data['plans'];
            if (plansList is List) {
              // ignore: avoid_print
              print('🔍 DEBUG => plans array length: ${plansList.length}');
            } else {
              // ignore: avoid_print
              print(
                '⚠️ DEBUG => plans is not a List, type: ${plansList.runtimeType}',
              );
            }
          } else {
            // ignore: avoid_print
            print('⚠️ DEBUG => Response does not contain "plans" key');
          }
        }
      }

      final data = response.data as Map<String, dynamic>;

      // Match web behavior: Array.isArray(res.data.plans) ? res.data.plans : []
      final List<dynamic>? plansList = data['plans'] as List<dynamic>?;

      if (plansList == null || plansList.isEmpty) {
        if (AppConfig.isDevelopment) {
          // ignore: avoid_print
          print('⚠️ RESPONSE: No plans found in response.plans');
        }
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
            } catch (e) {
              if (AppConfig.isDevelopment) {
                // ignore: avoid_print
                print(
                  '⚠️ Failed to parse features JSON string for plan ${json['id']}: $e',
                );
              }
              // Leave as null - _featuresFromJson will handle it
              json['features'] = null;
            }
          }

          // Log raw values for debugging
          if (AppConfig.isDevelopment) {
            // ignore: avoid_print
            print(
              '🔍 Plan $i raw values: price=${json['price']} (${json['price'].runtimeType}), duration=${json['duration']} (${json['duration'].runtimeType}), features=${json['features']?.runtimeType}',
            );
          }

          final plan = Plan.fromJson(json);
          plans.add(plan);
        } catch (e, stackTrace) {
          if (AppConfig.isDevelopment) {
            // ignore: avoid_print
            print('⚠️ Failed to parse plan at index $i: $e');
            // ignore: avoid_print
            print('⚠️ Stack trace: $stackTrace');
            // ignore: avoid_print
            print('⚠️ Plan data: ${plansList[i]}');
          }
          // Skip invalid plans but continue processing others
        }
      }

      if (AppConfig.isDevelopment) {
        // ignore: avoid_print
        print(
          '✅ Parsed ${plans.length}/${plansList.length} plans successfully',
        );
        // ignore: avoid_print
        print('📊 Plans final count: ${plans.length}');
      }

      return ApiResponse(
        success: true,
        data: plans,
        message: 'Plans fetched successfully',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        // ignore: avoid_print
        print('❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /plans');
        // ignore: avoid_print
        print('❌ ERROR => Type: ${e.type}');
        // ignore: avoid_print
        print('❌ ERROR => Final URL: ${e.requestOptions.uri}');
        // ignore: avoid_print
        print('❌ ERROR => Message: ${e.message}');
        if (e.error != null) {
          // ignore: avoid_print
          print('❌ ERROR => Error: ${e.error}');
        }
        if (e.response != null) {
          // ignore: avoid_print
          print('❌ ERROR => Status Code: ${e.response?.statusCode}');
          // ignore: avoid_print
          print('❌ ERROR => Response Data: ${e.response?.data}');
        }
      }

      return ApiResponse(
        success: false,
        data: [],
        message:
            e.response?.data?['message'] as String? ?? 'Failed to fetch plans',
        error: e.response?.data as Map<String, dynamic>?,
      );
    } catch (e) {
      if (AppConfig.isDevelopment) {
        // ignore: avoid_print
        print('❌ UNEXPECTED ERROR => /plans: $e');
      }

      return ApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch plans: ${e.toString()}',
      );
    }
  }
}
