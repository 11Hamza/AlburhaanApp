import 'package:flutter/material.dart';
import '../models/ebook.dart';
import '../models/video.dart';
import '../services/content_service.dart';
import '../services/cache_service.dart';

/// Provider that caches videos and ebooks data for instant loading
/// Uses stale-while-revalidate pattern for optimal UX
class ContentProvider extends ChangeNotifier {
  final ContentService _service = ContentService();

  // ============ VIDEOS STATE ============
  List<Video> _videos = [];
  List<ContentCategory> _videoCategories = [];
  bool _videosLoaded = false;
  bool _isLoadingVideos = false;
  bool _isLoadingMoreVideos = false;
  bool _isBackgroundRefreshingVideos = false;
  int _videosPage = 1;
  int _videosTotal = 0;
  String? _videosError;
  String? _videosCacheAge;

  // ============ EBOOKS STATE ============
  List<Ebook> _ebooks = [];
  List<ContentCategory> _ebookCategories = [];
  bool _ebooksLoaded = false;
  bool _isLoadingEbooks = false;
  bool _isLoadingMoreEbooks = false;
  bool _isBackgroundRefreshingEbooks = false;
  int _ebooksPage = 1;
  int _ebooksTotal = 0;
  String? _ebooksError;
  String? _ebooksCacheAge;

  // ============ VIDEOS GETTERS ============
  List<Video> get videos => _videos;
  List<ContentCategory> get videoCategories => _videoCategories;
  bool get videosLoaded => _videosLoaded;
  bool get isLoadingVideos => _isLoadingVideos && _videos.isEmpty;
  bool get isLoadingMoreVideos => _isLoadingMoreVideos;
  bool get isBackgroundRefreshingVideos => _isBackgroundRefreshingVideos;
  int get videosTotal => _videosTotal;
  bool get hasMoreVideos => _videos.length < _videosTotal;
  String? get videosError => _videosError;
  String? get videosCacheAge => _videosCacheAge;

  // ============ EBOOKS GETTERS ============
  List<Ebook> get ebooks => _ebooks;
  List<ContentCategory> get ebookCategories => _ebookCategories;
  bool get ebooksLoaded => _ebooksLoaded;
  bool get isLoadingEbooks => _isLoadingEbooks && _ebooks.isEmpty;
  bool get isLoadingMoreEbooks => _isLoadingMoreEbooks;
  bool get isBackgroundRefreshingEbooks => _isBackgroundRefreshingEbooks;
  int get ebooksTotal => _ebooksTotal;
  bool get hasMoreEbooks => _ebooks.length < _ebooksTotal;
  String? get ebooksError => _ebooksError;
  String? get ebooksCacheAge => _ebooksCacheAge;

  // ============ VIDEOS METHODS ============

  /// Load videos with stale-while-revalidate pattern
  /// 1. Return cached data immediately
  /// 2. Fetch fresh data in background if cache is stale
  Future<void> loadVideos({bool forceRefresh = false}) async {
    // Don't reload if already loading
    if (_isLoadingVideos) return;

    _videosError = null;
    _videosPage = 1;

    // Step 1: Load from local cache immediately
    if (_videos.isEmpty) {
      _isLoadingVideos = true;
      notifyListeners();

      final cachedVideos = await CacheService.getCachedVideos();
      if (cachedVideos.isNotEmpty) {
        _videos = cachedVideos;
        _videosTotal = cachedVideos.length;
        _videosCacheAge = CacheService.getCacheAge('videos');
        _videosLoaded = true;
        _isLoadingVideos = false;
        notifyListeners();
      }

      // Load cached categories
      final cachedCategories = CacheService.getCachedVideoCategories();
      if (cachedCategories.isNotEmpty) {
        _videoCategories = cachedCategories.map((name) =>
          ContentCategory(name: name, ebookCount: 0, videoCount: 1)
        ).toList();
      }
    }

    // Step 2: Check if we need to fetch fresh data
    final shouldFetch = forceRefresh ||
        _videos.isEmpty ||
        CacheService.isCacheStale('videos');

    if (!shouldFetch && _videosLoaded) return;

    // Step 3: Fetch fresh data (in background if we have cached data)
    if (_videos.isNotEmpty) {
      _isBackgroundRefreshingVideos = true;
    } else {
      _isLoadingVideos = true;
    }
    notifyListeners();

    try {
      // Fetch all videos for caching
      final allVideos = await _fetchAllVideos();
      final categories = await _service.getCategories();

      // Cache the data
      await CacheService.cacheVideos(allVideos);
      final categoryNames = categories
          .where((c) => c.videoCount > 0)
          .map((c) => c.name)
          .toList();
      await CacheService.cacheVideoCategories(categoryNames);

      _videos = allVideos;
      _videosTotal = allVideos.length;
      _videoCategories = categories.where((c) => c.videoCount > 0).toList();
      _videosCacheAge = CacheService.getCacheAge('videos');
      _videosLoaded = true;
    } catch (e) {
      // Keep showing cached data on error
      if (_videos.isEmpty) {
        _videosError = e.toString();
      }
    }

    _isBackgroundRefreshingVideos = false;
    _isLoadingVideos = false;
    notifyListeners();
  }

  /// Fetch all videos from API for caching
  Future<List<Video>> _fetchAllVideos() async {
    List<Video> allVideos = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final result = await _service.getVideos(page: page, pageSize: 50);
      allVideos.addAll(result.videos);
      hasMore = result.videos.length >= 50 && allVideos.length < result.total;
      page++;

      // Safety limit
      if (page > 20) break;
    }

    return allVideos;
  }

  /// Load more videos (pagination)
  Future<void> loadMoreVideos() async {
    if (_isLoadingMoreVideos || !hasMoreVideos) return;

    _isLoadingMoreVideos = true;
    notifyListeners();

    try {
      final result = await _service.getVideos(
        page: _videosPage + 1,
        pageSize: 20,
      );

      _videos.addAll(result.videos);
      _videosPage++;
    } catch (e) {
      _videosError = e.toString();
    }

    _isLoadingMoreVideos = false;
    notifyListeners();
  }

  /// Search videos (doesn't affect main list)
  Future<List<Video>> searchVideos({
    String? query,
    String? category,
  }) async {
    try {
      final result = await _service.getVideos(
        page: 1,
        pageSize: 50,
        category: category,
        search: query,
      );
      return result.videos;
    } catch (e) {
      return [];
    }
  }

  /// Refresh videos
  Future<void> refreshVideos() async {
    await loadVideos(forceRefresh: true);
  }

  // ============ EBOOKS METHODS ============

  /// Load ebooks with stale-while-revalidate pattern
  /// 1. Return cached data immediately
  /// 2. Fetch fresh data in background if cache is stale
  Future<void> loadEbooks({bool forceRefresh = false}) async {
    // Don't reload if already loading
    if (_isLoadingEbooks) return;

    _ebooksError = null;
    _ebooksPage = 1;

    // Step 1: Load from local cache immediately
    if (_ebooks.isEmpty) {
      _isLoadingEbooks = true;
      notifyListeners();

      final cachedEbooks = await CacheService.getCachedEbooks();
      if (cachedEbooks.isNotEmpty) {
        _ebooks = cachedEbooks;
        _ebooksTotal = cachedEbooks.length;
        _ebooksCacheAge = CacheService.getCacheAge('ebooks');
        _ebooksLoaded = true;
        _isLoadingEbooks = false;
        notifyListeners();
      }

      // Load cached categories
      final cachedCategories = CacheService.getCachedEbookCategories();
      if (cachedCategories.isNotEmpty) {
        _ebookCategories = cachedCategories.map((name) =>
          ContentCategory(name: name, ebookCount: 1, videoCount: 0)
        ).toList();
      }
    }

    // Step 2: Check if we need to fetch fresh data
    final shouldFetch = forceRefresh ||
        _ebooks.isEmpty ||
        CacheService.isCacheStale('ebooks');

    if (!shouldFetch && _ebooksLoaded) return;

    // Step 3: Fetch fresh data (in background if we have cached data)
    if (_ebooks.isNotEmpty) {
      _isBackgroundRefreshingEbooks = true;
    } else {
      _isLoadingEbooks = true;
    }
    notifyListeners();

    try {
      // Fetch all ebooks for caching
      final allEbooks = await _fetchAllEbooks();
      final categories = await _service.getCategories();

      // Cache the data
      await CacheService.cacheEbooks(allEbooks);
      final categoryNames = categories
          .where((c) => c.ebookCount > 0)
          .map((c) => c.name)
          .toList();
      await CacheService.cacheEbookCategories(categoryNames);

      _ebooks = allEbooks;
      _ebooksTotal = allEbooks.length;
      _ebookCategories = categories.where((c) => c.ebookCount > 0).toList();
      _ebooksCacheAge = CacheService.getCacheAge('ebooks');
      _ebooksLoaded = true;
    } catch (e) {
      // Keep showing cached data on error
      if (_ebooks.isEmpty) {
        _ebooksError = e.toString();
      }
    }

    _isBackgroundRefreshingEbooks = false;
    _isLoadingEbooks = false;
    notifyListeners();
  }

  /// Fetch all ebooks from API for caching
  Future<List<Ebook>> _fetchAllEbooks() async {
    List<Ebook> allEbooks = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final result = await _service.getEbooks(page: page, pageSize: 50);
      allEbooks.addAll(result.ebooks);
      hasMore = result.ebooks.length >= 50 && allEbooks.length < result.total;
      page++;

      // Safety limit
      if (page > 20) break;
    }

    return allEbooks;
  }

  /// Load more ebooks (pagination)
  Future<void> loadMoreEbooks() async {
    if (_isLoadingMoreEbooks || !hasMoreEbooks) return;

    _isLoadingMoreEbooks = true;
    notifyListeners();

    try {
      final result = await _service.getEbooks(
        page: _ebooksPage + 1,
        pageSize: 20,
      );

      _ebooks.addAll(result.ebooks);
      _ebooksPage++;
    } catch (e) {
      _ebooksError = e.toString();
    }

    _isLoadingMoreEbooks = false;
    notifyListeners();
  }

  /// Search ebooks (doesn't affect main list)
  Future<List<Ebook>> searchEbooks({
    String? query,
    String? category,
  }) async {
    try {
      final result = await _service.getEbooks(
        page: 1,
        pageSize: 50,
        category: category,
        search: query,
      );
      return result.ebooks;
    } catch (e) {
      return [];
    }
  }

  /// Refresh ebooks
  Future<void> refreshEbooks() async {
    await loadEbooks(forceRefresh: true);
  }

  // ============ PRELOAD ============

  /// Preload both videos and ebooks in background
  Future<void> preloadAll() async {
    await Future.wait([
      loadVideos(),
      loadEbooks(),
    ]);
  }
}
