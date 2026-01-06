import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthResult {
  final bool success;
  final User? user;
  final String? token;
  final String? error;
  final bool needsRegistration;
  final Map<String, dynamic>? ssoProfile;

  AuthResult({
    required this.success,
    this.user,
    this.token,
    this.error,
    this.needsRegistration = false,
    this.ssoProfile,
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

  /// Register new user
  Future<AuthResult> register({
    required String firstName,
    required String surname,
    required String email,
    String? phone,
    String? libraryId,
    String? categoryId,
    String? ssoProvider,
    String? ssoProviderAccountId,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/register',
      body: {
        'firstName': firstName,
        'surname': surname,
        'email': email,
        if (phone != null) 'phone': phone,
        if (libraryId != null) 'libraryId': libraryId,
        if (categoryId != null) 'categoryId': categoryId,
        if (ssoProvider != null) 'ssoProvider': ssoProvider,
        if (ssoProviderAccountId != null) 'ssoProviderAccountId': ssoProviderAccountId,
      },
    );

    if (response.success && response.data != null) {
      final data = response.data!;
      final token = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token != null) {
        await _storage.setAuthToken(token);
        await _storage.setIsGuest(false);
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
      error: response.error ?? 'Registration failed',
    );
  }

  /// Get registration requirements (libraries, categories)
  Future<Map<String, dynamic>?> getRegistrationInfo() async {
    debugPrint('DEBUG: Fetching registration info from /auth/register');
    final response = await _api.get<Map<String, dynamic>>('/auth/register');
    debugPrint('DEBUG: Registration info response success=${response.success}, statusCode=${response.statusCode}');
    debugPrint('DEBUG: Registration info data=${response.data}');
    debugPrint('DEBUG: Registration info error=${response.error}');
    return response.success ? response.data : null;
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
