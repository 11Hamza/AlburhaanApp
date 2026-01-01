import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ============ Secure Storage (for sensitive data) ============

  /// Store auth token securely
  Future<void> setAuthToken(String token) async {
    await _secureStorage.write(key: StorageKeys.authToken, value: token);
  }

  /// Get stored auth token
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: StorageKeys.authToken);
  }

  /// Clear auth data
  Future<void> clearAuth() async {
    await _secureStorage.delete(key: StorageKeys.authToken);
    await _secureStorage.delete(key: StorageKeys.refreshToken);
  }

  // ============ Shared Preferences (for non-sensitive data) ============

  /// Set language preference
  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.language, language);
  }

  /// Get language preference
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.language) ?? 'en';
  }

  /// Set theme preference
  Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.theme, theme);
  }

  /// Get theme preference
  Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.theme) ?? 'light';
  }

  /// Set home library
  Future<void> setHomeLibrary(String libraryId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.homeLibrary, libraryId);
  }

  /// Get home library
  Future<String?> getHomeLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.homeLibrary);
  }

  /// Set guest status
  Future<void> setIsGuest(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.isGuest, isGuest);
  }

  /// Get guest status
  Future<bool> getIsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.isGuest) ?? false;
  }

  /// Clear all preferences
  Future<void> clearAll() async {
    await clearAuth();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
