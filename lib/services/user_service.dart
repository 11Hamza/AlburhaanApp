import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/loan.dart';
import '../models/hold.dart';
import '../models/favorite.dart';
import '../models/library.dart';
import '../utils/type_utils.dart';
import 'api_service.dart';
import 'books_service.dart';

class UserService {
  final ApiService _api = ApiService();

  /// Get user profile
  Future<({User? patron, UserPreferences? preferences})> getProfile() async {
    final response = await _api.get<Map<String, dynamic>>('/user/profile');

    if (response.success && response.data != null) {
      final data = response.data!;
      final patron = data['patron'] != null
          ? User.fromJson(data['patron'])
          : null;
      final preferences = data['preferences'] != null
          ? UserPreferences.fromJson(data['preferences'])
          : null;

      return (patron: patron, preferences: preferences);
    }

    return (patron: null, preferences: null);
  }

  /// Update user preferences
  Future<bool> updatePreferences({
    String? language,
    String? theme,
    bool? notificationsEnabled,
    String? homeLibraryId,
  }) async {
    final body = <String, dynamic>{};
    if (language != null) body['language'] = language;
    if (theme != null) body['theme'] = theme;
    if (notificationsEnabled != null) body['notificationsEnabled'] = notificationsEnabled;
    if (homeLibraryId != null) body['homeLibraryId'] = homeLibraryId;

    final response = await _api.put('/user/profile', body: body);
    return response.success;
  }

  /// Get library card with QR code and barcode
  Future<LibraryCard?> getLibraryCard() async {
    final response = await _api.get<LibraryCard>(
      '/user/card',
      fromJson: (json) => LibraryCard.fromJson(json),
    );

    return response.data;
  }

  /// Get account summary
  Future<AccountSummary?> getSummary() async {
    final response = await _api.get<AccountSummary>(
      '/user/summary',
      fromJson: (json) => AccountSummary.fromJson(json),
    );

    return response.data;
  }

  /// Get current loans
  Future<({List<Loan> loans, LoansSummary summary})> getLoans() async {
    final response = await _api.get<Map<String, dynamic>>('/loans');

    if (response.success && response.data != null) {
      final data = response.data!;
      final loans = (data['loans'] as List?)
              ?.map((l) => Loan.fromJson(l))
              .toList() ??
          [];
      final summary = data['summary'] != null
          ? LoansSummary.fromJson(data['summary'])
          : LoansSummary();

      return (loans: loans, summary: summary);
    }

    return (loans: <Loan>[], summary: LoansSummary());
  }

  /// Get loan history
  Future<PaginatedResult<LoanHistory>> getLoanHistory({
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/loans/history',
      queryParams: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );

    if (response.success && response.data != null) {
      final data = response.data!;
      final items = (data['data'] as List?)
              ?.map((l) => LoanHistory.fromJson(l))
              .toList() ??
          [];
      final pagination = data['pagination'] ?? {};

      return PaginatedResult(
        items: items,
        page: pagination['page'] ?? page,
        perPage: pagination['perPage'] ?? perPage,
        total: pagination['total'],
        hasMore: parseBool(pagination['hasMore']),
      );
    }

    return PaginatedResult(
      items: [],
      page: page,
      perPage: perPage,
      hasMore: false,
    );
  }

  /// Renew a loan
  Future<({bool success, String? error, Loan? loan})> renewLoan(int checkoutId) async {
    final response = await _api.post<Map<String, dynamic>>('/loans/$checkoutId/renew');

    if (response.success && response.data != null) {
      return (
        success: true,
        error: null,
        loan: Loan.fromJson(response.data!),
      );
    }

    return (success: false, error: response.error, loan: null);
  }

  /// Renew all loans
  Future<({int renewed, int failed, String? message})> renewAllLoans() async {
    final response = await _api.post<Map<String, dynamic>>('/loans/renew-all');

    if (response.success && response.data != null) {
      final data = response.data!;
      final summary = data['summary'] ?? {};

      return (
        renewed: (summary['renewed'] as int?) ?? 0,
        failed: (summary['failed'] as int?) ?? 0,
        message: data['message'] as String?,
      );
    }

    return (renewed: 0, failed: 0, message: response.error);
  }

  /// Get current holds
  Future<({List<Hold> holds, HoldsSummary summary})> getHolds() async {
    final response = await _api.get<Map<String, dynamic>>('/holds');

    if (response.success && response.data != null) {
      final data = response.data!;
      final holds = (data['holds'] as List?)
              ?.map((h) => Hold.fromJson(h))
              .toList() ??
          [];
      final summary = data['summary'] != null
          ? HoldsSummary.fromJson(data['summary'])
          : HoldsSummary();

      return (holds: holds, summary: summary);
    }

    return (holds: <Hold>[], summary: HoldsSummary());
  }

  /// Place a hold
  Future<({bool success, String? error, Hold? hold})> placeHold({
    required int biblioId,
    required String pickupLibraryId,
    String? notes,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/holds',
      body: {
        'biblioId': biblioId,
        'pickupLibraryId': pickupLibraryId,
        if (notes != null) 'notes': notes,
      },
    );

    if (response.success && response.data != null) {
      final holdData = response.data!['hold'];
      return (
        success: true,
        error: null,
        hold: holdData != null ? Hold.fromJson(holdData) : null,
      );
    }

    return (success: false, error: response.error, hold: null);
  }

  /// Cancel a hold
  Future<bool> cancelHold(int holdId) async {
    debugPrint('DEBUG: Cancelling hold with ID: $holdId');
    final response = await _api.delete('/holds/$holdId');
    debugPrint('DEBUG: Cancel hold response - success: ${response.success}, error: ${response.error}, statusCode: ${response.statusCode}');
    return response.success;
  }

  /// Get favorites
  Future<PaginatedResult<Favorite>> getFavorites({
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/favorites',
      queryParams: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );

    if (response.success && response.data != null) {
      final data = response.data!;
      final items = (data['data'] as List?)
              ?.map((f) => Favorite.fromJson(f))
              .toList() ??
          [];
      final pagination = data['pagination'] ?? {};

      return PaginatedResult(
        items: items,
        page: pagination['page'] ?? page,
        perPage: pagination['perPage'] ?? perPage,
        total: pagination['total'],
        hasMore: parseBool(pagination['hasMore']),
      );
    }

    return PaginatedResult(
      items: [],
      page: page,
      perPage: perPage,
      hasMore: false,
    );
  }

  /// Add to favorites
  Future<bool> addToFavorites(int biblioId) async {
    final response = await _api.post(
      '/favorites',
      body: {'biblioId': biblioId},
    );
    return response.success;
  }

  /// Remove from favorites
  Future<bool> removeFromFavorites(int biblioId) async {
    final response = await _api.delete('/favorites/$biblioId');
    return response.success;
  }

  /// Check if book is favorited
  Future<bool> isFavorited(int biblioId) async {
    final response = await _api.get<Map<String, dynamic>>('/favorites/$biblioId');

    if (response.success && response.data != null) {
      return parseBool(response.data!['isFavorite']);
    }

    return false;
  }

  /// Get libraries
  Future<List<Library>> getLibraries() async {
    final response = await _api.get<Map<String, dynamic>>('/libraries');

    if (response.success && response.data != null) {
      final libraries = response.data!['libraries'] as List?;
      return libraries?.map((l) => Library.fromJson(l)).toList() ?? [];
    }

    return [];
  }

  /// Get library by ID
  Future<Library?> getLibraryById(String libraryId) async {
    final response = await _api.get<Library>(
      '/libraries/$libraryId',
      fromJson: (json) => Library.fromJson(json),
    );

    return response.data;
  }
}
