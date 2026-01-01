import 'book.dart';

class Favorite {
  final String id;
  final int biblioId;
  final DateTime addedAt;
  final Book? book;

  Favorite({
    required this.id,
    required this.biblioId,
    required this.addedAt,
    this.book,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] ?? '',
      biblioId: json['biblioId'] ?? 0,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'])
          : DateTime.now(),
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
    );
  }
}
