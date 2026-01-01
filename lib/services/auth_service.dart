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
      print('DEBUG [SSO]: Starting Google Sign-In');
      // Sign out first to ensure account picker shows
      await _googleSignIn.signOut();

      // Trigger Google sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('DEBUG [SSO]: Google sign in cancelled by user');
        return AuthResult(
          success: false,
          error: 'Google sign in cancelled',
        );
      }

      print('DEBUG [SSO]: Got Google user: ${googleUser.email}');

      // Get auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('DEBUG [SSO]: Got auth, idToken length=${googleAuth.idToken?.length ?? 0}');
      print('DEBUG [SSO]: Sending to backend...');

      // Send ID token to our backend
      final response = await _api.post<Map<String, dynamic>>(
        '/auth/sso/google',
        body: {
          'idToken': googleAuth.idToken,
        },
      );

      print('DEBUG [SSO]: Response received');
      print('DEBUG [SSO]: success=${response.success}, statusCode=${response.statusCode}');
      print('DEBUG [SSO]: error=${response.error}');
      print('DEBUG [SSO]: data type=${response.data?.runtimeType}');

      if (!response.success) {
        print('DEBUG [SSO]: Request failed with error: ${response.error}');
        return AuthResult(
          success: false,
          error: response.error ?? 'Google login failed',
        );
      }

      if (response.data == null) {
        print('DEBUG [SSO]: Response data is null');
        return AuthResult(
          success: false,
          error: 'Empty response from server',
        );
      }

      // Wrap data parsing in try-catch to catch type errors
      try {
        final data = response.data!;
        print('DEBUG [SSO]: Parsing response data');

        // Log all keys and their types
        data.forEach((key, value) {
          print('DEBUG [SSO]: data["$key"] = $value (${value?.runtimeType})');
        });

        // Check if registration is needed (handle both bool and string)
        final needsReg = data['needsRegistration'];
        print('DEBUG [SSO]: needsRegistration raw=$needsReg (${needsReg?.runtimeType})');

        if (needsReg == true || needsReg == 'true') {
          print('DEBUG [SSO]: User needs registration');
          final profile = data['profile'];
          print('DEBUG [SSO]: profile type=${profile?.runtimeType}');

          // Safely cast profile to Map
          Map<String, dynamic>? profileMap;
          if (profile is Map<String, dynamic>) {
            profileMap = profile;
          } else if (profile is Map) {
            profileMap = Map<String, dynamic>.from(profile);
          }

          return AuthResult(
            success: false,
            needsRegistration: true,
            ssoProfile: {
              'provider': 'google',
              'providerAccountId': profileMap?['providerAccountId'],
              'email': profileMap?['email'] ?? googleUser.email,
              'firstName': profileMap?['firstName'] ?? googleUser.displayName?.split(' ').first ?? '',
              'lastName': profileMap?['lastName'] ?? (googleUser.displayName?.split(' ').length ?? 0) > 1
                  ? googleUser.displayName!.split(' ').sublist(1).join(' ')
                  : '',
              'picture': profileMap?['picture'] ?? googleUser.photoUrl,
            },
            error: 'Account not found. Please register.',
          );
        }

        print('DEBUG [SSO]: User exists, extracting token');
        final token = data['token'];
        print('DEBUG [SSO]: token type=${token?.runtimeType}');

        if (token == null) {
          print('DEBUG [SSO]: Token is null');
          return AuthResult(
            success: false,
            error: 'No token in response',
          );
        }

        if (token is! String) {
          print('DEBUG [SSO]: Token is not a String, it is ${token.runtimeType}');
          return AuthResult(
            success: false,
            error: 'Invalid token type in response',
          );
        }

        final userData = data['user'];
        print('DEBUG [SSO]: user type=${userData?.runtimeType}');

        User? user;
        if (userData != null) {
          try {
            // Safely cast userData to Map<String, dynamic>
            Map<String, dynamic> userMap;
            if (userData is Map<String, dynamic>) {
              userMap = userData;
            } else if (userData is Map) {
              userMap = Map<String, dynamic>.from(userData);
            } else {
              print('DEBUG [SSO]: userData is not a Map: ${userData.runtimeType}');
              throw Exception('Invalid user data type');
            }

            print('DEBUG [SSO]: Parsing user data');
            // Log all user fields and types
            userMap.forEach((key, value) {
              print('DEBUG [SSO]: user["$key"] = $value (${value?.runtimeType})');
            });
            user = User.fromJson(userMap);
            print('DEBUG [SSO]: User parsed successfully');
          } catch (userParseError, userStackTrace) {
            print('DEBUG [SSO]: ERROR parsing user: $userParseError');
            print('DEBUG [SSO]: User stack trace: $userStackTrace');
            // Continue without user, we have the token
          }
        }

        await _storage.setAuthToken(token);
        await _storage.setIsGuest(false);
        _api.setAuthToken(token);
        print('DEBUG [SSO]: Login successful');

        return AuthResult(
          success: true,
          user: user,
          token: token,
        );
      } catch (parseError, stackTrace) {
        print('DEBUG [SSO]: ERROR parsing response: $parseError');
        print('DEBUG [SSO]: Stack trace: $stackTrace');
        return AuthResult(
          success: false,
          error: 'Error parsing response: ${parseError.toString()}',
        );
      }
    } catch (e, stackTrace) {
      print('DEBUG [SSO]: EXCEPTION: $e');
      print('DEBUG [SSO]: Stack trace: $stackTrace');
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
