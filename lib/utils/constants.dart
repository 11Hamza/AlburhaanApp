/// API Configuration
class ApiConstants {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:3000/api';

  // For Android emulator connecting to localhost
  static const String androidEmulatorUrl = 'http://10.0.2.2:3000/api';

  // For physical device testing (replace with your computer's IP)
  static const String localNetworkUrl = 'http://192.168.1.100:3000/api';

  // Endpoints
  static const String auth = '/auth';
  static const String books = '/books';
  static const String filters = '/filters';
  static const String user = '/user';
  static const String loans = '/loans';
  static const String holds = '/holds';
  static const String favorites = '/favorites';
  static const String libraries = '/libraries';
  static const String health = '/health';
}

/// App Configuration
class AppConstants {
  static const String appName = 'Al-Burhaan Library';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int itemsPerPage = 10;

  // Cache durations
  static const Duration cacheExpiry = Duration(hours: 1);

  // Image placeholder
  static const String placeholderImage = 'assets/images/book_placeholder.png';
}

/// Storage Keys
class StorageKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String language = 'language';
  static const String theme = 'theme';
  static const String homeLibrary = 'home_library';
  static const String isGuest = 'is_guest';
}
