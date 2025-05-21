class ApiConstants {
  static const String baseUrl = 'https://api.elsahm.com/api';
  
  // API endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String properties = '/properties';
  static const String users = '/users';
  static const String bookings = '/bookings';
  static const String categories = '/categories';
  
  // Shared preferences keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';
}

class AppConstants {
  // App name
  static const String appName = 'Elsahm';
  
  // Asset paths
  static const String logoPath = 'assets/images/logo_dark.png';
  static const String placeholderImage = 'assets/images/placeholder.png';
  
  // Animation durations
  static const int defaultAnimationDuration = 300; // in milliseconds
  
  // Default pagination limits
  static const int defaultPageSize = 10;
} 