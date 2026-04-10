// ??? ????????
class AppConstants {
  // API base URL: use [AppConfig.baseUrl] (reads .env APP_API_URL / defaults).

  // Storage Keys
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';

  // Roles
  static const int roleAdmin = 1;
  static const int roleClient = 2;
  static const int roleFreelancer = 3;
}
