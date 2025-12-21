import 'book.dart';

class ReadingList {
  final String id;
  final String name;
  final String? description;
  final bool isPublic;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ReadingListItem>? items;

  ReadingList({
    required this.id,
    required this.name,
    this.description,
    this.isPublic = false,
    this.itemCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  factory ReadingList.fromJson(Map<String, dynamic> json) {
    return ReadingList(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      isPublic: json['isPublic'] ?? false,
      itemCount: json['itemCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((i) => ReadingListItem.fromJson(i))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isPublic': isPublic,
      'itemCount': itemCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ReadingListItem {
  final String id;
  final int biblioId;
  final String? notes;
  final String status;
  final int sortOrder;
  final DateTime addedAt;
  final Book? book;

  ReadingListItem({
    required this.id,
    required this.biblioId,
    this.notes,
    this.status = 'to_read',
    this.sortOrder = 0,
    required this.addedAt,
    this.book,
  });

  factory ReadingListItem.fromJson(Map<String, dynamic> json) {
    return ReadingListItem(
      id: json['id']?.toString() ?? '',
      biblioId: json['biblioId'] ?? 0,
      notes: json['notes'],
      status: json['status'] ?? 'to_read',
      sortOrder: json['sortOrder'] ?? 0,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'])
          : DateTime.now(),
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'reading':
        return 'Reading';
      case 'completed':
        return 'Completed';
      case 'to_read':
      default:
        return 'To Read';
    }
  }
}
