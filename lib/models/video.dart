class Video {
  final String id;
  final String title;
  final String? description;
  final String youtubeId;
  final String? thumbnailUrl;
  final String? category;
  final String? speaker;
  final String? language;
  final int? durationSeconds;
  final DateTime createdAt;
  final String? embedUrl;
  final String? watchUrl;

  Video({
    required this.id,
    required this.title,
    this.description,
    required this.youtubeId,
    this.thumbnailUrl,
    this.category,
    this.speaker,
    this.language,
    this.durationSeconds,
    required this.createdAt,
    this.embedUrl,
    this.watchUrl,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    final ytId = json['youtubeId'] ?? '';
    return Video(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      youtubeId: ytId,
      thumbnailUrl: json['thumbnailUrl'] ??
          (ytId.isNotEmpty ? 'https://img.youtube.com/vi/$ytId/mqdefault.jpg' : null),
      category: json['category'],
      speaker: json['speaker'],
      language: json['language'],
      durationSeconds: json['durationSeconds'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      embedUrl: json['embedUrl'],
      watchUrl: json['watchUrl'],
    );
  }

  String get durationFormatted {
    if (durationSeconds == null) return '';
    final hours = durationSeconds! ~/ 3600;
    final minutes = (durationSeconds! % 3600) ~/ 60;
    final seconds = durationSeconds! % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class VideosResult {
  final List<Video> videos;
  final int total;
  final int page;
  final int pageSize;

  VideosResult({
    required this.videos,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory VideosResult.fromJson(Map<String, dynamic> json) {
    // Backend returns 'data' array, not 'videos'
    final videosList = json['data'] ?? json['videos'] ?? [];
    return VideosResult(
      videos: (videosList as List)
              .map((v) => Video.fromJson(v))
              .toList(),
      total: json['pagination']?['total'] ?? 0,
      page: json['pagination']?['page'] ?? 1,
      pageSize: json['pagination']?['perPage'] ?? json['pagination']?['pageSize'] ?? 20,
    );
  }

  bool get hasMore => videos.length < total;
}

class ContentCategory {
  final String name;
  final int ebookCount;
  final int videoCount;

  ContentCategory({
    required this.name,
    required this.ebookCount,
    required this.videoCount,
  });

  factory ContentCategory.fromJson(Map<String, dynamic> json) {
    return ContentCategory(
      name: json['name'] ?? '',
      ebookCount: json['ebookCount'] ?? 0,
      videoCount: json['videoCount'] ?? 0,
    );
  }

  int get totalCount => ebookCount + videoCount;
}
