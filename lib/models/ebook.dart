class Ebook {
  final String id;
  final String title;
  final String? author;
  final String? description;
  final String? coverUrl;
  final String? category;
  final String? language;
  final int? pageCount;
  final String? fileType;
  final int? fileSize;
  final DateTime createdAt;
  final String? accessUrl;

  Ebook({
    required this.id,
    required this.title,
    this.author,
    this.description,
    this.coverUrl,
    this.category,
    this.language,
    this.pageCount,
    this.fileType,
    this.fileSize,
    required this.createdAt,
    this.accessUrl,
  });

  factory Ebook.fromJson(Map<String, dynamic> json) {
    return Ebook(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      author: json['author'],
      description: json['description'],
      coverUrl: json['coverUrl'],
      category: json['category'],
      language: json['language'],
      pageCount: json['pageCount'],
      fileType: json['fileType'],
      fileSize: json['fileSize'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      accessUrl: json['accessUrl'],
    );
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class EbooksResult {
  final List<Ebook> ebooks;
  final int total;
  final int page;
  final int pageSize;

  EbooksResult({
    required this.ebooks,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory EbooksResult.fromJson(Map<String, dynamic> json) {
    return EbooksResult(
      ebooks: (json['ebooks'] as List?)
              ?.map((e) => Ebook.fromJson(e))
              .toList() ??
          [],
      total: json['pagination']?['total'] ?? 0,
      page: json['pagination']?['page'] ?? 1,
      pageSize: json['pagination']?['pageSize'] ?? 20,
    );
  }

  bool get hasMore => ebooks.length < total;
}
