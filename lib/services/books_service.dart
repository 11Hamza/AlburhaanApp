import '../models/book.dart';
import 'api_service.dart';

class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final int perPage;
  final int? total;
  final bool hasMore;

  PaginatedResult({
    required this.items,
    required this.page,
    required this.perPage,
    this.total,
    required this.hasMore,
  });
}

class BooksService {
  final ApiService _api = ApiService();

  /// Get paginated list of books
  Future<PaginatedResult<Book>> getBooks({
    int page = 1,
    int perPage = 10,
    String? query,
    String? author,
    String? subject,
    String? language,
    String? library,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (query != null && query.isNotEmpty) queryParams['q'] = query;
    if (author != null && author.isNotEmpty) queryParams['author'] = author;
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;
    if (language != null && language.isNotEmpty) queryParams['language'] = language;
    if (library != null && library.isNotEmpty) queryParams['library'] = library;

    final response = await _api.get<Map<String, dynamic>>(
      '/books',
      queryParams: queryParams,
    );

    if (response.success && response.data != null) {
      final data = response.data!;
      final items = (data['data'] as List?)
              ?.map((json) => Book.fromJson(json))
              .toList() ??
          [];
      final pagination = data['pagination'] ?? {};

      return PaginatedResult(
        items: items,
        page: pagination['page'] ?? page,
        perPage: pagination['perPage'] ?? perPage,
        total: pagination['total'],
        hasMore: pagination['hasMore'] ?? items.length == perPage,
      );
    }

    return PaginatedResult(
      items: [],
      page: page,
      perPage: perPage,
      hasMore: false,
    );
  }

  /// Get book by ID
  Future<Book?> getBookById(int biblioId) async {
    final response = await _api.get<Book>(
      '/books/$biblioId',
      fromJson: (json) => Book.fromJson(json),
    );

    return response.data;
  }

  /// Get book availability
  Future<BookAvailability?> getBookAvailability(int biblioId) async {
    final response = await _api.get<BookAvailability>(
      '/books/$biblioId/availability',
      fromJson: (json) => BookAvailability.fromJson(json),
    );

    return response.data;
  }

  /// Search books with advanced filters
  Future<PaginatedResult<Book>> searchBooks({
    String? keyword,
    String? title,
    String? author,
    String? isbn,
    String? subject,
    String? language,
    String? yearFrom,
    String? yearTo,
    String? sort,
    String? order,
    int page = 1,
    int perPage = 10,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
    if (title != null && title.isNotEmpty) queryParams['title'] = title;
    if (author != null && author.isNotEmpty) queryParams['author'] = author;
    if (isbn != null && isbn.isNotEmpty) queryParams['isbn'] = isbn;
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;
    if (language != null && language.isNotEmpty) queryParams['language'] = language;
    if (yearFrom != null && yearFrom.isNotEmpty) queryParams['year_from'] = yearFrom;
    if (yearTo != null && yearTo.isNotEmpty) queryParams['year_to'] = yearTo;
    if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;
    if (order != null && order.isNotEmpty) queryParams['order'] = order;

    final response = await _api.get<Map<String, dynamic>>(
      '/books/search',
      queryParams: queryParams,
    );

    if (response.success && response.data != null) {
      final data = response.data!;
      final items = (data['data'] as List?)
              ?.map((json) => Book.fromJson(json))
              .toList() ??
          [];
      final pagination = data['pagination'] ?? {};

      return PaginatedResult(
        items: items,
        page: pagination['page'] ?? page,
        perPage: pagination['perPage'] ?? perPage,
        total: pagination['total'],
        hasMore: pagination['hasMore'] ?? items.length == perPage,
      );
    }

    return PaginatedResult(
      items: [],
      page: page,
      perPage: perPage,
      hasMore: false,
    );
  }

  /// Get filter options (subjects, classifications, languages)
  Future<List<FilterOption>> getSubjects() async {
    final response = await _api.get<Map<String, dynamic>>('/filters/subjects');

    if (response.success && response.data != null) {
      final subjects = response.data!['subjects'] as List?;
      return subjects?.map((s) => FilterOption.fromJson(s)).toList() ?? [];
    }

    return [];
  }

  Future<List<FilterOption>> getClassifications() async {
    final response = await _api.get<Map<String, dynamic>>('/filters/classifications');

    if (response.success && response.data != null) {
      final classifications = response.data!['classifications'] as List?;
      return classifications?.map((c) => FilterOption.fromJson(c)).toList() ?? [];
    }

    return [];
  }

  Future<List<FilterOption>> getLanguages() async {
    final response = await _api.get<Map<String, dynamic>>('/filters/languages');

    if (response.success && response.data != null) {
      final languages = response.data!['languages'] as List?;
      return languages?.map((l) => FilterOption.fromJson(l)).toList() ?? [];
    }

    return [];
  }
}
