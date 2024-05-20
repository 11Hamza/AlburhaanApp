class FavoriteBookDetail {
  final int biblioId;
  final String title;
  final String author;
  final String? imageUrl;
  final String id; // For deletion purposes

  FavoriteBookDetail({
    required this.biblioId,
    required this.title,
    required this.author,
    this.imageUrl,
    required this.id,
  });

  factory FavoriteBookDetail.fromFirestore(Map<String, dynamic> firestore, String docId) {
    print("Firestore data: $firestore"); // Debug statement

    int biblioId;
    if (firestore['biblioId'] is int) {
      biblioId = firestore['biblioId'];
    } else if (firestore['biblioId'] is String) {
      biblioId = int.tryParse(firestore['biblioId']) ?? 0;
    } else {
      biblioId = 0; // Default to 0 if biblioId is missing or invalid
    }

    print("Parsed biblioId: $biblioId"); // Debug statement

    return FavoriteBookDetail(
      biblioId: biblioId,
      title: firestore['title'] as String? ?? 'No Title',
      author: firestore['author'] as String? ?? 'No Author',
      imageUrl: firestore['imageUrl'] as String?,
      id: docId,
    );
  }
}
