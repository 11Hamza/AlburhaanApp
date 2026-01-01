import 'api_service.dart';
import '../models/reading_list.dart';

class ReadingListService {
  final ApiService _api = ApiService();

  /// Get all reading lists for the current user
  Future<List<ReadingList>> getReadingLists() async {
    final response = await _api.get<Map<String, dynamic>>(
      '/api/reading-lists',
    );

    if (response.success && response.data != null) {
      final lists = response.data!['lists'] as List? ?? [];
      return lists.map((l) => ReadingList.fromJson(l)).toList();
    }
    return [];
  }

  /// Get a single reading list with items
  Future<ReadingList?> getReadingList(String id) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/api/reading-lists/$id',
    );

    if (response.success && response.data != null) {
      return ReadingList.fromJson(response.data!);
    }
    return null;
  }

  /// Create a new reading list
  Future<ReadingList?> createReadingList({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/reading-lists',
      body: {
        'name': name,
        if (description != null) 'description': description,
        'isPublic': isPublic,
      },
    );

    if (response.success && response.data != null) {
      return ReadingList.fromJson(response.data!);
    }
    return null;
  }

  /// Update a reading list
  Future<bool> updateReadingList({
    required String id,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    final response = await _api.put<Map<String, dynamic>>(
      '/api/reading-lists/$id',
      body: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (isPublic != null) 'isPublic': isPublic,
      },
    );

    return response.success;
  }

  /// Delete a reading list
  Future<bool> deleteReadingList(String id) async {
    final response = await _api.delete<Map<String, dynamic>>(
      '/api/reading-lists/$id',
    );
    return response.success;
  }

  /// Add a book to a reading list
  Future<ReadingListItem?> addBookToList({
    required String listId,
    required int biblioId,
    String? notes,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/reading-lists/$listId/items',
      body: {
        'biblioId': biblioId,
        if (notes != null) 'notes': notes,
      },
    );

    if (response.success && response.data != null) {
      return ReadingListItem.fromJson(response.data!);
    }
    return null;
  }

  /// Update an item in a reading list
  Future<bool> updateListItem({
    required String listId,
    required String itemId,
    String? notes,
    String? status,
    int? sortOrder,
  }) async {
    final response = await _api.put<Map<String, dynamic>>(
      '/api/reading-lists/$listId/items/$itemId',
      body: {
        if (notes != null) 'notes': notes,
        if (status != null) 'status': status,
        if (sortOrder != null) 'sortOrder': sortOrder,
      },
    );

    return response.success;
  }

  /// Remove a book from a reading list
  Future<bool> removeFromList({
    required String listId,
    required String itemId,
  }) async {
    final response = await _api.delete<Map<String, dynamic>>(
      '/api/reading-lists/$listId/items/$itemId',
    );
    return response.success;
  }
}
