import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');
  String? _homeLibraryId;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String? get homeLibraryId => _homeLibraryId;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load theme
    final theme = await _storage.getTheme();
    _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;

    // Load language
    final language = await _storage.getLanguage();
    _locale = Locale(language);

    // Load home library
    _homeLibraryId = await _storage.getHomeLibrary();

    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.setTheme(mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  /// Toggle theme
  Future<void> toggleTheme() async {
    await setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  /// Set locale
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _storage.setLanguage(locale.languageCode);
    notifyListeners();
  }

  /// Set language by code
  Future<void> setLanguage(String languageCode) async {
    await setLocale(Locale(languageCode));
  }

  /// Set home library
  Future<void> setHomeLibrary(String libraryId) async {
    _homeLibraryId = libraryId;
    await _storage.setHomeLibrary(libraryId);
    notifyListeners();
  }

  /// Check if locale is RTL
  bool get isRTL {
    return _locale.languageCode == 'ar' || _locale.languageCode == 'ur';
  }
}
