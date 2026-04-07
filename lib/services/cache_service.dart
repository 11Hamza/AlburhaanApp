import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';
import '../models/video.dart';
import '../models/ebook.dart';

/// CacheService provides local caching using Hive for offline support
/// and instant data loading with stale-while-revalidate pattern.
class CacheService {
  static const String _booksBox = 'books_cache';
  static const String _videosBox = 'videos_cache';
  static const String _ebooksBox = 'ebooks_cache';
  static const String _metaBox = 'cache_meta';

  static bool _initialized = false;

  /// Initialize Hive and open all cache boxes
  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<String>(_booksBox),
      Hive.openBox<String>(_videosBox),
      Hive.openBox<String>(_ebooksBox),
      Hive.openBox(_metaBox),
    ]);

    _initialized = true;
  }

  /// Check if cache is stale (older than specified duration)
  static bool isCacheStale(String key, {Duration maxAge = const Duration(hours: 1)}) {
    final meta = Hive.box(_metaBox);
    final lastUpdated = meta.get('${key}_updated');
    if (lastUpdated == null) return true;

    final timestamp = DateTime.tryParse(lastUpdated.toString());
    if (timestamp == null) return true;

    return DateTime.now().difference(timestamp) > maxAge;
  }

  /// Get cache age as human-readable string
  static String? getCacheAge(String key) {
    final meta = Hive.box(_metaBox);
    final lastUpdated = meta.get('${key}_updated');
    if (lastUpdated == null) return null;

    final timestamp = DateTime.tryParse(lastUpdated.toString());
    if (timestamp == null) return null;

    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ===== BOOKS CACHE =====

  /// Get cached books list
  static Future<List<Book>> getCachedBooks() async {
    final box = Hive.box<String>(_booksBox);
    final jsonList = box.get('all_books');
    if (jsonList == null) return [];

    try {
      final List<dynamic> decoded = json.decode(jsonList);
      return decoded.map((j) => Book.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Cache books list
  static Future<void> cacheBooks(List<Book> books) async {
    final box = Hive.box<String>(_booksBox);
    final jsonList = json.encode(books.map((b) => b.toJson()).toList());
    await box.put('all_books', jsonList);

    final meta = Hive.box(_metaBox);
    await meta.put('books_updated', DateTime.now().toIso8601String());
    await meta.put('books_count', books.length);
  }

  /// Get cached book count
  static int getCachedBooksCount() {
    final meta = Hive.box(_metaBox);
    return meta.get('books_count', defaultValue: 0);
  }

  // ===== VIDEOS CACHE =====

  /// Get cached videos list
  static Future<List<Video>> getCachedVideos() async {
    final box = Hive.box<String>(_videosBox);
    final jsonList = box.get('all_videos');
    if (jsonList == null) return [];

    try {
      final List<dynamic> decoded = json.decode(jsonList);
      return decoded.map((j) => Video.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Cache videos list
  static Future<void> cacheVideos(List<Video> videos) async {
    final box = Hive.box<String>(_videosBox);
    final jsonList = json.encode(videos.map((v) => _videoToJson(v)).toList());
    await box.put('all_videos', jsonList);

    final meta = Hive.box(_metaBox);
    await meta.put('videos_updated', DateTime.now().toIso8601String());
    await meta.put('videos_count', videos.length);
  }

  /// Get cached videos count
  static int getCachedVideosCount() {
    final meta = Hive.box(_metaBox);
    return meta.get('videos_count', defaultValue: 0);
  }

  // ===== EBOOKS CACHE =====

  /// Get cached ebooks list
  static Future<List<Ebook>> getCachedEbooks() async {
    final box = Hive.box<String>(_ebooksBox);
    final jsonList = box.get('all_ebooks');
    if (jsonList == null) return [];

    try {
      final List<dynamic> decoded = json.decode(jsonList);
      return decoded.map((j) => Ebook.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Cache ebooks list
  static Future<void> cacheEbooks(List<Ebook> ebooks) async {
    final box = Hive.box<String>(_ebooksBox);
    final jsonList = json.encode(ebooks.map((e) => _ebookToJson(e)).toList());
    await box.put('all_ebooks', jsonList);

    final meta = Hive.box(_metaBox);
    await meta.put('ebooks_updated', DateTime.now().toIso8601String());
    await meta.put('ebooks_count', ebooks.length);
  }

  /// Get cached ebooks count
  static int getCachedEbooksCount() {
    final meta = Hive.box(_metaBox);
    return meta.get('ebooks_count', defaultValue: 0);
  }

  // ===== CATEGORIES CACHE =====

  /// Cache video categories
  static Future<void> cacheVideoCategories(List<String> categories) async {
    final meta = Hive.box(_metaBox);
    await meta.put('video_categories', json.encode(categories));
  }

  /// Get cached video categories
  static List<String> getCachedVideoCategories() {
    final meta = Hive.box(_metaBox);
    final data = meta.get('video_categories');
    if (data == null) return [];
    try {
      return List<String>.from(json.decode(data));
    } catch (e) {
      return [];
    }
  }

  /// Cache ebook categories
  static Future<void> cacheEbookCategories(List<String> categories) async {
    final meta = Hive.box(_metaBox);
    await meta.put('ebook_categories', json.encode(categories));
  }

  /// Get cached ebook categories
  static List<String> getCachedEbookCategories() {
    final meta = Hive.box(_metaBox);
    final data = meta.get('ebook_categories');
    if (data == null) return [];
    try {
      return List<String>.from(json.decode(data));
    } catch (e) {
      return [];
    }
  }

  // ===== UTILITY METHODS =====

  /// Clear all caches
  static Future<void> clearAll() async {
    await Future.wait([
      Hive.box<String>(_booksBox).clear(),
      Hive.box<String>(_videosBox).clear(),
      Hive.box<String>(_ebooksBox).clear(),
      Hive.box(_metaBox).clear(),
    ]);
  }

  /// Clear specific cache
  static Future<void> clearCache(String type) async {
    switch (type) {
      case 'books':
        await Hive.box<String>(_booksBox).clear();
        final meta = Hive.box(_metaBox);
        await meta.delete('books_updated');
        await meta.delete('books_count');
        break;
      case 'videos':
        await Hive.box<String>(_videosBox).clear();
        final metaV = Hive.box(_metaBox);
        await metaV.delete('videos_updated');
        await metaV.delete('videos_count');
        break;
      case 'ebooks':
        await Hive.box<String>(_ebooksBox).clear();
        final metaE = Hive.box(_metaBox);
        await metaE.delete('ebooks_updated');
        await metaE.delete('ebooks_count');
        break;
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'books': {
        'count': getCachedBooksCount(),
        'age': getCacheAge('books'),
        'stale': isCacheStale('books'),
      },
      'videos': {
        'count': getCachedVideosCount(),
        'age': getCacheAge('videos'),
        'stale': isCacheStale('videos'),
      },
      'ebooks': {
        'count': getCachedEbooksCount(),
        'age': getCacheAge('ebooks'),
        'stale': isCacheStale('ebooks'),
      },
    };
  }

  // ===== HELPER METHODS =====

  static Map<String, dynamic> _videoToJson(Video video) {
    return {
      'id': video.id,
      'title': video.title,
      'description': video.description,
      'youtubeId': video.youtubeId,
      'thumbnailUrl': video.thumbnailUrl,
      'category': video.category,
      'speaker': video.speaker,
      'language': video.language,
      'durationSeconds': video.durationSeconds,
      'createdAt': video.createdAt.toIso8601String(),
      'embedUrl': video.embedUrl,
      'watchUrl': video.watchUrl,
    };
  }

  static Map<String, dynamic> _ebookToJson(Ebook ebook) {
    return {
      'id': ebook.id,
      'title': ebook.title,
      'author': ebook.author,
      'description': ebook.description,
      'coverUrl': ebook.coverUrl,
      'category': ebook.category,
      'language': ebook.language,
      'pageCount': ebook.pageCount,
      'fileType': ebook.fileType,
      'fileSize': ebook.fileSize,
      'createdAt': ebook.createdAt.toIso8601String(),
      'accessUrl': ebook.accessUrl,
    };
  }
}
