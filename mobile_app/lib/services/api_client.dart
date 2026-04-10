// ??? ????????
import 'package:dio/dio.dart';
import '../core/config/app_config.dart';
import 'storage_service.dart';

class ApiClient {
  late Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 403) {
            // Token expired or invalid
            StorageService.deleteToken();
            StorageService.deleteUser();
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Auth Endpoints
  Future<Response> register(Map<String, dynamic> data) async {
    return await _dio.post('/users/register', data: data);
  }

  Future<Response> verifyEmail(Map<String, dynamic> data) async {
    return await _dio.post('/users/verify-email', data: data);
  }

  Future<Response> login(Map<String, dynamic> data) async {
    return await _dio.post('/users/login', data: data);
  }

  Future<Response> verifyOtp(Map<String, dynamic> data) async {
    return await _dio.post('/users/verify-otp', data: data);
  }

  Future<Response> sendOtp(Map<String, dynamic> data) async {
    return await _dio.post('/users/send-otp', data: data);
  }

  // User Endpoints
  Future<Response> getUserData() async {
    return await _dio.get('/users/getUserdata');
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return await _dio.put('/users/edit', data: data);
  }

  Future<Response> uploadProfilePic(FormData formData) async {
    return await _dio.post('/users/uploadProfilePic', data: formData);
  }

  // Project Endpoints
  Future<Response> getMyProjects() async {
    return await _dio.get('/projects/myprojects');
  }

  Future<Response> getProjectsByCategory(int categoryId) async {
    return await _dio.get('/projects/public/category/$categoryId');
  }

  Future<Response> getProjectDetails(int projectId) async {
    return await _dio.get('/projects/project/$projectId/applications');
  }

  Future<Response> createProject(FormData formData) async {
    return await _dio.post('/projects', data: formData);
  }

  Future<Response> applyForProject(int projectId, {String? message}) async {
    return await _dio.post(
      '/projects/$projectId/apply',
      data: message != null ? {'message': message} : {},
    );
  }

  // Categories
  Future<Response> getCategories() async {
    return await _dio.get('/category');
  }

  Future<Response> getSubCategories(int categoryId) async {
    return await _dio.get('/category/$categoryId/sub-categories');
  }

  Future<Response> getSubSubCategories(int subCategoryId) async {
    return await _dio.get(
      '/category/sub-category/$subCategoryId/sub-sub-categories',
    );
  }

  // Payments
  Future<Response> getUserPayments(int userId) async {
    return await _dio.get('/payments/user/$userId');
  }

  // Plans
  Future<Response> getPlans() async {
    return await _dio.get('/plans');
  }
}
