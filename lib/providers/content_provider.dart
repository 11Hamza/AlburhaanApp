import 'package:flutter/material.dart';
import '../models/ebook.dart';
import '../models/video.dart';
import '../services/content_service.dart';

/// Provider that caches videos and ebooks data for instant loading
class ContentProvider extends ChangeNotifier {
  final ContentService _service = ContentService();

  // ============ VIDEOS STATE ============
  List<Video> _videos = [];
  List<ContentCategory> _videoCategories = [];
  bool _videosLoaded = false;
  bool _isLoadingVideos = false;
  bool _isLoadingMoreVideos = false;
  int _videosPage = 1;
  int _videosTotal = 0;
  String? _videosError;

  // ============ EBOOKS STATE ============
  List<Ebook> _ebooks = [];
  List<ContentCategory> _ebookCategories = [];
  bool _ebooksLoaded = false;
  bool _isLoadingEbooks = false;
  bool _isLoadingMoreEbooks = false;
  int _ebooksPage = 1;
  int _ebooksTotal = 0;
  String? _ebooksError;

  // ============ VIDEOS GETTERS ============
  List<Video> get videos => _videos;
  List<ContentCategory> get videoCategories => _videoCategories;
  bool get videosLoaded => _videosLoaded;
  bool get isLoadingVideos => _isLoadingVideos;
  bool get isLoadingMoreVideos => _isLoadingMoreVideos;
  int get videosTotal => _videosTotal;
  bool get hasMoreVideos => _videos.length < _videosTotal;
  String? get videosError => _videosError;

  // ============ EBOOKS GETTERS ============
  List<Ebook> get ebooks => _ebooks;
  List<ContentCategory> get ebookCategories => _ebookCategories;
  bool get ebooksLoaded => _ebooksLoaded;
  bool get isLoadingEbooks => _isLoadingEbooks;
  bool get isLoadingMoreEbooks => _isLoadingMoreEbooks;
  int get ebooksTotal => _ebooksTotal;
  bool get hasMoreEbooks => _ebooks.length < _ebooksTotal;
  String? get ebooksError => _ebooksError;

  // ============ VIDEOS METHODS ============

  /// Load videos (uses cache if already loaded)
  Future<void> loadVideos({bool forceRefresh = false}) async {
    // Return cached data if already loaded and not forcing refresh
    if (_videosLoaded && !forceRefresh) {
      return;
    }

    // Don't reload if already loading
    if (_isLoadingVideos) return;

    _isLoadingVideos = true;
    _videosError = null;
    _videosPage = 1;
    notifyListeners();

    try {
      // Load videos and categories in parallel
      final results = await Future.wait([
        _service.getVideos(page: 1, pageSize: 20),
        _service.getCategories(),
      ]);

      final videosResult = results[0] as VideosResult;
      final categories = results[1] as List<ContentCategory>;

      _videos = videosResult.videos;
      _videosTotal = videosResult.total;
      _videoCategories = categories.where((c) => c.videoCount > 0).toList();
      _videosLoaded = true;
    } catch (e) {
      _videosError = e.toString();
    }

    _isLoadingVideos = false;
    notifyListeners();
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

  /// Load ebooks (uses cache if already loaded)
  Future<void> loadEbooks({bool forceRefresh = false}) async {
    // Return cached data if already loaded and not forcing refresh
    if (_ebooksLoaded && !forceRefresh) {
      return;
    }

    // Don't reload if already loading
    if (_isLoadingEbooks) return;

    _isLoadingEbooks = true;
    _ebooksError = null;
    _ebooksPage = 1;
    notifyListeners();

    try {
      // Load ebooks and categories in parallel
      final results = await Future.wait([
        _service.getEbooks(page: 1, pageSize: 20),
        _service.getCategories(),
      ]);

      final ebooksResult = results[0] as EbooksResult;
      final categories = results[1] as List<ContentCategory>;

      _ebooks = ebooksResult.ebooks;
      _ebooksTotal = ebooksResult.total;
      _ebookCategories = categories.where((c) => c.ebookCount > 0).toList();
      _ebooksLoaded = true;
    } catch (e) {
      _ebooksError = e.toString();
    }

    _isLoadingEbooks = false;
    notifyListeners();
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
