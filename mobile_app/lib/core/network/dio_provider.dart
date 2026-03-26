// ??? ????????
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';

/// Provides a single Dio instance for the app. Data sources depend on this.
/// Token is attached via [AuthInterceptor] (reads from SecureStore), not from Riverpod,
/// to avoid circular dependency with auth providers.
final dioProvider = Provider<Dio>((ref) {
  return DioClient.instance;
});
