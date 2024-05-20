import 'package:json_annotation/json_annotation.dart';

part 'book_response.g.dart'; // Ensures the generated file is correctly linked

@JsonSerializable()
class BookResponse {
  @JsonKey(name: 'biblio_id')
  final int biblioId;
  final String title;
  final String author;
  final String? isbn;
  final String? publicationYear;
  final String? publisher;
  final String? imageUrl;
  final String? id; // For Firestore document ID

  BookResponse({
    required this.biblioId,
    required this.title,
    required this.author,
    this.isbn,
    this.publicationYear,
    this.publisher,
    this.imageUrl,
    this.id,
  });

  factory BookResponse.fromJson(Map<String, dynamic> json) {
    return BookResponse(
      biblioId: json['biblio_id'] ?? 0,
      title: json['title'] ?? 'No Title',
      author: json['author'] ?? 'No Author',
      isbn: json['isbn'],
      publicationYear: json['publication_year'],
      publisher: json['publisher'],
      imageUrl: json['image_url'] ?? "https://library.al-burhaan.org/cgi-bin/koha/opac-image.pl?thumbnail=1&biblionumber=${json['biblio_id']}&filetype=image",
      id: json['id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$BookResponseToJson(this);

  factory BookResponse.fromFirestore(Map<String, dynamic> firestore, String docId) {
    return BookResponse(
      biblioId: firestore['biblioId'] is int
          ? firestore['biblioId']
          : int.tryParse(firestore['biblioId'].toString()) ?? 0,
      title: firestore['title'] as String? ?? 'No Title',
      author: firestore['author'] as String? ?? 'No Author',
      isbn: firestore['isbn'] as String?,
      publicationYear: firestore['publicationYear'] as String?,
      publisher: firestore['publisher'] as String?,
      imageUrl: firestore['imageUrl'] as String?,
      id: docId,
    );
  }
}
