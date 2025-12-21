import 'package:google_sign_in/google_sign_in.dart';
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

  // Google Sign In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

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

  /// Login with Google
  Future<AuthResult> loginWithGoogle() async {
    try {
      // Sign out first to ensure account picker shows
      await _googleSignIn.signOut();

      // Trigger Google sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult(
          success: false,
          error: 'Google sign in cancelled',
        );
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Send ID token to our backend
      final response = await _api.post<Map<String, dynamic>>(
        '/auth/sso/google',
        body: {
          'idToken': googleAuth.idToken,
        },
      );

      if (response.success && response.data != null) {
        final data = response.data!;

        // Check if registration is needed
        if (data['needsRegistration'] == true) {
          final profile = data['profile'] as Map<String, dynamic>?;
          return AuthResult(
            success: false,
            needsRegistration: true,
            ssoProfile: {
              'provider': 'google',
              'providerAccountId': profile?['providerAccountId'],
              'email': profile?['email'] ?? googleUser.email,
              'firstName': profile?['firstName'] ?? googleUser.displayName?.split(' ').first ?? '',
              'lastName': profile?['lastName'] ?? (googleUser.displayName?.split(' ').length ?? 0) > 1
                  ? googleUser.displayName!.split(' ').sublist(1).join(' ')
                  : '',
              'picture': profile?['picture'] ?? googleUser.photoUrl,
            },
            error: 'Account not found. Please register.',
          );
        }

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
        error: response.error ?? 'Google login failed',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Google sign in error: ${e.toString()}',
      );
    }
  }

  /// Register new user
  Future<AuthResult> register({
    required String firstName,
    required String surname,
    required String email,
    String? phone,
    String? libraryId,
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
    final response = await _api.get<Map<String, dynamic>>('/auth/register');
    return response.success ? response.data : null;
  }

  /// Logout
  Future<void> logout() async {
    // Sign out from Google if signed in
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

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
