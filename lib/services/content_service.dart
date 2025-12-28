import 'api_service.dart';
import '../models/ebook.dart';
import '../models/video.dart';

class ContentService {
  final ApiService _api = ApiService();

  // ============ EBOOKS ============

  /// Get all ebooks with optional filtering
  Future<EbooksResult> getEbooks({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? language,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (category != null) queryParams['category'] = category;
    if (language != null) queryParams['language'] = language;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _api.get<Map<String, dynamic>>(
      '/ebooks',
      queryParams: queryParams,
    );

    if (response.success && response.data != null) {
      return EbooksResult.fromJson(response.data!);
    }
    return EbooksResult(ebooks: [], total: 0, page: 1, pageSize: pageSize);
  }

  /// Get a single ebook with access URL
  Future<Ebook?> getEbook(String id) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/ebooks/$id',
    );

    if (response.success && response.data != null) {
      return Ebook.fromJson(response.data!);
    }
    return null;
  }

  // ============ VIDEOS ============

  /// Get all videos with optional filtering
  Future<VideosResult> getVideos({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? language,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (category != null) queryParams['category'] = category;
    if (language != null) queryParams['language'] = language;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _api.get<Map<String, dynamic>>(
      '/videos',
      queryParams: queryParams,
    );

    if (response.success && response.data != null) {
      return VideosResult.fromJson(response.data!);
    }
    return VideosResult(videos: [], total: 0, page: 1, pageSize: pageSize);
  }

  /// Get a single video
  Future<Video?> getVideo(String id) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/videos/$id',
    );

    if (response.success && response.data != null) {
      return Video.fromJson(response.data!);
    }
    return null;
  }

  // ============ CATEGORIES ============

  /// Get content categories with counts
  Future<List<ContentCategory>> getCategories() async {
    final response = await _api.get<Map<String, dynamic>>(
      '/content/categories',
    );

    if (response.success && response.data != null) {
      final categories = response.data!['categories'] as List? ?? [];
      return categories.map((c) => ContentCategory.fromJson(c)).toList();
    }
    return [];
  }
}
