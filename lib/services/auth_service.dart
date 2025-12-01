import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthResult {
  final bool success;
  final User? user;
  final String? token;
  final String? error;

  AuthResult({
    required this.success,
    this.user,
    this.token,
    this.error,
  });
}

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  /// Login with library card number and password
  Future<AuthResult> login(String cardNumber, String password) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      body: {
        'cardNumber': cardNumber,
        'password': password,
      },
    );

    if (response.success && response.data != null) {
      final data = response.data!;
      final token = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token != null) {
        // Save token
        await _storage.setAuthToken(token);
        _api.setAuthToken(token);

        // Create user
        final user = userData != null
            ? User.fromJson(userData)
            : User(patronId: 0, cardNumber: cardNumber, firstName: '', surname: '');

        await _storage.setIsGuest(false);

        return AuthResult(
          success: true,
          user: user,
          token: token,
        );
      }
    }

    return AuthResult(
      success: false,
      error: response.error ?? 'Login failed',
    );
  }

  /// Login as guest
  Future<AuthResult> loginAsGuest() async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/guest',
    );

    if (response.success && response.data != null) {
      final data = response.data!;
      final token = data['token'] as String?;

      if (token != null) {
        await _storage.setAuthToken(token);
        await _storage.setIsGuest(true);
        _api.setAuthToken(token);

        return AuthResult(
          success: true,
          user: User.guest(),
          token: token,
        );
      }
    }

    return AuthResult(
      success: false,
      error: response.error ?? 'Failed to create guest session',
    );
  }

  /// Logout
  Future<void> logout() async {
    await _api.post('/auth/logout');
    await _storage.clearAuth();
    _api.setAuthToken(null);
  }

  /// Refresh token
  Future<AuthResult> refreshToken() async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/refresh',
    );

    if (response.success && response.data != null) {
      final data = response.data!;
      final token = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token != null) {
        await _storage.setAuthToken(token);
        _api.setAuthToken(token);

        return AuthResult(
          success: true,
          user: userData != null ? User.fromJson(userData) : null,
          token: token,
        );
      }
    }

    return AuthResult(
      success: false,
      error: response.error ?? 'Token refresh failed',
    );
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.getAuthToken();
    if (token != null) {
      _api.setAuthToken(token);
      return true;
    }
    return false;
  }

  /// Check if current session is guest
  Future<bool> isGuest() async {
    return await _storage.getIsGuest();
  }

  /// Get stored token
  Future<String?> getToken() async {
    return await _storage.getAuthToken();
  }
}
