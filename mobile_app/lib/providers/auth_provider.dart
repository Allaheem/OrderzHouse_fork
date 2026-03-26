// ??? ????????
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  String? get userRole => _user?.role;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final storedUser = await StorageService.getUser();
      final token = await StorageService.getToken();

      if (storedUser != null && token != null) {
        // Verify token is still valid by fetching user data
        try {
          final response = await _apiClient.getUserData();
          if (response.statusCode == 200) {
            _user = User.fromJson(
              response.data['user'] as Map<String, dynamic>,
            );
            await StorageService.saveUser(_user!);
          } else {
            await StorageService.clearAll();
          }
        } catch (e) {
          await StorageService.clearAll();
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.login({
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data['token'] != null) {
          // Direct login (no OTP/2FA)
          await StorageService.saveToken(data['token'] as String);
          _user = User.fromJson(data['userInfo'] as Map<String, dynamic>);
          await StorageService.saveUser(_user!);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          // OTP required
          _error = 'OTP required';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        final data = response.data as Map<String, dynamic>;
        _error = data['message'] as String? ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.verifyOtp({'email': email, 'otp': otp});

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await StorageService.saveToken(data['token'] as String);
        _user = User.fromJson(data['userInfo'] as Map<String, dynamic>);
        await StorageService.saveUser(_user!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = response.data as Map<String, dynamic>;
        _error = data['message'] as String? ?? 'OTP verification failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required int roleId,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
    required String country,
    required String username,
    List<int>? categoryIds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = {
        'role_id': roleId,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'phone_number': phoneNumber,
        'country': country,
        'username': username,
      };

      if (categoryIds != null && categoryIds.isNotEmpty) {
        data['category_ids'] = categoryIds;
      }

      final response = await _apiClient.register(data);

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] as String? ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.verifyEmail({
        'email': email,
        'otp': otp,
      });

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error =
            response.data['message'] as String? ?? 'Email verification failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.clearAll();
    _user = null;
    _error = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      final response = await _apiClient.getUserData();
      if (response.statusCode == 200) {
        _user = User.fromJson(response.data['user'] as Map<String, dynamic>);
        await StorageService.saveUser(_user!);
        notifyListeners();
      }
    } catch (e) {
      // Silent fail
    }
  }
}
