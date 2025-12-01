import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _error;
  bool _isGuest = false;
  AccountSummary? _summary;
  LibraryCard? _libraryCard;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isGuest => _isGuest;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  AccountSummary? get summary => _summary;
  LibraryCard? get libraryCard => _libraryCard;

  /// Initialize auth state
  Future<void> init() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final isLoggedIn = await _authService.isLoggedIn();

    if (isLoggedIn) {
      _isGuest = await _authService.isGuest();

      if (_isGuest) {
        _user = User.guest();
        _status = AuthStatus.authenticated;
      } else {
        // Fetch user profile
        await _fetchUserProfile();
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// Login with library card
  Future<bool> login(String cardNumber, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _authService.login(cardNumber, password);

    if (result.success) {
      _user = result.user;
      _isGuest = false;
      _status = AuthStatus.authenticated;
      await _fetchUserProfile();
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Login as guest
  Future<bool> loginAsGuest() async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _authService.loginAsGuest();

    if (result.success) {
      _user = result.user ?? User.guest();
      _isGuest = true;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isGuest = false;
    _summary = null;
    _libraryCard = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Refresh user profile
  Future<void> refreshProfile() async {
    if (!_isGuest) {
      await _fetchUserProfile();
    }
  }

  /// Fetch user profile
  Future<void> _fetchUserProfile() async {
    try {
      final profile = await _userService.getProfile();
      if (profile.patron != null) {
        _user = profile.patron;
      }
      _status = AuthStatus.authenticated;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  /// Fetch account summary
  Future<void> fetchSummary() async {
    if (!_isGuest) {
      _summary = await _userService.getSummary();
      notifyListeners();
    }
  }

  /// Fetch library card
  Future<void> fetchLibraryCard() async {
    if (!_isGuest) {
      _libraryCard = await _userService.getLibraryCard();
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
